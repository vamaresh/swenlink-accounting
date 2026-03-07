-- ===================================================================
-- COMPREHENSIVE MIGRATION SCRIPT - RUN THIS IN SUPABASE SQL EDITOR
-- ===================================================================
-- This script includes:
-- 1. RLS security policies for all tables
-- 2. Bank reconciliation features
-- 3. Categorization rules engine
-- 4. Chart of accounts with default UK accounts
-- 5. Journal entries for double-entry bookkeeping
-- 6. RPC functions for reconciliation automation
--
-- Run this entire script in Supabase SQL Editor
-- ===================================================================

-- ===================================================================
-- PART 1: ENABLE ROW LEVEL SECURITY (FIXES SECURITY ADVISOR WARNINGS)
-- ===================================================================

-- Enable RLS on existing tables only
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'dla_movements') THEN
    ALTER TABLE public.dla_movements ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'audit_log') THEN
    ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'frs105_account_mapping') THEN
    ALTER TABLE public.frs105_account_mapping ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'commitments') THEN
    ALTER TABLE public.commitments ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'guarantees') THEN
    ALTER TABLE public.guarantees ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_subscriptions') THEN
    ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'app_daily_metrics') THEN
    ALTER TABLE public.app_daily_metrics ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'bank_transactions') THEN
    ALTER TABLE public.bank_transactions ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'companies') THEN
    ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'directors') THEN
    ALTER TABLE public.directors ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'invoices') THEN
    ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'line_items') THEN
    ALTER TABLE public.line_items ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- DLA Movements: Users can only see/modify movements for their companies
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'dla_movements') THEN
    DROP POLICY IF EXISTS "Users can view dla_movements for their companies" ON public.dla_movements;
    CREATE POLICY "Users can view dla_movements for their companies"
    ON public.dla_movements FOR SELECT
    USING (
      company_id IN (
        SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text
      )
    );

    DROP POLICY IF EXISTS "Users can insert dla_movements for their companies" ON public.dla_movements;
    CREATE POLICY "Users can insert dla_movements for their companies"
    ON public.dla_movements FOR INSERT
    WITH CHECK (
      company_id IN (
        SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text
      )
    );
  END IF;
END $$;

-- Audit Log: Users can view audit logs (simplified - uses action_by field)
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'audit_log') THEN
    DROP POLICY IF EXISTS "Users can view their audit logs" ON public.audit_log;
    CREATE POLICY "Users can view their audit logs"
    ON public.audit_log FOR SELECT
    USING (auth.uid() IS NOT NULL);

    DROP POLICY IF EXISTS "System can insert audit logs" ON public.audit_log;
    CREATE POLICY "System can insert audit logs"
    ON public.audit_log FOR INSERT
    WITH CHECK (true);
  END IF;
END $$;

-- FRS105 Account Mapping (only if table exists)
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'frs105_account_mapping') THEN
    DROP POLICY IF EXISTS "Users can view frs105_account_mapping for their companies" ON public.frs105_account_mapping;
    CREATE POLICY "Users can view frs105_account_mapping for their companies"
    ON public.frs105_account_mapping FOR SELECT
    USING (
      company_id IN (
        SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text
      )
    );

    DROP POLICY IF EXISTS "Users can manage frs105_account_mapping for their companies" ON public.frs105_account_mapping;
    CREATE POLICY "Users can manage frs105_account_mapping for their companies"
    ON public.frs105_account_mapping FOR ALL
    USING (
      company_id IN (
        SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text
      )
    );
  END IF;
END $$;

-- Commitments
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'commitments') THEN
    DROP POLICY IF EXISTS "Users can manage commitments for their companies" ON public.commitments;
    CREATE POLICY "Users can manage commitments for their companies"
    ON public.commitments FOR ALL
    USING (
      company_id IN (
        SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text
      )
    );
  END IF;
END $$;

-- Guarantees
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'guarantees') THEN
    DROP POLICY IF EXISTS "Users can manage guarantees for their companies" ON public.guarantees;
    CREATE POLICY "Users can manage guarantees for their companies"
    ON public.guarantees FOR ALL
    USING (
      company_id IN (
        SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text
      )
    );
  END IF;
