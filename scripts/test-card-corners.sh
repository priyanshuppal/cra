#!/bin/bash
# The page card's corner covers its shadow's cut-out: a card layer composited by the window server against
# CardShadowView's cut-out, in an off-screen window. No CEF.
set -euo pipefail
cd "$(dirname "$0")/.."
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cra-card-corners.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
xcrun swiftc -swift-version 5 -parse-as-library ${CRA_TEST_SWIFTC_FLAGS:-} \
  Sources/Cra/UI/SplitView/CardShadowView.swift Packages/CraCore/Sources/CraCore/CardFill.swift \
  Tests/CardCornersTests.swift \
  -o "$TEST_DIR/card-corners-tests"
"$TEST_DIR/card-corners-tests"
[ -z "${CRA_TEST_KEEP:-}" ] || cp "$TEST_DIR/card-corners-tests" "$CRA_TEST_KEEP/"
