import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    // Proxying /api keeps the browser on a single origin in development, so
    // the session cookie is same-site and behaves exactly as it will in
    // production behind one hostname. Pointing the client straight at :4000
    // instead would make every dev request cross-origin and hide cookie
    // problems until deploy.
    proxy: {
      '/api': {
        target: 'http://localhost:4000',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
});
