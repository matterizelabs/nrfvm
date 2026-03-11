# Troubleshooting

## nrfutil not found

Symptom:

`nrfvm: nrfutil is not in PATH.`

Fix:

1. Install `nrfutil` from Nordic documentation.
2. Confirm with `nrfutil --version`.
3. Restart shell and run `nrfvm status`.

## use command does not persist

Symptom:

`nrfvm: this command must run in a sourced shell...`

Fix:

1. Add source line to your shell rc file.
2. Open new shell.
3. Run `nrfvm use <version>` again.

## return to pre-use shell

Symptom:

You want to undo environment changes from `nrfvm use`.

Fix:

Run:

`nrfvm deactive`

Alias also supported:

`nrfvm deactivate`

## sdk-manager plugin missing

Symptom:

`Required nrfutil plugin 'sdk-manager' is missing.`

Fix:

Accept the prompt, or run manually:

`nrfutil install sdk-manager`

## sdk-manager subcommand mismatch

If your installed `sdk-manager` version uses different verbs than expected, run:

`nrfutil sdk-manager --help`

Then adjust your command invocation accordingly.

## SDK version format errors

Symptom:

`Version number must start with a 'v'`

`nrfvm` normalizes plain versions to a `v` prefix automatically. If you call
`nrfutil sdk-manager` directly, use `v` prefixed versions (for example
`v3.2.3`).

## west command not found after use

`nrfvm use <version>` now auto-activates toolchain shell env in the current
session. If `west` is still missing, verify the toolchain environment command:

`nrfutil sdk-manager toolchain env --ncs-version v3.2.3 --as-script sh`

If it fails, inspect available toolchains:

`nrfutil sdk-manager toolchain list`

## Where SDKs/toolchains are installed

Check configured location:

`nrfutil sdk-manager config show`

If `install-dir` is `unset`, sdk-manager uses its platform default. On first
SDK operation, `nrfvm` prompts for a location and sets it using:

`nrfutil sdk-manager config install-dir set <path>`
