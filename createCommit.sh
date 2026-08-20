#!/usr/bin/env bash
set -euo pipefail

: "${COMMIT_MESSAGE:?Error: commit-message must be set}"

if [[ "${GITHUB_REF_TYPE}" != "branch" ]]; then
  echo "::error::this action can only be used to commit to branches, not tags"
  exit 1
fi

tmpdir=$(mktemp -d --tmpdir="${RUNNER_TEMP}")
trap 'rm -rf "${tmpdir}"' EXIT

additions_file="${tmpdir}/additions.jsonl"
deletions_file="${tmpdir}/deletions.jsonl"

touch "${additions_file}"
touch "${deletions_file}"

line=0
while IFS='' read -r -d '' status; do
  IFS='' read -r -d '' path || {
    echo "::error::git status unexpectedly ended in entry ${line}"
    exit 1
  }

  case "${status}" in
    A|M)
      jq \
        --null-input \
        --compact-output \
        --arg path "${path}" \
        --rawfile contents <(git show ":${path}" | base64 -w0) \
        '{ path: $path, contents: $contents }' \
        >> "${additions_file}"
      ;;

    D)
      jq \
        --null-input \
        --compact-output \
        --arg path "${path}" \
        '{ path: $path }' \
        >> "${deletions_file}"
      ;;

    *)
      echo "::error::Unexpected git file status: ${status} for entry ${line} (${path})"
      exit 1
      ;;
  esac

  line=$(( line + 1 ))
done < <(git diff --staged --name-status --no-renames -z "${GITHUB_SHA}")

query_file="${tmpdir}/query.json"

jq \
  --null-input \
  --compact-output \
  --rawfile query "${GITHUB_ACTION_PATH}/createCommit.graphql" \
  --arg repo "${GITHUB_REPOSITORY}" \
  --arg branch "${GITHUB_REF_NAME}" \
  --arg expectedHeadOid "${GITHUB_SHA}" \
  --arg commitMessage "${COMMIT_MESSAGE}" \
  --slurpfile additions "${additions_file}" \
  --slurpfile deletions "${deletions_file}" \
  --from-file "${GITHUB_ACTION_PATH}/createCommit.jq" \
  > "${query_file}"

API_HEADERS=(
  --header "Authorization: Bearer ${GITHUB_API_TOKEN}"
  --header "Content-Type: application/json"
)

response=$(curl \
  --silent \
  --show-error \
  --fail-with-body \
  "${API_HEADERS[@]}" \
  --request POST \
  --data "@${query_file}" \
  "${GITHUB_GRAPHQL_URL}")

commit_oid=$(jq -r '.data.createCommitOnBranch.commit.oid' "${response}")

echo "commit-oid=${commit_oid}" >> "${GITHUB_OUTPUT}"
