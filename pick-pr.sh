#!/bin/bash

function usage() {
    cat >&2 << EOF
$0

Cherry pick the canges specified by REMOTE_REPOSITORY and PULL_REQUEST_ID into
the actual branch. It will always recreate two branches: pick_tgt and pick_src

Usage:
    $0 REMOTE_REPOSITORY PULL_REQUEST_ID TARGET_BRANCH

Where:
    REMOTE_REPOSITORY     URL to the remote repository, like:
                          https://github.com/xapi-project/sm

    PULL_REQUEST_ID       id of the pull request relative to REMOTE_REPOSITORY
                          it's a simple number, like 153

    TARGET_BRANCH         This is the target branch.

EOF
    exit 1
}

[ -z "$1" ] && usage
[ -z "$2" ] && usage
[ -z "$3" ] && usage

set -eux

THISFILE=$(readlink -f $0)
THISDIR=$(dirname $THISFILE)

REMOTE_REPOSITORY="$1"
PULL_REQUEST_ID="$2"
TARGET_BRANCH="$3"

git fetch "$REMOTE_REPOSITORY" "$TARGET_BRANCH"
git checkout FETCH_HEAD -B pick_tgt --no-track
git fetch "$REMOTE_REPOSITORY" "refs/pull/$PULL_REQUEST_ID/head"
git checkout FETCH_HEAD -B pick_src --no-track

git rebase pick_tgt

tmp_file=$(mktemp)
git log "pick_tgt..pick_src" --format=%H --reverse > $tmp_file

git checkout pick_tgt

LATEST_COMMIT=$(git rev-parse HEAD)

cmdfile=$(mktemp)
cat $tmp_file | while read commit_id; do
    cat >> $cmdfile << EOF
git cherry-pick $commit_id
VISUAL=$THISDIR/add_reviewed_by.py git commit --amend
git commit --amend
EOF
done

bash $cmdfile
