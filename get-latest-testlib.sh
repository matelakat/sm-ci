#!/bin/bash

function usage() {
    cat >&2 << EOF
$0

Update your actual branch by cherry-picking all the changes that are related to
tests/testlib.py and tests/test_testlib.py

Usage:
    $0 REMOTE_REPOSITORY BRANCH

Where:
    REMOTE_REPOSITORY     URL to the remote repository, like:
                          https://github.com/xapi-project/sm

    BRANCH                This is the branch from which you want to get the
                          latest library code.

EOF
    exit 1
}

[ -z "$1" ] && usage
[ -z "$2" ] && usage

set -eu

REMOTE_REPOSITORY="$1"
BRANCH="$2"

tmp_file=$(mktemp)

git fetch "$REMOTE_REPOSITORY" "$BRANCH"
git log --format=%H HEAD..FETCH_HEAD -- tests/test_testlib.py tests/testlib.py > $tmp_file

cat $tmp_file | while read commit_id; do
    if git show $commit_id | git apply --check > /dev/null 2>&1; then
        git cherry-pick -x $commit_id
    else
        echo "COMMIT $commit_id was not applied - you might have already picked that"
    fi
done
