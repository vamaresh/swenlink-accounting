-- Scheduled maintenance for Supabase: daily metrics rollup + cleanup
-- Run in Supabase SQL Editor after supabase-schema.sql

CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE TABLE IF NOT EXISTS app_daily_metrics (
    metric_date DATE PRIMARY KEY,
    companies_created INTEGER NOT NULL DEFAULT 0,
    customers_created INTEGER NOT NULL DEFAULT 0,
    suppliers_created INTEGER NOT NULL DEFAULT 0,
    invoices_created INTEGER NOT NULL DEFAULT 0,
    bills_created INTEGER NOT NULL DEFAULT 0,
    expenses_created INTEGER NOT NULL DEFAULT 0,
    vat_returns_created INTEGER NOT NULL DEFAULT 0,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.refresh_daily_metrics()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO app_daily_metrics (
        metric_date,
        companies_created,
        customers_created,
        suppliers_created,
        invoices_created,
        bills_created,
        expenses_created,
        vat_returns_created,
        generated_at
    )
    VALUES (
        CURRENT_DATE,
        (SELECT COUNT(*) FROM companies WHERE created_at::date = CURRENT_DATE),
        (SELECT COUNT(*) FROM customers WHERE created_at::date = CURRENT_DATE),
        (SELECT COUNT(*) FROM suppliers WHERE created_at::date = CURRENT_DATE),
        (SELECT COUNT(*) FROM invoices WHERE created_at::date = CURRENT_DATE),
        (SELECT COUNT(*) FROM bills WHERE created_at::date = CURRENT_DATE),
        (SELECT COUNT(*) FROM expenses WHERE created_at::date = CURRENT_DATE),
        (SELECT COUNT(*) FROM vat_returns WHERE created_at::date = CURRENT_DATE),
        NOW()
    )
    ON CONFLICT (metric_date) DO UPDATE SET
        companies_created = EXCLUDED.companies_created,
        customers_created = EXCLUDED.customers_created,
        suppliers_created = EXCLUDED.suppliers_created,
        invoices_created = EXCLUDED.invoices_created,
        bills_created = EXCLUDED.bills_created,
        expenses_created = EXCLUDED.expenses_created,
        vat_returns_created = EXCLUDED.vat_returns_created,
        generated_at = EXCLUDED.generated_at;

    DELETE FROM app_daily_metrics
    WHERE metric_date < (CURRENT_DATE - INTERVAL '180 days');
END;
$$;

-- Recreate the schedule idempotently
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'daily_app_metrics_rollup';

-- Schedule daily at 03:15 UTC
SELECT cron.schedule(
    'daily_app_metrics_rollup',
    '15 3 * * *',
    $$SELECT public.refresh_daily_metrics();$$
);
