import vue from "@vitejs/plugin-vue";
import { defineConfig } from "vite";
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
	plugins: [vue(), tailwindcss()],
	resolve: {
		alias: {
			"@": "/src",
			lib: "/target/js/release/build/lib",
		},
	},
	server: {
		watch: {
			ignored: ["assets/**", "*.mbt", "moon.pkg.json"],
		},
		// watch: null,
		port: 8080,
		proxy: {
			"/login": {
				target: "http://192.168.31.85:30000",
				// target: "http://localhost:8484",
				// changeOrigin: true,
				ws: true,
			},
			"/channel/7575": {
				target: "http://192.168.31.85:30001",
				// target: "http://localhost:7575",
				// changeOrigin: true,
				ws: true,
			},
		},
	},
});
