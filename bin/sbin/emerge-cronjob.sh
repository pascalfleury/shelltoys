#!/bin/bash
. $(dirname $0)/emerge.shlib

# Script run as updates the a Gentoo system. Runs in a cron job,
# syncs the tree, cleans up the distdir and tries to build
# as many packages as possible.
# SysAdm then can use emerge -uDa --newuse --usepkg world
# to install packages swiftly.
# it also runs a revdep-rebuild, to catch any left-overs from
# previous installs.

usage="Usage: $(basename $0) [-f]"
while getopts ":f" options ; do
    case $options in
	f ) FAST_MODE=1;;
	\?) info $usage; exit 1;;
	* ) info $usage; exit 1;;
    esac
done

echo "----- Started on $(date) [FastMode=$FAST_MODE]"
[ singleton_script ] || error "Process with pid $? already running. Aborting."

emerge_import PKGDIR PORTDIR DISTDIR
CACHEFILE=$PKGDIR/update-ready.db
ADDS=$PKGDIR/update-new.db
INFOFILE=$HOME/new_packages.txt

# Find out if $PORTDIR is on NFS, in which case we assume the
# NFS server has updated the sync tree.
if [ ! $FAST_MODE ] ; then
    PART=$(df $PORTDIR | tail -n 1 | awk '{print $1}')
    MOUNTTYPE=$(mount | grep $PART | awk '{print $5}') 
    if [ "$MOUNTTYPE" == "nfs" ] ; then
	emerge --metadata
    else
	emerge --sync
    fi
fi

$HOME/bin/sbin/kde-unstable 3.5 > /etc/portage/package.keywords/kde
$HOME/bin/sbin/koffice-unstable 1.6 > /etc/portage/package.keywords/koffice

[ $FAST_MODE ] || layman -S

info "Getting new packages..."
emerge_packlist PACK_LIST "-uDp --newuse"
info "Packages that would be merged with:"
info "> emerge -uDa --newuse --usepkg world"
info $(echo "${PACK_LIST[*]}" | tr ' ' '\n')

# Cleanup the distfiles dir, delete files not accessed in the last week
( cd $DISTDIR && find . ! -atime 6 -delete )

# Make sure at least we have up-to-date packages
[ $FAST_MODE ] || revdep-rebuild

# Build additional user-registered packs
cache_list NEWPACKS $ADDS


# Pre-build packages
COUNT=0
for pack in ${PACK_LIST[*]} ${NEWPACKS[*]}; do
    ((COUNT = COUNT + 1))
    echo "-------------- Building $pack package ($COUNT of ${#PACK_LIST[*]}) ....."
    if [ -f $PKGDIR/All/$(echo $pack | sed 's,.*/,,g').tbz2 ]; then
	echo "Package for $pack exists already."
	cache_add $CACHEFILE $pack
    else
	emerge -uD --newuse --nospinner --buildpkgonly $pack
	if [ $? != 0 ]; then
	    warn "##### Build package $pack failed. Will be picked up in next iteration."
	else
	    cache_add $CACHEFILE $pack
	fi
    fi
done


# check what has been pre-built
emerge_packlist BUILT_LIST "-uDp --newuse --usepkgonly"
cat > $INFOFILE <<-EOF
    Packages that would merge with
    emerge -uDa --newuse --usepkgonly world
    ${BUILT_LIST[*]}
EOF

info "----- Ended on $(date) ($SECONDS seconds)"

