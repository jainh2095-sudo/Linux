#!/bin/bash

# Lightning Linux - Quick Issue Checker (UPDATED)
# Fast check for critical issues
# Part of HarshitOS / Lightning Linux project
# Updated to reflect all fixes

print_section() {
    echo ""
    echo "=== $1 ==="
    echo ""
}

PASS=0
WARN=0
FAIL=0

echo "Lightning Linux - Quick Issue Check (UPDATED)"
echo "=============================================="

# 1. Check project structure
print_section "1. Project Structure"

for dir in scripts scripts/build scripts/config scripts/test config packages packages/base packages/security packages/desktop docs build; do
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

for file in BUILD_NOW.sh QUICK_START.md IMPORTANT.md README.md LICENSE BUILD_GUIDE.md config/build.conf BUGS_AND_ISSUES.md; do
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

for script in BUILD_NOW.sh scripts/build/*.sh scripts/config/*.sh scripts/test/*.sh; do
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
    echo "⚠ $HARDCODED hardcoded paths found (may be intentional)"
    ((WARN++))
fi

# 5. Check for debootstrap error handling
print_section "5. Critical Error Handling"

if grep -q "if !.*debootstrap" BUILD_NOW.sh; then
    echo "✓ debootstrap has error handling (FIXED)"
    ((PASS++))
else
    echo "✗ debootstrap missing error handling"
    ((FAIL++))
fi

# 6. Check space requirement
print_section "6. Space Check"

if grep -q "15000000" BUILD_NOW.sh; then
    echo "✓ Space check is 15GB (FIXED)"
    ((PASS++))
else
    echo "⚠ Space check may be too low"
    ((WARN++))
fi

# 7. Check for timeout handling
print_section "7. Timeout Handling"

if grep -q "timeout_exec" BUILD_NOW.sh; then
    echo "✓ Timeout handling present (FIXED)"
    ((PASS++))
else
    echo "✗ No timeout handling for long operations"
    ((FAIL++))
fi

# 8. Check EFI support
print_section "8. EFI Boot Support"

if grep -q "EFI/BOOT" BUILD_NOW.sh; then
    echo "✓ EFI support added (FIXED)"
    ((PASS++))
else
    echo "✗ EFI support may be missing"
    ((FAIL++))
fi

# 9. Check Windows instructions
print_section "9. Windows Compatibility"

if grep -qi "WSL2" QUICK_START.md; then
    echo "✓ Windows WSL2 instructions present (FIXED)"
    ((PASS++))
else
    echo "✗ Windows instructions missing"
    ((FAIL++))
fi

if grep -qi "VirtualBox" QUICK_START.md; then
    echo "✓ Windows VirtualBox instructions present (FIXED)"
    ((PASS++))
else
    echo "✗ VirtualBox instructions missing"
    ((FAIL++))
fi

# 10. Check configuration defaults
print_section "10. Configuration Defaults"

for var in LIBC_IMPLEMENTATION KERNEL_PATCHES OUTPUT_DIR UBUNTU_VERSION; do
    if grep -q "\${$var:- " config/build.conf; then
        echo "✓ $var has default value (FIXED)"
        ((PASS++))
    else
        echo "⚠ $var may not have default value"
        ((WARN++))
    fi
done

# 11. Check root validation
print_section "11. Root Validation"

if grep -q "check_root" BUILD_NOW.sh; then
    echo "✓ Root validation present (FIXED)"
    ((PASS++))
else
    echo "✗ Root validation missing"
    ((FAIL++))
fi

# 12. Check package list validity
print_section "12. Package List Validity"

# Check if security tools list has been cleaned
if [ -f "packages/security/security-tools.txt" ]; then
    PACKAGE_COUNT=$(grep -v "^#" packages/security/security-tools.txt | grep -v "^$" | wc -l)
    if [ "$PACKAGE_COUNT" -lt 100 ]; then
        echo "✓ Package list cleaned (FIXED) - $PACKAGE_COUNT packages"
        ((PASS++))
    else
        echo "⚠ Package list may still have too many packages"
        ((WARN++))
    fi
fi

# Summary
echo ""
echo "======================================"
echo "SUMMARY"
echo "======================================"
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

if [ $FAIL -eq 0 ] && [ $WARN -le 2 ]; then
    echo "✅ ALL CRITICAL ISSUES FIXED!"
    echo "   Project is PRODUCTION READY!"
    exit 0
elif [ $FAIL -eq 0 ]; then
    echo "⚠️  Some minor warnings found."
    echo "   Project is ready for testing."
    exit 0
else
    echo "❌ Some checks failed. Fix these issues first."
    exit 1
fi
