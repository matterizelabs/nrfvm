_nrfvm_complete() {
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local commands="install use list remote current status config help i u ls r c st cfg"
  local targets="-s -n sdk nrfutil"
  local config_actions="list show set unset"
  local config_keys="default_target remote_cache_ttl auto_install_plugins"

  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$targets $commands" -- "$cur") )
    return
  fi

  if [ "$prev" = "config" ] || [ "$prev" = "cfg" ]; then
    COMPREPLY=( $(compgen -W "$config_actions" -- "$cur") )
    return
  fi

  if [ "$prev" = "set" ] || [ "$prev" = "unset" ]; then
    COMPREPLY=( $(compgen -W "$config_keys" -- "$cur") )
    return
  fi

  COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
}

complete -F _nrfvm_complete nrfvm
