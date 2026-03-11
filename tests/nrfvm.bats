#!/usr/bin/env bats

setup() {
  export TEST_ROOT="$BATS_TEST_TMPDIR/root"
  mkdir -p "$TEST_ROOT/bin"
  export PATH="$TEST_ROOT/bin:$PATH"
  export HOME="$TEST_ROOT/home"
  mkdir -p "$HOME"
  export NRFVM_DIR="$TEST_ROOT/nrfvm-state"
  export NRFUTIL_FAKE_LOG="$TEST_ROOT/nrfutil.log"
  export NRFUTIL_FAKE_CONFIG_FILE="$TEST_ROOT/sdk-manager-install-dir"
  export NRFUTIL_FAKE_TOOLCHAIN_BIN="$TEST_ROOT/toolchain/bin"
  unset NRFUTIL_FAKE_TOOLCHAIN_ENV_SCRIPT
  mkdir -p "$NRFUTIL_FAKE_TOOLCHAIN_BIN"
  cat > "$NRFUTIL_FAKE_TOOLCHAIN_BIN/west" <<'EOF'
#!/usr/bin/env bash
echo "west 0.0.test"
EOF
  chmod +x "$NRFUTIL_FAKE_TOOLCHAIN_BIN/west"
  : > "$NRFUTIL_FAKE_LOG"
  : > "$NRFUTIL_FAKE_CONFIG_FILE"
}

_write_fake_nrfutil() {
  cat > "$TEST_ROOT/bin/nrfutil" <<'EOF'
#!/usr/bin/env bash

if [ -n "${NRFUTIL_FAKE_LOG:-}" ]; then
  printf '%s\n' "$*" >> "$NRFUTIL_FAKE_LOG"
fi

if [ "${1:-}" = "--json" ]; then
  shift
  _json=1
else
  _json=0
fi

case "$1" in
  --version)
    echo "nrfutil 0.0.test"
    ;;
  sdk-manager)
    shift
    case "$1" in
      --help)
        exit 0
        ;;
      install)
        if [ "${2:-}" = "--help" ]; then
          exit 0
        fi
        echo "sdk install ${2:-}"
        ;;
      list)
        if [ "${2:-}" = "--help" ]; then
          exit 0
        fi

        if [ "$_json" -eq 1 ] && [ -n "${NRFUTIL_FAKE_JSON_LIST_OUTPUT:-}" ]; then
          printf '%s\n' "$NRFUTIL_FAKE_JSON_LIST_OUTPUT"
          exit 0
        fi

        if [ -n "${NRFUTIL_FAKE_LIST_OUTPUT:-}" ]; then
          printf '%s\n' "$NRFUTIL_FAKE_LIST_OUTPUT"
          exit 0
        fi

        shift
        if [ "${1:-}" = "--styling" ]; then
          shift 2
        fi
        _query="${1:-}"

        if [ -n "${NRFUTIL_FAKE_INSTALLED_VERSION:-}" ] && {
          [ -z "$_query" ] || [ "$_query" = "$NRFUTIL_FAKE_INSTALLED_VERSION" ];
        }; then
          echo "SDK Type  SDK Version  SDK Status  Toolchain Status"
          echo "nrf       ${NRFUTIL_FAKE_INSTALLED_VERSION}  Installed   Installed"
        else
          echo "No SDKs installed"
        fi
        ;;
      search)
        if [ "${2:-}" = "--help" ]; then
          exit 0
        fi
        echo "sdk search ${2:-}"
        ;;
      uninstall)
        if [ "${2:-}" = "--help" ]; then
          exit 0
        fi
        echo "sdk uninstall ${2:-}"
        ;;
      toolchain)
        shift
        case "$1" in
          env)
            if [ "${2:-}" = "--help" ]; then
              exit 0
            fi
            if [ -n "${NRFUTIL_FAKE_TOOLCHAIN_ENV_SCRIPT:-}" ]; then
              printf '%s\n' "$NRFUTIL_FAKE_TOOLCHAIN_ENV_SCRIPT"
            else
              echo "export PATH=\"${NRFUTIL_FAKE_TOOLCHAIN_BIN}:\$PATH\""
              echo "export NRFUTIL_FAKE_ENV_ACTIVATED=1"
            fi
            ;;
          list)
            if [ "${2:-}" = "--help" ]; then
              exit 0
            fi
            if [ -n "${NRFUTIL_FAKE_INSTALLED_VERSION:-}" ]; then
              echo "Toolchain ${NRFUTIL_FAKE_INSTALLED_VERSION} Installed"
            fi
            ;;
          *)
            exit 1
            ;;
        esac
        ;;
      sdk)
        shift
        case "$1" in
          register)
            if [ "${2:-}" = "--help" ]; then
              exit 0
            fi
            echo "sdk register ${2:-}"
            ;;
          *)
            exit 1
            ;;
        esac
        ;;
      config)
        shift
        case "$1" in
          show)
            _install_dir=""
            if [ -f "${NRFUTIL_FAKE_CONFIG_FILE:-}" ]; then
              _install_dir="$(cat "$NRFUTIL_FAKE_CONFIG_FILE")"
            fi
            if [ "$_json" -eq 1 ]; then
              if [ -n "$_install_dir" ]; then
                echo "{\"type\":\"info\",\"data\":{\"default\":{\"install_dir\":\"$_install_dir\",\"sdk_index\":null,\"toolchain_index\":null},\"sdk_indexes\":{},\"toolchain_indexes\":{}}}"
              else
                echo '{"type":"info","data":{"default":{"install_dir":null,"sdk_index":null,"toolchain_index":null},"sdk_indexes":{},"toolchain_indexes":{}}}'
              fi
            else
              if [ -n "$_install_dir" ]; then
                echo "default:"
                echo "  install-dir: $_install_dir"
              else
                echo "default:"
                echo "  install-dir: unset"
              fi
            fi
            ;;
          install-dir)
            shift
            case "$1" in
              set)
                if [ -z "${2:-}" ]; then
                  exit 1
                fi
                printf '%s' "$2" > "$NRFUTIL_FAKE_CONFIG_FILE"
                echo "set install-dir $2"
                ;;
              unset)
                : > "$NRFUTIL_FAKE_CONFIG_FILE"
                echo "unset install-dir"
                ;;
              *)
                exit 1
                ;;
            esac
            ;;
          *)
            exit 1
            ;;
        esac
        ;;
      help)
        exit 0
        ;;
      "")
        exit 0
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  install)
    echo "install ${2:-}"
    ;;
  list)
    if [ "${2:-}" = "--help" ]; then
      exit 0
    fi
    echo "Found 1 installed command(s)"
    ;;
  search)
    if [ "${2:-}" = "--help" ]; then
      exit 0
    fi
    echo "search ${2:-}"
    ;;
  help)
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
  chmod +x "$TEST_ROOT/bin/nrfutil"
}

