#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
#
# SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

## Remove write permission of given file(s).
## Given files are either:
## - absolute full path to one file
## - a glob pattern suitable for git ls-files
##
## Examples of use:
##  $0 "*.sqlite"
##     SQLite files in top folder will be made read-only
##  $0 "**.sqlite"
##     SQLite files in all repo will be made read-only
##  $0 "**.sqlite" "**.png" "**.PNG"
##     SQLite and PNG files in all repo will be made read-only

set -e
set -u
set -o pipefail

if [[ $# -eq "0" ]]; then
    echo "${0##*[/\\]}: Required argument missing" >&2
    echo "At least one git ls-files pattern expected, see -h" >&2
    echo "Hint: you may have forgotten to override pre-commit args array" >&2
    exit 1
elif [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
    grep '^##' "$0" | sed 's/^## \?//' | sed "s,\$0,$0,"
    exit 0
fi

set -f
IFS=$'\r\n'

for file_pattern in "$@"; do
    for file in $(git ls-files ":/${file_pattern}"); do
        chmod --changes --preserve-root a-w -- "${file}"
    done
done
