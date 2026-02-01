/*
Simple job script to query `view_dla_s455_alerts` and perform an action (console log or notify).
Run as a cron or on-demand. Requires environment variables:
  - SUPABASE_URL
  - SUPABASE_SERVICE_ROLE_KEY

Example:
  SUPABASE_URL=https://xyz.supabase.co SUPABASE_SERVICE_ROLE_KEY=ey... node scripts/dla_s455_job.js
*/

const fetch = require('node-fetch')

const SUPABASE_URL = process.env.SUPABASE_URL
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY
if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error('Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in environment')
  process.exit(2)
}

async function run() {
  const url = `${SUPABASE_URL}/rest/v1/view_dla_s455_alerts?select=*`;
  const res = await fetch(url, {
    headers: {
      'apikey': SERVICE_KEY,
      'Authorization': `Bearer ${SERVICE_KEY}`,
      'Accept': 'application/json'
    }
  })
  if (!res.ok) {
    console.error('Failed to load alerts', res.status, await res.text())
    process.exit(1)
  }
  const alerts = await res.json()
  if (!alerts || alerts.length === 0) {
    console.log('No S455 alerts at this time')
    return
  }
  // For now: just print them. In production, you could send email or create a notification.
  console.log('S455 Alerts:')
  alerts.forEach(a => {
    console.log(`Company: ${a.company_id} Director: ${a.director_name || a.director_id} Balance: £${(a.total_balance||0).toFixed(2)} Days: ${a.days_outstanding}`)
  })
}

run().catch(err => {
  console.error(err)
  process.exit(1)
})
