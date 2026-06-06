module.exports = async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'GET required' })
  }

  const cronSecret = process.env.CRON_SECRET
  const authHeader = req.headers.authorization
  const userAgent = req.headers['user-agent'] || ''

  if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
    return res.status(401).json({ error: 'Unauthorized' })
  }

  if (!cronSecret && !userAgent.includes('vercel-cron/1.0')) {
    return res.status(401).json({ error: 'Unauthorized' })
  }

  const supabaseUrl = process.env.SUPABASE_URL
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY

  if (!supabaseUrl || !supabaseKey) {
    return res.status(500).json({ error: 'Supabase environment variables are not configured' })
  }

  try {
    const response = await fetch(`${supabaseUrl}/rest/v1/companies?select=id&limit=1`, {
      method: 'GET',
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
        Accept: 'application/json'
      }
    })

    const body = await response.text()

    if (!response.ok) {
      return res.status(502).json({
        error: 'Supabase keepalive failed',
        status: response.status,
        body
      })
    }

    return res.status(200).json({
      ok: true,
      checked_at: new Date().toISOString()
    })
  } catch (error) {
    return res.status(500).json({ error: 'Supabase keepalive request failed', details: error.message })
  }
}
