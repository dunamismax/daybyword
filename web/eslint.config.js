// Lints the TypeScript and Svelte sources (decisions E34, E36).
import js from "@eslint/js";
import svelte from "eslint-plugin-svelte";
import tseslint from "typescript-eslint";

export default [
  { ignores: ["build/", ".svelte-kit/", "node_modules/"] },
  js.configs.recommended,
  ...tseslint.configs.strict,
  ...svelte.configs.recommended,
  {
    files: ["**/*.svelte", "**/*.svelte.ts"],
    languageOptions: {
      parserOptions: { parser: tseslint.parser, extraFileExtensions: [".svelte"] },
    },
  },
  // TypeScript checks names itself; ESLint's no-undef does not know its globals.
  { rules: { "no-undef": "off" } },
];
