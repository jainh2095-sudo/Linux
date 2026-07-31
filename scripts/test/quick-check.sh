#!/bin/bash

# Lightning Linux - Quick Issue Checker
# Fast check for critical issues
# Part of HarshitOS / Lightning Linux project

print_section() {
    echo ""
    echo "=== $1 ==="
    echo ""
}

PASS=0
WARN=0
FAIL=0

echo "Lightning Linux - Quick Issue Check"
echo "===================================="

# 1. Check project structure
print_section "1. Project Structure"

for dir in scripts scripts/build scripts/config config packages packages/base packages/security packages/desktop docs build; do
    if [ -d "$dir" ]; then
        echo "✓ Directory exists: $dir"
        ((PASS++))
    else
        echo "✗ Directory missing: $dir"
        ((FAIL++))
    fi
done

# 2. Check required files
print_section "2. Required Files"

for file in BUILD_NOW.sh QUICK_START.md IMPORTANT.md README.md LICENSE BUILD_GUIDE.md config/build.conf; do
    if [ -f "$file" ]; then
        echo "✓ File exists: $file"
        ((PASS++))
    else
        echo "✗ File missing: $file"
        ((FAIL++))
    fi
done

# 3. Check script syntax
print_section "3. Script Syntax"

for script in BUILD_NOW.sh scripts/build/*.sh scripts/config/*.sh; do
    if [ -f "$script" ]; then
        if bash -n "$script" 2>/dev/null; then
            echo "✓ Syntax OK: $(basename $script)"
            ((PASS++))
        else
            echo "✗ Syntax error: $(basename $script)"
            ((FAIL++))
        fi
    fi
done

# 4. Check for hardcoded paths
print_section "4. Hardcoded Paths"

HARDCODED=$(grep -r "/workspace/jainh2095-sudo" scripts/ config/ 2>/dev/null | wc -l)
if [ "$HARDCODED" -eq 0 ]; then
    echo "✓ No hardcoded paths found"
    ((PASS++))
else
    echo "⚠ $HARDCODED hardcoded paths found"
    ((WARN++))
fi

# 5. Check for debootstrap error handling
print_section "5. Critical Error Handling"

if grep -q "if ! debootstrap" BUILD_NOW.sh; then
    echo "✓ debootstrap has error handling"
    ((PASS++))
else
    echo "⚠ debootstrap missing error handling"
    ((WARN++))
fi

# 6. Check space requirement
print_section "6. Space Check"

if grep -q "10000000" BUILD_NOW.sh; then
    echo "⚠ Space check may be too low (10GB)"
    ((WARN++))
else
    echo "✓ Space check looks good"
    ((PASS++))
fi

# 7. Check for timeout handling
print_section "7. Timeout Handling"

if grep -q "timeout" BUILD_NOW.sh; then
    echo "✓ Timeout handling present"
    ((PASS++))
else
    echo "⚠ No timeout handling for long operations"
    ((WARN++))
fi

# 8. Check EFI support
print_section "8. EFI Boot Support"

if grep -q "EFI" scripts/build/create-live-system.sh; then
    echo "✓ EFI support detected"
    ((PASS++))
else
    echo "⚠ EFI support may be missing"
    ((WARN++))
fi

# 9. Check Windows instructions
print_section "9. Windows Compatibility"

if grep -qi "windows" IMPORTANT.md; then
    echo "✓ Windows instructions present"
    ((PASS++))
else
    echo "⚠ Windows instructions missing"
    ((WARN++))
fi

# 10. Check configuration
print_section "10. Configuration"

for var in LIBC_IMPLEMENTATION KERNEL_PATCHES OUTPUT_DIR; do
    if grep -q "$var" config/build.conf; then
        echo "✓ $var defined"
        ((PASS++))
    else
        echo "⚠ $var not defined"
        ((WARN++))
    fi
done

# Summary
echo ""
echo "===================================="
echo "SUMMARY"
echo "===================================="
echo "Passed: $PASS"
echo "Warnings: $WARN"
echo "Failed: $FAIL"
echo ""

TOTAL=$((PASS + WARN + FAIL))
if [ $TOTAL -gt 0 ]; then
    SCORE=$((PASS * 100 / TOTAL))
    echo "Score: $SCORE%"
fi

echo ""

if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
    echo "✅ All checks passed!"
    exit 0
elif [ $FAIL -eq 0 ]; then
    echo "⚠️  Some warnings found. Review BUGS_AND_ISSUES.md"
    exit 0
else
    echo "❌ Some checks failed. Fix these issues first."
    exit 1
fi
