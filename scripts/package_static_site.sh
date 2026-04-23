#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  package_static_site.sh <source-dir> <output-zip> [--build] [--build-command CMD] [--output-dir DIR]

Examples:
  package_static_site.sh ./public-site /tmp/site.zip
  package_static_site.sh ./frontend /tmp/frontend.zip --build --build-command "npm run build" --output-dir dist
EOF
}

SOURCE_DIR=""
OUTPUT_ZIP=""
BUILD=0
BUILD_COMMAND=""
OUTPUT_DIR=""

if [[ $# -lt 2 ]]; then
  usage >&2
  exit 1
fi

SOURCE_DIR="$1"
OUTPUT_ZIP="$2"
shift 2

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build)
      BUILD=1
      shift
      ;;
    --build-command)
      [[ $# -ge 2 ]] || { echo "Missing value for --build-command" >&2; exit 1; }
      BUILD_COMMAND="$2"
      shift 2
      ;;
    --output-dir)
      [[ $# -ge 2 ]] || { echo "Missing value for --output-dir" >&2; exit 1; }
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

SOURCE_DIR="$(cd "${SOURCE_DIR}" && pwd)"
OUTPUT_ZIP="$(python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "${OUTPUT_ZIP}")"

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "Source directory does not exist: ${SOURCE_DIR}" >&2
  exit 1
fi

if [[ "${BUILD}" -eq 1 ]]; then
  if [[ -z "${BUILD_COMMAND}" ]]; then
    BUILD_COMMAND="npm run build"
  fi
  if [[ -z "${OUTPUT_DIR}" ]]; then
    OUTPUT_DIR="dist"
  fi

  echo "Building ${SOURCE_DIR} with: ${BUILD_COMMAND}" >&2
  (cd "${SOURCE_DIR}" && bash -lc "${BUILD_COMMAND}")
  PACKAGE_DIR="${SOURCE_DIR}/${OUTPUT_DIR}"
else
  PACKAGE_DIR="${SOURCE_DIR}"
fi

if [[ ! -d "${PACKAGE_DIR}" ]]; then
  echo "Package directory does not exist: ${PACKAGE_DIR}" >&2
  exit 1
fi

if [[ ! -f "${PACKAGE_DIR}/index.html" ]]; then
  echo "index.html not found at package root: ${PACKAGE_DIR}" >&2
  exit 1
fi

mkdir -p "$(dirname "${OUTPUT_ZIP}")"
rm -f "${OUTPUT_ZIP}"

(cd "${PACKAGE_DIR}" && zip -qr "${OUTPUT_ZIP}" . -x ".git/*" "node_modules/*" ".DS_Store")

if ! zipinfo -1 "${OUTPUT_ZIP}" | grep -qx "index.html"; then
  echo "Packaged zip is invalid: index.html is not at zip root." >&2
  exit 1
fi

echo "${OUTPUT_ZIP}"
