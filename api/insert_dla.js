// Example server/Edge function showing secure RPC usage with Supabase service role key.
// This is a minimal example. Deploy this as a serverless function (Vercel, Netlify, etc.)

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST required' })
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY
  const url = process.env.SUPABASE_URL
  if (!key || !url) return res.status(500).json({ error: 'Supabase service key or URL not configured' })

  const body = await req.json()
  // expected body: { company_id, director_id, amount, movement_type, created_by }
  try {
    const rpcUrl = `${url}/rpc/app.insert_dla_movement`
    const r = await fetch(rpcUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': key,
        'Authorization': `Bearer ${key}`
      },
      body: JSON.stringify({
        p_company_id: body.company_id,
        p_director_id: body.director_id,
        p_amount: body.amount,
        p_movement_type: body.movement_type,
        p_created_by: body.created_by
      })
    })
    const text = await r.text()
    if (!r.ok) return res.status(r.status).send(text)
    // return RPC response
    try { return res.status(200).json(JSON.parse(text)) } catch(e) { return res.status(200).send(text) }
  } catch (err) {
    console.error('insert_dla RPC failed', err)
    return res.status(500).json({ error: 'rpc failed' })
  }
}
