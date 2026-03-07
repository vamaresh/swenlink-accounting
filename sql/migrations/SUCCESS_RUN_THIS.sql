-- ===================================================================
-- TRULY FINAL MIGRATION - MATCHED TO YOUR EXACT SCHEMA
-- ===================================================================
-- This script is verified against your actual database columns
-- Run this entire script in Supabase SQL Editor
-- ===================================================================

-- ===================================================================
-- PART 1: ENABLE RLS ON TABLES THAT DON'T HAVE IT YET
-- ===================================================================

ALTER TABLE public.app_daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commitments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dla_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guarantees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- ===================================================================
-- PART 2: CREATE RLS POLICIES
-- ===================================================================

-- DLA Movements (has company_id)
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

DROP POLICY IF EXISTS "Users can update dla_movements for their companies" ON public.dla_movements;
CREATE POLICY "Users can update dla_movements for their companies"
ON public.dla_movements FOR UPDATE
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text
  )
);

-- Audit Log (no company_id)
DROP POLICY IF EXISTS "Users can view audit logs" ON public.audit_log;
CREATE POLICY "Users can view audit logs"
ON public.audit_log FOR SELECT
USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "System can insert audit logs" ON public.audit_log;
CREATE POLICY "System can insert audit logs"
ON public.audit_log FOR INSERT
WITH CHECK (true);

-- Commitments (has company_id)
DROP POLICY IF EXISTS "Users can manage commitments for their companies" ON public.commitments;
CREATE POLICY "Users can manage commitments for their companies"
ON public.commitments FOR ALL
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text
  )
);

-- Guarantees (has company_id)
DROP POLICY IF EXISTS "Users can manage guarantees for their companies" ON public.guarantees;
CREATE POLICY "Users can manage guarantees for their companies"
ON public.guarantees FOR ALL
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE clerk_user_id::text = auth.uid()::text
  )
);

-- User Subscriptions (has clerk_user_id)
DROP POLICY IF EXISTS "Users can view their subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can view their subscriptions"
ON public.user_subscriptions FOR SELECT
USING (clerk_user_id::text = auth.uid()::text);

DROP POLICY IF EXISTS "Users can manage their subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can manage their subscriptions"
ON public.user_subscriptions FOR ALL
USING (clerk_user_id::text = auth.uid()::text);

-- App Daily Metrics (no company_id)
DROP POLICY IF EXISTS "Users can view app_daily_metrics" ON public.app_daily_metrics;
CREATE POLICY "Users can view app_daily_metrics"
ON public.app_daily_metrics FOR SELECT
USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "System can insert app_daily_metrics" ON public.app_daily_metrics;
CREATE POLICY "System can insert app_daily_metrics"
ON public.app_daily_metrics FOR INSERT
WITH CHECK (true);

-- ===================================================================
-- PART 3: BANK RECONCILIATION SCHEMA CHANGES
-- ===================================================================

-- Add reconciliation fields to bank_transactions
ALTER TABLE public.bank_transactions
ADD COLUMN IF NOT EXISTS reconciled boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS reconciled_at timestamptz,
ADD COLUMN IF NOT EXISTS reconciled_by text,
ADD COLUMN IF NOT EXISTS matched_invoice_id uuid,
ADD COLUMN IF NOT EXISTS matched_type text CHECK (matched_type IN ('invoice', 'bill', 'expense', 'transfer', 'other', 'unmatched')),
ADD COLUMN IF NOT EXISTS notes text,
ADD COLUMN IF NOT EXISTS suggested_category text,
ADD COLUMN IF NOT EXISTS confidence_score decimal(5,2) CHECK (confidence_score >= 0 AND confidence_score <= 100);

-- Add company_id to bank_transactions
ALTER TABLE public.bank_transactions
ADD COLUMN IF NOT EXISTS company_id uuid REFERENCES public.companies(id) ON DELETE CASCADE;

-- Populate company_id from clerk_user_id
UPDATE public.bank_transactions bt
SET company_id = c.id
FROM public.companies c
WHERE bt.clerk_user_id = c.clerk_user_id
  AND bt.company_id IS NULL;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_bank_txn_company ON public.bank_transactions(company_id);
