#!/bin/bash

GIT_AUTO_SYNC="$(which git-auto-sync)"
if [[ -z "${GIT_AUTO_SYNC}" ]]; then
    echo "No git-auto-sync binary found !" >&2
    exit 1
fi

for repos in $(${GIT_AUTO_SYNC} daemon list); do
    echo "Syncing repository ${repos} ..." >&2
    (
        cd "${repos}"
        ${GIT_AUTO_SYNC} sync
    )
done
