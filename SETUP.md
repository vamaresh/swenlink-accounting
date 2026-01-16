# Setup Instructions - Clerk + Supabase Integration

## Prerequisites
- Clerk Account (Free tier)
- Supabase Account (Free tier)

## Step 1: Supabase Database Setup

1. Go to your Supabase project: https://brorfoqjqzkkwetbykly.supabase.co
2. Click **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy the entire contents of `supabase-schema.sql` file
5. Paste into the SQL editor
6. Click **Run** to create all tables and policies

## Step 1b: Scheduled Maintenance (Daily Metrics Rollup)

This creates a small daily rollup table and a scheduled job that keeps 180 days of metrics.

1. In Supabase **SQL Editor**, click **New Query**
2. Copy the entire contents of `supabase-maintenance.sql`
3. Paste into the SQL editor
4. Click **Run** to create the function, table, and cron schedule

## Step 2: Supabase Storage Setup (for images)

1. In Supabase dashboard, go to **Storage**
2. Click **Create a new bucket**
3. Name it: `bill-images`
4. Set to **Public** (so users can view their uploaded images)
5. Click **Create bucket**

### Set Storage Policies:
Go to bucket policies and add these:

**Policy 1: Allow authenticated users to upload**
```sql
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'bill-images');
```

**Policy 2: Allow users to view their own images**
```sql
CREATE POLICY "Allow users to view own images"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'bill-images');
```

**Policy 3: Allow users to delete their own images**
```sql
CREATE POLICY "Allow users to delete own images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'bill-images');
```

## Step 3: Clerk Setup

1. Go to https://dashboard.clerk.com
2. Select your application
3. Go to **Configure** → **Email, Phone, Username**
4. Enable **Email** authentication
5. Optionally enable **Google OAuth** or other providers
6. Go to **Configure** → **Sessions** → Make sure session duration is appropriate
7. Go to **User & Authentication** → **Email & SMS** → Customize welcome emails

## Step 4: Update Application Config

Your keys are already configured in the app:
- **Clerk Publishable Key:** `pk_test_b3Blbi1yaGluby0zMS5jbGVyay5hY2NvdW50cy5kZXYk`
- **Supabase URL:** `https://brorfoqjqzkkwetbykly.supabase.co`
- **Supabase Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## Step 5: Deploy

The app will now:
- Use Clerk for authentication (no more plain text passwords!)
- Store all data in Supabase PostgreSQL (persistent forever)
- Store images in Supabase Storage (not as base64)
- Support multi-device access
- Provide automatic backups (7-day retention)

## Features After Integration

✅ Secure authentication with Clerk
✅ Persistent data storage in Supabase
✅ Multi-device synchronization
✅ Proper image storage (not base64)
✅ Data isolation per user (RLS policies)
✅ Automatic backups
✅ Audit trail with created_at/updated_at timestamps
✅ Scalable to thousands of users

## Testing

1. Open the app
2. Sign up with Clerk (creates account automatically)
3. Fill in company details
4. Create customers, invoices, bills
5. Upload images to bills/expenses
6. Verify data persists after refresh
7. Try logging in from different browser/device

## Monitoring

- **Supabase Dashboard:** Monitor database size, API calls, storage usage
- **Clerk Dashboard:** Monitor user signups, sessions, authentication logs

## Free Tier Limits

**Clerk Free:**
- 10,000 monthly active users
- Unlimited signups

**Supabase Free:**
- 500MB database storage
- 2GB file storage
- Unlimited API requests
- 2GB bandwidth per month
- 7-day backup retention

## Need Help?

- Clerk Docs: https://clerk.com/docs
- Supabase Docs: https://supabase.com/docs
- Issue Tracker: Create issue in GitHub repo
