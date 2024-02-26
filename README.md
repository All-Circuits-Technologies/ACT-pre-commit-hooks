<!--
SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# Act pre-commit hooks

## Presentation

This repo contains a few pre-commit hooks seen as useful for All Circuits
design center.

## Usage

Those hooks are provided as is, with no guarantees.
They are free to use/fork/copy (free as in speech and free as in beer) either
personally or commercially.

Example of use, which will help you to keep SQLite files read-only.

```yaml
repos:
- repo: https://github.com/All-Circuits-Technologies/act-pre-commit-hooks
  rev: # any tag or sha
  hooks:
  - id: set-readonly
    files: '.+\.sqlite'
```

## Hooks available

### `set-readonly`

This hook removes write permissions to explicitly chosen files.
You must set `files` hook attribute to list files you want to be read-only.

This hook never fails. It succeed even when files were not yet read-only.

No specific dependencies.

### `msg-add-redmine-refs`

This hook only act upon prepare-commit-msg stage.
It pre-fills commit message with one or several "Refs:" trailers pointing to
redmine tickets. IDs of inserted redmine tickets are taken from numbers found
in current branch name.

### `msg-remove-empty-trailers`

This hook act upon commit-msg stage.
It removes empty trailers if any, which may arise when a commit-msg template
is used which suggests optional trailers to fill.

For example, a final line such as "Refs: " pointing to nothing would be removed.
