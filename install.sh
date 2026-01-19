#!/usr/bin/env bash
set -e

REPO="https://github.com/harivansh-afk/claude-code-vertical.git"
TMP="/tmp/claude-code-vertical-$$"

git clone --depth 1 "$REPO" "$TMP" 2>/dev/null

mkdir -p .claude/vertical/plans
cp -r "$TMP/commands" .claude/
cp -r "$TMP/skills" .claude/
cp -r "$TMP/skill-index" .claude/
cp -r "$TMP/lib" .claude/

rm -rf "$TMP"

echo "Installed to .claude/"
echo "Run: claude then /plan"
