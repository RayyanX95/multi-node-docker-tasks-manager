// Use the current browser hostname with backend port
// This works for both local development and production deployments
export const API_BASE_URL = typeof window !== 'undefined' 
  ? `http://${window.location.hostname}:4000`
  : "http://localhost:4000";
