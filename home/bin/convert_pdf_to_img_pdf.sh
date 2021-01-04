#!/bin/bash
set -o errexit

PDFFILE=${1}
IMG_PDFFILE=${2}
RESOLUTION=${RESOLUTION:-600}  # in DPI

function info() {
  echo "[ INFO ] $*"
}

function warning() {
  echo "[ WARNING ] $*"
}

function die() {
  echo "[ ERROR ] $*"
  exit 1
}

[[ -n "${PDFFILE}" ]] || die "Usage: $0 <pdffile>"

# Check the needed tools
GHOSTSCRIPT=$(which gs)
CONVERT=$(which convert)
[[ -n "${CONVERT}" ]] || die "Could not find 'convert' !"
[[ -n "${GHOSTSCRIPT}" ]] || die "Could not find 'gs' !"

# Prepare the space
readonly TMPDIR=${PDFFILE%.*}_imgs
mkdir -p ${TMPDIR}

# Make the PDFFILE absolute path
BASE_PDFFILE="$(basename "${PDFFILE}")"
PDFFILE="$(cd $(dirname "${PDFFILE}") && echo $PWD)/${BASE_PDFFILE}"
if [[ -z "${IMG_PDFFILE}" ]]; then
    IMG_PDFFILE="$(dirname "${PDFFILE}")/${BASE_PDFFILE%.*}_img.pdf"
fi

pushd ${TMPDIR} >/dev/null 2>&1

# Split it into pages
info "Splitting into separate ${RESOLUTION}x${RESOLUTION} dpi pages..."
${GHOSTSCRIPT} -dSAFER -dBATCH -dNOPAUSE \
    -r${RESOLUTION}x${RESOLUTION} \
    -sDEVICE=png16m \
    -dGraphicsAlphaBits=4 \
    -sOutputFile=pg_%04d.png "${PDFFILE}" \
    >/dev/null 2>&1

declare -i num_pages=$(ls pg_*.png | wc -l)
info "Found ${num_pages} pages."

info "Reassembling images into PDF..."
${CONVERT} pg_*.png \
    -density ${RESOLUTION}x${RESOLUTION} -units PixelsPerInch \
    "${IMG_PDFFILE}"

# Cleanup
info "Cleaning up..."
popd
info "Done. Result: ${IMG_PDFFILE}"
