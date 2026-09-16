#!/bin/sh
set -eu

# Test script for tools/bump_patch_version.sh
# Runs against fixture directories under tools/fixtures/bump-patch-version/

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
HELPER_SCRIPT="$SCRIPT_DIR/bump_patch_version.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures/bump-patch-version"

# Fixed release date for consistent test assertions
export RELEASE_DATE="2026-01-02"

test_case() {
    local case_name="$1"
    local fixture_dir="$FIXTURES_DIR/$case_name"
    
    if [ ! -d "$fixture_dir" ]; then
        echo "FAIL: $case_name - fixture directory not found"
        return 1
    fi
    
    # Create temp directory and copy fixture
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT
    
    cp -r "$fixture_dir"/* "$temp_dir/" 2>/dev/null || true
    
    case "$case_name" in
        "valid-patch")
            # Test: pubspec 0.1.1 → stdout exactly 0.1.2, exit 0
            local output
            if output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) && [ $? -eq 0 ]; then
                if [ "$output" = "0.1.2" ]; then
                    # Assert written pubspec has version: 0.1.2
                    if grep -q "^version: 0.1.2$" "$temp_dir/pubspec.yaml"; then
                        # Assert changelog line 3 equals expected format
                        local line3
                        line3=$(sed -n '3p' "$temp_dir/CHANGELOG.md")
                        if [ "$line3" = "## 0.1.2 - 2026-01-02" ]; then
                            # Check no square brackets
                            if ! echo "$line3" | grep -q '\[' && ! echo "$line3" | grep -q '\]'; then
                                # Assert line 5 equals expected bullet
                                local line5
                                line5=$(sed -n '5p' "$temp_dir/CHANGELOG.md")
                                if [ "$line5" = "- Automated patch release from main." ]; then
                                    # Check previous heading still appears
                                    if grep -q "## 0.1.1 - 2026-08-01" "$temp_dir/CHANGELOG.md"; then
                                        echo "PASS: $case_name"
                                        return 0
                                    else
                                        echo "FAIL: $case_name - previous heading missing"
                                    fi
                                else
                                    echo "FAIL: $case_name - wrong bullet line: '$line5'"
                                fi
                            else
                                echo "FAIL: $case_name - heading contains brackets"
                            fi
                        else
                            echo "FAIL: $case_name - wrong heading line 3: '$line3'"
                        fi
                    else
                        echo "FAIL: $case_name - pubspec version not updated correctly"
                    fi
                else
                    echo "FAIL: $case_name - wrong output: '$output'"
                fi
            else
                echo "FAIL: $case_name - helper failed or wrong exit code"
            fi
            ;;
            
        "valid-minor-untouched")
            # Test: pubspec 1.2.3 → written pubspec has version: 1.2.4
            if sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1; then
                if grep -q "^version: 1.2.4$" "$temp_dir/pubspec.yaml"; then
                    # Assert no line equals version: 1.3.0 or version: 2.0.0
                    if ! grep -q "^version: 1.3.0$" "$temp_dir/pubspec.yaml" && \
                       ! grep -q "^version: 2.0.0$" "$temp_dir/pubspec.yaml"; then
                        echo "PASS: $case_name"
                        return 0
                    else
                        echo "FAIL: $case_name - wrong version component changed"
                    fi
                else
                    echo "FAIL: $case_name - version not updated to 1.2.4"
                fi
            else
                echo "FAIL: $case_name - helper failed"
            fi
            ;;
            
        "valid-leading-blank")
            # Test: a changelog whose title is preceded by a blank line keeps exactly one
            # title line and one blank separator before the previously top-most section.
            local output
            if output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) && [ "$output" = "2.4.10" ]; then
                # The fixture's leading blank line is preserved, so the title sits on line 2
                # and the new section starts on line 4.
                local title_count separator
                title_count=$(grep -c '^# Changelog$' "$temp_dir/CHANGELOG.md")
                separator=$(sed -n '7p' "$temp_dir/CHANGELOG.md")
                if [ "$title_count" = "1" ]; then
                    if [ "$(sed -n '4p' "$temp_dir/CHANGELOG.md")" = "## 2.4.10 - 2026-01-02" ] \
                       && [ "$(sed -n '6p' "$temp_dir/CHANGELOG.md")" = "- Automated patch release from main." ] \
                       && [ -z "$separator" ] \
                       && [ "$(sed -n '8p' "$temp_dir/CHANGELOG.md")" = "## 2.4.9 - 2026-08-01" ]; then
                        echo "PASS: $case_name"
                        return 0
                    else
                        echo "FAIL: $case_name - new section not laid out as expected"
                    fi
                else
                    echo "FAIL: $case_name - title line count was $title_count"
                fi
            else
                echo "FAIL: $case_name - helper failed or wrong output: '${output:-}'"
            fi
            ;;

        "reject-prerelease")
            # Test: version 0.1.1-dev.1 → non-zero, both files byte-identical
            local before_pubspec before_changelog
            before_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
            before_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
            
            if ! sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1; then
                local after_pubspec after_changelog
                after_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
                after_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
                
                if [ "$before_pubspec" = "$after_pubspec" ] && [ "$before_changelog" = "$after_changelog" ]; then
                    echo "PASS: $case_name"
                    return 0
                else
                    echo "FAIL: $case_name - files were modified"
                fi
            else
                echo "FAIL: $case_name - helper should have failed"
            fi
            ;;
            
        "reject-two-components")
            # Test: version 0.1 → non-zero, both files byte-identical
            local before_pubspec before_changelog
            before_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
            before_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
            
            if ! sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1; then
                local after_pubspec after_changelog
                after_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
                after_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
                
                if [ "$before_pubspec" = "$after_pubspec" ] && [ "$before_changelog" = "$after_changelog" ]; then
                    echo "PASS: $case_name"
                    return 0
                else
                    echo "FAIL: $case_name - files were modified"
                fi
            else
                echo "FAIL: $case_name - helper should have failed"
            fi
            ;;
            
        "reject-no-changelog-title")
            # Test: CHANGELOG.md without # Changelog title → non-zero, files byte-identical
            local before_pubspec before_changelog
            before_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
            before_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
            
            if ! sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1; then
                local after_pubspec after_changelog
                after_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
                after_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
                
                if [ "$before_pubspec" = "$after_pubspec" ] && [ "$before_changelog" = "$after_changelog" ]; then
                    echo "PASS: $case_name"
                    return 0
                else
                    echo "FAIL: $case_name - files were modified"
                fi
            else
                echo "FAIL: $case_name - helper should have failed"
            fi
            ;;
            
        "reject-missing-changelog")
            # Test: valid pubspec, no CHANGELOG.md → non-zero, stdout empty, pubspec byte-identical
            local before_pubspec
            before_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
            
            local output exit_code
            set +e
            output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null)
            exit_code=$?
            set -e
            
            if [ $exit_code -ne 0 ]; then
                local after_pubspec
                after_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
                
                if [ "$before_pubspec" = "$after_pubspec" ] && [ -z "$output" ]; then
                    echo "PASS: $case_name"
                    return 0
                else
                    echo "FAIL: $case_name - pubspec modified or stdout not empty"
                fi
            else
                echo "FAIL: $case_name - helper should have failed"
            fi
            ;;
            
        "reject-missing-pubspec")
            # Test: empty directory → non-zero, non-empty stderr, stdout empty, directory still empty
            local output stderr_output exit_code
            set +e
            stderr_output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>&1 >/dev/null)
            output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null)
            exit_code=$?
            set -e
            
            if [ $exit_code -ne 0 ]; then
                if [ -n "$stderr_output" ] && [ -z "$output" ]; then
                    # Check directory is still empty
                    if [ -z "$(ls -A "$temp_dir" 2>/dev/null)" ]; then
                        echo "PASS: $case_name"
                        return 0
                    else
                        echo "FAIL: $case_name - directory not empty"
                    fi
                else
                    echo "FAIL: $case_name - wrong output behavior"
                fi
            else
                echo "FAIL: $case_name - helper should have failed"
            fi
            ;;
            
        "reject-changelog-ahead")
            # Test: pubspec 0.1.1 and CHANGELOG.md with ## 0.1.2 → non-zero, files byte-identical
            local before_pubspec before_changelog
            before_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
            before_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
            
            if ! sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1; then
                local after_pubspec after_changelog
                after_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
                after_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
                
                if [ "$before_pubspec" = "$after_pubspec" ] && [ "$before_changelog" = "$after_changelog" ]; then
                    echo "PASS: $case_name"
                    return 0
                else
                    echo "FAIL: $case_name - files were modified"
                fi
            else
                echo "FAIL: $case_name - helper should have failed"
            fi
            ;;
            
        *)
            echo "FAIL: $case_name - unknown test case"
            return 1
            ;;
    esac
    
    return 1
}

# Test real repository root
test_real_repo() {
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT
    
    # Copy real pubspec.yaml and CHANGELOG.md
    cp "$REPOSITORY_ROOT/pubspec.yaml" "$temp_dir/"
    cp "$REPOSITORY_ROOT/CHANGELOG.md" "$temp_dir/"
    
    local current_version expected_version output
    current_version=$(sed -n 's/^version:[[:space:]]*//p' "$REPOSITORY_ROOT/pubspec.yaml" | head -n 1)
    expected_version=$(printf '%s\n' "$current_version" | awk -F. \
        'NF == 3 { printf "%s.%s.%d\n", $1, $2, $3 + 1 }')

    if output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) && [ "$output" = "$expected_version" ]; then
        echo "PASS: real-repo-test"
        return 0
    else
        echo "FAIL: real-repo-test - expected '$expected_version', output was '$output'"
        return 1
    fi
}

# Run all test cases
echo "Running bump_patch_version.sh tests..."

failures=0

for case_name in valid-patch valid-minor-untouched valid-leading-blank \
                 reject-prerelease reject-two-components \
                 reject-no-changelog-title reject-missing-changelog reject-missing-pubspec \
                 reject-changelog-ahead; do
    if ! test_case "$case_name"; then
        failures=$((failures + 1))
    fi
done

# Test against real repository
if ! test_real_repo; then
    failures=$((failures + 1))
fi

if [ $failures -eq 0 ]; then
    echo "All tests passed"
    exit 0
else
    echo "$failures test(s) failed"
    exit 1
fi
