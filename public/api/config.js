module.exports = (req, res) => {
  let url = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || '';
  const key = process.env.SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';
  
  // Limpieza rigurosa de URL para evitar el error 404 /rest/v1/rest/v1/
  if (url) {
    url = url.trim()
      .replace(/\/+$/, '')
      .replace(/\/rest\/v1\/?$/i, '')
      .replace(/\/+$/, '');
  }
  
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Cache-Control', 'no-store, max-age=0');
  
  const hasServiceKey = !!(process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SERVICE_KEY);
  
  res.status(200).json({ url, key, hasServiceKey });
};
