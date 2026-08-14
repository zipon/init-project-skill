# Release notes — 1.0.1

Initial public-submission candidate for AWS CDK Project Init, a skills-only plugin published personally by Lars Andersson.

- Changes the cyan brand color to `#0097B2`, providing 3.46:1 contrast against white and satisfying the plugin submission requirement.
- Creates standardized AWS CDK TypeScript projects from Traceability `v1.0.4`.
- Renames generated files, classes, tests, package identity, and stack identifiers.
- Installs dependencies and verifies the TypeScript build and Jest tests.
- Provides optional GitHub Actions deployment guidance using the exact IAM role name `GitHubActionsOIDCRole` and short-lived OIDC credentials.
- Clearly states that AWS OIDC configuration is required only for automatic deployment through GitHub Actions.
- Includes three starter prompts, five positive test cases, three negative test cases, support information, a privacy policy, terms, and creator attribution.

Reviewer setup: the plugin has no MCP server, hosted backend, authentication, or test account. Tests require an empty writable directory, Bash, Git, Node.js, npm/npx, and public access to GitHub and the npm registry.
