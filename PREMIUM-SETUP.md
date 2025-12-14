# Hybrid System - Free + Premium Implementation

## Overview
The app now supports two modes:
1. **Free Tier** - localStorage (current system, works offline)
2. **Premium Tier** - £5/month - Clerk + Supabase (cloud sync, multi-device, secure)
3. **Admin Tier** - Free for you (all premium features)

## Setup Steps

### 1. Run Updated Database Schema

The subscription table has been added to `supabase-schema.sql`. Run this in Supabase SQL Editor:

```sql
-- User Subscriptions table
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    subscription_tier TEXT NOT NULL DEFAULT 'free',
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    subscription_status TEXT DEFAULT 'inactive',
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscription" ON user_subscriptions 
FOR SELECT USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can insert own subscription" ON user_subscriptions 
FOR INSERT WITH CHECK (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can update own subscription" ON user_subscriptions 
FOR UPDATE USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE INDEX idx_user_subscriptions_clerk_user ON user_subscriptions(clerk_user_id);
CREATE INDEX idx_user_subscriptions_email ON user_subscriptions(email);

CREATE TRIGGER update_user_subscriptions_updated_at 
BEFORE UPDATE ON user_subscriptions 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 2. Grant Yourself Admin Access

After you sign up with Clerk for the first time, run this SQL (replace with your details):

```sql
-- First, sign up through the app to get your Clerk user ID
-- Then run this to grant yourself admin access

INSERT INTO user_subscriptions (clerk_user_id, email, subscription_tier, subscription_status)
VALUES (
    'user_xxxxxxxxxxxxx',  -- Your Clerk user ID (get from Clerk dashboard after signup)
    'your-email@example.com',  -- Your email
    'admin', 
    'active'
)
ON CONFLICT (clerk_user_id) 
DO UPDATE SET 
    subscription_tier = 'admin', 
    subscription_status = 'active';
```

### 3. Set Up Stripe (for payments)

1. Go to https://dashboard.stripe.com/register
2. Create account / Sign in
3. Go to **Developers** → **API Keys**
4. Copy **Publishable key** (pk_test_...)
5. Go to **Products** → **Add Product**
   - Name: "Premium Accounting"
   - Price: £5.00 / month
   - Recurring billing
6. Copy the **Price ID** (price_...)

### 4. Configure App

Update the config in `index.html` (I'll add this):

```javascript
const CONFIG = {
    ADMIN_EMAIL: 'your-email@example.com',
    STRIPE_PUBLISHABLE_KEY: 'pk_test_your_key',
    STRIPE_PRICE_ID: 'price_your_price_id',
    PREMIUM_PRICE: '£5',
    PREMIUM_PRICE_AMOUNT: 500 // in pence
};
```

## Features by Tier

### Free Tier (localStorage)
✅ All accounting features
✅ Works offline
✅ No account required
❌ Data lost if browser cleared
❌ No multi-device sync
❌ Limited to ~5MB storage
❌ Images stored as base64 (uses lots of space)

### Premium Tier (£5/month)
✅ All accounting features
✅ Secure cloud storage (Supabase)
✅ Clerk authentication (no passwords to remember)
✅ Multi-device sync
✅ Unlimited storage (500MB database + 2GB files)
✅ Images stored efficiently in Supabase Storage
✅ 7-day backup retention
✅ Data persists forever
✅ Audit trail with timestamps

### Admin Tier (Free for you)
✅ All Premium features
✅ No payment required
✅ View all users' stats (future feature)
✅ Analytics dashboard (future feature)

## User Journey

### New User Flow:
1. Land on app
2. Choose: "Try Free (No Signup)" or "Go Premium (£5/month)"
3. **Free:** Start using immediately with localStorage
4. **Premium:** Sign up with Clerk → Show payment form → Subscribe → Access cloud features

### Upgrade Flow:
1. Free user sees "Upgrade to Premium" banner
2. Click upgrade → Sign up with Clerk
3. Enter payment details (Stripe)
4. Offer to migrate localStorage data to cloud
5. Now using Premium features

### Your Admin Flow:
1. Sign up with your email
2. I manually grant you admin status in database
3. You get all premium features free
4. Future: Admin dashboard to view stats

## Migration Tool

The app will include a "Migrate Data" button that:
1. Exports all localStorage data
2. Uploads to Supabase under your Clerk user ID
3. Confirms migration successful
4. Optionally clears localStorage

## Monitoring

### As Admin, you'll be able to:
- View total users (free vs premium)
- Monthly recurring revenue (MRR)
- Churn rate
- Active subscriptions
- Storage usage per user

### Revenue Estimates:
- 100 premium users = £500/month
- 500 premium users = £2,500/month
- 1000 premium users = £5,000/month

## Next Steps

1. ✅ Database schema updated with subscriptions table
2. ⏳ Integrate Stripe payments
3. ⏳ Add tier selection UI
4. ⏳ Implement data migration tool
5. ⏳ Build admin dashboard
6. ⏳ Set up Stripe webhooks for subscription management

Would you like me to proceed with the implementation?
