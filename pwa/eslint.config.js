import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import tseslint from 'typescript-eslint'

export default tseslint.config(
  { ignores: ['dist', 'node_modules'] },
  {
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
    },
    plugins: {
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': [
        'warn',
        { allowConstantExport: true },
      ],
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'warn',
      // Warn instead of error for setState-in-effect pattern (pre-existing codebase pattern)
      'react-hooks/exhaustive-deps': 'warn',
      // Disable new react-hooks v7 rules that flag pre-existing patterns across all route files
      'react-hooks/set-state-in-effect': 'off',
      'react-hooks/no-call-in-body': 'off',
      // Allow regex with multiple spaces (pre-existing pattern in domain code)
      'no-regex-spaces': 'off',
      // Disable react-hooks v7 purity rule (Date.now() in useRef is a common valid pattern)
      'react-hooks/purity': 'off',
    },
  },
  // Test files: relax rules for test utilities and fixture loading
  {
    files: ['**/__tests__/**/*.{ts,tsx}', '**/*.test.{ts,tsx}', '**/*.spec.{ts,tsx}'],
    rules: {
      '@typescript-eslint/no-require-imports': 'off',
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unused-vars': 'warn',
    },
  },
)
