# nrfvm

`nrfvm` is a source-able Bash wrapper around `nrfutil` for nRF SDK and nrfutil
plugin version workflows.

This project is intentionally modeled after `espvm` ergonomics:

- short aliases (`i`, `u`, `ls`, `r`, `st`, ...)
- version-first invocation (`nrfvm 2.9.0`)
- shell-aware activation behavior

## Why this project exists

`nrfutil` is the backend of truth, but direct plugin CLI usage is not always
ergonomic for day-to-day switching and team onboarding. `nrfvm` adds a stable,
opinionated frontend that:

- enforces a preflight check before command dispatch
- keeps a single, consistent command surface for users
- handles missing plugin bootstrap interactively
- keeps shell activation semantics explicit and safe

## Project status

The repository is in early bootstrap phase (`0.1.x`) and focuses on core parity:

- `install`, `use`, `list`, `remote`, `current`, `status`, `config`
- SDK domain and nrfutil plugin domain
- Linux and macOS with bash/zsh

## Runtime model

`nrfvm` is designed to be sourced so `use` commands can persist environment
changes in the current shell session.

At command entry, preflight checks always run:

1. Current shell is supported (`bash` or `zsh`)
2. `nrfutil` exists in `PATH`

If `nrfutil` is missing, `nrfvm` fails fast with install guidance.

## SDK and toolchain install location

`nrfutil sdk-manager` stores SDK and toolchain bundles under its install
directory.

- Linux default (from sdk-manager docs): `~/ncs`
- macOS default (from sdk-manager docs): `/opt/nordic/ncs`

On first SDK operation, `nrfvm` checks `nrfutil sdk-manager config show`.
If `install-dir` is unset and the platform allows overrides, `nrfvm` prompts
for a location and persists it with:

```bash
nrfutil sdk-manager config install-dir set <path>
```

## Repository layout

- `nrfvm`: main shell implementation and command dispatcher
- `install.sh`: installer for local and online (raw GitHub) distribution
- `completions/nrfvm.bash`: bash completion
- `completions/_nrfvm`: zsh completion
- `docs/COMMANDS.md`: command and alias contract
- `docs/TROUBLESHOOTING.md`: common failures and fixes
- `tests/nrfvm.bats`: initial Bats test coverage

## Install

Online installer:

```bash
curl -fsSL https://raw.githubusercontent.com/matterizelabs/nrfvm/main/install.sh | bash
```

Local installer (from repo checkout):

```bash
./install.sh
```

Installer behavior:

- installs runtime script to `~/.local/share/nrfvm/nrfvm`
- copies executable shim to `~/.local/bin/nrfvm`
- installs completion assets under `~/.local/share/nrfvm/completions`
- appends source/completion lines to `~/.bashrc` and `~/.zshrc` idempotently

Open a new shell after installation.

## Usage

```bash
nrfvm [-s|-n] <command> [args]
nrfvm <sdk-version>
```

Targets:

- `-s` or `sdk`: SDK domain (default)
- `-n` or `nrfutil`: nrfutil plugin domain

Core commands:

- `install` (`i`)
- `use` (`u`)
- `list` (`ls`)
- `remote` (`r`)
- `current` (`c`)
- `status` (`st`)
- `config` (`cfg`)

Examples:

```bash
# SDK
nrfvm 2.9.0
nrfvm -s install 2.9.0
nrfvm -s list

# nrfutil plugins
nrfvm -n install sdk-manager=1.11.0
nrfvm -n list
```

Note: SDK versions are normalized to a leading `v` (`2.9.0` becomes `v2.9.0`).

## Backend behavior for developers

SDK commands route through `nrfutil sdk-manager` and use compatibility probing.
If the plugin is missing, `nrfvm` prompts and can install it via:

```bash
nrfutil install sdk-manager
```

The adapter isolates top-level UX from backend command drift between plugin
versions.

For SDK activation semantics: `nrfutil sdk-manager` has no stable top-level
`use` subcommand. `nrfvm use <version>` performs install-if-missing, evaluates
the toolchain shell environment (`nrfutil sdk-manager toolchain env ...
--as-script sh`) in the current shell, and stores the selected SDK version in
`nrfvm` state for follow-up commands.

## Local development

Prerequisites:

- `bash`
- `nrfutil`
- optional for quality gates: `shellcheck`, `shfmt`, `bats`

Quick loop:

```bash
# run directly in current shell
source ./nrfvm
nrfvm status

# lint/syntax
bash -n nrfvm
bash -n install.sh
shellcheck nrfvm install.sh

# tests
bats tests/nrfvm.bats
```

## State and config

By default, state is stored in `~/.nrfvm` (override with `NRFVM_DIR`).

- config: `~/.nrfvm/config`
- state: `~/.nrfvm/state/*`

Config keys currently supported:

- `default_target`
- `remote_cache_ttl`
- `auto_install_plugins`

## Contributing notes

- Keep shell code portable for bash and zsh execution paths.
- Maintain fast-fail preflight behavior.
- Preserve source-able semantics for env-mutating commands.
- Prefer stable top-level UX over backend-specific command naming.

See `docs/COMMANDS.md` and `docs/TROUBLESHOOTING.md` before changing CLI behavior.
