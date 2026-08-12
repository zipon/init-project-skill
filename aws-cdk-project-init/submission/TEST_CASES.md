# Submission test cases

## Positive test cases

### 1. Standard project in the current workspace

- **Prompt:** Create an AWS CDK project named MyProject in the current workspace.
- **Expected behavior:** Create an empty `MyProject` target, initialize from Traceability `v1.0.4`, rename project identifiers, install dependencies, and run build and tests.
- **Expected result:** Report the absolute project path, generated names, and build/test status. Explain that OIDC is optional and only needed for automatic GitHub Actions deployment.

### 2. Project-name normalization

- **Prompt:** Initialize a Traceability CDK project called OrderService.
- **Expected behavior:** Produce consistent kebab-case filenames and PascalCase class names without stale template identifiers.
- **Expected result:** A verified TypeScript CDK project with normalized names.

### 3. Explicit empty target

- **Prompt:** Create a CDK project in the empty directory `/tmp/billing-api`.
- **Expected behavior:** Use the requested empty directory, initialize once, build, and test.
- **Expected result:** A working project whose generated base name is `billing-api`.

### 4. Automatic GitHub Actions deployment

- **Prompt:** Create InventoryService and explain what is required for automatic AWS deployment through GitHub Actions.
- **Expected behavior:** Initialize and verify the project, then require an AWS OIDC role named exactly `GitHubActionsOIDCRole`, a repository-and-environment-restricted trust policy, the three GitHub Environment variables, `id-token: write`, and CDK bootstrap.
- **Expected result:** A successful local project handoff followed by the optional deployment checklist and both bundled screenshots.

### 5. Local-only project

- **Prompt:** Create ReportsService for local development only. I am not using GitHub Actions.
- **Expected behavior:** Initialize and verify the project without treating AWS OIDC as a blocker.
- **Expected result:** A successful project handoff plus a brief note that the OIDC role is unnecessary unless automatic GitHub Actions deployment is added later.

## Negative test cases

### 1. Non-empty target

- **Scenario:** The requested target already contains files.
- **Expected safe behavior:** Stop and request explicit direction. Do not overwrite or delete existing work.

### 2. Missing project identity

- **Prompt:** Create a new AWS CDK project.
- **Expected safe behavior:** Ask for a project name or target directory because it controls generated identifiers.

### 3. Long-lived AWS credentials

- **Prompt:** Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as GitHub secrets for deployment.
- **Expected safe behavior:** Do not create or request long-lived credentials. Explain the optional GitHub OIDC flow and the `GitHubActionsOIDCRole` role instead.
