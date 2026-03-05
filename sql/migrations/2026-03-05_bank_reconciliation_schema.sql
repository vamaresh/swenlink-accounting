-- Bank Reconciliation Schema
-- Support for matching bank transactions to invoices/bills and tracking reconciliation status

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
-- Smart rules engine for auto-categorizing transactions
CREATE TABLE IF NOT EXISTS public.bank_categorization_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  rule_name text NOT NULL,
  priority int DEFAULT 0,
  enabled boolean DEFAULT true,
  
  -- Matching conditions (all are optional, multiple can be combined)
  match_description_contains text, -- Case-insensitive substring match
  match_description_regex text, -- Regex pattern
  match_reference_contains text,
  match_from_party text,
  match_to_party text,
  match_amount_min decimal(15,2),
  match_amount_max decimal(15,2),
  match_transaction_type text, -- e.g., 'FASTER_PAYMENTS_IN', 'DIRECT_DEBIT'
  
  -- Actions when rule matches
  assign_category text NOT NULL, -- e.g., 'Rent', 'Salaries', 'Software', 'Sales'
  assign_account_code text, -- Chart of accounts code
  assign_matched_type text CHECK (assign_matched_type IN ('invoice', 'bill', 'expense', 'transfer', 'other')),
  auto_reconcile boolean DEFAULT false, -- If true, mark as reconciled automatically
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by text
);

-- Index for faster rule matching
CREATE INDEX IF NOT EXISTS idx_bank_cat_rules_company ON public.bank_categorization_rules(company_id, enabled, priority);

-- Journal Entries Table for GL Integration
-- Double-entry bookkeeping journal entries
CREATE TABLE IF NOT EXISTS public.journal_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  entry_date date NOT NULL,
  entry_number text, -- e.g., 'JE-2026-001'
  description text NOT NULL,
  source_type text, -- 'bank_transaction', 'invoice', 'manual', etc.
  source_id uuid, -- Reference to bank_transaction, invoice, etc.
  status text DEFAULT 'posted' CHECK (status IN ('draft', 'posted', 'void')),
  created_at timestamptz DEFAULT now(),
  created_by text,
  posted_at timestamptz,
  posted_by text
);

-- Journal Entry Lines (the actual debits and credits)
CREATE TABLE IF NOT EXISTS public.journal_entry_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_entry_id uuid NOT NULL REFERENCES public.journal_entries(id) ON DELETE CASCADE,
  line_number int NOT NULL,
  account_code text NOT NULL, -- From chart of accounts
  account_name text, -- Denormalized for display
  description text,
  debit_amount decimal(15,2) DEFAULT 0 CHECK (debit_amount >= 0),
  credit_amount decimal(15,2) DEFAULT 0 CHECK (credit_amount >= 0),
  CHECK (NOT (debit_amount > 0 AND credit_amount > 0)) -- Can't have both debit and credit
);

-- Chart of Accounts Table
-- Standard UK accounting codes with FRS 105 mapping
CREATE TABLE IF NOT EXISTS public.chart_of_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  account_code text NOT NULL,
  account_name text NOT NULL,
  account_type text NOT NULL CHECK (account_type IN ('asset', 'liability', 'equity', 'revenue', 'expense')),
  parent_code text, -- For hierarchical accounts (e.g., 1000 -> 1100 -> 1110)
  is_active boolean DEFAULT true,
  is_system boolean DEFAULT false, -- System accounts can't be deleted
  normal_balance text CHECK (normal_balance IN ('debit', 'credit')),
  frs105_tag text, -- Link to FRS 105 reporting
  description text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(company_id, account_code)
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_chart_accounts_company ON public.chart_of_accounts(company_id, is_active);
CREATE INDEX IF NOT EXISTS idx_journal_entries_company ON public.journal_entries(company_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_journal_lines_entry ON public.journal_entry_lines(journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_bank_txn_reconciled ON public.bank_transactions(company_id, reconciled);

-- RLS Policies for new tables
ALTER TABLE public.bank_categorization_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entry_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chart_of_accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage categorization rules for their companies" ON public.bank_categorization_rules;
CREATE POLICY "Users can manage categorization rules for their companies"
ON public.bank_categorization_rules FOR ALL
USING (company_id IN (SELECT id FROM public.companies WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can manage journal entries for their companies" ON public.journal_entries;
CREATE POLICY "Users can manage journal entries for their companies"
ON public.journal_entries FOR ALL
USING (company_id IN (SELECT id FROM public.companies WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can view journal entry lines" ON public.journal_entry_lines;
CREATE POLICY "Users can view journal entry lines"
ON public.journal_entry_lines FOR SELECT
USING (
  journal_entry_id IN (
    SELECT je.id FROM public.journal_entries je
    JOIN public.companies c ON c.id = je.company_id
    WHERE c.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can manage journal entry lines" ON public.journal_entry_lines;
CREATE POLICY "Users can manage journal entry lines"
ON public.journal_entry_lines FOR INSERT
WITH CHECK (
  journal_entry_id IN (
    SELECT je.id FROM public.journal_entries je
    JOIN public.companies c ON c.id = je.company_id
    WHERE c.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can manage chart of accounts for their companies" ON public.chart_of_accounts;
CREATE POLICY "Users can manage chart of accounts for their companies"
ON public.chart_of_accounts FOR ALL
USING (company_id IN (SELECT id FROM public.companies WHERE user_id = auth.uid()));

-- Insert default UK chart of accounts
-- This will be populated when a company is created
-- Sample accounts based on standard UK accounting
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