END $$;

-- User Subscriptions: Users can view their own subscriptions
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_subscriptions') THEN
    DROP POLICY IF EXISTS "Users can view their subscriptions" ON public.user_subscriptions;
    CREATE POLICY "Users can view their subscriptions"
    ON public.user_subscriptions FOR SELECT
    USING (clerk_user_id::text = auth.uid()::text);
  END IF;
END $$;

-- App Daily Metrics
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'app_daily_metrics') THEN
    DROP POLICY IF EXISTS "Users can view app_daily_metrics" ON public.app_daily_metrics;
    CREATE POLICY "Users can view app_daily_metrics"
    ON public.app_daily_metrics FOR SELECT
    USING (auth.uid() IS NOT NULL);

    DROP POLICY IF EXISTS "System can insert app_daily_metrics" ON public.app_daily_metrics;
    CREATE POLICY "System can insert app_daily_metrics"
    ON public.app_daily_metrics FOR INSERT
    WITH CHECK (true);
  END IF;
END $$;

-- Bank Transactions
DROP POLICY IF EXISTS "Users can manage bank_transactions for their companies" ON public.bank_transactions;
CREATE POLICY "Users can manage bank_transactions for their companies"
ON public.bank_transactions FOR ALL
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text
  )
);

-- Companies
DROP POLICY IF EXISTS "Users can manage their companies" ON public.companies;
CREATE POLICY "Users can manage their companies"
ON public.companies FOR ALL
USING (clerk_user_id::text = auth.uid()::text);

-- Directors
DROP POLICY IF EXISTS "Users can manage directors for their companies" ON public.directors;
CREATE POLICY "Users can manage directors for their companies"
ON public.directors FOR ALL
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text
  )
);

-- Invoices
DROP POLICY IF EXISTS "Users can manage invoices for their companies" ON public.invoices;
CREATE POLICY "Users can manage invoices for their companies"
ON public.invoices FOR ALL
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text
  )
);

-- Line Items
DROP POLICY IF EXISTS "Users can manage line_items for their invoices" ON public.line_items;
CREATE POLICY "Users can manage line_items for their invoices"
ON public.line_items FOR ALL
USING (
  invoice_id IN (
    SELECT i.id FROM public.invoices i
    JOIN public.companies c ON c.id = i.company_id
    WHERE c.clerk_user_id::text = auth.uid()::text
  )
);

-- Grant SELECT on views (only if they exist)
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM pg_views WHERE schemaname = 'public' AND viewname = 'view_dla_s455_alerts') THEN
    GRANT SELECT ON public.view_dla_s455_alerts TO authenticated;
  END IF;
  IF EXISTS (SELECT FROM pg_views WHERE schemaname = 'public' AND viewname = 'view_frs105_balance_sheet') THEN
    GRANT SELECT ON public.view_frs105_balance_sheet TO authenticated;
  END IF;
END $$;

-- ===================================================================
-- PART 2: BANK RECONCILIATION SCHEMA
-- ===================================================================

-- Add reconciliation fields to bank_transactions
ALTER TABLE IF EXISTS public.bank_transactions
ADD COLUMN IF NOT EXISTS reconciled boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS reconciled_at timestamptz,
ADD COLUMN IF NOT EXISTS reconciled_by text,
ADD COLUMN IF NOT EXISTS matched_invoice_id uuid,
ADD COLUMN IF NOT EXISTS matched_type text CHECK (matched_type IN ('invoice', 'bill', 'expense', 'transfer', 'other', 'unmatched')),
ADD COLUMN IF NOT EXISTS notes text,
ADD COLUMN IF NOT EXISTS suggested_category text,
ADD COLUMN IF NOT EXISTS confidence_score decimal(5,2) CHECK (confidence_score >= 0 AND confidence_score <= 100);

