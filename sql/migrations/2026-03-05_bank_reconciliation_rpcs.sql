-- RPC Functions for Bank Reconciliation

-- Function to apply categorization rules to a transaction
CREATE OR REPLACE FUNCTION app.apply_categorization_rules(
  p_transaction_id uuid,
  p_company_id uuid
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
  -- Get the transaction
  SELECT * INTO v_transaction
  FROM public.bank_transactions
  WHERE id = p_transaction_id AND company_id = p_company_id;
  
  IF NOT FOUND THEN
    RETURN;
  END IF;
  
  -- Loop through rules in priority order
  FOR v_rule IN 
    SELECT * FROM public.bank_categorization_rules
    WHERE company_id = p_company_id AND enabled = true
    ORDER BY priority DESC, created_at ASC
  LOOP
    v_score := 0;
    
    -- Check description match
    IF v_rule.match_description_contains IS NOT NULL THEN
      IF v_transaction.description ILIKE '%' || v_rule.match_description_contains || '%' THEN
        v_score := v_score + 30;
      ELSE
        CONTINUE; -- Skip this rule if mandatory match fails
      END IF;
    END IF;
    
    -- Check regex match
    IF v_rule.match_description_regex IS NOT NULL THEN
      IF v_transaction.description ~ v_rule.match_description_regex THEN
        v_score := v_score + 35;
      ELSE
        CONTINUE;
      END IF;
    END IF;
    
    -- Check reference match
    IF v_rule.match_reference_contains IS NOT NULL THEN
      IF v_transaction.reference ILIKE '%' || v_rule.match_reference_contains || '%' THEN
        v_score := v_score + 25;
      END IF;
    END IF;
    
    -- Check from_party match
    IF v_rule.match_from_party IS NOT NULL THEN
      IF v_transaction.from_party ILIKE '%' || v_rule.match_from_party || '%' THEN
        v_score := v_score + 20;
      END IF;
    END IF;
    
    -- Check to_party match
    IF v_rule.match_to_party IS NOT NULL THEN
      IF v_transaction.to_party ILIKE '%' || v_rule.match_to_party || '%' THEN
        v_score := v_score + 20;
      END IF;
    END IF;
    
    -- Check amount range
    IF v_rule.match_amount_min IS NOT NULL AND v_rule.match_amount_max IS NOT NULL THEN
      IF v_transaction.amount BETWEEN v_rule.match_amount_min AND v_rule.match_amount_max THEN
        v_score := v_score + 15;
      END IF;
    END IF;
    
    -- Check transaction type
    IF v_rule.match_transaction_type IS NOT NULL THEN
      IF v_transaction.transaction_type = v_rule.match_transaction_type THEN
        v_score := v_score + 10;
      END IF;
    END IF;
    
    -- Keep track of best matching rule
    IF v_score > v_best_score THEN
      v_best_score := v_score;
      v_best_rule := v_rule;
    END IF;
  END LOOP;
  
  -- Return the best match if found
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

-- Function to reconcile a bank transaction
CREATE OR REPLACE FUNCTION app.reconcile_bank_transaction(
  p_transaction_id uuid,
  p_company_id uuid,
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
  -- Update the transaction
  UPDATE public.bank_transactions
  SET 
    reconciled = true,
    reconciled_at = now(),
    reconciled_by = p_user_id,
    matched_invoice_id = p_matched_invoice_id,
    matched_type = p_matched_type,
    notes = p_notes
  WHERE id = p_transaction_id AND company_id = p_company_id;
  
  -- Update invoice if matched
  IF p_matched_invoice_id IS NOT NULL THEN
    UPDATE public.invoices
    SET 
      status = 'paid',
      paid_date = (SELECT date FROM public.bank_transactions WHERE id = p_transaction_id)
    WHERE id = p_matched_invoice_id AND company_id = p_company_id;
  END IF;
  
  RETURN FOUND;
END;
$$;

-- Function to create a journal entry from a bank transaction
CREATE OR REPLACE FUNCTION app.create_journal_entry_from_bank_transaction(
  p_transaction_id uuid,
  p_company_id uuid,
  p_account_code text, -- The offsetting account (e.g., 'Sales', 'Rent')
  p_user_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_transaction record;
  v_entry_id uuid;
  v_entry_number text;
  v_bank_account_code text := '1000'; -- Default bank account
BEGIN
  -- Get the transaction
  SELECT * INTO v_transaction
  FROM public.bank_transactions
  WHERE id = p_transaction_id AND company_id = p_company_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;
  
  -- Generate entry number
  SELECT 'JE-' || TO_CHAR(now(), 'YYYY') || '-' || 
         LPAD(COALESCE(MAX(CAST(SUBSTRING(entry_number FROM '\d+$') AS INT)), 0) + 1::text, 4, '0')
  INTO v_entry_number
  FROM public.journal_entries
  WHERE company_id = p_company_id 
    AND entry_number LIKE 'JE-' || TO_CHAR(now(), 'YYYY') || '-%';
  
  -- Create the journal entry
  INSERT INTO public.journal_entries (
    company_id,
    entry_date,
    entry_number,
    description,
    source_type,
    source_id,
    status,
    created_by,
    posted_at,
    posted_by
  ) VALUES (
    p_company_id,
    v_transaction.date,
    v_entry_number,
    'Bank: ' || COALESCE(v_transaction.description, 'Transaction'),
    'bank_transaction',
    p_transaction_id,
    'posted',
    p_user_id,
    now(),
    p_user_id
  )
  RETURNING id INTO v_entry_id;
  
  -- Create journal entry lines
  IF v_transaction.amount > 0 THEN
    -- Money coming in: Debit Bank, Credit Revenue/Other
    INSERT INTO public.journal_entry_lines (journal_entry_id, line_number, account_code, account_name, debit_amount)
    VALUES (v_entry_id, 1, v_bank_account_code, 'Bank Current Account', v_transaction.amount);
    
    INSERT INTO public.journal_entry_lines (journal_entry_id, line_number, account_code, account_name, credit_amount)
    VALUES (v_entry_id, 2, p_account_code, 
            (SELECT account_name FROM public.chart_of_accounts 
             WHERE company_id = p_company_id AND account_code = p_account_code LIMIT 1),
            v_transaction.amount);
  ELSE
    -- Money going out: Credit Bank, Debit Expense/Other
    INSERT INTO public.journal_entry_lines (journal_entry_id, line_number, account_code, account_name, credit_amount)
    VALUES (v_entry_id, 1, v_bank_account_code, 'Bank Current Account', ABS(v_transaction.amount));
    
    INSERT INTO public.journal_entry_lines (journal_entry_id, line_number, account_code, account_name, debit_amount)
    VALUES (v_entry_id, 2, p_account_code,
            (SELECT account_name FROM public.chart_of_accounts 
             WHERE company_id = p_company_id AND account_code = p_account_code LIMIT 1),
            ABS(v_transaction.amount));
  END IF;
  
  -- Mark transaction as reconciled
  UPDATE public.bank_transactions
  SET 
    reconciled = true,
    reconciled_at = now(),
    reconciled_by = p_user_id
  WHERE id = p_transaction_id;
  
  RETURN v_entry_id;
END;
$$;

-- Function to auto-categorize all uncategorized transactions
CREATE OR REPLACE FUNCTION app.auto_categorize_transactions(
  p_company_id uuid
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
  -- Loop through uncategorized transactions
  FOR v_transaction IN
    SELECT id FROM public.bank_transactions
    WHERE company_id = p_company_id 
      AND reconciled = false
      AND suggested_category IS NULL
  LOOP
    -- Apply rules to this transaction
    SELECT * INTO v_suggestion
    FROM app.apply_categorization_rules(v_transaction.id, p_company_id)
    LIMIT 1;
    
    -- If we got a suggestion, update the transaction
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

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION app.apply_categorization_rules TO authenticated;
GRANT EXECUTE ON FUNCTION app.reconcile_bank_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION app.create_journal_entry_from_bank_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION app.auto_categorize_transactions TO authenticated;
