// Simple serverless endpoint that proxies a Companies House fetch.
// Expects environment variable COMPANIES_HOUSE_API_KEY set in the deployment platform.

export default async function handler(req, res) {
  const { reg } = req.query || {}
  if (!reg) return res.status(400).json({ error: 'company registration number required as ?reg=' })
  const key = process.env.COMPANIES_HOUSE_API_KEY
  if (!key) return res.status(500).json({ error: 'COMPANIES_HOUSE_API_KEY not configured on server' })

  const u = `https://api.company-information.service.gov.uk/company/${encodeURIComponent(reg)}`
  const auth = Buffer.from(`${key}:`).toString('base64')
  try {
    const r = await fetch(u, { headers: { 'Authorization': `Basic ${auth}`, 'Accept': 'application/json' } })
    if (!r.ok) {
      const text = await r.text()
      return res.status(r.status).send(text)
    }
    const j = await r.json()
    return res.status(200).json(j)
  } catch (err) {
    console.error('Companies House proxy failed', err)
    return res.status(500).json({ error: 'fetch failed' })
  }
}
