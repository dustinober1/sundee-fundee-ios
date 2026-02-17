module.exports = function (api) {
  api.cache(true);
  return {
    presets: [
      ['babel-preset-expo', { jsxRuntime: 'automatic' }],
      '@babel/preset-typescript',
      'nativewind/babel',
    ],
    plugins: ['react-native-reanimated/plugin'],
  };
};
