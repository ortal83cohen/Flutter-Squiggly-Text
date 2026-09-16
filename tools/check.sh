#!/bin/sh
set -eu

REPOSITORY_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$REPOSITORY_ROOT"

for binary in flutter dart; do
  if ! command -v "$binary" >/dev/null 2>&1; then
    echo "Preflight failed: missing required binary: $binary" >&2
    exit 1
  fi
done
echo "Preflight: flutter and dart found"

stage_failed() {
  echo "Stage $1 failed: $2" >&2
  exit 1
}

flutter pub get || stage_failed 1 "dependencies"
(cd example && flutter pub get) || stage_failed 1 "example dependencies"
echo "Stage 1 passed: dependencies"

dart format --output=none --set-exit-if-changed lib test example/lib example/test ||
  stage_failed 2 "format"
echo "Stage 2 passed: format"

dart analyze --fatal-infos --fatal-warnings || stage_failed 3 "analysis"
(cd example && dart analyze --fatal-infos --fatal-warnings) ||
  stage_failed 3 "example analysis"
echo "Stage 3 passed: analysis"

flutter test || stage_failed 4 "tests"
(cd example && flutter test) || stage_failed 4 "example tests"
echo "Stage 4 passed: tests"

sh tools/test_bump_patch_version.sh || stage_failed 5 "version bump test"
echo "Stage 5 passed: version bump test"
