#!/usr/bin/env bats

setup() {
  export TEST_ROOT="$BATS_TEST_TMPDIR/root"
  mkdir -p "$TEST_ROOT/bin"
  export PATH="$TEST_ROOT/bin:$PATH"
  export HOME="$TEST_ROOT/home"
  mkdir -p "$HOME"
  export NRFVM_DIR="$TEST_ROOT/nrfvm-state"
  export NRFUTIL_FAKE_LOG="$TEST_ROOT/nrfutil.log"
  : > "$NRFUTIL_FAKE_LOG"
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
        # Return no installed SDKs in this fake.
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
            if [ "$_json" -eq 1 ]; then
              echo '{"type":"info","data":{"default":{"install_dir":null,"sdk_index":null,"toolchain_index":null},"sdk_indexes":{},"toolchain_indexes":{}}}'
            else
              echo "config show"
            fi
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

@test "version shorthand normalizes to v-prefix and registers SDK" {
  _write_fake_nrfutil
  run bash -c '. ./nrfvm; nrfvm 2.9.0'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Now using SDK version v2.9.0"* ]]
  run bash -c 'grep -F "sdk-manager install v2.9.0" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
  run bash -c 'grep -F "sdk-manager sdk register v2.9.0" "$NRFUTIL_FAKE_LOG" >/dev/null'
  [ "$status" -eq 0 ]
}
