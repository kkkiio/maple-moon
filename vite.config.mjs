import tailwindcss from '@tailwindcss/vite';
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
	appType: "mpa",
	plugins: [react(), tailwindcss()],
	resolve: {
		alias: {
			"@": "/src",
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
