#!/usr/bin/env bash
# the entrypoint for the GitHub Action; this script posts a given message to a given Slack channel.

echo "Hello World!"


# https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-syntax-for-github-actions#jobsjob_idstepswith
echo "token: $INPUT_TOKEN"
echo "$2"
echo "$3"