---
name: auto-deploy-cli-skill
description: Use when the user wants to deploy, update, list, or delete a static site through the auto-deploy-v2 CLI. This skill first confirms the deployment requirements, then runs the local CLI against the deploy service instead of improvising raw HTTP calls.
---

# Auto Deploy CLI Skill

## Overview

This skill handles static-site deployment tasks through the local `auto-deploy-v2` CLI.

Use it when the user wants to:

- publish a new static site from a zip
- overwrite an existing project deployment
- inspect the current project list
- delete a deployed project

Default deploy service:

```text
http://deploy.sites.tzxys.cn
```

Prefer the bundled script:

```bash
bash scripts/run_auto_deploy_cli.sh ...
```

Do not replace the CLI with ad hoc `curl` unless the CLI is unavailable or broken and you need a fallback to diagnose the issue.

## Required Confirmation

Before running any deploy command, confirm the request in concrete terms.

Always resolve these fields first:

- `action`: `list`, `publish`, `deploy`, or `delete`
- `base_url`: default to `http://deploy.sites.tzxys.cn` unless the user says otherwise
- `project_name`: required for `publish`
- `project_ref`: required for `deploy` and `delete`; may be id, slug, or exact name
- `zip_path`: required for `publish` and `deploy`

Use concise direct questions only for missing or ambiguous fields. Do not ask for fields that do not matter to the chosen action.

Once the intent is clear, restate the resolved command in one line before execution.

Examples:

```text
I am about to publish ./dist.zip as project "portal" to http://deploy.sites.tzxys.cn.
I am about to deploy ./dist.zip to project "portal-bf94f9" on http://deploy.sites.tzxys.cn.
I am about to delete project "portal-bf94f9" from http://deploy.sites.tzxys.cn.
```

If the user already gave all required fields clearly, do not ask again.

## Command Mapping

Map user intent to the CLI exactly as follows:

```bash
bash scripts/run_auto_deploy_cli.sh --base-url http://deploy.sites.tzxys.cn list
bash scripts/run_auto_deploy_cli.sh --base-url http://deploy.sites.tzxys.cn publish "<project-name>" "<zip-path>"
bash scripts/run_auto_deploy_cli.sh --base-url http://deploy.sites.tzxys.cn deploy "<project-ref>" "<zip-path>"
bash scripts/run_auto_deploy_cli.sh --base-url http://deploy.sites.tzxys.cn delete "<project-ref>"
```

Use `--json` when machine-readable output would help with follow-up parsing or validation.

## Execution Rules

1. Check that the zip path exists before `publish` or `deploy`.
2. Use the bundled script, not a hand-written CLI path, unless you are debugging the script itself.
3. Keep the action one-shot. Do not drop into REPL mode.
4. After `publish` or `deploy`, report:
   - project name
   - slug
   - resulting URL
   - latest deploy key when available
5. After `delete`, report that the project was removed.
6. After `list`, summarize the returned projects rather than dumping excessive raw output unless the user asked for JSON.

## CLI Resolution

The bundled script resolves the CLI in this order:

1. `AUTO_DEPLOY_CLI_PATH`
2. `../auto-deploy-v2/src/cli.js` relative to this skill repo
3. `/Users/jobo/projects/tangzhexue/others/auto-deploy-v2/src/cli.js`
4. `./src/cli.js` from the current working directory

If none of these paths exist, stop and say the local `auto-deploy-v2` repository is missing, then ask for the repo path or for `AUTO_DEPLOY_CLI_PATH`.

## Validation

After a mutating action, do one quick verification step when practical:

- `publish`: optionally fetch the returned site URL or run `list`
- `deploy`: verify the command succeeded and the returned deploy key changed
- `delete`: run `list` and confirm the project no longer appears

Do not over-validate when the service is slow or flaky. One confirming check is enough.
