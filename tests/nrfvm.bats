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
            echo "export PATH=\"${NRFUTIL_FAKE_TOOLCHAIN_BIN}:\$PATH\""
            echo "export NRFUTIL_FAKE_ENV_ACTIVATED=1"
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

@test "preflight fails when nrfutil missing" {
  run bash -c '. ./nrfvm; nrfvm status'
  [ "$status" -ne 0 ]
  [[ "$output" == *"nrfutil is not in PATH"* ]]
}

@test "status works when nrfutil exists" {
  _write_fake_nrfutil
  run bash -c '. ./nrfvm; nrfvm status'
  [ "$status" -eq 0 ]
  [[ "$output" == *"nrfvm version"* ]]
}

@test "first sdk use configures sdk-manager install-dir" {
  _write_fake_nrfutil
  run bash -c '. ./nrfvm; nrfvm u v3.2.3'
  [ "$status" -eq 0 ]
  run bash -c 'grep -F "sdk-manager config install-dir set" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c '[ -s "$NRFUTIL_FAKE_CONFIG_FILE" ]'
  [ "$status" -eq 0 ]
}

@test "tilde install-dir input is expanded to absolute path" {
  _write_fake_nrfutil
  run bash -c '. ./nrfvm; nrfvm u v3.2.3 <<< "~/office/ncs/source"'
  [ "$status" -eq 0 ]
  run bash -c 'expected="$HOME/office/ncs/source"; [ "$(cat "$NRFUTIL_FAKE_CONFIG_FILE")" = "$expected" ]'
  [ "$status" -eq 0 ]
  run bash -c 'expected="sdk-manager config install-dir set $HOME/office/ncs/source"; grep -F "$expected" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
}

@test "version shorthand normalizes to v-prefix and activates toolchain env" {
  _write_fake_nrfutil
  run bash -c '. ./nrfvm; nrfvm 2.9.0'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Now using SDK version v2.9.0"* ]]
  run bash -c 'grep -F "sdk-manager install v2.9.0" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c 'grep -F "sdk-manager toolchain env --ncs-version v2.9.0 --as-script sh" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c '! grep -F "sdk-manager sdk register v2.9.0" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c '. ./nrfvm; nrfvm 2.9.0 >/dev/null; command -v west >/dev/null'
  [ "$status" -eq 0 ]
}

@test "use skips install when sdk is already installed" {
  _write_fake_nrfutil
  export NRFUTIL_FAKE_INSTALLED_VERSION="v3.2.3"
  run bash -c '. ./nrfvm; nrfvm u v3.2.3'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Now using SDK version v3.2.3"* ]]
  run bash -c '! grep -F "sdk-manager install v3.2.3" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c 'grep -F "sdk-manager toolchain env --ncs-version v3.2.3 --as-script sh" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c '! grep -F "sdk-manager sdk register v3.2.3" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c '. ./nrfvm; nrfvm u v3.2.3 >/dev/null; west --version >/dev/null'
  [ "$status" -eq 0 ]
}
