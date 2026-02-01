-- Basic FRS105 mapping table and a view that aggregates balances into FRS105 balance sheet lines.
-- This is a starting point: project-specific account codes must be populated in `frs105_account_mapping`.

CREATE TABLE IF NOT EXISTS public.frs105_account_mapping (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  account_code text NOT NULL,
  frs105_tag text NOT NULL,
  label text,
  created_at timestamptz default now()
);

CREATE OR REPLACE VIEW public.view_frs105_balance_sheet AS
SELECT
  m.company_id,
  m.frs105_tag,
  m.label,
  SUM(COALESCE(t.amount,0)) AS total_amount
FROM public.frs105_account_mapping m
LEFT JOIN public.transactions t ON t.account_code = m.account_code AND t.company_id = m.company_id
GROUP BY m.company_id, m.frs105_tag, m.label;

-- The view creation above assumes `public.transactions` exists. To make this migration safe to run
-- in any order, replace above with a defensive DO block that creates either the real view (if
-- transactions exists) or an empty view with the expected columns.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'transactions' AND n.nspname = 'public'
  ) THEN
    EXECUTE $sql$
    CREATE OR REPLACE VIEW public.view_frs105_balance_sheet AS
    SELECT
      m.company_id,
      m.frs105_tag,
      m.label,
      SUM(COALESCE(t.amount,0)) AS total_amount
    FROM public.frs105_account_mapping m
    LEFT JOIN public.transactions t ON t.account_code = m.account_code AND t.company_id = m.company_id
    GROUP BY m.company_id, m.frs105_tag, m.label;
    $sql$;
  ELSE
    EXECUTE $sql$
    CREATE OR REPLACE VIEW public.view_frs105_balance_sheet AS
    SELECT NULL::uuid AS company_id, NULL::text AS frs105_tag, NULL::text AS label, 0::numeric AS total_amount WHERE false;
    $sql$;
  END IF;
END
$$;

GRANT SELECT ON public.view_frs105_balance_sheet TO authenticated;
