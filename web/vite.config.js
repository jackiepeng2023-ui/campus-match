import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// 開發時把 /api 與 /ws 轉給後端；後端不在 8080 時用 VITE_PROXY_TARGET 指定
const target = process.env.VITE_PROXY_TARGET || 'http://localhost:8080'
export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    proxy: { '/api': { target, changeOrigin: true }, '/ws': { target: target.replace(/^http/, 'ws'), ws: true } }
  }
})
