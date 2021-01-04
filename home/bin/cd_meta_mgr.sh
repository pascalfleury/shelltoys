#!/bin/bash

# Configuration
MUSICROOT=/cloud/TestCollection
MUSICROOT=/cloud/FullMusicCollection

# Properties that remain constant across tracks of the same album, with their
# defaults values if no appropriate value is found.
declare -a ALBUM_CONSTANTS=("ARTIST" "ALBUM" "TRACKTOTAL" "CDDB" "DATE")
# Properties that remain constant across albums of an artist
declare -a ARTIST_CONSTANTS=("ARTIST")

declare -A DEFAULTS=(
    ["ARTIST"]="Various Artists"
    ["ALBUM"]="Album Title"
)

declare -i DEBUG=0
function vecho() {
    local -i level=$1
    shift
    (( level-1  < DEBUG )) && echo "$*"
}

# Extract all metadata
# extract_metadata <rootdir>
function sync_metadata() {
    local root="$1"
    cd "${root}"

    local file
    while IFS='' read -r file || [[ -n "${file}" ]]; do
        vecho 2 "handling file <${file}>"
        local ALBUMDIR="$(dirname "${file}")"
        local TRACKFILE="$(basename "${file}")"
        local TRACKNUMBER="${TRACKFILE%% *}"
        local METAFILE="${ALBUMDIR}/${TRACKNUMBER}.meta"
        if ! [[ -e "${METAFILE}" ]]; then
            echo "Extracting ${TRACKFILE}  ---> ${METAFILE}"
            metaflac --export-tags-to="${METAFILE}" "${file}"
            sort -o "${METAFILE}" "${METAFILE}"  # Sort in-place
        elif [[ "${METAFILE}" -ot "${file}" ]]; then
            metaflac --export-tags-to="${METAFILE}.new" "${file}"
            sort -o "${METAFILE}.new" "${METAFILE}.new"  # Sort in-place
            if ! diff -q "${METAFILE}" "${METAFILE}.new" >/dev/null; then
                echo "Updating ${METAFILE}"
                diff "${METAFILE}" "${METAFILE}.new"
                mv "${METAFILE}.new" "${METAFILE}"
            else
                rm "${METAFILE}.new"
            fi
        else
            metaflac --export-tags-to="${METAFILE}.old" "${file}"
            sort -o "${METAFILE}.old" "${METAFILE}.old"  # Sort in-place
            if ! diff -q "${METAFILE}.old" "${METAFILE}" >/dev/null; then
                echo "Embedding ${METAFILE} ---> ${TRACKFILE}"
                diff "${METAFILE}.old" "${METAFILE}"
                metaflac --remove-all-tags --import-tags-from="${METAFILE}" "${file}"
            fi
            rm "${METAFILE}.old"
        fi
    done < <(find . -name \*.flac)
}

