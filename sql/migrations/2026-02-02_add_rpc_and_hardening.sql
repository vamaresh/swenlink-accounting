-- Migration: 2026-02-02_add_rpc_and_hardening.sql
-- Purpose: Add RPC wrapper for inserting DLA movements (sets session user)
--          and harden audit_log permissions (revoke UPDATE/DELETE from public).

-- 1) Create schema for application helper functions
CREATE SCHEMA IF NOT EXISTS app;

-- 2) RPC: insert_dla_movement
-- This function sets the session-local `app.current_user` and inserts a row
-- into `dla_movements` within the same transaction. It's SECURITY DEFINER so
-- it can be executed by authenticated clients without requiring them to have
-- direct INSERT privileges on `dla_movements` (careful with who can call it).
CREATE OR REPLACE FUNCTION app.insert_dla_movement(
  p_company_id uuid,
  p_director_id uuid,
  p_amount numeric,
  p_movement_type text,
  p_created_by text
) RETURNS void AS $$
BEGIN
  PERFORM set_config('app.current_user', p_created_by, true);
  INSERT INTO dla_movements (company_id, director_id, amount, movement_type, created_by)
  VALUES (p_company_id, p_director_id, p_amount, p_movement_type, p_created_by);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3) Grant minimal privileges to allow calling the RPC from authenticated clients
GRANT USAGE ON SCHEMA app TO authenticated;
GRANT EXECUTE ON FUNCTION app.insert_dla_movement(uuid, uuid, numeric, text, text) TO authenticated;

-- 4) Harden audit_log: prevent accidental updates/deletes by non-admin roles
-- Keep INSERT so triggers can continue to write audit entries; revoke update/delete.
REVOKE UPDATE, DELETE ON audit_log FROM PUBLIC;

-- End of migration
