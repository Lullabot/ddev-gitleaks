#!/usr/bin/env bash
#ddev-generated
# Warn (never block) if the container environment or project .env files contain
# secrets/API keys. Runs as a DDEV post-start hook and MUST always exit 0 so it
# can never abort `ddev start`.
set -uo pipefail

CONFIG="/etc/gitleaks/gitleaks.toml"

found=0

# Run gitleaks against stdin. `--exit-code 2` makes the exit status unambiguous:
#   0          -> clean (no leaks)
#   2          -> leaks found
#   any other  -> gitleaks itself errored (missing binary, bad config, removed
#                 flag after an upgrade, ...). We report that but never treat it
#                 as a leak, so a broken scanner can't spam the warning banner.
# `--log-level error` keeps a clean run silent (no "no leaks found" noise);
# `--redact` keeps secret values out of the output.
scan() {
  gitleaks stdin --no-banner --redact -v --log-level error --exit-code 2 "$@"
}

# 1) Scan the container environment, using the DDEV allowlist config so benign
#    DDEV-provided variables (DDEV_*, IS_DDEV_PROJECT, ...) do not raise false
#    positives on a clean baseline.
ENV_CFG=()
[ -f "$CONFIG" ] && ENV_CFG=(-c "$CONFIG")
rc=0
env | scan "${ENV_CFG[@]}" || rc=$?
case "$rc" in
  0) ;;
  2) found=1 ;;
  *) echo "gitleaks-scan: environment scan failed (gitleaks exit $rc); skipping" >&2 ;;
esac

# 2) Scan dotenv-style files in the project. .env files are usually gitignored,
#    so scan the filesystem rather than git. The DDEV allowlist is deliberately
#    NOT applied here: its regexes are keyed to process-env names (^DDEV_=, ...)
#    and would wrongly suppress a real secret that shares one of those key
#    prefixes inside a project .env file. Heavy/irrelevant directories are
#    pruned and committed template files are skipped, but depth is not limited
#    so a secret in a deeply nested .env (e.g. a multisite or sub-app) is found.
APPROOT="${DDEV_APPROOT:-/var/www/html}"
if [ -d "$APPROOT" ]; then
  while IFS= read -r f; do
    case "${f##*/}" in
      .env.example|.env.dist|.env.sample|.env.template) continue ;;
    esac
    rel="${f#"$APPROOT"/}"
    rc=0
    scan < "$f" || rc=$?
    case "$rc" in
      0) ;;
      2) echo "  ^ findings above are from project file: $rel" >&2; found=1 ;;
      *) echo "gitleaks-scan: scan of '$rel' failed (gitleaks exit $rc); skipping" >&2 ;;
    esac
  done < <(find "$APPROOT" \
      \( -name vendor -o -name node_modules -o -name .git \) -prune -o \
      -type f \( -name '.env' -o -name '.env.*' \) -print 2>/dev/null)
fi

[ "$found" -eq 0 ] && exit 0

cat >&2 <<'WARN'

============================================================================
  WARNING: gitleaks detected likely secrets or API keys

  gitleaks found what look like secrets or API keys in this container's
  environment and/or project .env files. These are often propagated from
  your GLOBAL DDEV config (e.g. web_environment / TERMINUS_MACHINE_TOKEN).

  Any process running in this web container can READ and USE these values,
  including AI coding assistants such as Claude Code.

  Review what you run here:
    * Check every command, script, skill, or hook before executing it.
    * Avoid auto-accept / permission-skipping ("yolo") modes (for example,
      Claude Code's --dangerously-skip-permissions) while real secrets are
      present.
    * Consider unsetting secrets for projects where untrusted automation runs.
============================================================================

WARN
exit 0
