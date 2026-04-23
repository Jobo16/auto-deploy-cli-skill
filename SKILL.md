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
- package and deploy a simple HTML/static folder
- build and deploy a Vite/React/Vue/Svelte-style frontend project
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
- `deploy_source_type`: `existing_zip`, `static_folder`, or `frontend_project` for `publish` and `deploy`
- `project_name`: required for `publish`
- `project_ref`: required for `deploy` and `delete`; may be id, slug, or exact name
- `zip_path`: required only when `deploy_source_type` is `existing_zip`
- `source_dir`: required when `deploy_source_type` is `static_folder` or `frontend_project`
- `build_command`: required for `frontend_project`; default suggestion is `npm run build`
- `build_output_dir`: required for `frontend_project`; default suggestion is `dist`

Use concise direct questions only for missing or ambiguous fields. Do not ask for fields that do not matter to the chosen action.

Once the intent is clear, restate the resolved command in one line before execution.

Examples:

```text
I am about to publish ./dist.zip as project "portal" to http://deploy.sites.tzxys.cn.
I am about to deploy ./dist.zip to project "portal-bf94f9" on http://deploy.sites.tzxys.cn.
I am about to delete project "portal-bf94f9" from http://deploy.sites.tzxys.cn.
I am about to build /path/app with "npm run build", zip /path/app/dist, and publish it as "portal".
```

If the user already gave all required fields clearly, do not ask again.

## Beginner Intake

When the user is not precise, ask what they are deploying:

```text
你要部署的是哪一种？
1. 已经打好的 dist.zip
2. 一个普通 HTML 静态目录，里面有 index.html
3. Vite / React / Vue / Svelte 这类前端项目，需要先构建
```

For `frontend_project`, ask for or infer:

- project root directory
- package manager from lockfile: `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, or `package-lock.json`
- build command, usually `npm run build`, `pnpm build`, `yarn build`, or `bun run build`
- output directory, usually `dist`; Create React App often uses `build`

If dependencies are missing, ask before installing. Example:

```text
这个项目没有 node_modules。我需要先运行 npm install，然后 npm run build，再压缩 dist 目录。确认执行吗？
```

Do not deploy source code directories such as a React project root directly. Deploy the built output directory.

For Next.js or SSR projects, stop and confirm whether the app has been configured for static export. This deployer only serves static files; it does not run Node SSR servers.

## Preparing A Zip

The deploy service expects a zip whose root contains `index.html`.

Use the bundled packaging script:

```bash
bash scripts/package_static_site.sh "<source-dir-or-build-output>" "/tmp/<project>.zip"
```

For frontend projects:

```bash
bash scripts/package_static_site.sh "<project-root>" "/tmp/<project>.zip" --build --build-command "npm run build" --output-dir "dist"
```

Before publishing, verify the zip shape:

```bash
zipinfo -1 "/tmp/<project>.zip" | head
```

The output must include:

```text
index.html
```

at the zip root, not only under a nested folder.

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
