#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ATARI800_BIN="$ROOT_DIR/third_party/atari800/build/src/atari800"
HATARI_BIN="$ROOT_DIR/third_party/hatari/build/src/hatari"
EMUTOS_DIR="$ROOT_DIR/UserMedia/Firmware/EmuTOS"

ETOS_192="$EMUTOS_DIR/etos192us.img"
ETOS_256="$EMUTOS_DIR/etos256us.img"
ETOS_512="$EMUTOS_DIR/etos512us.img"
ETOS_1024="$EMUTOS_DIR/etos1024k.img"

tmpfiles=()

cleanup() {
  local file
  for file in "${tmpfiles[@]:-}"; do
    [[ -f "$file" ]] && rm -f "$file"
  done
}

trap cleanup EXIT

require_executable() {
  local path="$1"
  if [[ ! -x "$path" ]]; then
    print "Missing executable: $path" >&2
    exit 1
  fi
}

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    print "Missing required file: $path" >&2
    exit 1
  fi
}

pass() {
  print "PASS  $1"
}

fail() {
  print "FAIL  $1" >&2
  [[ -f "$2" ]] && sed -n '1,40p' "$2" >&2
  exit 1
}

run_atari800_test() {
  local label="$1"
  local machine_arg="$2"
  local log_file
  local pid

  log_file="$(mktemp "${TMPDIR:-/tmp}/atarixl.XXXXXX")"
  tmpfiles+=("$log_file")

  SDL_VIDEODRIVER=dummy "$ATARI800_BIN" \
    "$machine_arg" \
    -ntsc \
    -no-autosave-config \
    -xl-rev altirra \
    -basic-rev altirra \
    -basic \
    >"$log_file" 2>&1 &
  pid=$!

  sleep 2

  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
  fi
  wait "$pid" 2>/dev/null || true

  if rg -q "Invalid argument|Could not initialize|ERROR:|Failed to start" "$log_file"; then
    fail "$label" "$log_file"
  fi

  pass "$label"
}

run_hatari_test() {
  local label="$1"
  local machine_type="$2"
  local tos_image="$3"
  shift 3

  local log_file
  local exit_status

  log_file="$(mktemp "${TMPDIR:-/tmp}/hatari.XXXXXX")"
  tmpfiles+=("$log_file")

  SDL_VIDEODRIVER=dummy "$HATARI_BIN" \
    --machine "$machine_type" \
    --tos "$tos_image" \
    --confirm-quit false \
    --statusbar false \
    --sound off \
    --disable-video true \
    --run-vbls 120 \
    --benchmark \
    "$@" \
    >"$log_file" 2>&1 || exit_status=$?

  exit_status="${exit_status:-0}"
  if [[ "$exit_status" -ne 0 ]]; then
    fail "$label" "$log_file"
  fi

  pass "$label"
}

main() {
  require_executable "$ATARI800_BIN"
  require_executable "$HATARI_BIN"
  require_file "$ETOS_256"
  require_file "$ETOS_512"
  require_file "$ETOS_1024"

  print "8-bit cold boots"
  run_atari800_test "Atari XL" "-xl"
  run_atari800_test "Atari XE" "-xe"
  run_atari800_test "Atari 65XE" "-xl"
  run_atari800_test "Atari 130XE" "-xe"
  run_atari800_test "Super XL" "-576xe"
  run_atari800_test "Super Max XL" "-1088xe"

  print ""
  print "ST-family cold boots"
  run_hatari_test "Atari ST/F" "st" "$ETOS_256"
  run_hatari_test "Atari Mega ST" "megast" "$ETOS_256"
  run_hatari_test "Atari Stacy" "st" "$ETOS_256"
  run_hatari_test "Atari STE" "ste" "$ETOS_512"
  run_hatari_test "Atari Mega STE" "megaste" "$ETOS_512"
  run_hatari_test "Super ST" "st" "$ETOS_256"
  run_hatari_test "Super Mega ST" "megast" "$ETOS_256"
  run_hatari_test "Super Max ST" "megast" "$ETOS_256"

  print ""
  print "TT / Falcon cold boots"
  run_hatari_test "Atari TT030" "tt" "$ETOS_1024"
  run_hatari_test "Super TT" "tt" "$ETOS_1024"
  run_hatari_test "Super Max TT" "tt" "$ETOS_1024"
  run_hatari_test "Atari Falcon030" "falcon" "$ETOS_1024" --dsp emu --mic false
  run_hatari_test "Super Max Falcon" "falcon" "$ETOS_1024" --dsp emu --mic false
  run_hatari_test "Super Falcon X1200" "falcon" "$ETOS_1024" --dsp emu --mic false

  print ""
  print "All configured machine smoke tests passed."
}

main "$@"
