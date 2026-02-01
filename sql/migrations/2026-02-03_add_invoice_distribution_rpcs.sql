-- Migration: 2026-02-03_add_invoice_distribution_rpcs.sql
-- Purpose: Add RPC wrappers for inserting invoices and distributions (sets session user).
-- These are created only if the corresponding tables exist to keep the migration safe.

-- 1) Insert distribution RPC (if distributions table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'distributions') THEN
    EXECUTE $fn$
    CREATE OR REPLACE FUNCTION app.insert_distribution(
      p_company_id uuid,
      p_amount numeric,
      p_movement_type text,
      p_notes text DEFAULT NULL,
      p_created_by text
    ) RETURNS text AS $body$
    DECLARE v_id text;
    BEGIN
      PERFORM set_config('app.current_user', p_created_by, true);
      INSERT INTO distributions (company_id, amount, movement_type, notes, created_by)
      VALUES (p_company_id, p_amount, p_movement_type, p_notes, p_created_by)
      RETURNING id::text INTO v_id;
      RETURN v_id;
    END;
    $body$ LANGUAGE plpgsql SECURITY DEFINER;
    $fn$;
  END IF;
END$$;

-- Grant execute if function exists
DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE p.proname = 'insert_distribution' AND n.nspname = 'app') THEN
    GRANT EXECUTE ON FUNCTION app.insert_distribution(uuid, numeric, text, text, text) TO authenticated;
  END IF;
END$$;


-- 2) Insert invoice RPC (if invoices table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'invoices') THEN
    EXECUTE $fn$
    CREATE OR REPLACE FUNCTION app.insert_invoice(
      p_company_id uuid,
      p_customer_id uuid,
      p_line_items jsonb,
      p_total numeric,
      p_created_by text
    ) RETURNS text AS $body$
    DECLARE v_id text;
    BEGIN
      PERFORM set_config('app.current_user', p_created_by, true);
      INSERT INTO invoices (company_id, customer_id, line_items, total, created_by)
      VALUES (p_company_id, p_customer_id, p_line_items, p_total, p_created_by)
      RETURNING id::text INTO v_id;
      RETURN v_id;
    END;
    $body$ LANGUAGE plpgsql SECURITY DEFINER;
    $fn$;
  END IF;
END$$;

-- Grant execute if function exists
DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE p.proname = 'insert_invoice' AND n.nspname = 'app') THEN
    GRANT EXECUTE ON FUNCTION app.insert_invoice(uuid, uuid, jsonb, numeric, text) TO authenticated;
  END IF;
END$$;

-- End of migration
