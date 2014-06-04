#!/bin/bash

function usage() {
    cat >&2 << EOF
$0

Cherry pick the canges specified by REMOTE_REPOSITORY and PULL_REQUEST_ID into
the actual branch.

Usage:
    $0 REMOTE_REPOSITORY PULL_REQUEST_ID TARGET_BRANCH LOCAL_BRANCH

Where:
    REMOTE_REPOSITORY     URL to the remote repository, like:
                          https://github.com/xapi-project/sm

    PULL_REQUEST_ID       id of the pull request relative to REMOTE_REPOSITORY
                          it's a simple number, like 153

EOF
    exit 1
}

[ -z "$1" ] && usage
[ -z "$2" ] && usage

set -eux

REMOTE_REPOSITORY="$1"
PULL_REQUEST_ID="$2"

tmpfile=$(mktemp)

ACTUAL_COMMIT=$(git rev-parse HEAD)

git fetch "$REMOTE_REPOSITORY" "refs/pull/$PULL_REQUEST_ID/head"
git log "$ACTUAL_COMMIT..FETCH_HEAD" --format=%H --reverse > $tmpfile

cat $tmpfile | while read commit; do
    git cherry-pick $commit
done