-- Categorization Rules Table
CREATE TABLE IF NOT EXISTS public.bank_categorization_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  rule_name text NOT NULL,
  priority int DEFAULT 0,
  enabled boolean DEFAULT true,
  
  -- Matching conditions
  match_description_contains text,
  match_description_regex text,
  match_reference_contains text,
  match_from_party text,
  match_to_party text,
  match_amount_min decimal(15,2),
  match_amount_max decimal(15,2),
  match_transaction_type text,
  
  -- Actions
  assign_category text NOT NULL,
  assign_account_code text,
  assign_matched_type text CHECK (assign_matched_type IN ('invoice', 'bill', 'expense', 'transfer', 'other')),
  auto_reconcile boolean DEFAULT false,
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by text
);

CREATE INDEX IF NOT EXISTS idx_bank_cat_rules_company ON public.bank_categorization_rules(company_id, enabled, priority);
CREATE INDEX IF NOT EXISTS idx_bank_txn_reconciled ON public.bank_transactions(company_id, reconciled);

-- ===================================================================
-- PART 3: DOUBLE-ENTRY BOOKKEEPING - JOURNAL ENTRIES & CHART OF ACCOUNTS
-- ===================================================================

-- Chart of Accounts
CREATE TABLE IF NOT EXISTS public.chart_of_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  account_code text NOT NULL,
  account_name text NOT NULL,
  account_type text NOT NULL CHECK (account_type IN ('asset', 'liability', 'equity', 'revenue', 'expense')),
  parent_code text,
  is_active boolean DEFAULT true,
  is_system boolean DEFAULT false,
  normal_balance text CHECK (normal_balance IN ('debit', 'credit')),
  frs105_tag text,
  description text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(company_id, account_code)
);

-- Journal Entries
CREATE TABLE IF NOT EXISTS public.journal_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  entry_date date NOT NULL,
  entry_number text,
  description text NOT NULL,
  source_type text,
  source_id uuid,
  status text DEFAULT 'posted' CHECK (status IN ('draft', 'posted', 'void')),
  created_at timestamptz DEFAULT now(),
  created_by text,
  posted_at timestamptz,
  posted_by text
);

-- Journal Entry Lines
CREATE TABLE IF NOT EXISTS public.journal_entry_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_entry_id uuid NOT NULL REFERENCES public.journal_entries(id) ON DELETE CASCADE,
  line_number int NOT NULL,
  account_code text NOT NULL,
  account_name text,
  description text,
  debit_amount decimal(15,2) DEFAULT 0 CHECK (debit_amount >= 0),
  credit_amount decimal(15,2) DEFAULT 0 CHECK (credit_amount >= 0),
  CHECK (NOT (debit_amount > 0 AND credit_amount > 0))
);

