# Premium Version Testing Checklist

## How to Test
1. Open `index.html` in your browser
2. Follow the test cases below

## ✅ Test Cases

### 1. Authentication (Clerk)
- [ ] Sign up with new email - should show Clerk sign-up UI
- [ ] Sign in with existing account - should show Clerk sign-in UI
- [ ] After sign-in, should redirect to app or company setup
- [ ] Test with **amareshvel@gmail.com** - should get admin tier automatically

### 2. Company Setup (First Time Users)
- [ ] New user sees company setup screen
- [ ] Fill in: Company Name, Reg Number, Tax Number, Address, Financial Year Start
- [ ] Submit - should create company in Supabase and show dashboard
- [ ] Check Supabase `companies` table - record should exist
- [ ] Check Supabase `chart_of_accounts` table - 7 default accounts created

### 3. Customers Module
- [ ] Add new customer (name, email, phone, address)
- [ ] Edit existing customer
- [ ] Delete customer
- [ ] Check Supabase `customers` table - changes should persist
- [ ] Reload page - data should persist

### 4. Suppliers Module
- [ ] Add new supplier
- [ ] Edit supplier
- [ ] Delete supplier
- [ ] Check Supabase `suppliers` table

### 5. Invoices Module
- [ ] Add invoice (select customer, invoice number, date, due date, description, subtotal)
- [ ] VAT should auto-calculate (20% default)
- [ ] Edit invoice
- [ ] Mark as paid/unpaid
- [ ] Delete invoice
- [ ] Check Supabase `invoices` table

### 6. Bills Module (with Image Upload)
- [ ] Add bill (select supplier, amounts, dates)
- [ ] Upload bill image(s) - should upload to Supabase Storage `bill-images` bucket
- [ ] Check Supabase Storage UI - images should appear
- [ ] Check `bill_images` table - URLs should be saved
- [ ] Edit bill and upload new images
- [ ] Delete bill - images should cascade delete

### 7. Expenses Module (with Image Upload)
- [ ] Add expense with category, description, amount
- [ ] Upload receipt images
- [ ] Check Supabase Storage and `expense_images` table
- [ ] Edit and delete expenses

### 8. Banking Module
- [ ] Add bank account (name, bank, account number, sort code, balance)
- [ ] View account balance
- [ ] Edit account
- [ ] Delete account
- [ ] Check `bank_accounts` table

### 9. Chart of Accounts
- [ ] View default 7 accounts created during setup
- [ ] Add new account (code, name, type, balance)
- [ ] Edit account
- [ ] Delete account

### 10. VAT Returns
- [ ] Click "Generate VAT Return"
- [ ] Should calculate based on invoices and bills for current quarter
- [ ] Check output VAT, input VAT, VAT due
- [ ] Status should be "draft"
- [ ] Click "File VAT Return" - status should change to "filed"
- [ ] Check `vat_returns` table

### 11. Subscription Tiers
- [ ] Sign in with **amareshvel@gmail.com**
- [ ] Check `user_subscriptions` table - `subscription_tier` should be 'admin'
- [ ] Sign in with other email
- [ ] Check table - `subscription_tier` should be 'free'

### 12. Multi-Device Sync
- [ ] Make changes on one device/browser
- [ ] Open same account on another device/browser
- [ ] Data should sync automatically (cloud-based)

### 13. Data Isolation (Security Test)
- [ ] Sign in as User A
- [ ] Add some customers/invoices
- [ ] Sign out
- [ ] Sign in as User B
- [ ] Should NOT see User A's data (RLS policies working)

### 14. Logout
- [ ] Click logout button
- [ ] Should redirect to Clerk sign-in screen
- [ ] User state should be cleared

### 15. Error Handling
- [ ] Try to submit forms with missing required fields - should show validation
- [ ] Turn off internet, try to save - should show error message
- [ ] Turn internet back on, retry - should work

## 🐛 Known Issues / Limitations
- Image upload size limit: Check Supabase Storage limits (default 50MB per file)
- RLS policies require Clerk JWT in request headers (automatically handled)
- First load might be slow (~2-3 seconds) while Clerk and Supabase initialize

## 📊 Database Verification (Supabase Dashboard)

### Tables to Check
1. `companies` - Should have 1 row per user with clerk_user_id
2. `customers` - User-specific data with clerk_user_id
3. `suppliers` - User-specific data
4. `invoices` - With customer_id foreign keys
5. `bills` - With supplier_id foreign keys
6. `bill_images` - Image URLs with bill_id foreign keys
7. `expenses` - User-specific data
8. `expense_images` - Image URLs with expense_id foreign keys
9. `bank_accounts` - User-specific data
10. `bank_transactions` - Future feature (not implemented yet)
11. `chart_of_accounts` - 7 default + user custom accounts
12. `vat_returns` - Generated returns
13. `user_subscriptions` - Subscription tiers (admin for amareshvel@gmail.com)

### Storage Bucket
- `bill-images` - Should contain uploaded bill/expense images
- Check public access is enabled

## ✅ Success Criteria
- All CRUD operations work without errors
- Data persists after page reload
- Images upload successfully to Supabase Storage
- Multi-device sync works (same data on different browsers)
- Admin email gets admin tier automatically
- RLS policies prevent users from seeing each other's data
- No console errors in browser developer tools
- Clerk authentication works smoothly

## 🚀 Next Steps After Testing
1. Fix any bugs found
2. Add Stripe payment integration for premium tier (£5/month)
3. Create data migration tool (localStorage → Supabase)
4. Deploy to production hosting (Vercel, Netlify, etc.)
5. Set up custom domain
6. Add email notifications (via Supabase Edge Functions)
7. Implement backup/export functionality
