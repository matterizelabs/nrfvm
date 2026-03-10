#!/usr/bin/env bats

setup() {
  export TEST_ROOT="$BATS_TEST_TMPDIR/root"
  mkdir -p "$TEST_ROOT/bin"
  export PATH="$TEST_ROOT/bin:$PATH"
  export HOME="$TEST_ROOT/home"
  mkdir -p "$HOME"
  export NRFVM_DIR="$TEST_ROOT/nrfvm-state"
}

_write_fake_nrfutil() {
  cat > "$TEST_ROOT/bin/nrfutil" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --version)
    echo "nrfutil 0.0.test"
    ;;
  sdk-manager)
    shift
    case "$1" in
      --help) exit 0 ;;
      install|use|list|list-remote)
        echo "sdk-manager $1 ok"
        ;;
      *) exit 1 ;;
    esac
    ;;
  install)
    echo "install $2"
    ;;
  list)
    echo "Found 0 installed command(s)"
    ;;
  search)
    echo "search $2"
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

@test "version shorthand routes to sdk use" {
  _write_fake_nrfutil
  run bash -c '. ./nrfvm; nrfvm 2.9.0'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Now using SDK version 2.9.0"* ]]
}
