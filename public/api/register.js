// API Serverless de Registro en Vercel con Auto-Confirmación en Supabase
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
    const name = (body.name || '').trim();

    if (!email || !password || password.length < 6) {
      return res.status(400).json({ error: 'Correo y contraseña (mínimo 6 caracteres) requeridos.' });
    }

    let url = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || body.url || '';
    let anonKey = process.env.SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || body.key || '';
    const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SERVICE_KEY || body.serviceKey || '';

    if (url) {
      url = url.trim().replace(/\/+$/, '').replace(/\/rest\/v1\/?$/i, '').replace(/\/+$/, '');
    }

    if (!url) {
      return res.status(400).json({ error: 'URL de Supabase no configurada.' });
    }

    // 1. Si disponemos de Service Role Key en Vercel, creamos el usuario con email_confirm: true (Admin API)
    if (serviceKey) {
      const adminRes = await fetch(`${url}/auth/v1/admin/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': serviceKey,
          'Authorization': `Bearer ${serviceKey}`
        },
        body: JSON.stringify({
          email,
          password,
          email_confirm: true, // Pre-confirmación automática: Cero espera de email
          user_metadata: {
            full_name: name
          }
        })
      });

      const adminData = await adminRes.json();

      if (!adminRes.ok) {
        const errMsg = adminData.msg || adminData.message || JSON.stringify(adminData);
        if (errMsg.toLowerCase().includes('already') || errMsg.toLowerCase().includes('exists')) {
          return res.status(409).json({ error: 'already_exists', message: 'Este correo ya está registrado en Supabase.' });
        }
        return res.status(adminRes.status).json({ error: errMsg });
      }

      // Guardar en tabla anotadores
      try {
        await fetch(`${url}/rest/v1/anotadores`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': serviceKey,
            'Authorization': `Bearer ${serviceKey}`,
            'Prefer': 'resolution=merge-duplicates'
          },
          body: JSON.stringify({
            user_id: adminData.id,
            email: email,
            nombre_completo: name
          })
        });
      } catch (e) {}

      // Generar sesión inmediatamente
      const authKey = anonKey || serviceKey;
      const tokenRes = await fetch(`${url}/auth/v1/token?grant_type=password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': authKey
        },
        body: JSON.stringify({ email, password })
      });

      const tokenData = await tokenRes.json();
      if (tokenRes.ok) {
        return res.status(200).json({
          success: true,
          session: tokenData,
          user: tokenData.user || adminData
        });
      }

      return res.status(200).json({
        success: true,
        user: adminData
      });
    }

    // 2. Si no hay Service Key, guardar directamente en la tabla anotadores (Cero emails, cero códigos de verificación)
    if (!anonKey) {
      return res.status(400).json({ error: 'Anon key de Supabase no configurada.' });
    }

    try {
      const anotadorRes = await fetch(`${url}/rest/v1/anotadores`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': `Bearer ${anonKey}`,
          'Prefer': 'resolution=merge-duplicates,return=representation'
        },
        body: JSON.stringify({
          email: email,
          nombre_completo: name
        })
      });

      const anotadorData = await anotadorRes.json();

      return res.status(200).json({
        success: true,
        user: {
          email: email,
          user_metadata: { full_name: name }
        },
        anotador: Array.isArray(anotadorData) ? anotadorData[0] : anotadorData
      });
    } catch(errAnotador) {
      return res.status(500).json({ error: errAnotador.message || 'Error guardando anotador' });
    }

  } catch (err) {
    console.error('Error en /api/register:', err);
    return res.status(500).json({ error: err.message || 'Error interno del servidor' });
  }
};
