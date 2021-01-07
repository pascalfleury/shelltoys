#!/bin/bash
#
# This script is meant to work with an alias, like this:
#  alias dup='eval `clonepwd.sh`'

source gbash.sh
source module google3/experimental/users/fleury/shelltoys/console.shl

PWDFILE=$HOME/.pwd_location.txt
MAXDIFF=3600 # one hour

function store() {
    LOCATION=$(pwd)
    WHEN=$(date +%s)
    cat >$PWDFILE <<EOF
# Cloned location with $(basename $0)
LOCATION=$LOCATION
WHEN=$WHEN
EOF
}

function restore() {
    source $PWDFILE
    rm -f $PWDFILE
}

if [ -f $PWDFILE ]; then
    restore
    NOW=$(date +%s)
    ((DIFF = NOW - WHEN))
    if [ $DIFF -gt $MAXDIFF ]; then
	warn "Location $LOCATION is $DIFF seconds old."
	yes_no "Use it anyway ?" || bailout "Removed stale file."
    fi
    warn "Cd'ing to $LOCATION"
    echo "cd $LOCATION"
else
    store
    warn "Cloned $LOCATION"
fi