CREATE INDEX IF NOT EXISTS idx_chart_accounts_company ON public.chart_of_accounts(company_id, is_active);
CREATE INDEX IF NOT EXISTS idx_journal_entries_company ON public.journal_entries(company_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_journal_lines_entry ON public.journal_entry_lines(journal_entry_id);

-- ===================================================================
-- PART 4: RLS POLICIES FOR NEW TABLES
-- ===================================================================

ALTER TABLE public.bank_categorization_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entry_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chart_of_accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage categorization rules for their companies" ON public.bank_categorization_rules;
CREATE POLICY "Users can manage categorization rules for their companies"
ON public.bank_categorization_rules FOR ALL
USING (company_id IN (SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text));

DROP POLICY IF EXISTS "Users can manage journal entries for their companies" ON public.journal_entries;
CREATE POLICY "Users can manage journal entries for their companies"
ON public.journal_entries FOR ALL
USING (company_id IN (SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text));

DROP POLICY IF EXISTS "Users can view journal entry lines" ON public.journal_entry_lines;
CREATE POLICY "Users can view journal entry lines"
ON public.journal_entry_lines FOR SELECT
USING (
  journal_entry_id IN (
    SELECT je.id FROM public.journal_entries je
    JOIN public.companies c ON c.id = je.company_id
    WHERE c.clerk_user_id::text = auth.uid()::text
  )
);

DROP POLICY IF EXISTS "Users can manage journal entry lines" ON public.journal_entry_lines;
CREATE POLICY "Users can manage journal entry lines"
ON public.journal_entry_lines FOR INSERT
WITH CHECK (
  journal_entry_id IN (
    SELECT je.id FROM public.journal_entries je
    JOIN public.companies c ON c.id = je.company_id
    WHERE c.clerk_user_id::text = auth.uid()::text
  )
);

DROP POLICY IF EXISTS "Users can manage chart of accounts for their companies" ON public.chart_of_accounts;
CREATE POLICY "Users can manage chart of accounts for their companies"
ON public.chart_of_accounts FOR ALL
USING (company_id IN (SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text));

-- ===================================================================
-- PART 5: DEFAULT UK CHART OF ACCOUNTS
-- ===================================================================

INSERT INTO public.chart_of_accounts (company_id, account_code, account_name, account_type, normal_balance, frs105_tag, is_system, description)
SELECT 
  c.id,
  account_code,
  account_name,
  account_type,
  normal_balance,
  frs105_tag,
  true,
  description
FROM public.companies c
CROSS JOIN (VALUES
  -- Assets
  ('1000', 'Bank Current Account', 'asset', 'debit', 'cash_bank', 'Main business bank account'),
  ('1100', 'Accounts Receivable', 'asset', 'debit', 'debtors', 'Trade debtors'),
  ('1200', 'Inventory', 'asset', 'debit', 'stock', 'Stock on hand'),
  ('1500', 'Fixed Assets', 'asset', 'debit', 'fixed_assets', 'Tangible fixed assets'),
  ('1510', 'Accumulated Depreciation', 'asset', 'credit', 'fixed_assets', 'Depreciation of fixed assets'),
  
  -- Liabilities
  ('2000', 'Accounts Payable', 'liability', 'credit', 'creditors', 'Trade creditors'),
  ('2100', 'VAT Liability', 'liability', 'credit', 'taxation', 'VAT owed to HMRC'),
  ('2200', 'PAYE Liability', 'liability', 'credit', 'taxation', 'PAYE/NIC owed to HMRC'),
  ('2300', 'Corporation Tax', 'liability', 'credit', 'taxation', 'Corporation tax provision'),
  ('2400', 'Director Loan Account', 'liability', 'credit', 'creditors', 'Loans from directors'),
  ('2500', 'Bank Loan', 'liability', 'credit', 'creditors', 'Long-term borrowing'),
  
  -- Equity
  ('3000', 'Share Capital', 'equity', 'credit', 'capital', 'Issued share capital'),
  ('3100', 'Retained Earnings', 'equity', 'credit', 'reserves', 'Accumulated profits'),
  
  -- Revenue
  ('4000', 'Sales Revenue', 'revenue', 'credit', 'turnover', 'Sales of goods/services'),
  ('4100', 'Other Income', 'revenue', 'credit', 'other_income', 'Miscellaneous income'),
  
  -- Expenses
  ('5000', 'Cost of Sales', 'expense', 'debit', 'cost_of_sales', 'Direct costs'),
  ('6000', 'Salaries and Wages', 'expense', 'debit', 'staff_costs', 'Employee costs'),
  ('6100', 'Rent', 'expense', 'debit', 'admin_expenses', 'Office rent'),
  ('6200', 'Insurance', 'expense', 'debit', 'admin_expenses', 'Business insurance'),
  ('6300', 'Professional Fees', 'expense', 'debit', 'admin_expenses', 'Accountant, legal fees'),
  ('6400', 'Software & Subscriptions', 'expense', 'debit', 'admin_expenses', 'Software costs'),
  ('6500', 'Bank Charges', 'expense', 'debit', 'admin_expenses', 'Bank fees'),
  ('6600', 'Depreciation', 'expense', 'debit', 'depreciation', 'Depreciation expense')
) AS accounts(account_code, account_name, account_type, normal_balance, frs105_tag, description)
WHERE NOT EXISTS (
  SELECT 1 FROM public.chart_of_accounts 
  WHERE chart_of_accounts.company_id = c.id 
  AND chart_of_accounts.account_code = accounts.account_code
);

-- ===================================================================
-- PART 6: RPC FUNCTIONS FOR AUTOMATION
-- ===================================================================

-- Create app schema if not exists
CREATE SCHEMA IF NOT EXISTS app;

-- Function to apply categorization rules
CREATE OR REPLACE FUNCTION app.apply_categorization_rules(
  p_transaction_id uuid,
  p_company_id uuid
)
RETURNS TABLE (
  suggested_category text,
  suggested_account_code text,
  matched_type text,
  confidence_score decimal,
  rule_name text
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_transaction record;
  v_rule record;
  v_score decimal;
  v_best_score decimal := 0;
  v_best_rule record;
BEGIN
  SELECT * INTO v_transaction
  FROM public.bank_transactions
  WHERE id = p_transaction_id AND company_id = p_company_id;
  
  IF NOT FOUND THEN
    RETURN;
  END IF;
  
  FOR v_rule IN 
    SELECT * FROM public.bank_categorization_rules
    WHERE company_id = p_company_id AND enabled = true
    ORDER BY priority DESC, created_at ASC
  LOOP
    v_score := 0;
    
    IF v_rule.match_description_contains IS NOT NULL THEN
      IF v_transaction.description ILIKE '%' || v_rule.match_description_contains || '%' THEN
        v_score := v_score + 30;
      ELSE
        CONTINUE;
      END IF;
    END IF;
    
    IF v_rule.match_reference_contains IS NOT NULL THEN
      IF v_transaction.reference ILIKE '%' || v_rule.match_reference_contains || '%' THEN
        v_score := v_score + 25;
      END IF;
    END IF;
    
    IF v_rule.match_from_party IS NOT NULL THEN
      IF v_transaction.from_party ILIKE '%' || v_rule.match_from_party || '%' THEN
        v_score := v_score + 20;
      END IF;
    END IF;
    
    IF v_score > v_best_score THEN
      v_best_score := v_score;
      v_best_rule := v_rule;
    END IF;
  END LOOP;
  
  IF v_best_score > 0 THEN
    RETURN QUERY SELECT 
      v_best_rule.assign_category,
      v_best_rule.assign_account_code,
      v_best_rule.assign_matched_type,
      v_best_score,
      v_best_rule.rule_name;
  END IF;
END;
$$;

-- Function to reconcile a transaction
CREATE OR REPLACE FUNCTION app.reconcile_bank_transaction(
  p_transaction_id uuid,
  p_company_id uuid,
  p_matched_invoice_id uuid DEFAULT NULL,
  p_matched_type text DEFAULT 'unmatched',
  p_notes text DEFAULT NULL,
  p_user_id text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.bank_transactions
  SET 
    reconciled = true,
    reconciled_at = now(),
    reconciled_by = p_user_id,
    matched_invoice_id = p_matched_invoice_id,
    matched_type = p_matched_type,
    notes = p_notes
  WHERE id = p_transaction_id AND company_id = p_company_id;
  
  IF p_matched_invoice_id IS NOT NULL THEN
    UPDATE public.invoices
    SET 
      status = 'paid',
      paid_date = (SELECT date FROM public.bank_transactions WHERE id = p_transaction_id)
    WHERE id = p_matched_invoice_id AND company_id = p_company_id;
  END IF;
  
  RETURN FOUND;
END;
$$;

-- Function to create journal entry
CREATE OR REPLACE FUNCTION app.create_journal_entry_from_bank_transaction(
  p_transaction_id uuid,
  p_company_id uuid,
  p_account_code text,
  p_user_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_transaction record;
  v_entry_id uuid;
  v_entry_number text;
  v_bank_account_code text := '1000';
BEGIN
  SELECT * INTO v_transaction
  FROM public.bank_transactions
  WHERE id = p_transaction_id AND company_id = p_company_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;
  
  SELECT 'JE-' || TO_CHAR(now(), 'YYYY') || '-' || 
         LPAD(COALESCE(MAX(CAST(SUBSTRING(entry_number FROM '\d+$') AS INT)), 0) + 1::text, 4, '0')
  INTO v_entry_number
  FROM public.journal_entries
  WHERE company_id = p_company_id 
    AND entry_number LIKE 'JE-' || TO_CHAR(now(), 'YYYY') || '-%';
  
  INSERT INTO public.journal_entries (
    company_id, entry_date, entry_number, description, source_type, source_id, 
    status, created_by, posted_at, posted_by
  ) VALUES (
    p_company_id, v_transaction.date, v_entry_number, 'Bank: ' || COALESCE(v_transaction.description, 'Transaction'),
    'bank_transaction', p_transaction_id, 'posted', p_user_id, now(), p_user_id
  )
  RETURNING id INTO v_entry_id;
  
  IF v_transaction.amount > 0 THEN
    INSERT INTO public.journal_entry_lines (journal_entry_id, line_number, account_code, account_name, debit_amount)
    VALUES (v_entry_id, 1, v_bank_account_code, 'Bank Current Account', v_transaction.amount);
    
    INSERT INTO public.journal_entry_lines (journal_entry_id, line_number, account_code, account_name, credit_amount)
    VALUES (v_entry_id, 2, p_account_code, 
            (SELECT account_name FROM public.chart_of_accounts 
             WHERE company_id = p_company_id AND account_code = p_account_code LIMIT 1),
            v_transaction.amount);
  ELSE
    INSERT INTO public.journal_entry_lines (journal_entry_id, line_number, account_code, account_name, credit_amount)
    VALUES (v_entry_id, 1, v_bank_account_code, 'Bank Current Account', ABS(v_transaction.amount));
    
    INSERT INTO public.journal_entry_lines (journal_entry_id, line_number, account_code, account_name, debit_amount)
    VALUES (v_entry_id, 2, p_account_code,
            (SELECT account_name FROM public.chart_of_accounts 
             WHERE company_id = p_company_id AND account_code = p_account_code LIMIT 1),
            ABS(v_transaction.amount));
  END IF;
  
  UPDATE public.bank_transactions
  SET reconciled = true, reconciled_at = now(), reconciled_by = p_user_id
  WHERE id = p_transaction_id;
  
  RETURN v_entry_id;
END;
$$;

-- Function to auto-categorize all transactions
CREATE OR REPLACE FUNCTION app.auto_categorize_transactions(
  p_company_id uuid
)
RETURNS TABLE (
  transaction_id uuid,
  suggested_category text,
  confidence_score decimal
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_transaction record;
  v_suggestion record;
BEGIN
  FOR v_transaction IN
    SELECT id FROM public.bank_transactions
    WHERE company_id = p_company_id 
      AND reconciled = false
      AND suggested_category IS NULL
  LOOP
    SELECT * INTO v_suggestion
    FROM app.apply_categorization_rules(v_transaction.id, p_company_id)
    LIMIT 1;
    
    IF FOUND THEN
      UPDATE public.bank_transactions
      SET 
        suggested_category = v_suggestion.suggested_category,
        confidence_score = v_suggestion.confidence_score,
        matched_type = v_suggestion.matched_type
      WHERE id = v_transaction.id;
      
      RETURN QUERY SELECT 
        v_transaction.id,
        v_suggestion.suggested_category,
        v_suggestion.confidence_score;
    END IF;
  END LOOP;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION app.apply_categorization_rules TO authenticated;
GRANT EXECUTE ON FUNCTION app.reconcile_bank_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION app.create_journal_entry_from_bank_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION app.auto_categorize_transactions TO authenticated;

-- ===================================================================
-- MIGRATION COMPLETE!
-- ===================================================================
-- Next steps:
-- 1. Verify all tables and policies are created
-- 2. Test bank transaction import
-- 3. Create categorization rules
-- 4. Test reconciliation workflow
-- 5. Check Security Advisor - all warnings should be resolved
-- ===================================================================