_write_fake_toolchain_nrfutil_with_unset_config() {
  cat > "$NRFUTIL_FAKE_TOOLCHAIN_BIN/nrfutil" <<'EOF'
#!/usr/bin/env bash

if [ -n "${NRFUTIL_FAKE_LOG:-}" ]; then
  printf 'toolchain:%s\n' "$*" >> "$NRFUTIL_FAKE_LOG"
fi

if [ "${1:-}" = "--json" ]; then
  shift
  _json=1
else
  _json=0
fi

case "$1" in
  --version)
    echo "nrfutil 0.0.toolchain"
    ;;
  sdk-manager)
    shift
    case "$1" in
      config)
        shift
        case "$1" in
          show)
            if [ "$_json" -eq 1 ]; then
              echo '{"type":"info","data":{"default":{"install_dir":null,"sdk_index":null,"toolchain_index":null},"sdk_indexes":{},"toolchain_indexes":{}}}'
            else
              echo "default:"
              echo "  install-dir: unset"
            fi
            ;;
          *)
            exit 1
            ;;
        esac
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  *)
    exit 1
    ;;
esac
EOF
  chmod +x "$NRFUTIL_FAKE_TOOLCHAIN_BIN/nrfutil"
}

@test "preflight fails when nrfutil missing" {
  run bash -c '. ./nrfvm; nrfvm status'
  [ "$status" -ne 0 ]
  [[ "$output" == *"nrfutil not in PATH"* ]]
}

@test "status works when nrfutil exists" {
  _write_fake_nrfutil
  run bash -c '. ./nrfvm; nrfvm status'
  [ "$status" -eq 0 ]
  [[ "$output" == *"nrfvm:"* ]]
}

@test "first sdk use configures sdk-manager install-dir" {
  _write_fake_nrfutil
  export NRFUTIL_FAKE_INSTALLED_VERSION="v3.2.3"
  run bash -c '. ./nrfvm; nrfvm u v3.2.3'
  [ "$status" -eq 0 ]
  run bash -c 'grep -F "sdk-manager config install-dir set" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c '[ -s "$NRFUTIL_FAKE_CONFIG_FILE" ]'
  [ "$status" -eq 0 ]
}

