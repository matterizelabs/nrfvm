# Commands

## Targets

- `-s` or `sdk`: SDK domain via `nrfutil sdk-manager`
- `-n` or `nrfutil`: nrfutil command/plugin domain

Default target is SDK.

## Command list

- `install`, `i`
- `use`, `u`
- `deactive`/`deactivate`, `d`
- `list`, `ls`
- `remote`, `r`
- `current`, `c`
- `status`, `st`
- `config`, `cfg`

## Version shorthand

- `nrfvm 2.9.0` => `nrfvm -s use v2.9.0`
- `nrfvm sdk@2.9.0` => `nrfvm -s use v2.9.0`
- `nrfvm nrfutil@sdk-manager=1.11.0` => `nrfvm -n use sdk-manager=1.11.0`

SDK versions are normalized to a leading `v` when omitted.

## SDK `use` behavior

`nrfutil sdk-manager` does not provide a top-level `use` command. For SDK target,
`nrfvm use <version>` does this flow:

1. Normalize version to `v*`
2. Ensure `sdk-manager install-dir` is configured (prompts first time, then sets via `nrfutil sdk-manager config install-dir set`)
3. Install the SDK if it is missing
4. Evaluate `nrfutil sdk-manager toolchain env --ncs-version <version> --as-script sh`
5. Set `ZEPHYR_BASE` for the selected SDK
6. Persist selected version in `nrfvm` state

## SDK `deactive` behavior

`nrfvm deactive` (or `nrfvm deactivate`) restores the shell environment snapshot
taken before the most recent `nrfvm use` call:

1. Restore `PATH`
2. Restore `ZEPHYR_BASE`
3. Restore `NRFVM_SDK_VERSION`
4. Restore previous `current-sdk` state

## Plugin bootstrap

If `sdk-manager` is missing and an SDK command is requested, `nrfvm` prompts:

`Required nrfutil plugin 'sdk-manager' is missing. Install now? [y/N]`

If accepted, it runs:

`nrfutil install sdk-manager`

## Config keys

- `default_target`
- `remote_cache_ttl`
- `auto_install_plugins`

Example:

```bash
nrfvm config set default_target nrfutil
nrfvm config list
```
