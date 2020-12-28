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

# input parameters
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

# extract / default vars (for local testing)
commit="${GITHUB_SHA:0:7}" # use shorthand commit
commit="${commit:-commit}"
repo="${GITHUB_REPOSITORY:-repo}"
workflow="${GITHUB_WORKFLOW:-workflow}"
ref="${GITHUB_REF:-ref}"
event="${GITHUB_EVENT_NAME:-event}"
actor="${GITHUB_ACTOR:-actor}"
runId="${GITHUB_RUN_ID:-runId}"

# determine message status
# https://docs.github.com/en/free-pro-team@latest/actions/reference/context-and-expression-syntax-for-github-actions#job-context
msg=""; color=""
case "$status" in
success)
  msg=":thumbsup::skin-tone-2: *GitHub Action succeeded!*"
  color="#44E544"
  ;;
failure)
  msg=":thumbsdown::skin-tone-2: *GitHub Action failed!*"
  color="#FF4C4C"
  ;;
cancelled)
  msg=":hand::skin-tone-2: *GitHub Action cancelled!*"
  color="#FF7F50"
  ;;
*) die "missing $status implementation"
esac

# query to execute
read -d '' q <<@
{
  "text": "$msg",
  "attachments": [
    {
      "color": "$color",
      "blocks": [
        {
          "type": "section",
          "fields": [
            {
              "type": "mrkdwn",
              "text": "*Repository:*\\\\n<https://github.com/$repo|$repo>"
            },
            {
              "type": "mrkdwn",
              "text": "*Commit:*\\\\n<https://github.com/$repo/commit/$commit|$commit>"
            },
            {
              "type": "mrkdwn",
              "text": "*Action:*\\\\n<https://github.com/$repo/actions/runs/$runId|$workflow>"
            },
            {
              "type": "mrkdwn",
              "text": "*Triggered by:*\\\\n<https://github.com/$actor>"
            },
            {
              "type": "mrkdwn",
              "text": "*Branch:*\\\\n$ref"
            },
            {
              "type": "mrkdwn",
              "text": "*Event:*\\\\n$event"
            }
			    ]
        }
      ]
    }
  ]
}
@

# validate query
[[ $(<<<"$q" jq '. | tojson') ]] \
  || die "query is an invalid json payload"

# post query to webhook
# https://api.slack.com/messaging/webhooks
echo "##[group]Posting message to webhook"
resp=$(curl -s "$webhook" \
  -H "Content-type: application/json" \
  -d "$q") \
  || die "failed curl to post message to webhook"
[[ "$resp" != "ok" ]] \
    && die "non-successful message returned when posting message to webhook: $resp"
echo "##[endgroup]"