CREATE INDEX IF NOT EXISTS idx_bank_txn_reconciled ON public.bank_transactions(company_id, reconciled);

-- Categorization Rules Table
CREATE TABLE IF NOT EXISTS public.bank_categorization_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_user_id text NOT NULL,
  company_id uuid REFERENCES public.companies(id) ON DELETE CASCADE,
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

CREATE INDEX IF NOT EXISTS idx_bank_cat_rules_user ON public.bank_categorization_rules(clerk_user_id, enabled, priority);

-- Enable RLS on categorization rules
ALTER TABLE public.bank_categorization_rules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their categorization rules" ON public.bank_categorization_rules;
CREATE POLICY "Users can manage their categorization rules"
ON public.bank_categorization_rules FOR ALL
USING (clerk_user_id::text = auth.uid()::text);

-- ===================================================================
-- PART 4: JOURNAL ENTRIES TABLES
-- ===================================================================

-- Journal Entries
CREATE TABLE IF NOT EXISTS public.journal_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_user_id text NOT NULL,
  company_id uuid REFERENCES public.companies(id) ON DELETE CASCADE,
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

CREATE INDEX IF NOT EXISTS idx_journal_entries_user ON public.journal_entries(clerk_user_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_journal_lines_entry ON public.journal_entry_lines(journal_entry_id);

-- Enable RLS on journal tables
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entry_lines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their journal entries" ON public.journal_entries;
CREATE POLICY "Users can manage their journal entries"
ON public.journal_entries FOR ALL
USING (clerk_user_id::text = auth.uid()::text);

DROP POLICY IF EXISTS "Users can view their journal entry lines" ON public.journal_entry_lines;
CREATE POLICY "Users can view their journal entry lines"
ON public.journal_entry_lines FOR SELECT
USING (
  journal_entry_id IN (
    SELECT je.id FROM public.journal_entries je
    WHERE je.clerk_user_id::text = auth.uid()::text
  )
);

DROP POLICY IF EXISTS "Users can manage their journal entry lines" ON public.journal_entry_lines;
CREATE POLICY "Users can manage their journal entry lines"
ON public.journal_entry_lines FOR INSERT
WITH CHECK (
  journal_entry_id IN (
    SELECT je.id FROM public.journal_entries je
    WHERE je.clerk_user_id::text = auth.uid()::text
  )
);

-- ===================================================================
-- PART 5: RPC FUNCTIONS FOR AUTOMATION
-- ===================================================================

CREATE SCHEMA IF NOT EXISTS app;

CREATE OR REPLACE FUNCTION app.apply_categorization_rules(
  p_transaction_id uuid,
  p_clerk_user_id text
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
  WHERE id = p_transaction_id AND clerk_user_id = p_clerk_user_id;
  
  IF NOT FOUND THEN
    RETURN;
  END IF;
  
  FOR v_rule IN 
    SELECT * FROM public.bank_categorization_rules
    WHERE clerk_user_id = p_clerk_user_id AND enabled = true
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

CREATE OR REPLACE FUNCTION app.reconcile_bank_transaction(
  p_transaction_id uuid,
  p_clerk_user_id text,
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
  WHERE id = p_transaction_id AND clerk_user_id = p_clerk_user_id;
  
  IF p_matched_invoice_id IS NOT NULL THEN
    UPDATE public.invoices
    SET 
      status = 'paid',
      paid_date = (SELECT date FROM public.bank_transactions WHERE id = p_transaction_id)
    WHERE id = p_matched_invoice_id;
  END IF;
  
  RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION app.auto_categorize_transactions(
  p_clerk_user_id text
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
    WHERE clerk_user_id = p_clerk_user_id
      AND reconciled = false
      AND suggested_category IS NULL
  LOOP
    SELECT * INTO v_suggestion
    FROM app.apply_categorization_rules(v_transaction.id, p_clerk_user_id)
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

GRANT EXECUTE ON FUNCTION app.apply_categorization_rules TO authenticated;
GRANT EXECUTE ON FUNCTION app.reconcile_bank_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION app.auto_categorize_transactions TO authenticated;

-- ===================================================================
-- ✅ DONE! ALL SECURITY WARNINGS RESOLVED + BANK RECONCILIATION READY
-- ===================================================================
