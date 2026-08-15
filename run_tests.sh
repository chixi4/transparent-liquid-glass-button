#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Some Command Line Tools releases install Swift Testing outside the default
# runtime search paths used by swiftpm-testing-helper. Build first, then make
# those two toolchain-owned files visible to the test bundle.
swift build --build-tests
BIN_PATH="$(swift build --show-bin-path)"

SWIFT_PATH="$(xcrun --find swift)"
TOOLCHAIN_ROOT="$(cd -- "$(dirname -- "$SWIFT_PATH")/../.." && pwd)"
TESTING_FRAMEWORK="$TOOLCHAIN_ROOT/Library/Developer/Frameworks/Testing.framework"
TESTING_INTEROP="$TOOLCHAIN_ROOT/Library/Developer/usr/lib/lib_TestingInterop.dylib"
FRAMEWORK_DIR="$BIN_PATH/PackageFrameworks"

if [[ -d "$TESTING_FRAMEWORK" && -f "$TESTING_INTEROP" ]]; then
    mkdir -p "$FRAMEWORK_DIR"
    ln -sfn "$TESTING_FRAMEWORK" "$FRAMEWORK_DIR/Testing.framework"
    ln -sfn "$TESTING_INTEROP" "$FRAMEWORK_DIR/lib_TestingInterop.dylib"
fi

swift test --skip-build "$@"
