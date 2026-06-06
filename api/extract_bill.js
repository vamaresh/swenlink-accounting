// Vercel serverless function — extract bill details from an image using OpenAI GPT-4o Vision.
// Requires environment variable OPENAI_API_KEY to be set in the Vercel project settings.

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { imageUrl } = req.body || {};
  if (!imageUrl) {
    return res.status(400).json({ error: 'imageUrl is required' });
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    console.error('OPENAI_API_KEY not configured');
    return res.status(500).json({ error: 'OPENAI_API_KEY not configured on server' });
  }

  const prompt = `You are a UK accounting assistant. Extract the following details from this bill or invoice image.
Return ONLY a valid JSON object with these exact keys (use null if a field cannot be determined):

{
  "supplierName": "string — the supplier or vendor company name",
  "billNumber": "string — the invoice or bill reference number",
  "date": "string — invoice date in YYYY-MM-DD format",
  "dueDate": "string — payment due date in YYYY-MM-DD format (if not shown, add 30 days to the invoice date)",
  "subtotal": "number — amount before VAT, no currency symbol",
  "vatRate": "number — VAT rate as a decimal e.g. 0.20 for 20%, use 0 if no VAT",
  "vatAmount": "number — VAT amount, no currency symbol",
  "total": "number — total amount including VAT, no currency symbol",
  "description": "string — brief description of goods or services purchased"
}`;

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: prompt },
              { type: 'image_url', image_url: { url: imageUrl, detail: 'high' } },
            ],
          },
        ],
        max_tokens: 600,
        response_format: { type: 'json_object' },
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error('OpenAI API error:', response.status, errText);
      return res.status(502).json({ error: 'OpenAI API error', status: response.status });
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;
    if (!content) {
      return res.status(502).json({ error: 'No content returned from OpenAI' });
    }

    const extracted = JSON.parse(content);
    return res.status(200).json(extracted);
  } catch (err) {
    console.error('extract_bill exception:', err);
    return res.status(500).json({ error: 'Extraction failed', details: err.message });
  }
}
