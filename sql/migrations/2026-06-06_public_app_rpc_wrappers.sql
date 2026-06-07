-- Public RPC wrappers for app-schema functions.
-- Supabase/PostgREST commonly exposes the public schema by default. These
-- wrappers let the web app call banking and DLA RPCs without exposing the
-- internal app schema through API settings.

CREATE OR REPLACE FUNCTION public.reconcile_bank_transaction(
  p_transaction_id uuid,
  p_company_id uuid,
  p_matched_invoice_id uuid DEFAULT NULL,
  p_matched_type text DEFAULT 'unmatched',
  p_notes text DEFAULT NULL,
  p_user_id text DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, app
AS $$
  SELECT app.reconcile_bank_transaction(
    p_transaction_id,
    p_company_id,
    p_matched_invoice_id,
    p_matched_type,
    p_notes,
    p_user_id
  );
$$;

CREATE OR REPLACE FUNCTION public.create_journal_entry_from_bank_transaction(
  p_transaction_id uuid,
  p_company_id uuid,
  p_account_code text,
  p_user_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, app
AS $$
  SELECT app.create_journal_entry_from_bank_transaction(
    p_transaction_id,
    p_company_id,
    p_account_code,
    p_user_id
  );
$$;

CREATE OR REPLACE FUNCTION public.auto_categorize_transactions(
  p_company_id uuid
)
RETURNS TABLE (
  transaction_id uuid,
  suggested_category text,
  confidence_score decimal
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, app
AS $$
  SELECT * FROM app.auto_categorize_transactions(p_company_id);
$$;

CREATE OR REPLACE FUNCTION public.insert_dla_movement(
  p_company_id uuid,
  p_director_id uuid,
  p_amount numeric,
  p_movement_type text,
  p_created_by text
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, app
AS $$
  SELECT app.insert_dla_movement(
    p_company_id,
    p_director_id,
    p_amount,
    p_movement_type,
    p_created_by
  );
$$;

GRANT EXECUTE ON FUNCTION public.reconcile_bank_transaction(uuid, uuid, uuid, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_journal_entry_from_bank_transaction(uuid, uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.auto_categorize_transactions(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.insert_dla_movement(uuid, uuid, numeric, text, text) TO authenticated;