# propagate_properties <metafile> <properties-map> <depfiles> <message>
function propagate_properties() {
    local metafile="$1"
    local -a constants=( "${!2}" )
    local -a _depfiles=( "${!3}" )
    local message="$4"

    local most_recent=$(ls -t "${_depfiles[@]}" | head -n 1)

    if ! [[ -e "${metafile}" ]] || [[ "${metafile}" -ot "${most_recent}" ]]; then
        vecho 1 "Updating ${message}"
        local property
        for property in "${constants[@]}"; do
            vecho 2 "checking property ${property} in ${_depfiles[*]}"
            local -i num_items=${#_depfiles[@]}
            local -i num_variants=$(grep -h "${property}=" "${_depfiles[@]}" \
                                        | sort | uniq | wc -l)
            local -i most_frequent=$(grep -h "${property}=" "${_depfiles[@]}" \
                                         | sort | uniq -c | sort -k 1 -n -r \
                                         | head -n 1 | awk '{print $1}')
            vecho 3 "${num_items} items have ${num_variants} variants for property ${property}, most frequent is ${most_frequent} times."

            # Simple majority vote for the field value
            if (( num_variants == 1 )) || (( most_frequent > num_items / 2)); then
                grep -h "${property}=" "${_depfiles[@]}" \
                    | sort | uniq -c | sort -k 1 -n -r \
                    | head -n 1 | sed 's/^ *[0-9]* *//' >> "${metafile}.new"
            elif [[ -n "${DEFAULTS[$property]}" ]]; then
                # use the provided default value when provided
                echo "${property}=${DEFAULTS[$property]}" >> "${metafile}.new"
            fi
        done
        vecho 3 "${metafile}"
        sort -o "${metafile}.new" "${metafile}.new"
        if ! [[ -e "${metafile}" ]]; then
            echo "Created ${message}"
            mv "${metafile}.new" "${metafile}"
        elif ! diff -q "${metafile}" "${metafile}.new" >/dev/null; then
            echo "Updated ${message}"
            diff "${metafile}" "${metafile}.new"
            mv "${metafile}.new" "${metafile}"
        else
            rm "${metafile}.new"
        fi
    else
        vecho 1 "Propagate ${message}"
        # Replicate the album metadata into the track metadata.
        local file
        for file in "${_depfiles[@]}"; do
            vecho 3 "fiddling with file <${file}>"
            cp "${file}" "${file}.new"
            local property
            for property in "${constants[@]}"; do
                local value=$(grep "${property}=" "${metafile}")
                # If the metafile's value is the default, skip the update
                [[ "${value#*=}" != "${DEFAULTS[$property]}" ]] || continue
                grep -v "${property}=" "${file}.new" > "${file}.tmp"
                grep    "${property}=" "${metafile}"  >> "${file}.tmp"
                mv "${file}.tmp" "${file}.new"
            done
            sort -o "${file}.new" "${file}.new"
            if ! diff -q "${file}" "${file}.new" >/dev/null; then
                echo "Updated track metadata in ${file}"
                diff "${file}" "${file}.new"
                mv "${file}.new" "${file}"
            else
                rm "${file}.new"
            fi
        done
    fi
}

function sync_album_metadata() {
    local root="$1"
    cd "${root}"

    local query="($(IFS='|' ; echo "${!ALBUM_CONSTANTS[*]}"))="
    local albumdir
    while IFS='' read -r albumdir || [[ -n "${albumdir}" ]]; do
        vecho 1 "Checking album ${albumdir}"
        local ALBUM_META="${albumdir}/album.meta"
        local IFS=$'\t\n'
        local -a album_files=( $(find "${albumdir}" -name \*.meta) )
        unset IFS
        vecho 3 "Found files: ${album_files[*]}"

        propagate_properties "${ALBUM_META}" ALBUM_CONSTANTS[@] album_files[@] \
                             "album metadata for album ${albumdir}"

    done < <(find . -name \*.meta -print0 \
                 | grep -z '[0-9][0-9]*\.meta$' \
                 | xargs --null -L 1 dirname | sort | uniq)
}

function sync_artist_metadata() {
    local root="$1"
    cd "${root}"

    local query="($(IFS='|' ; echo "${!ARTIST_CONSTANTS[*]}"))="
    local artistdir
    while IFS='' read -r artistdir || [[ -n "${artistdir}" ]]; do
        vecho 1 "Checking artist $artistdir"
        local ARTIST_META="${artistdir}/artist.meta"
        local IFS=$'\t\n'
        local -a album_files=( $(find "${artistdir}" -name album.meta) ) #
        unset IFS

        propagate_properties "${ARTIST_META}" ARTIST_CONSTANTS[@] album_files[@] \
                             "artist metadata for ${artistdir}"

    done < <(find . -mindepth 1 -maxdepth 1 -type d | grep -v abcde.)
}

# Sync bottom-up the top-down
sync_metadata "${MUSICROOT}"
sync_album_metadata "${MUSICROOT}"
sync_artist_metadata "${MUSICROOT}"
sync_album_metadata "${MUSICROOT}"
sync_metadata "${MUSICROOT}"
