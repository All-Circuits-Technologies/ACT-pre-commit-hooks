#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
#
# SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

## Peek redmine ticket id(s) from current git branch name
## and appends a "Refs: #xxxx" trailer to commit message.
##
## This trailer is compatible with Redmine commit message parsing.
## This allows Redmine to references commits from a ticket.
##
## USAGE: $0 [arguments] commit-msg-file
##
## Optional arguments:
##   -h      Show help and exit
##   -c 5    No more than this amount of redmine IDs will be
##           extracted from current git branch
##   -m 3    Ignore IDs whose length is less than this value
##   -M 10   Ignore IDs whose length is more than this value
##   -1      Concatenate several refs in a single line with ", #"
##   -d ""   What ref value should be used when no IDs are found in branch name.
##           Examples: "#MISSING", "#none", "#0000" or "#".
##           When empty, no trailers are added if no IDs are found but script
##           succeed if -f is not provided.
##           Defaults to empty.
##   -f      Fail if no IDs are found in current branch name,
##           even if a non-empty -d is given
##   -k      Try to continue despite minor unexpected but fixable situations
##           - create commit-msg-file if it does not exists, which should never
##             occur given git documentation but which nevertheless occurs with
##             git gui broken prepare-commit-msg hook calls.
##
## Optional vars:
## Those environment variables can be used to override default arguments value.
## When both environment variable and related argument are set, argumment wins.
##   -c      MARR_MAX_ID_COUNT
##   -m      MARR_MIN_ID_LENGTH
##   -M      MARR_MAX_ID_LENGTH
##   -1      MAAR_ONE_LINER
##   -d      MAAR_DEFAULT_REF_VALUE
##   -f      MAAR_FAIL_IF_NO_IDS
##   -k      MAAR_KEEP_GOING

# Globally enable a few optional/extra shellcheck checks
# shellcheck enable=check-unassigned-uppercase  # SC2154
# shellcheck enable=check-extra-masked-returns  # SC2155 SC2312
# shellcheck enable=quote-safe-variables        # SC2248
# shellcheck enable=require-variable-braces     # SC2250

set -e
set -u
set -o pipefail

# CONSTS
readonly REDMINE_TRAILER_KEY="Refs"

# OPTS
MAX_ID_COUNT="${MARR_MAX_ID_COUNT:-5}"
MIN_ID_LENGTH="${MARR_MIN_ID_LENGTH:-3}"
MAX_ID_LENGTH="${MARR_MAX_ID_LENGTH:-10}"
ONE_LINER="${MAAR_ONE_LINER:-}"
DEFAULT_REF_VALUE="${MAAR_DEFAULT_REF_VALUE:-}"
FAIL_IF_NO_IDS="${MAAR_FAIL_IF_NO_IDS:-}"
KEEP_GOING="${MAAR_KEEP_GOING:-}"

# ARGS
COMMIT_MSG_FILE=""

# Print arguments to stderr and die
# $*: Error text to be printed
die() {
    printf "[DIE] ${0##*[/\\]}: %s\n" "$*" >&2
    exit 1
}

# Print arguments to stderr
# $*: Warning text to be printed
warn() {
    printf "[WARN] ${0##*[/\\]}: %s\n" "$*" >&2
}

# Print script help
# $1: optional verbosity (minimal leading hashes count), defaults to 2
print_help() {
    grep "^##\( \|\$\)" "$0" | sed 's/^#* \?//' | sed "s,\$0,$0,"
}

# Parse arguments and fills global variables (OPTS and ARGS) out of them
parse_args() {
    while getopts "hc:m:M:1d:fk" OPTKEY; do
        case "${OPTKEY}" in
            h)
                print_help
                exit 0
                ;;
            c)
                #[[ "${OPTARG}" ~= "[0-9]+" ]] || die "Invalid -c value"
                MAX_ID_COUNT="${OPTARG}"
                ;;
            m)
                #[[ "${OPTARG}" ~= "[0-9]+" ]] || die "Invalid -m value"
                MIN_ID_LENGTH="${OPTARG}"
                ;;
            M)
                #[[ "${OPTARG}" ~= "[0-9]+" ]] || die "Invalid -M value"
                MAX_ID_LENGTH="${OPTARG}"
                ;;
            1)
                ONE_LINER="1"
                ;;
            d)
                DEFAULT_REF_VALUE="${OPTARG}"
                ;;
            f)
                FAIL_IF_NO_IDS="1"
                ;;
            k)
                KEEP_GOING="1"
                ;;
            *)
                die "Unexpected argument, see -h"
                ;;
        esac
    done

    if [[ ${MIN_ID_LENGTH} -gt ${MAX_ID_LENGTH} ]]; then
        die "Min ID length requirement must be equal or greater than max length"
    fi

    shift $((OPTIND - 1))
    if [[ $# -eq 0 ]]; then
        die "Missing commit-msg-file argument"
    elif [[ $# -gt 1 ]]; then
        die "Too many commit-msg-file arguments, only one supported"
    fi

    COMMIT_MSG_FILE="${1}"

    if [[ ! -f ${COMMIT_MSG_FILE} ]] && [[ -n ${KEEP_GOING} ]]; then
        warn "Missing required '${COMMIT_MSG_FILE}' commit-msg-file argument"
        warn "Creating '${COMMIT_MSG_FILE}' empty file as a workaround"
        touch "${COMMIT_MSG_FILE}"
    fi

    if [[ ! -w $1 ]]; then
        die "commit-msg-file argument ($1) is not a writable file"
    fi
}

# Parse current git branch name and print its numbers, space-separated.
peek_redmine_ids() {
    git symbolic-ref --short HEAD |
        (grep -wo "[0-9]\{${MIN_ID_LENGTH},${MAX_ID_LENGTH}\}" || true) |
        head -n "${MAX_ID_COUNT}" |
        tr '\n' ' ' |
        sed 's/ $//'
}

main() {
    parse_args "$@"

    local ids
    ids="$(peek_redmine_ids)"

    # Special no IDs found cases
    if [[ -z ${ids} ]] && [[ -n ${FAIL_IF_NO_IDS} ]]; then
        die "No IDs found in current branch name"
    fi

    if [[ -z ${ids} ]] && [[ -z ${DEFAULT_REF_VALUE} ]]; then
        # No fallback trailer values, nothing to do, success
        exit 0
    fi

    # Compute wanted redmine ref trailer value(s)
    REF_VALUES=()
    if [[ -z ${ids} ]]; then
        REF_VALUES+=("${DEFAULT_REF_VALUE}")
    elif [[ -n ${ONE_LINER} ]]; then
        REF_VALUES+=("#${ids// /, #}")
    else
        for id in ${ids}; do
            REF_VALUES+=("#${id}")
        done
    fi

    # Add trailers to commit-msg-file
    for REF_VALUE in "${REF_VALUES[@]}"; do
        git interpret-trailers \
            --in-place \
            --trailer "${REDMINE_TRAILER_KEY}: ${REF_VALUE}" \
            --if-exists addIfDifferent \
            "${COMMIT_MSG_FILE}"
    done
}

main "$@"
