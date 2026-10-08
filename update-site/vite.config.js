import { defineConfig } from 'vite';

export default defineConfig({
  root: '.',
  publicDir: 'public',
  // Relative base: the same build works on GitHub Pages
  // (https://kayrawatcher.github.io/KargomNerede/) and later on the custom
  // domain root (https://kargomnerede.com/) without rebuilding.
  base: './',
  build: {
    outDir: '../build/update-site',
    emptyOutDir: true,
    assetsDir: 'assets',
    rollupOptions: {
      output: {
        assetFileNames: 'assets/[name].[hash].[ext]',
        chunkFileNames: 'assets/[name].[hash].js',
        entryFileNames: 'assets/[name].[hash].js',
      },
    },
  },
  server: {
    port: 5173,
  },
});
