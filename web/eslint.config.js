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
  // Links are plain: the site has no base path (paths.base) and no client
  // router (csr = false, E38), so resolve() would change nothing.
  { rules: { "no-undef": "off", "svelte/no-navigation-without-resolve": "off" } },
  // The domain module is pure, for the server and the browser alike
  // (docs/engine.md, "The boundary"): it imports only its own files and
  // touches no DOM, Node, storage or network.
  {
    files: ["src/lib/domain/**"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            { regex: "^(?!\\./)", message: "src/lib/domain/ imports only its own files." },
          ],
        },
      ],
      "no-restricted-globals": [
        "error",
        ...[
          "window",
          "document",
          "navigator",
          "localStorage",
          "sessionStorage",
          "indexedDB",
          "fetch",
          "process",
          "Buffer",
          "console",
        ].map((name) => ({ name, message: "src/lib/domain/ is pure (docs/engine.md)." })),
      ],
    },
  },
];
