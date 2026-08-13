# OpenAI plugin submission checklist

## Technical package — complete

- [x] Skills-only plugin manifest is present and valid.
- [x] `SKILL.md`, UI metadata, scripts, and referenced assets are bundled.
- [x] The initializer uses the pinned Traceability `v1.0.4` starter.
- [x] Project creation, identifier normalization, dependency installation, build, and tests have been exercised end to end.
- [x] GitHub Actions OIDC is clearly optional and required only for automatic deployment.
- [x] The optional deployment role is named exactly `GitHubActionsOIDCRole`.
- [x] Long-lived AWS access keys are not requested or recommended.
- [x] Public profile, website, support, releases, privacy, terms, source-download, starter, and GitHub OIDC discovery URLs are checked by `scripts/validate.sh --links`.
- [x] The Medium article is reachable in a normal browser; Medium returns HTTP 403 only to automated command-line probes.
- [x] Five positive and three negative reviewer tests include all required fields.
- [x] Repeatable skill and plugin packaging is provided by `scripts/package.sh`.
- [x] The repository marketplace allows installation directly from GitHub.

## Application steps — publisher action required

- [ ] Complete individual verification for Lars Andersson in the publishing OpenAI organization.
- [ ] Confirm **Apps Management: Write** access in that organization.
- [ ] Open <https://platform.openai.com/plugins> and create a **Skills only** submission.
- [ ] Confirm that **AWS CDK Project Init** is accepted as the public plugin name.
- [ ] Download and upload [`init-aws-cdk-project-skill-1.0.0.zip`](https://github.com/zipon/init-project-skill/releases/download/v1.0.0/init-aws-cdk-project-skill-1.0.0.zip).
- [ ] Enter the information from `LISTING.md` and upload `assets/logo.png`.
- [ ] Enter the prompts from `STARTER_PROMPTS.md`.
- [ ] Enter the five positive and three negative cases from `TEST_CASES.md`.
- [ ] Select all offered countries and regions if the publisher is comfortable supporting them under the published terms.
- [ ] Enter `RELEASE_NOTES.md`, complete the policy attestations, and submit for review.
- [ ] After approval, publish the approved version from the portal.

The OpenAI submission portal is the authoritative check for public-name availability and publisher eligibility.
