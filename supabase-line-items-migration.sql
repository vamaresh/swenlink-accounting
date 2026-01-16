-- Migration: Add line_items support to invoices table
-- Run this in Supabase SQL Editor

-- Add line_items column to invoices table (JSONB for flexibility)
ALTER TABLE invoices 
ADD COLUMN IF NOT EXISTS line_items JSONB DEFAULT '[]'::jsonb;

-- Add comment explaining the structure
COMMENT ON COLUMN invoices.line_items IS 'Array of line items: [{description, quantity, unitPrice, amount}]';

-- Optional: Create an index for better query performance on line_items
CREATE INDEX IF NOT EXISTS idx_invoices_line_items ON invoices USING gin(line_items);

-- Example line_items structure:
-- [
--   {"description": "Web Design", "quantity": 1, "unitPrice": 500.00, "amount": 500.00},
--   {"description": "Logo Design", "quantity": 1, "unitPrice": 150.00, "amount": 150.00}
-- ]
