// API Serverless de Login en Vercel para Supabase
module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Método no permitido' });
  }

  try {
    let body = req.body;
    if (typeof body === 'string') {
      try { body = JSON.parse(body); } catch (e) {}
    }
    body = body || {};

    const email = (body.email || '').trim().toLowerCase();
    const password = body.password || '';

    if (!email || !password) {
      return res.status(400).json({ error: 'Correo y contraseña requeridos.' });
    }

    let url = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || body.url || '';
    let key = process.env.SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || body.key || '';
    const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SERVICE_KEY || '';

    if (url) {
      url = url.trim().replace(/\/+$/, '').replace(/\/rest\/v1\/?$/i, '').replace(/\/+$/, '');
    }

    const authKey = key || serviceKey;
    if (!url || !authKey) {
      return res.status(400).json({ error: 'Credenciales de Supabase no configuradas.' });
    }

    const tokenRes = await fetch(`${url}/auth/v1/token?grant_type=password`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': authKey
      },
      body: JSON.stringify({ email, password })
    });

    const tokenData = await tokenRes.json();

    if (!tokenRes.ok) {
      const errMsg = tokenData.error_description || tokenData.msg || tokenData.message || 'Credenciales incorrectas';
      return res.status(tokenRes.status).json({ error: errMsg });
    }

    return res.status(200).json({
      success: true,
      session: tokenData,
      user: tokenData.user
    });
  } catch (err) {
    console.error('Error en /api/login:', err);
    return res.status(500).json({ error: err.message || 'Error interno del servidor' });
  }
};
