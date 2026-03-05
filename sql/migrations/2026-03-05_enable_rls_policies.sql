-- Enable Row Level Security (RLS) on all tables
-- This addresses the Supabase Security Advisor warnings

-- Enable RLS on all tables
ALTER TABLE IF EXISTS public.dla_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.frs105_account_mapping ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.commitments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.guarantees ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.app_daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.bank_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.directors ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.line_items ENABLE ROW LEVEL SECURITY;

-- DLA Movements: Users can only see/modify movements for their companies
DROP POLICY IF EXISTS "Users can view dla_movements for their companies" ON public.dla_movements;
CREATE POLICY "Users can view dla_movements for their companies"
ON public.dla_movements FOR SELECT
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can insert dla_movements for their companies" ON public.dla_movements;
CREATE POLICY "Users can insert dla_movements for their companies"
ON public.dla_movements FOR INSERT
WITH CHECK (
  company_id IN (
    SELECT id FROM public.companies WHERE user_id = auth.uid()
  )
);

-- Audit Log: Users can view their own audit logs
DROP POLICY IF EXISTS "Users can view their audit logs" ON public.audit_log;
CREATE POLICY "Users can view their audit logs"
ON public.audit_log FOR SELECT
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "System can insert audit logs" ON public.audit_log;
CREATE POLICY "System can insert audit logs"
ON public.audit_log FOR INSERT
WITH CHECK (true);

-- FRS105 Account Mapping: Users can manage mappings for their companies
DROP POLICY IF EXISTS "Users can view frs105_account_mapping for their companies" ON public.frs105_account_mapping;
CREATE POLICY "Users can view frs105_account_mapping for their companies"
ON public.frs105_account_mapping FOR SELECT
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can manage frs105_account_mapping for their companies" ON public.frs105_account_mapping;
CREATE POLICY "Users can manage frs105_account_mapping for their companies"
ON public.frs105_account_mapping FOR ALL
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE user_id = auth.uid()
  )
);

-- Commitments: Users can manage commitments for their companies
DROP POLICY IF EXISTS "Users can manage commitments for their companies" ON public.commitments;
CREATE POLICY "Users can manage commitments for their companies"
ON public.commitments FOR ALL
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE user_id = auth.uid()
  )
);

-- Guarantees: Users can manage guarantees for their companies
DROP POLICY IF EXISTS "Users can manage guarantees for their companies" ON public.guarantees;
CREATE POLICY "Users can manage guarantees for their companies"
ON public.guarantees FOR ALL
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE user_id = auth.uid()
  )
);

-- User Subscriptions: Users can view their own subscriptions
DROP POLICY IF EXISTS "Users can view their subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can view their subscriptions"
ON public.user_subscriptions FOR SELECT
USING (user_id = auth.uid());

-- App Daily Metrics: Read-only for authenticated users, insert for system
DROP POLICY IF EXISTS "Users can view app_daily_metrics" ON public.app_daily_metrics;
CREATE POLICY "Users can view app_daily_metrics"
ON public.app_daily_metrics FOR SELECT
USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "System can insert app_daily_metrics" ON public.app_daily_metrics;
CREATE POLICY "System can insert app_daily_metrics"
ON public.app_daily_metrics FOR INSERT
WITH CHECK (true);

-- Bank Transactions: Users can manage transactions for their companies
DROP POLICY IF EXISTS "Users can manage bank_transactions for their companies" ON public.bank_transactions;
CREATE POLICY "Users can manage bank_transactions for their companies"
ON public.bank_transactions FOR ALL
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE user_id = auth.uid()
  )
);

-- Companies: Users can manage their own companies
DROP POLICY IF EXISTS "Users can manage their companies" ON public.companies;
CREATE POLICY "Users can manage their companies"
ON public.companies FOR ALL
USING (user_id = auth.uid());

-- Directors: Users can manage directors for their companies
DROP POLICY IF EXISTS "Users can manage directors for their companies" ON public.directors;
CREATE POLICY "Users can manage directors for their companies"
ON public.directors FOR ALL
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE user_id = auth.uid()
  )
);

-- Invoices: Users can manage invoices for their companies
DROP POLICY IF EXISTS "Users can manage invoices for their companies" ON public.invoices;
CREATE POLICY "Users can manage invoices for their companies"
ON public.invoices FOR ALL
USING (
  company_id IN (
    SELECT id FROM public.companies WHERE user_id = auth.uid()
  )
);

-- Line Items: Users can manage line items for their invoices
DROP POLICY IF EXISTS "Users can manage line_items for their invoices" ON public.line_items;
CREATE POLICY "Users can manage line_items for their invoices"
ON public.line_items FOR ALL
USING (
  invoice_id IN (
    SELECT i.id FROM public.invoices i
    JOIN public.companies c ON c.id = i.company_id
    WHERE c.user_id = auth.uid()
  )
);

-- Views don't need RLS policies as they inherit from underlying tables
-- Grant SELECT on views to authenticated users
GRANT SELECT ON public.view_dla_s455_alerts TO authenticated;
GRANT SELECT ON public.view_frs105_balance_sheet TO authenticated;
