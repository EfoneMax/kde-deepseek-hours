#!/usr/bin/env bash
set -euo pipefail

readonly JACTIONLINT_VERSION="2.6.0"
readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/jactionlint/${JACTIONLINT_VERSION}"
readonly BIN="${CACHE_DIR}/jactionlint"

case "$(uname -s)" in
  Linux) os="linux" ;;
  Darwin) os="darwin" ;;
  *) echo "check.sh: unsupported OS: $(uname -s)" >&2; exit 2 ;;
esac

case "$(uname -m)" in
  x86_64|amd64) arch="amd64" ;;
  arm64|aarch64) arch="arm64" ;;
  *) echo "check.sh: unsupported architecture: $(uname -m)" >&2; exit 2 ;;
esac

case "${os}-${arch}" in
  linux-amd64) sha256="d5400967b8f0d3a5ae9a4cee21f56400a50eb3f05d0cbb4ef17184f17f0760c8" ;;
  linux-arm64) sha256="c726185a85f26d09aa94ea556509a19827979074b35d65f357f3a4947573e934" ;;
  darwin-amd64) sha256="aa89c49ad5c9530f2308f18333166050f97f14d420f478a8225d043bef1e2cab" ;;
  darwin-arm64) sha256="c3f373c7eac668aacb390b9c802cf4b5e2ad1a11b0b0c0aea6b04ca0cfa0c018" ;;
esac

if [[ ! -x "${BIN}" ]]; then
  mkdir -p "${CACHE_DIR}"
  archive="${CACHE_DIR}/jactionlint_${JACTIONLINT_VERSION}_${os}_${arch}.tar.gz"
  url="https://github.com/jdx/jactionlint/releases/download/v${JACTIONLINT_VERSION}/jactionlint_${JACTIONLINT_VERSION}_${os}_${arch}.tar.gz"

  curl --proto '=https' --tlsv1.2 -fsSL "${url}" -o "${archive}"
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s  %s\n' "${sha256}" "${archive}" | sha256sum -c -
  else
    printf '%s  %s\n' "${sha256}" "${archive}" | shasum -a 256 -c -
  fi
  tar -xzf "${archive}" -C "${CACHE_DIR}" jactionlint
  chmod +x "${BIN}"
fi

shellcheck_args=()
if shellcheck_bin="$(command -v shellcheck 2>/dev/null)" && "${shellcheck_bin}" --version >/dev/null 2>&1; then
  shellcheck_args=(--shellcheck="${shellcheck_bin}")
else
  echo "check.sh: shellcheck is not usable; running jactionlint without shellcheck" >&2
  shellcheck_args=(--shellcheck=)
fi

cd "${REPO_ROOT}"
exec "${BIN}" --profile default "${shellcheck_args[@]}" "$@"
