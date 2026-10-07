import { createApp } from './app.js';
import './styles.css';

// Initialize the app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  const app = createApp();
  app.mount('#app');
});