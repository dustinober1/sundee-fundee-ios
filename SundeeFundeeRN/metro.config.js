const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Enable package.json "exports" field resolution.
// Required for date-fns v4 which uses "type": "module" with ESM exports.
config.resolver.unstable_enablePackageExports = true;

module.exports = config;
