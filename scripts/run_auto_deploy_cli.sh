#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${AUTO_DEPLOY_BASE_URL:-http://deploy.sites.tzxys.cn}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  run_auto_deploy_cli.sh [--base-url URL] [--json] <command> [args...]

Commands:
  list
  publish <project-name> <zip-path>
  deploy <project-ref> <zip-path>
  delete <project-ref>
EOF
}

resolve_cli_path() {
  local candidates=()

  if [[ -n "${AUTO_DEPLOY_CLI_PATH:-}" ]]; then
    candidates+=("${AUTO_DEPLOY_CLI_PATH}")
  fi

  candidates+=(
    "${SKILL_ROOT}/../auto-deploy-v2/src/cli.js"
    "/Users/jobo/projects/tangzhexue/others/auto-deploy-v2/src/cli.js"
    "$(pwd)/src/cli.js"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -f "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  return 1
}

JSON_FLAG=""
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-url)
      [[ $# -ge 2 ]] || { echo "Missing value for --base-url" >&2; exit 1; }
      BASE_URL="$2"
      shift 2
      ;;
    --json)
      JSON_FLAG="--json"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]}"

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

CLI_PATH="$(resolve_cli_path || true)"
if [[ -z "${CLI_PATH}" ]]; then
  echo "Could not find auto-deploy-v2 CLI. Set AUTO_DEPLOY_CLI_PATH or place the repo at ../auto-deploy-v2." >&2
  exit 1
fi

exec node "${CLI_PATH}" --base-url "${BASE_URL}" ${JSON_FLAG:+"${JSON_FLAG}"} "$@"
