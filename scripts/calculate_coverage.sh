#!/bin/bash
set -euo pipefail
#
# Calculate Code Coverage with Optional Exclusions
#
# This script calculates code coverage and can exclude specific files
# that require API credentials to test properly.
#
# EXCLUDED FILES (require Internet Archive API key):
# - AccountVC.swift      - Account info display (requires login)
# - AccountNC.swift      - Account navigation controller
# - LoginVC.swift        - Login form
# - RegisterVC.swift     - Registration form
# - PeopleVC.swift       - People favorites (requires login)
# - ItemVC.swift         - Item detail view (requires metadata API)
#
# To enable testing of these files, add valid API credentials to
# Configuration.plist (see Configuration.plist.template)
#

# Find the latest xcresult
DERIVED_DATA_PATH=~/Library/Developer/Xcode/DerivedData
RESULT_PATH=$(find "$DERIVED_DATA_PATH"/Internet_Archive-*/Logs/Test -name "*.xcresult" -type d 2>/dev/null | sort -r | head -1)

if [ -z "$RESULT_PATH" ]; then
    echo "Error: No test results found. Run tests first."
    exit 1
fi

echo "Using test results: $RESULT_PATH"
echo ""

# Get full coverage report
FULL_REPORT=$(xcrun xccov view --report "$RESULT_PATH" 2>/dev/null)

# Extract app coverage line
APP_COVERAGE=$(echo "$FULL_REPORT" | grep "Internet Archive.app" | head -1)
echo "=== FULL COVERAGE ==="
echo "$APP_COVERAGE"
echo ""

# Parse total and covered lines
TOTAL_LINES=$(echo "$APP_COVERAGE" | grep -oE '\([0-9]+/[0-9]+\)' | grep -oE '[0-9]+/[0-9]+' | cut -d'/' -f2)
COVERED_LINES=$(echo "$APP_COVERAGE" | grep -oE '\([0-9]+/[0-9]+\)' | grep -oE '[0-9]+/[0-9]+' | cut -d'/' -f1)

# Validate extracted values
if [ -z "$TOTAL_LINES" ] || [ -z "$COVERED_LINES" ]; then
    echo "Error: Could not parse coverage data from report"
    echo "Report line: $APP_COVERAGE"
    exit 1
fi

# Files to exclude (require API credentials)
EXCLUDED_FILES=(
    "AccountVC.swift"
    "AccountNC.swift"
    "LoginVC.swift"
    "RegisterVC.swift"
    "PeopleVC.swift"
    "ItemVC.swift"
)

echo "=== EXCLUDED FILES (require API key) ==="
EXCLUDED_TOTAL=0
EXCLUDED_COVERED=0
for file in "${EXCLUDED_FILES[@]}"; do
    FILE_LINE=$(echo "$FULL_REPORT" | grep "$file" | head -1)
    if [ -n "$FILE_LINE" ]; then
        FILE_TOTAL=$(echo "$FILE_LINE" | grep -oE '\([0-9]+/[0-9]+\)' | grep -oE '[0-9]+/[0-9]+' | cut -d'/' -f2)
        FILE_COVERED=$(echo "$FILE_LINE" | grep -oE '\([0-9]+/[0-9]+\)' | grep -oE '[0-9]+/[0-9]+' | cut -d'/' -f1)
        # Default to 0 if extraction failed
        FILE_TOTAL=${FILE_TOTAL:-0}
        FILE_COVERED=${FILE_COVERED:-0}
        echo "  $file: $FILE_COVERED/$FILE_TOTAL lines"
        EXCLUDED_TOTAL=$((EXCLUDED_TOTAL + FILE_TOTAL))
        EXCLUDED_COVERED=$((EXCLUDED_COVERED + FILE_COVERED))
    fi
done
echo ""
echo "Total excluded: $EXCLUDED_COVERED/$EXCLUDED_TOTAL lines"
echo ""

# Calculate adjusted coverage
ADJUSTED_TOTAL=$((TOTAL_LINES - EXCLUDED_TOTAL))
ADJUSTED_COVERED=$((COVERED_LINES - EXCLUDED_COVERED))

# Validate adjusted total to avoid division by zero
if [ "$ADJUSTED_TOTAL" -le 0 ]; then
    echo "Error: No lines remaining after exclusions (ADJUSTED_TOTAL=$ADJUSTED_TOTAL)"
    exit 1
fi

ADJUSTED_PERCENTAGE=$(echo "scale=2; $ADJUSTED_COVERED * 100 / $ADJUSTED_TOTAL" | bc -l)

echo "=== ADJUSTED COVERAGE ==="
echo "Total lines (excluding API-dependent files): $ADJUSTED_TOTAL"
echo "Covered lines (excluding API-dependent files): $ADJUSTED_COVERED"
echo "Adjusted coverage: $ADJUSTED_PERCENTAGE%"
echo ""

# Provide recommendation
if (( $(echo "$ADJUSTED_PERCENTAGE >= 70" | bc -l) )); then
    echo "✅ Coverage target of 70% ACHIEVED (adjusted for API-dependent files)"
else
    NEEDED=$(echo "scale=0; ($ADJUSTED_TOTAL * 70 / 100) - $ADJUSTED_COVERED" | bc -l)
    echo "❌ Coverage target of 70% not yet achieved."
    echo "   Need approximately $NEEDED more lines covered."
fi
