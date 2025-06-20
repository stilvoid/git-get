#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_start() {
    echo -e "${YELLOW}Testing: $1${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo
}

test_fail() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo
}

# Create temporary directory for testing
TEST_DIR=$(mktemp -d)
echo "Using test directory: $TEST_DIR"

# Create a mock git command that doesn't actually clone
MOCK_GIT_DIR="$TEST_DIR/mock-bin"
mkdir -p "$MOCK_GIT_DIR"

cat > "$MOCK_GIT_DIR/git" << 'EOF'
#!/bin/bash
# Mock git command for testing
if [ "$1" = "config" ]; then
    # Handle git config calls
    if [ "$2" = "get.location" ]; then
        # Return test config if set
        if [ -f "$TEST_CONFIG_FILE" ]; then
            cat "$TEST_CONFIG_FILE"
        else
            exit 1  # Config not set
        fi
    fi
elif [ "$1" = "clone" ]; then
    # Mock git clone - just create the target directory
    TARGET_DIR="${@: -1}"  # Last argument is the target directory
    echo "Cloning into '$TARGET_DIR'..."
    mkdir -p "$TARGET_DIR"
    echo "Mock clone completed successfully"
else
    # Pass through other git commands to real git
    exec /usr/bin/git "$@"
fi
EOF

chmod +x "$MOCK_GIT_DIR/git"

# Set up test environment
export PATH="$MOCK_GIT_DIR:$PATH"
export TEST_CONFIG_FILE="$TEST_DIR/git-config"
export HOME="$TEST_DIR/fake-home"
mkdir -p "$HOME"

# Copy git-get to test directory for isolated testing
cp git-get "$TEST_DIR/git-get-test"

echo "Starting git-get tests..."
echo "=========================="
echo

# Test 1: Help output
test_start "Help output contains expected content"
HELP_OUTPUT=$("$TEST_DIR/git-get-test" --help 2>&1)
if echo "$HELP_OUTPUT" | grep -q "Usage: git get" && \
   echo "$HELP_OUTPUT" | grep -q "\-\-print\-path" && \
   echo "$HELP_OUTPUT" | grep -q "\-\-location"; then
    test_pass
else
    test_fail "Help output missing expected content"
fi

