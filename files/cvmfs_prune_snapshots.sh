#!/usr/bin/env bash
#
# Prune named snapshots on CVMFS release managers by age and count
#
set -euo pipefail

COUNT=50
VERBOSE=false
DRYRUN=false
MUTEX="${HOME}/.updaterepo.lock"
MUTEX_ACQUIRED=false

function help() {
    cat <<EOF
usage: $0 [options] REPOSITORY
options:
  -h        this help message
  -v        verbose ouptut
  -c COUNT  number of snapshots to keep (default: ${COUNT})
  -n        no changes (dry run, only show what would be done)
EOF
}

function trap_handler() {
    $MUTEX_ACQUIRED && { rmdir "$MUTEX"; }
    return 0
}
trap "trap_handler" SIGTERM SIGINT ERR EXIT

while getopts ":c:hnv" opt; do
    case "$opt" in
        c)
            COUNT="$OPTARG"
            ;;
        h)
            help
            exit 0
            ;;
        n)
            DRYRUN=true
            ;;
        v)
            VERBOSE=true
            ;;
        *)
            echo "ERROR: Unknown option: ${opt}. See '-h' for help."
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${1:-}" ]; then
    echo "ERROR: repository argument is required. See '-h' for help."
    exit 1
fi

REPO="$1"

echo "Keeping newest ${COUNT} named snapshots in repository: ${REPO}"

if ! $DRYRUN; then
    mkdir "$MUTEX"
    MUTEX_ACQUIRED=true
fi

tag_args=($(cvmfs_server tag -lx "$REPO" | sort -nk 5 | head -n -"$COUNT" | awk '{print $1}' | sed 's/^/-r /'))

if [ "${#tag_args[@]}" -eq 0 ]; then
    echo "no tags to remove"
    exit 0
fi

if $DRYRUN; then
    echo cvmfs_server tag -f "${tag_args[@]}" "$REPO"
else
    cvmfs_server tag -f "${tag_args[@]}" "$REPO"
fi
