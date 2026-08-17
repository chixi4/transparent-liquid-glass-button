#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BIN_PATH="$(swift build --show-bin-path)"

SWIFT_PATH="$(xcrun --find swift)"
TOOLCHAIN_ROOT="$(cd -- "$(dirname -- "$SWIFT_PATH")/../.." && pwd)"
TESTING_FRAMEWORK="$TOOLCHAIN_ROOT/Library/Developer/Frameworks/Testing.framework"
TESTING_INTEROP="$TOOLCHAIN_ROOT/Library/Developer/usr/lib/lib_TestingInterop.dylib"
TESTING_MACROS="$TOOLCHAIN_ROOT/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
FRAMEWORK_DIR="$BIN_PATH/PackageFrameworks"

# Some Command Line Tools releases omit the Swift Testing macro plugin from
# the compiler invocation. Load it explicitly when the toolchain provides it.
if [[ -f "$TESTING_MACROS" ]]; then
    swift build --build-tests \
        -Xswiftc -load-plugin-library \
        -Xswiftc "$TESTING_MACROS"
else
    swift build --build-tests
fi

# The same releases also omit Swift Testing from the runtime search paths used
# by swiftpm-testing-helper. Make the toolchain-owned files visible to the test
# bundle without copying them into the repository.
if [[ -d "$TESTING_FRAMEWORK" && -f "$TESTING_INTEROP" ]]; then
    mkdir -p "$FRAMEWORK_DIR"
    ln -sfn "$TESTING_FRAMEWORK" "$FRAMEWORK_DIR/Testing.framework"
    ln -sfn "$TESTING_INTEROP" "$FRAMEWORK_DIR/lib_TestingInterop.dylib"
fi

swift test --skip-build "$@"