@test "tilde install-dir input is expanded to absolute path" {
  _write_fake_nrfutil
  export NRFUTIL_FAKE_INSTALLED_VERSION="v3.2.3"
  run bash -c '. ./nrfvm; nrfvm u v3.2.3 <<< "~/office/ncs/source"'
  [ "$status" -eq 0 ]
  run bash -c 'expected="$HOME/office/ncs/source"; [ "$(cat "$NRFUTIL_FAKE_CONFIG_FILE")" = "$expected" ]'
  [ "$status" -eq 0 ]
  run bash -c 'expected="sdk-manager config install-dir set $HOME/office/ncs/source"; grep -F "$expected" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c '. ./nrfvm; nrfvm u v3.2.3 <<< "~/office/ncs/source" >/dev/null; [ "$ZEPHYR_BASE" = "$HOME/office/ncs/source/v3.2.3/zephyr" ]'
  [ "$status" -eq 0 ]
}

@test "version shorthand normalizes to v-prefix and activates toolchain env" {
  _write_fake_nrfutil
  export NRFUTIL_FAKE_INSTALLED_VERSION="v2.9.0"
  run bash -c '. ./nrfvm; nrfvm 2.9.0'
  [ "$status" -eq 0 ]
  [[ "$output" == *"using sdk: v2.9.0"* ]]
  run bash -c '! grep -F "sdk-manager install v2.9.0" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c 'grep -F "sdk-manager toolchain env --ncs-version v2.9.0 --as-script sh" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c '! grep -F "sdk-manager sdk register v2.9.0" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c '. ./nrfvm; nrfvm 2.9.0 >/dev/null; command -v west >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c '. ./nrfvm; nrfvm 2.9.0 >/dev/null; [ "$ZEPHYR_BASE" = "$HOME/ncs/v2.9.0/zephyr" ]'
  [ "$status" -eq 0 ]
}

@test "use skips install when sdk is already installed" {
  _write_fake_nrfutil
  export NRFUTIL_FAKE_INSTALLED_VERSION="v3.2.3"
  run bash -c '. ./nrfvm; nrfvm u v3.2.3'
  [ "$status" -eq 0 ]
  [[ "$output" == *"using sdk: v3.2.3"* ]]
  run bash -c '! grep -F "sdk-manager install v3.2.3" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c 'grep -F "sdk-manager toolchain env --ncs-version v3.2.3 --as-script sh" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c '! grep -F "sdk-manager sdk register v3.2.3" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c '. ./nrfvm; nrfvm u v3.2.3 >/dev/null; west --version >/dev/null'
  [ "$status" -eq 0 ]
}

@test "use prompts before sdk install and can cancel" {
  _write_fake_nrfutil
  printf '%s' "$HOME/ncs" > "$NRFUTIL_FAKE_CONFIG_FILE"
  export NRFUTIL_FAKE_LIST_OUTPUT=$'SDK Type  SDK Version  SDK Status      Toolchain Status\nnrf       v3.2.2      Not installed   Installed'
  run bash -c '. ./nrfvm; nrfvm u v3.2.2 <<< "n"'
  [ "$status" -ne 0 ]
  [[ "$output" == *"sdk install canceled: v3.2.2"* ]]
  run bash -c '! grep -F "sdk-manager install v3.2.2" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
}

@test "use installs sdk when sdk status is not installed" {
  _write_fake_nrfutil
  printf '%s' "$HOME/ncs" > "$NRFUTIL_FAKE_CONFIG_FILE"
  export NRFUTIL_FAKE_LIST_OUTPUT=$'SDK Type  SDK Version  SDK Status      Toolchain Status\nnrf       v3.2.2      Not installed   Installed'
  run bash -c '. ./nrfvm; nrfvm u v3.2.2 <<< "y"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"install sdk: v3.2.2"* ]]
  run bash -c 'grep -F "sdk-manager install v3.2.2" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
}

@test "sdk target command set smoke test" {
  _write_fake_nrfutil
  export NRFUTIL_FAKE_INSTALLED_VERSION="v3.2.3"
  run bash -c '. ./nrfvm; nrfvm help >/dev/null; nrfvm st >/dev/null; nrfvm cfg list >/dev/null; nrfvm ls >/dev/null; nrfvm r >/dev/null; nrfvm c >/dev/null; nrfvm i v3.2.3 >/dev/null; nrfvm u v3.2.3 >/dev/null; nrfvm d >/dev/null'
  [ "$status" -eq 0 ]
}

