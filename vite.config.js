import vue from '@vitejs/plugin-vue'
import { defineConfig } from 'vite'

export default defineConfig({
    plugins: [vue()],
    resolve: {
        alias: {
            '@': '/src',
            'lib': '/target/js/debug/build/lib'
        }
    },
    server: {
        watch: null,
        port: 8080,
        proxy: {
            '/login': {
                target: 'https://maple.kkkiiox.work',
                changeOrigin: true,
                ws: true
            },
            '/channel/7575': {
                target: 'https://maple.kkkiiox.work',
                changeOrigin: true,
                ws: true
            }
        }
    }
}) 