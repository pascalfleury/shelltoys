#!/bin/bash
#
# Impose the given file. This provides the default arguments for
# pdfjam.

function die() {
  echo "[ ERROR ] $*"
  exit 1
}

PDFJAM="$(which pdfjam)"
[[ -n "${PDFJAM}" ]] || die "Could not find pdfjam! (part of texlive-extra-utils)"

# Compose the document and make image-based PDF
"${PDFJAM}" \
  --landscape \
  --vanilla \
  --keepinfo \
  --noautoscale true \
  --frame false \
  --clip false \
  --no-tidy \
  "$@"