# Test 2: Print path with default location
test_start "Print path with default location"
EXPECTED_PATH="$HOME/code/github.com/stilvoid/git-get"
ACTUAL_PATH=$("$TEST_DIR/git-get-test" --print-path https://github.com/stilvoid/git-get.git 2>&1)
if [ "$ACTUAL_PATH" = "$EXPECTED_PATH" ]; then
    test_pass
else
    test_fail "Expected '$EXPECTED_PATH', got '$ACTUAL_PATH'"
fi

# Test 3: Print path with custom config location
test_start "Print path with custom config location"
echo "$TEST_DIR/custom-code" > "$TEST_CONFIG_FILE"
EXPECTED_PATH="$TEST_DIR/custom-code/github.com/stilvoid/git-get"
ACTUAL_PATH=$("$TEST_DIR/git-get-test" --print-path https://github.com/stilvoid/git-get.git 2>&1)
if [ "$ACTUAL_PATH" = "$EXPECTED_PATH" ]; then
    test_pass
else
    test_fail "Expected '$EXPECTED_PATH', got '$ACTUAL_PATH'"
fi

# Test 4: Print path with --location override
test_start "Print path with --location override"
EXPECTED_PATH="$TEST_DIR/override-location/github.com/stilvoid/git-get"
ACTUAL_PATH=$("$TEST_DIR/git-get-test" --location "$TEST_DIR/override-location" --print-path https://github.com/stilvoid/git-get.git 2>&1)
if [ "$ACTUAL_PATH" = "$EXPECTED_PATH" ]; then
    test_pass
else
    test_fail "Expected '$EXPECTED_PATH', got '$ACTUAL_PATH'"
fi

# Test 5: URL parsing - SSH format
test_start "URL parsing - SSH format"
rm -f "$TEST_CONFIG_FILE"  # Use default location
EXPECTED_PATH="$HOME/code/github.com/user/repo"
ACTUAL_PATH=$("$TEST_DIR/git-get-test" --print-path git@github.com:user/repo.git 2>&1)
if [ "$ACTUAL_PATH" = "$EXPECTED_PATH" ]; then
    test_pass
else
    test_fail "Expected '$EXPECTED_PATH', got '$ACTUAL_PATH'"
fi

# Test 6: URL parsing - HTTPS format
test_start "URL parsing - HTTPS format"
EXPECTED_PATH="$HOME/code/github.com/user/repo"
ACTUAL_PATH=$("$TEST_DIR/git-get-test" --print-path https://github.com/user/repo.git 2>&1)
if [ "$ACTUAL_PATH" = "$EXPECTED_PATH" ]; then
    test_pass
else
    test_fail "Expected '$EXPECTED_PATH', got '$ACTUAL_PATH'"
fi

# Test 7: URL parsing - Git protocol
test_start "URL parsing - Git protocol"
EXPECTED_PATH="$HOME/code/github.com/user/repo"
ACTUAL_PATH=$("$TEST_DIR/git-get-test" --print-path git://github.com/user/repo.git 2>&1)
if [ "$ACTUAL_PATH" = "$EXPECTED_PATH" ]; then
    test_pass
else
    test_fail "Expected '$EXPECTED_PATH', got '$ACTUAL_PATH'"
fi

# Test 8: URL without .git suffix
test_start "URL parsing - without .git suffix"
EXPECTED_PATH="$HOME/code/github.com/user/repo"
ACTUAL_PATH=$("$TEST_DIR/git-get-test" --print-path https://github.com/user/repo 2>&1)
if [ "$ACTUAL_PATH" = "$EXPECTED_PATH" ]; then
    test_pass
else
    test_fail "Expected '$EXPECTED_PATH', got '$ACTUAL_PATH'"
fi

# Test 9: Tilde expansion in --location
test_start "Tilde expansion in --location"
EXPECTED_PATH="$HOME/temp/github.com/user/repo"
ACTUAL_PATH=$("$TEST_DIR/git-get-test" --location ~/temp --print-path https://github.com/user/repo.git 2>&1)
if [ "$ACTUAL_PATH" = "$EXPECTED_PATH" ]; then
    test_pass
else
    test_fail "Expected '$EXPECTED_PATH', got '$ACTUAL_PATH'"
fi

# Test 10: Trailing slash handling in config
test_start "Trailing slash handling in config"
echo "$TEST_DIR/custom-code/" > "$TEST_CONFIG_FILE"  # Note trailing slash
EXPECTED_PATH="$TEST_DIR/custom-code/github.com/user/repo"
ACTUAL_PATH=$("$TEST_DIR/git-get-test" --print-path https://github.com/user/repo.git 2>&1)
if [ "$ACTUAL_PATH" = "$EXPECTED_PATH" ]; then
    test_pass
else
    test_fail "Expected '$EXPECTED_PATH', got '$ACTUAL_PATH'"
fi

# Test 11: Error handling - missing repository argument
test_start "Error handling - missing repository argument"
OUTPUT=$("$TEST_DIR/git-get-test" 2>&1 || true)
if echo "$OUTPUT" | grep -q "Usage: git get"; then
    test_pass
else
    test_fail "Should show usage when repository argument is missing"
fi

# Test 12: Error handling - --location without argument
test_start "Error handling - --location without argument"
OUTPUT=$("$TEST_DIR/git-get-test" --location 2>&1 || true)
if echo "$OUTPUT" | grep -q "Error: --location requires a directory path"; then
    test_pass
else
    test_fail "Should show error when --location has no argument"
fi

# Test 13: Actual clone operation (mock)
test_start "Actual clone operation (mocked)"
rm -f "$TEST_CONFIG_FILE"  # Use default location
TARGET_DIR="$HOME/code/github.com/test/repo"
OUTPUT=$("$TEST_DIR/git-get-test" https://github.com/test/repo.git 2>&1)
if [ -d "$TARGET_DIR" ] && echo "$OUTPUT" | grep -q "Successfully cloned to: $TARGET_DIR"; then
    test_pass
else
    test_fail "Clone operation failed or directory not created"
fi

# Test 14: Clone with additional git arguments
test_start "Clone with additional git arguments"
rm -rf "$HOME/code/github.com/test/repo-with-args"
OUTPUT=$("$TEST_DIR/git-get-test" https://github.com/test/repo-with-args.git --depth 1 2>&1)
TARGET_DIR="$HOME/code/github.com/test/repo-with-args"
if [ -d "$TARGET_DIR" ] && echo "$OUTPUT" | grep -q "Successfully cloned to: $TARGET_DIR"; then
    test_pass
else
    test_fail "Clone with additional arguments failed"
fi

# Test 15: Clone with --location override
test_start "Clone with --location override"
OVERRIDE_DIR="$TEST_DIR/override-test"
TARGET_DIR="$OVERRIDE_DIR/github.com/test/override-repo"
OUTPUT=$("$TEST_DIR/git-get-test" --location "$OVERRIDE_DIR" https://github.com/test/override-repo.git 2>&1)
if [ -d "$TARGET_DIR" ] && echo "$OUTPUT" | grep -q "Successfully cloned to: $TARGET_DIR"; then
    test_pass
else
    test_fail "Clone with --location override failed"
fi

# Cleanup
echo "Cleaning up test directory: $TEST_DIR"
rm -rf "$TEST_DIR"

# Summary
echo "=========================="
echo "Test Results:"
echo "  Total tests: $TESTS_RUN"
echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
    exit 1
else
    echo -e "  Failed: $TESTS_FAILED"
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
