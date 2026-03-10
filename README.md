# nrfvm

`nrfvm` is a Bash wrapper around `nrfutil` for SDK and plugin version workflows.

## What it does

- Mirrors `espvm`-style UX with short aliases and version shorthand.
- Manages both:
  - SDK target (via `nrfutil sdk-manager` plugin)
  - nrfutil plugin target (via `nrfutil install/list/search/...`)
- Requires being sourced for `use` commands so environment changes persist.

## Preflight behavior

Before dispatching commands, `nrfvm` checks:

1. Shell is supported (`bash` or `zsh`)
2. `nrfutil` is available in `PATH`

If `nrfutil` is missing, `nrfvm` stops and asks you to install it first.

## Install

```bash
./install.sh
```

This installs `nrfvm` to `~/.local/share/nrfvm/nrfvm`, copies an executable to
`~/.local/bin/nrfvm`, and appends source lines to `~/.bashrc` and `~/.zshrc`.

Open a new shell after installation.

## Usage

```bash
nrfvm [-s|-n] <command> [args]
nrfvm <sdk-version>
```

- `-s`: SDK target (default)
- `-n`: nrfutil plugin target

### Commands

- `install` (`i`)
- `use` (`u`)
- `list` (`ls`)
- `remote` (`r`)
- `current` (`c`)
- `status` (`st`)
- `config` (`cfg`)

### Examples

```bash
# SDK
nrfvm 2.9.0
nrfvm -s install 2.9.0
nrfvm -s list

# nrfutil plugins
nrfvm -n install sdk-manager=1.11.0
nrfvm -n list
```

See `docs/COMMANDS.md` for full command behavior.
