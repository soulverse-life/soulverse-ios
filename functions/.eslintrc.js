module.exports = {
  root: true,
  env: { es6: true, node: true },
  extends: ["eslint:recommended", "plugin:@typescript-eslint/recommended"],
  parser: "@typescript-eslint/parser",
  parserOptions: { ecmaVersion: 2020, sourceType: "module" },
  ignorePatterns: ["lib/", "node_modules/"],
  rules: {}
};
