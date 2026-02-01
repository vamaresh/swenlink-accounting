// Improved Companies House proxy endpoint with clearer error handling and logging.
// Requires environment variable COMPANIES_HOUSE_API_KEY to be set in the deployment environment.

export default async function handler(req, res) {
  const { reg } = req.query || {}
  if (!reg) return res.status(400).json({ error: 'company registration number required as ?reg=' })

  const key = process.env.COMPANIES_HOUSE_API_KEY
  if (!key) {
    console.error('Companies House key missing in environment')
    return res.status(500).json({ error: 'COMPANIES_HOUSE_API_KEY not configured on server' })
  }

  const url = `https://api.company-information.service.gov.uk/company/${encodeURIComponent(reg)}`
  const auth = Buffer.from(`${key}:`).toString('base64')

  try {
    const upstream = await fetch(url, {
      method: 'GET',
      headers: {
        'Authorization': `Basic ${auth}`,
        'Accept': 'application/json'
      }
    })

    const text = await upstream.text()
    if (!upstream.ok) {
      console.error('Companies House upstream error', upstream.status, text)
      return res.status(502).json({ error: 'Companies House fetch failed', status: upstream.status, body: text })
    }

    // upstream returned JSON-like payload; attempt to parse, otherwise return raw text
    try {
      const json = JSON.parse(text)
      return res.status(200).json(json)
    } catch (parseErr) {
      return res.status(200).send(text)
    }
  } catch (err) {
    console.error('Companies House proxy exception', err)
    return res.status(500).json({ error: 'fetch failed', details: err.message })
  }
}
