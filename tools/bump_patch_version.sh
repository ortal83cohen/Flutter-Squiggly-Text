#!/bin/sh
set -eu

# Helper script to bump patch version in pubspec.yaml and update CHANGELOG.md
# Usage: ./bump_patch_version.sh [repository_root]
# Environment: RELEASE_DATE (optional) - date to use for changelog entry

# Determine repository root
if [ $# -gt 0 ]; then
    REPO_ROOT="$1"
else
    SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
    REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
fi

# Validate repository root exists
if [ ! -d "$REPO_ROOT" ]; then
    echo "Error: Repository root directory does not exist: $REPO_ROOT" >&2
    exit 1
fi

PUBSPEC_PATH="$REPO_ROOT/pubspec.yaml"
CHANGELOG_PATH="$REPO_ROOT/CHANGELOG.md"

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC_PATH" ]; then
    echo "Error: pubspec.yaml not found at: $PUBSPEC_PATH" >&2
    exit 1
fi

# Check if CHANGELOG.md exists
if [ ! -f "$CHANGELOG_PATH" ]; then
    echo "Error: CHANGELOG.md not found at: $CHANGELOG_PATH" >&2
    exit 1
fi

# Read current version from pubspec.yaml
VERSION_LINE=$(grep "^version:" "$PUBSPEC_PATH" || true)
if [ -z "$VERSION_LINE" ]; then
    echo "Error: No top-level version key found in pubspec.yaml" >&2
    exit 1
fi

CURRENT_VERSION=$(echo "$VERSION_LINE" | sed 's/^version: *//;s/ *$//')

# Validate version format (exactly three dot-separated numeric components)
if ! echo "$CURRENT_VERSION" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' >/dev/null; then
    echo "Error: Version must be exactly three dot-separated numeric components, got: $CURRENT_VERSION" >&2
    exit 1
fi

# Extract version components
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)

# Compute new version (increment patch)
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"

# Validate CHANGELOG.md format. The title may be preceded by blank lines, so its line
# number is resolved here and reused when the file is rebuilt below.
TITLE_LINE_NUMBER=$(grep -n -v '^[[:space:]]*$' "$CHANGELOG_PATH" | head -n1 | cut -d: -f1)
if [ -z "$TITLE_LINE_NUMBER" ]; then
    echo "Error: CHANGELOG.md is empty: $CHANGELOG_PATH" >&2
    exit 1
fi

FIRST_NON_BLANK=$(sed -n "${TITLE_LINE_NUMBER}p" "$CHANGELOG_PATH" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
if [ "$FIRST_NON_BLANK" != "# Changelog" ]; then
    echo "Error: First non-blank line in CHANGELOG.md must be '# Changelog', got: $FIRST_NON_BLANK" >&2
    exit 1
fi

# Check if new version already exists in changelog. A heading is either the version alone
# or the version followed by the dated remainder.
if grep -Eq "^## $NEW_VERSION([[:space:]]|$)" "$CHANGELOG_PATH"; then
    echo "Error: Version $NEW_VERSION already exists in CHANGELOG.md" >&2
    exit 1
fi

# Determine release date
if [ -n "${RELEASE_DATE:-}" ]; then
    DATE="$RELEASE_DATE"
else
    DATE=$(date -u +%Y-%m-%d)
fi

# Prepare new files content in memory
TEMP_PUBSPEC=$(mktemp)
TEMP_CHANGELOG=$(mktemp)

# Clean up temp files on exit
trap 'rm -f "$TEMP_PUBSPEC" "$TEMP_CHANGELOG"' EXIT

# Create new pubspec.yaml content
sed "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_PATH" > "$TEMP_PUBSPEC"

# Create new CHANGELOG.md content: everything up to and including the title line, the new
# section, then the untouched remainder.
{
    sed -n "1,${TITLE_LINE_NUMBER}p" "$CHANGELOG_PATH"
    echo ""
    echo "## $NEW_VERSION - $DATE"
    echo ""
    echo "- Automated patch release from main."
    echo ""
    # Remainder after the title, with its leading blank lines dropped so exactly one blank
    # line separates the new section from the previously top-most one.
    awk -v title_line="$TITLE_LINE_NUMBER" '
        NR <= title_line { next }
        !started && $0 ~ /^[[:space:]]*$/ { next }
        { started = 1; print }
    ' "$CHANGELOG_PATH"
} > "$TEMP_CHANGELOG"

# Validate that we successfully created new content
if ! grep -q "^version: $NEW_VERSION$" "$TEMP_PUBSPEC"; then
    echo "Error: Failed to create updated pubspec.yaml content" >&2
    exit 1
fi

if ! grep -q "^## $NEW_VERSION - $DATE$" "$TEMP_CHANGELOG"; then
    echo "Error: Failed to create updated CHANGELOG.md content" >&2
    exit 1
fi

# Move temp files into place (atomic operation)
mv "$TEMP_PUBSPEC" "$PUBSPEC_PATH"
mv "$TEMP_CHANGELOG" "$CHANGELOG_PATH"

# Output new version
echo "$NEW_VERSION"