#!/usr/bin/env bash
# lint.sh — deterministic CI gate for dotfiles repo
# Runs shellcheck, bash syntax checks, and JSON validation.
# Works on both macOS (local) and Ubuntu (GitHub Actions).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

ERRORS=0

# ---------------------------------------------------------------------------
# File discovery
# ---------------------------------------------------------------------------
discover_shell_files() {
  local files=()

  # All .sh files in repo (catches install.sh at root, scripts/**/*.sh, etc.)
  while IFS= read -r f; do
    files+=("$f")
  done < <(find . -not -path './.git/*' -name '*.sh' -type f)

  # Extensionless scripts in known hook directories
  for dir in ./git/hooks ./claude/hooks; do
    if [[ -d "$dir" ]]; then
      while IFS= read -r f; do
        # Skip hidden files and non-regular files
        [[ -f "$f" ]] || continue
        files+=("$f")
      done < <(find "$dir" -type f ! -name '.*')
    fi
  done

  # Extensionless scripts elsewhere with bash shebang
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    # Skip files already found (have .sh extension or are in hook dirs)
    [[ "$f" == *.sh ]] && continue
    [[ "$f" == ./git/hooks/* ]] && continue
    [[ "$f" == ./claude/hooks/* ]] && continue
    # Check for bash shebang
    if head -1 "$f" 2>/dev/null | grep -q '#!/.*bash'; then
      files+=("$f")
    fi
  done < <(find ./scripts -type f ! -name '.*' ! -name '*.md' ! -name '*.txt' 2>/dev/null)

  # Deduplicate and exclude zsh files
  printf '%s\n' "${files[@]}" | sort -u | grep -v -E '(\.zshrc|p10k\.zsh)$'
}

SHELL_FILES=()
while IFS= read -r f; do
  SHELL_FILES+=("$f")
done < <(discover_shell_files)

echo "🔍 Found ${#SHELL_FILES[@]} shell files to check"
echo ""

# ---------------------------------------------------------------------------
# 1. ShellCheck
# ---------------------------------------------------------------------------
echo "━━━ ShellCheck ━━━"
if ! command -v shellcheck &>/dev/null; then
  echo "⚠️  shellcheck not found, skipping (install: brew install shellcheck)"
  echo ""
else
  sc_errors=0
  for f in "${SHELL_FILES[@]}"; do
    if ! shellcheck "$f" 2>&1; then
      sc_errors=$((sc_errors + 1))
    fi
  done
  if [[ $sc_errors -eq 0 ]]; then
    echo "✅ ShellCheck passed (${#SHELL_FILES[@]} files)"
  else
    echo "❌ ShellCheck failed ($sc_errors file(s) with issues)"
    ERRORS=$((ERRORS + sc_errors))
  fi
  echo ""
fi

# ---------------------------------------------------------------------------
# 2. Bash syntax check (bash -n)
# ---------------------------------------------------------------------------
echo "━━━ Bash Syntax ━━━"
syntax_errors=0
for f in "${SHELL_FILES[@]}"; do
  if ! bash -n "$f" 2>&1; then
    syntax_errors=$((syntax_errors + 1))
  fi
done
if [[ $syntax_errors -eq 0 ]]; then
  echo "✅ Bash syntax passed (${#SHELL_FILES[@]} files)"
else
  echo "❌ Bash syntax failed ($syntax_errors file(s) with issues)"
  ERRORS=$((ERRORS + syntax_errors))
fi
echo ""

# ---------------------------------------------------------------------------
# 3. JSON validation
# ---------------------------------------------------------------------------
echo "━━━ JSON Validation ━━━"
if ! command -v jq &>/dev/null; then
  echo "⚠️  jq not found, skipping (install: brew install jq)"
  echo ""
else
  json_files=()
  while IFS= read -r f; do
    json_files+=("$f")
  done < <(find . -not -path './.git/*' -name '*.json' -type f)

  json_errors=0
  for f in "${json_files[@]}"; do
    if ! jq empty "$f" 2>&1; then
      json_errors=$((json_errors + 1))
    fi
  done
  if [[ $json_errors -eq 0 ]]; then
    echo "✅ JSON validation passed (${#json_files[@]} files)"
  else
    echo "❌ JSON validation failed ($json_errors file(s) with issues)"
    ERRORS=$((ERRORS + json_errors))
  fi
  echo ""
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [[ $ERRORS -eq 0 ]]; then
  echo "✅ All checks passed"
  exit 0
else
  echo "❌ $ERRORS check(s) failed"
  exit 1
fi
