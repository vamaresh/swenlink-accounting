-- Supabase Schema for Limited Companies Accounting System
-- Run this in Supabase SQL Editor

-- Enable Row Level Security
ALTER DATABASE postgres SET timezone TO 'UTC';

-- Companies table (one per user)
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    reg_number TEXT,
    tax_number TEXT,
    address TEXT,
    financial_year_start DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customers table
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Suppliers table
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Invoices table
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT NOT NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    invoice_number TEXT NOT NULL,
    date DATE NOT NULL,
    due_date DATE NOT NULL,
    description TEXT,
    subtotal DECIMAL(12,2) NOT NULL,
    vat_rate DECIMAL(5,4) NOT NULL DEFAULT 0.20,
    vat DECIMAL(12,2) NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'unpaid',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bills table
CREATE TABLE bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT NOT NULL,
    supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL,
    bill_number TEXT NOT NULL,
    date DATE NOT NULL,
    due_date DATE NOT NULL,
    description TEXT,
    subtotal DECIMAL(12,2) NOT NULL,
    vat_rate DECIMAL(5,4) NOT NULL DEFAULT 0.20,
    vat DECIMAL(12,2) NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'unpaid',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bill Images table (for storing image URLs)
CREATE TABLE bill_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID REFERENCES bills(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Expenses table
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT NOT NULL,
    date DATE NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_method TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Expense Images table
CREATE TABLE expense_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_id UUID REFERENCES expenses(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bank Accounts table
CREATE TABLE bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    bank TEXT NOT NULL,
    account_number TEXT,
    sort_code TEXT,
    balance DECIMAL(12,2) NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'GBP',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bank Transactions table
CREATE TABLE bank_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT NOT NULL,
    bank_account_id UUID REFERENCES bank_accounts(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    description TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    type TEXT NOT NULL,
    balance DECIMAL(12,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chart of Accounts table
CREATE TABLE chart_of_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT NOT NULL,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    balance DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- VAT Returns table
CREATE TABLE vat_returns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    output_vat DECIMAL(12,2) NOT NULL,
    input_vat DECIMAL(12,2) NOT NULL,
    vat_due DECIMAL(12,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    generated_date DATE NOT NULL,
    filed_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Subscriptions table
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    subscription_tier TEXT NOT NULL DEFAULT 'free', -- 'free', 'premium', 'admin'
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    subscription_status TEXT DEFAULT 'inactive', -- 'active', 'inactive', 'cancelled', 'past_due'
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security on all tables
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chart_of_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE vat_returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS Policies (users can only access their own data)
-- Companies
CREATE POLICY "Users can view own company" ON companies FOR SELECT USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');
CREATE POLICY "Users can insert own company" ON companies FOR INSERT WITH CHECK (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');
CREATE POLICY "Users can update own company" ON companies FOR UPDATE USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Customers
CREATE POLICY "Users can manage own customers" ON customers FOR ALL USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Suppliers
CREATE POLICY "Users can manage own suppliers" ON suppliers FOR ALL USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Invoices
CREATE POLICY "Users can manage own invoices" ON invoices FOR ALL USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Bills
CREATE POLICY "Users can manage own bills" ON bills FOR ALL USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Bill Images (cascade from bills)
CREATE POLICY "Users can manage bill images" ON bill_images FOR ALL USING (
    EXISTS (SELECT 1 FROM bills WHERE bills.id = bill_images.bill_id AND bills.clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub')
);

-- Expenses
CREATE POLICY "Users can manage own expenses" ON expenses FOR ALL USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Expense Images (cascade from expenses)
CREATE POLICY "Users can manage expense images" ON expense_images FOR ALL USING (
    EXISTS (SELECT 1 FROM expenses WHERE expenses.id = expense_images.expense_id AND expenses.clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub')
);

-- Bank Accounts
CREATE POLICY "Users can manage own bank accounts" ON bank_accounts FOR ALL USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Bank Transactions
CREATE POLICY "Users can manage own transactions" ON bank_transactions FOR ALL USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Chart of Accounts
CREATE POLICY "Users can manage own accounts" ON chart_of_accounts FOR ALL USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- VAT Returns
CREATE POLICY "Users can manage own vat returns" ON vat_returns FOR ALL USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- User Subscriptions
CREATE POLICY "Users can view own subscription" ON user_subscriptions FOR SELECT USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');
CREATE POLICY "Users can insert own subscription" ON user_subscriptions FOR INSERT WITH CHECK (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');
CREATE POLICY "Users can update own subscription" ON user_subscriptions FOR UPDATE USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Create indexes for performance
CREATE INDEX idx_customers_clerk_user ON customers(clerk_user_id);
CREATE INDEX idx_suppliers_clerk_user ON suppliers(clerk_user_id);
CREATE INDEX idx_invoices_clerk_user ON invoices(clerk_user_id);
CREATE INDEX idx_bills_clerk_user ON bills(clerk_user_id);
CREATE INDEX idx_expenses_clerk_user ON expenses(clerk_user_id);
CREATE INDEX idx_bank_accounts_clerk_user ON bank_accounts(clerk_user_id);
CREATE INDEX idx_bank_transactions_clerk_user ON bank_transactions(clerk_user_id);
CREATE INDEX idx_chart_of_accounts_clerk_user ON chart_of_accounts(clerk_user_id);
CREATE INDEX idx_vat_returns_clerk_user ON vat_returns(clerk_user_id);
CREATE INDEX idx_user_subscriptions_clerk_user ON user_subscriptions(clerk_user_id);
CREATE INDEX idx_user_subscriptions_email ON user_subscriptions(email);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bills_updated_at BEFORE UPDATE ON bills FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON expenses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bank_accounts_updated_at BEFORE UPDATE ON bank_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chart_of_accounts_updated_at BEFORE UPDATE ON chart_of_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vat_returns_updated_at BEFORE UPDATE ON vat_returns FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_subscriptions_updated_at BEFORE UPDATE ON user_subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert admin user (replace with your email)
-- Run this after first signup to grant yourself admin access
-- INSERT INTO user_subscriptions (clerk_user_id, email, subscription_tier, subscription_status)
-- VALUES ('your_clerk_user_id', 'your-email@example.com', 'admin', 'active')
-- ON CONFLICT (clerk_user_id) DO UPDATE SET subscription_tier = 'admin', subscription_status = 'active';

-- Create storage bucket for images (Run this separately in Supabase Storage if needed)
-- You'll need to create a bucket named 'bill-images' in Supabase Storage UI
-- And set appropriate RLS policies
