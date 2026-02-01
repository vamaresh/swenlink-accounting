-- Migration: 2026-02-01_add_audit_and_dla.sql
-- Purpose: Add append-only audit_log, audit triggers for financial tables,
--          Director's Loan Account (DLA) table and dividend legality guard.

-- NOTE: Ensure your application sets the session parameter `app.current_user`
--       to the acting user's identifier before performing DML that should be
--       audited. Example: SET LOCAL app.current_user = 'user@example.com';

-- 1) Audit log table (append-only)
CREATE TABLE IF NOT EXISTS audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name TEXT NOT NULL,
  record_id TEXT,
  operation TEXT NOT NULL,
  changed_by TEXT,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  old_value JSONB,
  new_value JSONB
);

-- Make audit_log append-only for normal roles by revoking delete/update privileges.
-- (Do this from a DB user with higher privileges when installing.)
-- REVOKE UPDATE, DELETE ON audit_log FROM PUBLIC;

-- 2) Generic audit trigger function
CREATE OR REPLACE FUNCTION fn_audit_record() RETURNS TRIGGER AS $$
DECLARE
  v_old JSONB := NULL;
  v_new JSONB := NULL;
  v_rec_id TEXT := NULL;
  v_user TEXT := NULL;
BEGIN
  -- capture acting user set by application (optional)
  v_user := current_setting('app.current_user', true);

  IF TG_OP = 'DELETE' THEN
    v_old := to_jsonb(OLD);
    v_rec_id := COALESCE(OLD.id::text, OLD."id"::text, NULL);
    INSERT INTO audit_log(table_name, record_id, operation, changed_by, old_value, new_value)
    VALUES (TG_TABLE_NAME, v_rec_id, TG_OP, v_user, v_old, NULL);
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    v_old := to_jsonb(OLD);
    v_new := to_jsonb(NEW);
    v_rec_id := COALESCE(NEW.id::text, NEW."id"::text, NULL);
    INSERT INTO audit_log(table_name, record_id, operation, changed_by, old_value, new_value)
    VALUES (TG_TABLE_NAME, v_rec_id, TG_OP, v_user, v_old, v_new);
    RETURN NEW;
  ELSIF TG_OP = 'INSERT' THEN
    v_new := to_jsonb(NEW);
    v_rec_id := COALESCE(NEW.id::text, NEW."id"::text, NULL);
    INSERT INTO audit_log(table_name, record_id, operation, changed_by, old_value, new_value)
    VALUES (TG_TABLE_NAME, v_rec_id, TG_OP, v_user, NULL, v_new);
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3) Attach audit triggers to key financial tables
-- Tables to protect: invoices, bills, bank_transactions, transactions, distributions
-- Adjust table names if your schema uses different names.

DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM pg_class WHERE relname = 'invoices') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_invoices' AND tgrelid = 'invoices'::regclass) THEN
      EXECUTE 'CREATE TRIGGER audit_invoices AFTER INSERT OR UPDATE OR DELETE ON invoices FOR EACH ROW EXECUTE FUNCTION fn_audit_record();';
    END IF;
  END IF;
  IF EXISTS(SELECT 1 FROM pg_class WHERE relname = 'bills') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_bills' AND tgrelid = 'bills'::regclass) THEN
      EXECUTE 'CREATE TRIGGER audit_bills AFTER INSERT OR UPDATE OR DELETE ON bills FOR EACH ROW EXECUTE FUNCTION fn_audit_record();';
    END IF;
  END IF;
  IF EXISTS(SELECT 1 FROM pg_class WHERE relname = 'bank_transactions') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_bank_transactions' AND tgrelid = 'bank_transactions'::regclass) THEN
      EXECUTE 'CREATE TRIGGER audit_bank_transactions AFTER INSERT OR UPDATE OR DELETE ON bank_transactions FOR EACH ROW EXECUTE FUNCTION fn_audit_record();';
    END IF;
  END IF;
  IF EXISTS(SELECT 1 FROM pg_class WHERE relname = 'transactions') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_transactions' AND tgrelid = 'transactions'::regclass) THEN
      EXECUTE 'CREATE TRIGGER audit_transactions AFTER INSERT OR UPDATE OR DELETE ON transactions FOR EACH ROW EXECUTE FUNCTION fn_audit_record();';
    END IF;
  END IF;
  IF EXISTS(SELECT 1 FROM pg_class WHERE relname = 'distributions') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_distributions' AND tgrelid = 'distributions'::regclass) THEN
      EXECUTE 'CREATE TRIGGER audit_distributions AFTER INSERT OR UPDATE OR DELETE ON distributions FOR EACH ROW EXECUTE FUNCTION fn_audit_record();';
    END IF;
  END IF;
END$$;

-- 4) Director's Loan Account (DLA) movements table
CREATE TABLE IF NOT EXISTS dla_movements (
  id BIGSERIAL PRIMARY KEY,
  company_id UUID NOT NULL,
  director_id UUID NOT NULL,
  amount NUMERIC NOT NULL, -- positive = director owes company (loan), negative = repayment
  movement_type TEXT NOT NULL, -- 'borrow','repayment','salary','dividend','reimbursable','expense'
  related_invoice_id UUID,
  related_transaction_id UUID,
  notes TEXT,
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Ensure dla_movements are audited as well
DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM pg_class WHERE relname = 'dla_movements') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_dla_movements' AND tgrelid = 'dla_movements'::regclass) THEN
      EXECUTE 'CREATE TRIGGER audit_dla_movements AFTER INSERT OR UPDATE OR DELETE ON dla_movements FOR EACH ROW EXECUTE FUNCTION fn_audit_record();';
    END IF;
  END IF;
END$$;

-- 5) Prevent illegal dividends (simple guard)
-- This assumes you have a 'distributions' table where dividends are recorded,
-- and an 'transactions' table where retained earnings are tracked in account code 'RETAINED_EARNINGS'.

CREATE OR REPLACE FUNCTION fn_prevent_illegal_dividend() RETURNS TRIGGER AS $$
DECLARE
  v_retained NUMERIC := 0;
  v_new_div NUMERIC := 0;
BEGIN
  -- Only act on INSERT or UPDATE where type = 'dividend'
  IF (TG_OP = 'INSERT' AND NEW.movement_type = 'dividend') OR (TG_OP = 'UPDATE' AND NEW.movement_type = 'dividend') THEN
    -- Sum retained earnings from transactions linked to retained earnings account code
    SELECT COALESCE(SUM(t.amount), 0) INTO v_retained
    FROM transactions t
    JOIN accounts a ON a.id = t.account_id
    WHERE a.code = 'RETAINED_EARNINGS' AND a.company_id = COALESCE(NEW.company_id, OLD.company_id);

    v_new_div := COALESCE(NEW.amount, 0);
    IF v_retained - v_new_div < 0 THEN
      RAISE EXCEPTION 'Illegal dividend: retained earnings (%) insufficient for dividend (%)', v_retained, v_new_div;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on distributions table if exists
DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM pg_class WHERE relname = 'distributions') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_prevent_illegal_dividend' AND tgrelid = 'distributions'::regclass) THEN
      EXECUTE 'CREATE TRIGGER trg_prevent_illegal_dividend BEFORE INSERT OR UPDATE ON distributions FOR EACH ROW EXECUTE FUNCTION fn_prevent_illegal_dividend();';
    END IF;
  END IF;
END$$;

-- 6) Notes and guidance
-- To enable the audit user capture, set the following at the start of each DB session
-- where user context exists (e.g. per web request):
--   SET LOCAL app.current_user = 'user@example.com';
-- The app should set that before any transactional writes.

-- End of migration
