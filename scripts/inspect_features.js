async function inspectSpecificChunks() {
  const pages = {
    auth: '25ubxi17kn6ru.js',
    map: '0bppcrvv_0kjg.js',
    pandals: '088eo9g_rmiiz.js',
    routes: '4109c5e3krzap.js',
    groups: '34onex-2eb_vh.js'
  };

  for (const [name, file] of Object.entries(pages)) {
    const res = await fetch(`https://sharodiya.com/_next/static/chunks/${file}`);
    const text = await res.text();
    console.log(`\n=================== ${name.toUpperCase()} (${file}) len: ${text.length} ===================`);
    // Find all readable strings (e.g. English text, UI labels)
    const matches = [...text.matchAll(/"([^"\\]{4,80})"/g)]
      .map(m => m[1])
      .filter(s => 
        !s.startsWith('/') && 
        !s.includes('{') && 
        !s.includes(';') && 
        !s.startsWith('var ') && 
        !s.includes('webpack') &&
        !/^[a-zA-Z0-9_-]+$/.test(s) // filter out random variable names
      );
    console.log('UI Strings & Labels:', [...new Set(matches)].slice(0, 30));
  }
}

inspectSpecificChunks().catch(console.error);