@test "nrfutil target command set smoke test" {
  _write_fake_nrfutil
  run bash -c '. ./nrfvm; nrfvm -n help >/dev/null; nrfvm -n ls >/dev/null; nrfvm -n r sdk-manager >/dev/null; nrfvm -n i sdk-manager=1.11.0 >/dev/null; nrfvm -n u sdk-manager=1.11.0 >/dev/null; nrfvm -n c >/dev/null; nrfvm -n d >/dev/null'
  [ "$status" -eq 0 ]
}

@test "zephyr base uses install-dir from pre-activation nrfutil" {
  _write_fake_nrfutil
  export NRFUTIL_FAKE_INSTALLED_VERSION="v3.2.3"
  _write_fake_toolchain_nrfutil_with_unset_config
  run bash -c '. ./nrfvm; nrfvm u v3.2.3 <<< "~/office/ncs/source" >/dev/null; [ "$ZEPHYR_BASE" = "$HOME/office/ncs/source/v3.2.3/zephyr" ]'
  [ "$status" -eq 0 ]
}

@test "deactive restores shell variables to pre-use values" {
  _write_fake_nrfutil
  export NRFUTIL_FAKE_INSTALLED_VERSION="v3.2.3"
  run bash -c '. ./nrfvm; original_path="$PATH"; export ZEPHYR_BASE="/tmp/previous-zephyr"; export NRFVM_SDK_VERSION="v0.0.0"; nrfvm u v3.2.3 >/dev/null; nrfvm deactive >/dev/null; [ "$PATH" = "$original_path" ] && [ "$ZEPHYR_BASE" = "/tmp/previous-zephyr" ] && [ "$NRFVM_SDK_VERSION" = "v0.0.0" ]'
  [ "$status" -eq 0 ]
}

@test "deactivate unsets nrfvm vars when they were initially unset" {
  _write_fake_nrfutil
  export NRFUTIL_FAKE_INSTALLED_VERSION="v3.2.3"
  run bash -c '. ./nrfvm; original_path="$PATH"; nrfvm u v3.2.3 >/dev/null; command -v west >/dev/null; nrfvm deactivate >/dev/null; [ "$PATH" = "$original_path" ] && [ -z "${ZEPHYR_BASE+x}" ] && [ -z "${NRFVM_SDK_VERSION+x}" ] && ! command -v west >/dev/null'
  [ "$status" -eq 0 ]
}

@test "deactivate reports no-op when nothing is active" {
  _write_fake_nrfutil
  run bash -c '. ./nrfvm; nrfvm deactivate'
  [ "$status" -eq 0 ]
  [[ "$output" == *"no active sdk env"* ]]
}

@test "deactive restores LD_LIBRARY_PATH changed by toolchain env" {
  _write_fake_nrfutil
  export NRFUTIL_FAKE_INSTALLED_VERSION="v3.2.3"
  export NRFUTIL_FAKE_TOOLCHAIN_ENV_SCRIPT=$'export PATH="'$NRFUTIL_FAKE_TOOLCHAIN_BIN':$PATH"\nexport LD_LIBRARY_PATH="/tmp/nrf-tool/lib:${LD_LIBRARY_PATH}"'
  run bash -c '. ./nrfvm; export LD_LIBRARY_PATH="/usr/lib"; nrfvm u v3.2.3 >/dev/null; [[ "$LD_LIBRARY_PATH" == /tmp/nrf-tool/lib:* ]]; nrfvm d >/dev/null; [ "$LD_LIBRARY_PATH" = "/usr/lib" ]'
  [ "$status" -eq 0 ]
}

@test "use rejects unsafe toolchain env script" {
  _write_fake_nrfutil
  export NRFUTIL_FAKE_INSTALLED_VERSION="v3.2.3"
  export NRFUTIL_FAKE_TOOLCHAIN_ENV_SCRIPT='export PATH="/tmp/evil:$PATH"; touch /tmp/pwned'
  run bash -c '. ./nrfvm; nrfvm u v3.2.3'
  [ "$status" -ne 0 ]
  [[ "$output" == *"unsafe toolchain env blocked"* ]]
}

@test "config file content is parsed not executed" {
  _write_fake_nrfutil
  run bash -c 'p="$BATS_TEST_TMPDIR/pwned"; printf "NRFVM_DEFAULT_TARGET=sdk\nmalicious=\$(touch $BATS_TEST_TMPDIR/pwned)\n" > "$NRFVM_DIR/config"; . ./nrfvm; nrfvm status >/dev/null; [ ! -f "$p" ]'
  [ "$status" -eq 0 ]
}
