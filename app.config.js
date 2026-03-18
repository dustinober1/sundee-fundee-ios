// Dynamic config wrapper — resolves Google services files from EAS file
// environment variables during cloud builds, falls back to local paths for
// local development.

const appJson = require("./app.json");

const config = appJson.expo;

// EAS file env vars write content to a temp path stored in the env var.
// Fall back to local file paths for local development / Expo Go.
if (process.env.GOOGLE_SERVICES_PLIST) {
  config.ios = {
    ...config.ios,
    googleServicesFile: process.env.GOOGLE_SERVICES_PLIST,
  };
}

if (process.env.GOOGLE_SERVICES_JSON) {
  config.android = {
    ...config.android,
    googleServicesFile: process.env.GOOGLE_SERVICES_JSON,
  };
}

module.exports = ({ config: _cfg }) => ({
  ...config,
});
