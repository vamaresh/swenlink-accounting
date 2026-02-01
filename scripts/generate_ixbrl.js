/*
Prototype iXBRL generator for FRS105 balance sheet using `view_frs105_balance_sheet`.
Requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY env variables.

This generates a simple HTML file with minimal iXBRL-like tags for demonstration.
*/

const fs = require('fs')
const fetch = require('node-fetch')

const SUPABASE_URL = process.env.SUPABASE_URL
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY
if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error('Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY')
  process.exit(2)
}

async function generate(companyId, out='frs105_ixbrl.html') {
  const q = `${SUPABASE_URL}/rest/v1/view_frs105_balance_sheet?select=*` + (companyId ? `&company_id=eq.${companyId}` : '')
  const res = await fetch(q, { headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}` } })
  if (!res.ok) throw new Error('failed to fetch')
  const rows = await res.json()
  const grouped = {}
  rows.forEach(r => {
    grouped[r.frs105_tag] = (grouped[r.frs105_tag] || 0) + parseFloat(r.total_amount || 0)
  })

  let html = `<!doctype html><html><head><meta charset="utf-8"><title>FRS105 iXBRL</title></head><body>`
  html += `<h1>FRS105 Balance Sheet (iXBRL prototype)</h1>`
  html += `<table border="1" cellpadding="6"><thead><tr><th>FRS105 Tag</th><th>Amount</th></tr></thead><tbody>`
  for (const tag of Object.keys(grouped)) {
    html += `<tr><td><span class="ixbrl" data-tag="${tag}">${tag}</span></td><td>£${grouped[tag].toFixed(2)}</td></tr>`
  }
  html += `</tbody></table></body></html>`

  fs.writeFileSync(out, html)
  console.log('Written', out)
}

const companyId = process.argv[2]
generate(companyId).catch(err => { console.error(err); process.exit(1) })
