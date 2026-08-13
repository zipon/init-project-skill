# Lars Andersson's Codex plugins

This repository contains installable plugins and skills for ChatGPT and Codex.

## AWS CDK Project Init

`aws-cdk-project-init` creates standardized AWS CDK TypeScript projects from the pinned Traceability `v1.0.4` starter. See the [plugin documentation](aws-cdk-project-init/README.md) for its behavior and requirements.

### Install from this repository

Add this repository as a Codex marketplace and install the plugin:

```bash
codex plugin marketplace add zipon/init-project-skill --ref main
codex plugin add aws-cdk-project-init@init-project-skill
```

Restart the ChatGPT desktop app after installation, then start a new task so the installed skill is discovered.

### Download

- [Download the current repository as a ZIP](https://github.com/zipon/init-project-skill/archive/refs/heads/main.zip)
- [Browse releases](https://github.com/zipon/init-project-skill/releases)

To create the OpenAI submission bundle and the full plugin archive locally, run:

```bash
./scripts/package.sh
```

The archives and SHA-256 checksums are written to `dist/`. They are generated artifacts and are intentionally not committed.

## Publishing

The repository includes the public listing details, starter prompts, reviewer test cases, release notes, privacy policy, terms, support information, and reproducible packaging needed for a skills-only OpenAI plugin submission.

Publishing to the universal Plugins Directory still requires a verified publisher identity, **Apps Management: Write** access, review, and final publication through the [OpenAI plugin submission portal](https://platform.openai.com/plugins).
