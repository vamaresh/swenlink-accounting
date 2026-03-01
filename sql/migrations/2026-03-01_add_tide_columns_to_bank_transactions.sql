-- Add additional columns to bank_transactions for Tide CSV import
-- This captures all the rich data from Tide exports

ALTER TABLE public.bank_transactions 
ADD COLUMN IF NOT EXISTS transaction_id TEXT,
ADD COLUMN IF NOT EXISTS reference TEXT,
ADD COLUMN IF NOT EXISTS from_party TEXT,
ADD COLUMN IF NOT EXISTS to_party TEXT,
ADD COLUMN IF NOT EXISTS paid_in NUMERIC(12,2),
ADD COLUMN IF NOT EXISTS paid_out NUMERIC(12,2),
ADD COLUMN IF NOT EXISTS category TEXT,
ADD COLUMN IF NOT EXISTS transaction_type TEXT,
ADD COLUMN IF NOT EXISTS status TEXT,
ADD COLUMN IF NOT EXISTS initiated_by TEXT;

-- Add index on transaction_id for fast lookups and duplicate prevention
CREATE INDEX IF NOT EXISTS idx_bank_transactions_transaction_id ON public.bank_transactions(transaction_id);

COMMENT ON COLUMN public.bank_transactions.transaction_id IS 'Unique transaction ID from bank (e.g., Tide transaction ID)';
COMMENT ON COLUMN public.bank_transactions.reference IS 'Transaction reference text';
COMMENT ON COLUMN public.bank_transactions.from_party IS 'Sender name';
COMMENT ON COLUMN public.bank_transactions.to_party IS 'Recipient name';
COMMENT ON COLUMN public.bank_transactions.paid_in IS 'Money received';
COMMENT ON COLUMN public.bank_transactions.paid_out IS 'Money sent';
COMMENT ON COLUMN public.bank_transactions.category IS 'Transaction category (e.g., Director''s Loan, Income, Bank fees)';
COMMENT ON COLUMN public.bank_transactions.transaction_type IS 'Type of transaction (e.g., FasterPaymentIn, FasterPaymentOut, CardPaymentOut)';
COMMENT ON COLUMN public.bank_transactions.status IS 'Transaction status (e.g., Cleared, Pending)';
COMMENT ON COLUMN public.bank_transactions.initiated_by IS 'Person who initiated the transaction';
