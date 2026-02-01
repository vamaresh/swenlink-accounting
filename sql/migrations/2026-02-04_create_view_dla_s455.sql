-- Creates a view exposing DLA movements aggregated per director to help detect potential S455 issues.
-- The view computes total balance, oldest movement date and days outstanding per director per company.
-- This file is defensive: if the underlying tables do not exist yet, create an empty view with the
-- same columns so running the SQL editor won't fail.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'dla_movements' AND n.nspname = 'public'
  ) AND EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c2
    JOIN pg_catalog.pg_namespace n2 ON n2.oid = c2.relnamespace
    WHERE c2.relname = 'directors' AND n2.nspname = 'public'
  ) THEN
    EXECUTE $sql$
    CREATE OR REPLACE VIEW public.view_dla_s455_alerts AS
    SELECT
      dm.company_id,
      dm.director_id,
      d.name AS director_name,
      (SUM(COALESCE(dm.amount,0)) FILTER (WHERE dm.movement_type IN ('borrow','reimbursable','salary','expense'))
        - SUM(COALESCE(dm.amount,0)) FILTER (WHERE dm.movement_type IN ('repayment')))::numeric AS total_balance,
      MIN(dm.created_at) AS oldest_movement,
      (CURRENT_DATE - MIN(dm.created_at)::date) AS days_outstanding
    FROM public.dla_movements dm
    LEFT JOIN public.directors d ON d.id = dm.director_id
    GROUP BY dm.company_id, dm.director_id, d.name;
    $sql$;
  ELSE
    -- create an empty view with the same columns to keep clients happy
    EXECUTE $sql$
    CREATE OR REPLACE VIEW public.view_dla_s455_alerts AS
    SELECT NULL::uuid AS company_id,
           NULL::uuid AS director_id,
           NULL::text AS director_name,
           0::numeric AS total_balance,
           NULL::timestamptz AS oldest_movement,
           0::int AS days_outstanding
    WHERE false;
    $sql$;
  END IF;
END
$$;

-- Grant SELECT to authenticated role (no-op if role doesn't exist)
GRANT SELECT ON public.view_dla_s455_alerts TO authenticated;
