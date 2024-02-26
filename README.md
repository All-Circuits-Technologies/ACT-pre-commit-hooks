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
  rev: master # or any tag/sha
  hooks:
  - id: set-readonly
    files: '.+\.sqlite'
```

## Hooks available

### `set-readonly`

This hook removes write permissions to explicitly given files.
You must set `files` hook attribute to list files you want to be read-only.

This hook never fails. It succeed even when files were not yet read-only.

No specific dependencies.