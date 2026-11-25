import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import { alphaTab } from '@coderline/alphatab-vite'

export default defineConfig({
  plugins: [vue(), tailwindcss(), alphaTab()],
})
