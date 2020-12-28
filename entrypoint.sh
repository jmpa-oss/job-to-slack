#!/usr/bin/env bash
# the entrypoint for the GitHub Action; this script posts a given message to a given Slack channel.

# funcs
die() { echo "$1" >&2; exit "${2:-1}"; }
diejq() { echo "$1" >&2; jq '.' <<< "$2"; exit "${3:-1}"; }

# check deps
deps=(curl)
for dep in "${deps[@]}"; do
  hash "$dep" 2>/dev/null || missing+=("$dep")
done
if [[ ${#missing[@]} -ne 0 ]]; then
  [[ ${#missing[@]} -gt 1 ]] && { s="s"; }
  die "missing dep${s}: ${missing[*]}"
fi

# parameters
# https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-syntax-for-github-actions#jobsjob_idstepswith
webhook="$INPUT_WEBHOOK"
status="$INPUT_STATUS"

# validate parameters
missing=()
[[ -z "$webhook" ]] && { missing+=("webhook"); }
[[ -z "$status" ]] && { missing+=("status"); }
if [[ ${#missing[@]} -ne 0 ]]; then
  [[ ${#missing[@]} -gt 1 ]] && { s="s"; }
  die "missing input parameter${s}: ${missing[*]}"
fi

# extract vars
commit="${GITHUB_SHA:0:7}"
repo="$GITHUB_REPOSITORY"
workflow="$GITHUB_WORKFLOW"

# determine message status
msg=""
color=""
case "$status" in
success)
  msg=":thumbsup::skin-tone-2: *GitHub Action succeeded!*"
  color="#44E544"
  ;;
fail)
  msg=":thumbsdown::skin-tone-2: *GitHub Action failed!*"
  color="#FF4C4C"
  ;;
*) die "missing $status implementation"
esac

# query to execute
# FIXME figure out a way to do this without escaping the quotes in this variable.
read -d '' q <<@
{
  \"text\": \"$msg\",
  \"attachments\": [
    {
      \"color\": \"$color\",
      \"fields\": [
        {
          \"title\": \"Repo\",
          \"value\": \"<https://github.com/$GITHUB_REPOSITORY|$repo>\"
        },
        {
          \"title\": \"Commit\",
          \"value\": \"<https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA|$commit>\"
        },
        {
          \"title\": \"Action\",
          \"value\": \"<https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_ACTION|$workflow>\"
        }
      ]
    }
  ]
}
@

# post message
resp=$(curl -s "$webhook" \
  -H "Content-type: application/json" \
  -d "$q") \
  || die "failed curl to post message to webhook"
[[ "$resp" != "ok" ]] \
    && die "non-successful message returned when posting message to webhook: $resp"
