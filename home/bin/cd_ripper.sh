#!/bin/bash
SR=$(ls /dev/sr* | head -n 1 | sed -e 's,/dev/,,')
CD=/dev/$(echo ${1:-$SR} | sed -e "s/.*\(sr[0-9]\).*/\\1/")
TMPFILE=/tmp/abcde_$$.sh
export EDITOR=emacs

cat > "${TMPFILE}" <<EOF
#!/bin/bash
cd "${PWD}"
abcde -d //$CD
#2>&1 | tee /home/fleury/abcde.log
EOF
chmod 700 "${TMPFILE}"

konsole -e "${TMPFILE}"
rm -f "${TMPFILE}"
