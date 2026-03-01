-- Add key dates columns to companies table for persisting Companies House data
-- This allows us to store fetched dates and display them without re-fetching

ALTER TABLE public.companies 
ADD COLUMN IF NOT EXISTS company_reg_date DATE,
ADD COLUMN IF NOT EXISTS next_accounts_due DATE,
ADD COLUMN IF NOT EXISTS confirmation_due DATE,
ADD COLUMN IF NOT EXISTS last_accounts_date DATE,
ADD COLUMN IF NOT EXISTS last_confirmation_date DATE,
ADD COLUMN IF NOT EXISTS accounts_overdue BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS confirmation_overdue BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS key_dates_last_fetched TIMESTAMPTZ;

-- Add comment for documentation
COMMENT ON COLUMN public.companies.company_reg_date IS 'Date company was registered at Companies House';
COMMENT ON COLUMN public.companies.next_accounts_due IS 'Next accounts filing deadline';
COMMENT ON COLUMN public.companies.confirmation_due IS 'Next confirmation statement deadline';
COMMENT ON COLUMN public.companies.last_accounts_date IS 'Date of last accounts filed';
COMMENT ON COLUMN public.companies.last_confirmation_date IS 'Date of last confirmation statement filed';
COMMENT ON COLUMN public.companies.accounts_overdue IS 'Flag indicating if accounts filing is overdue';
COMMENT ON COLUMN public.companies.confirmation_overdue IS 'Flag indicating if confirmation statement is overdue';
COMMENT ON COLUMN public.companies.key_dates_last_fetched IS 'Timestamp when key dates were last fetched from Companies House API';
