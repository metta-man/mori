import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig(({ mode }) => ({
  plugins: [react(), tailwindcss()],
  server: {
    host: '0.0.0.0',
    allowedHosts: ['terminal.local']
  },
  build: mode === 'library'
    ? {
        lib: {
          entry: 'src/index.ts',
          name: 'MoriUI',
          fileName: (format) => format === 'es' ? 'mori-ui.es.js' : 'mori-ui.umd.cjs'
        },
        rollupOptions: {
          external: ['react', 'react-dom'],
          output: {
            globals: {
              react: 'React',
              'react-dom': 'ReactDOM'
            }
          }
        }
      }
    : undefined
}))
