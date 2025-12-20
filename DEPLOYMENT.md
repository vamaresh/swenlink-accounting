# SwenBooks Deployment Guide

## 🚀 Quick Deploy to Vercel

### Prerequisites
- Vercel CLI: `npm install -g vercel`
- Vercel account (free): https://vercel.com/signup

### Deploy Steps

1. **Login to Vercel**
   ```bash
   vercel login
   ```

2. **Deploy from project root**
   ```bash
   cd /Users/bethel/Apps/AccountingSW/swenlink-accounting
   vercel --prod
   ```

3. **Follow prompts**
   - Set up and deploy? **Yes**
   - Which scope? **Your account**
   - Link to existing project? **No**
   - Project name? **swenbooks**
   - Directory? **./** (current directory)
   - Override settings? **No**

4. **Note the deployment URL** (e.g., `swenbooks.vercel.app`)

### Password Protection (Beta Testing)

The app is configured with password protection via `vercel.json`:
- **Password**: `swenbooks-beta-2025`
- Change this in Vercel dashboard: Project Settings → Environment Variables → Add `VERCEL_PASSWORD`

### Custom Domain Setup

1. **Add domain in Vercel dashboard**
   - Go to Project → Settings → Domains
   - Add: `accounts.swenlink.co.uk`

2. **Update DNS records at your domain registrar**
   - Add CNAME record:
     ```
     Type: CNAME
     Name: accounts
     Value: cname.vercel-dns.com
     TTL: 3600
     ```

3. **Wait for SSL** (automatic, ~1-2 minutes)

4. **Verify**: Visit `https://accounts.swenlink.co.uk`

### Alternative: Subdomain on swenlink.co.uk

If you prefer the app itself to be `swenbooks.co.uk`:
1. Register `swenbooks.co.uk` domain
2. Point to Vercel:
   ```
   Type: A
   Name: @
   Value: 76.76.21.21
   
   Type: CNAME
   Name: www
   Value: cname.vercel-dns.com
   ```

### Monitoring & Analytics

- **Deployment logs**: `vercel logs`
- **Analytics**: Vercel dashboard (free tier includes basic analytics)
- **Real-time errors**: Vercel integrates with Sentry (optional)

### Update Clerk Allowed Domains

After deploying, update Clerk settings:
1. Go to Clerk Dashboard: https://dashboard.clerk.com
2. Navigate to: Your App → Settings → Domains
3. Add production URLs:
   - `https://swenbooks.vercel.app`
   - `https://accounts.swenlink.co.uk`

### Update Supabase Allowed Origins

1. Go to Supabase Dashboard
2. Navigate to: Project → Authentication → URL Configuration
3. Add to **Site URL** and **Redirect URLs**:
   - `https://swenbooks.vercel.app`
   - `https://accounts.swenlink.co.uk`

## 🔒 Security Checklist

- ✅ Password protection enabled (beta)
- ✅ HTTPS enforced automatically
- ✅ Security headers configured in `vercel.json`
- ✅ Environment variables for sensitive data
- ⚠️ Remove password after GA launch

## 📱 Testing Checklist

After deployment, test:
- [ ] Login/signup with Clerk
- [ ] Create company profile
- [ ] Add customers/suppliers
- [ ] Create invoices/bills
- [ ] Upload images (Supabase Storage)
- [ ] Generate VAT returns
- [ ] Settings page (company + preferences)
- [ ] Mobile responsive layout
- [ ] Sidebar collapse/expand

## 🎯 Go Live (GA)

When ready for public launch:

1. **Remove password protection**
   ```bash
   # Delete VERCEL_PASSWORD from environment variables
   # Or remove from vercel.json
   ```

2. **Announce**
   - Update website with link to `accounts.swenlink.co.uk`
   - Prepare marketing materials
   - Set up support email

3. **Monitor**
   - Watch Vercel logs for errors
   - Check Supabase usage/quotas
   - Review Clerk authentication metrics

## 💰 Pricing (Current Setup)

- **Vercel**: Free (Hobby tier - sufficient for small business)
- **Clerk**: Free up to 10,000 MAUs
- **Supabase**: Free up to 500MB database + 1GB storage
- **Domain**: ~£10/year (swenlink.co.uk or swenbooks.co.uk)

**Upgrade when**:
- Vercel: >100GB bandwidth/month → $20/mo
- Clerk: >10k users → $25/mo
- Supabase: >500MB data → $25/mo

## 🆘 Troubleshooting

**Deployment fails:**
```bash
vercel --debug --prod
```

**Clerk redirect issues:**
- Verify allowed domains in Clerk dashboard
- Check redirect URLs match exactly (https://)

**Supabase connection fails:**
- Verify CORS settings in Supabase
- Check API keys are correct
- Ensure RLS policies are active

**Need help?**
- Vercel docs: https://vercel.com/docs
- Clerk docs: https://clerk.com/docs
- Supabase docs: https://supabase.com/docs
