-- Add tax deadline columns to companies table
-- These deadlines are calculated based on financial year but can be manually overridden

ALTER TABLE public.companies 
ADD COLUMN IF NOT EXISTS corporation_tax_due DATE,
ADD COLUMN IF NOT EXISTS vat_quarter_1_due DATE,
ADD COLUMN IF NOT EXISTS vat_quarter_2_due DATE,
ADD COLUMN IF NOT EXISTS vat_quarter_3_due DATE,
ADD COLUMN IF NOT EXISTS vat_quarter_4_due DATE,
ADD COLUMN IF NOT EXISTS self_assessment_due DATE,
ADD COLUMN IF NOT EXISTS paye_deadline DATE,
ADD COLUMN IF NOT EXISTS p11d_deadline DATE,
ADD COLUMN IF NOT EXISTS tax_year_end DATE;

COMMENT ON COLUMN public.companies.corporation_tax_due IS 'Corporation tax payment deadline (9 months + 1 day after accounting period end)';
COMMENT ON COLUMN public.companies.vat_quarter_1_due IS 'VAT return Q1 deadline';
COMMENT ON COLUMN public.companies.vat_quarter_2_due IS 'VAT return Q2 deadline';
COMMENT ON COLUMN public.companies.vat_quarter_3_due IS 'VAT return Q3 deadline';
COMMENT ON COLUMN public.companies.vat_quarter_4_due IS 'VAT return Q4 deadline';
COMMENT ON COLUMN public.companies.self_assessment_due IS 'Self-assessment tax return deadline (31 January following tax year)';
COMMENT ON COLUMN public.companies.paye_deadline IS 'PAYE payment deadline (22nd of each month)';
COMMENT ON COLUMN public.companies.p11d_deadline IS 'P11D submission deadline (6 July)';
COMMENT ON COLUMN public.companies.tax_year_end IS 'UK tax year end (5 April)';
