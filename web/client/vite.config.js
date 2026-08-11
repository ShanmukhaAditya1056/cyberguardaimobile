import { fileURLToPath, URL } from 'node:url';

import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// The Flutter app's font assets, referenced rather than copied — the same
// reasoning that makes the server read `assets/models/` in place. A duplicated
// Inter under web/client/public would go stale the first time the app changed
// weight coverage, and the browser would quietly render a different typeface
// from the phone while every colour and dimension still matched.
const repoRoot = fileURLToPath(new URL('../..', import.meta.url));
const sharedFonts = fileURLToPath(new URL('../../assets/fonts', import.meta.url));

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@fonts': sharedFonts,
    },
  },
  server: {
    port: 5173,
    // Vite refuses to serve files outside the project root unless they are
    // allow-listed, so the @fonts alias resolves in dev as well as in build.
    fs: {
      allow: [repoRoot],
    },
    // Proxying /api keeps the browser on a single origin in development, so
    // the session cookie is same-site and behaves exactly as it will in
    // production behind one hostname. Pointing the client straight at :4000
    // instead would make every dev request cross-origin and hide cookie
    // problems until deploy.
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:4000',
        changeOrigin: true,
        // Vite's default handler turns an upstream connection failure into a
        // bare 500. Every fetch in the client then fails to parse the body and
        // reports a JSON error, which reads like nineteen broken endpoints
        // rather than one API that is not up yet. Answer with JSON naming the
        // real cause instead.
        configure: (proxy) => {
          proxy.on('error', (err, _req, res) => {
            if (!res || res.writableEnded) return;
            const refused = err.code === 'ECONNREFUSED';
            res.writeHead(refused ? 503 : 502, {
              'content-type': 'application/json',
              'retry-after': '2',
            });
            res.end(
              JSON.stringify({
                error: refused
                  ? 'The API is not running — start it with `npm run dev` in web/.'
                  : `Proxy error talking to the API: ${err.code ?? err.message}`,
                upstream: 'http://127.0.0.1:4000',
              }),
            );
          });
        },
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
});
