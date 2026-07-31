#!/bin/bash

# Lightning Linux - Issue Checker
# Automatically checks for known bugs and issues
# Part of HarshitOS / Lightning Linux project

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Counters
PASS=0
WARN=0
FAIL=0

# Function to check file exists
check_file() {
    if [ -f "$1" ]; then
        print_success "File exists: $1"
        ((PASS++))
        return 0
    else
        print_error "File missing: $1"
        ((FAIL++))
        return 1
    fi
}

# Function to check directory exists
check_dir() {
    if [ -d "$1" ]; then
        print_success "Directory exists: $1"
        ((PASS++))
        return 0
    else
        print_error "Directory missing: $1"
        ((FAIL++))
        return 1
    fi
}

# Function to check command exists
check_command() {
    if command -v "$1" &>/dev/null; then
        print_success "Command available: $1"
        ((PASS++))
        return 0
    else
        print_warning "Command missing: $1 (may be needed for build)"
        ((WARN++))
        return 1
    fi
}

# Function to check script syntax
check_syntax() {
    local file="$1"
    if bash -n "$file" 2>/dev/null; then
        print_success "Syntax OK: $file"
        ((PASS++))
        return 0
    else
        print_error "Syntax error in: $file"
        ((FAIL++))
        return 1
    fi
}

# Function to check for hardcoded paths
check_hardcoded_paths() {
    local file="$1"
    local hardcoded=$(grep -n "/workspace/jainh2095-sudo" "$file" 2>/dev/null || echo "")
    
    if [ -z "$hardcoded" ]; then
        print_success "No hardcoded paths in: $file"
        ((PASS++))
        return 0
    else
        print_warning "Hardcoded paths found in: $file"
        echo "$hardcoded" | while read line; do
            print_warning "  Line $line"
        done
        ((WARN++))
        return 1
    fi
}

# Function to check for missing variables
check_missing_vars() {
    local file="$1"
    # Look for $VAR without ${VAR:-default} or declaration
    local missing=$(grep -n '\$[A-Za-z_][A-Za-z0-9_]*\b' "$file" | grep -v '\${\|\$0\|\$1\|\$2\|\$3\|\$#\|\$@\|\$*\|\$?\|\$!\|\$\$\|\$-\|#' || echo "")
    
    if [ -z "$missing" ]; then
        print_success "No potential missing variables in: $file"
        ((PASS++))
        return 0
    else
        print_warning "Potential missing variables in: $file"
        # This is just a warning, not necessarily an error
        ((WARN++))
        return 1
    fi
}

# Function to check for sudo without proper checks
check_sudo_usage() {
    local file="$1"
    local sudo_lines=$(grep -n "sudo " "$file" | grep -v "sudo apt\|sudo chroot\|sudo rm\|sudo mkdir\|sudo cp\|sudo mv\|sudo chmod\|sudo chown\|sudo mount\|sudo umount" || echo "")
    
    if [ -z "$sudo_lines" ]; then
        print_success "Sudo usage looks safe in: $file"
        ((PASS++))
        return 0
    else
        print_warning "Potential unsafe sudo usage in: $file"
        echo "$sudo_lines" | while read line; do
            print_warning "  Line $line"
        done
        ((WARN++))
        return 1
    fi
}

# Function to check for rm -rf without proper checks
check_rm_usage() {
    local file="$1"
    local rm_lines=$(grep -n "rm -rf" "$file" | grep -v "rm -rf \"\$WORK_DIR\|rm -rf \$WORK_DIR\|rm -rf build\|rm -rf tmp" || echo "")
    
    if [ -z "$rm_lines" ]; then
        print_success "rm -rf usage looks safe in: $file"
        ((PASS++))
        return 0
    else
        print_warning "Potential unsafe rm -rf usage in: $file"
        echo "$rm_lines" | while read line; do
            print_warning "  Line $line"
        done
        ((WARN++))
        return 1
    fi
}

# Main checks
print_header "Lightning Linux - Issue Checker"
print_status "Starting comprehensive issue check..."
print_status ""

# 1. Check project structure
print_header "1. Project Structure Check"

check_dir "scripts"
check_dir "scripts/build"
check_dir "scripts/config"
check_dir "config"
check_dir "packages"
check_dir "packages/base"
check_dir "packages/security"
check_dir "packages/desktop"
check_dir "docs"
check_dir "build"

print_status ""

# 2. Check required files
print_header "2. Required Files Check"

check_file "BUILD_NOW.sh"
check_file "QUICK_START.md"
check_file "IMPORTANT.md"
check_file "README.md"
check_file "LICENSE"
check_file "BUILD_GUIDE.md"
check_file "config/build.conf"
check_file "scripts/build/build-iso.sh"
check_file "scripts/build/create-live-system.sh"
check_file "scripts/build/install-dependencies.sh"
check_file "scripts/config/configure-build.sh"
check_file "packages/base/base-packages.txt"
check_file "packages/security/security-tools.txt"
check_file "packages/desktop/xfce4-packages.txt"

print_status ""

# 3. Check script syntax
print_header "3. Script Syntax Check"

for script in BUILD_NOW.sh scripts/build/*.sh scripts/config/*.sh; do
    if [ -f "$script" ]; then
        check_syntax "$script"
    fi
done

print_status ""

# 4. Check for hardcoded paths
print_header "4. Hardcoded Paths Check"

for script in BUILD_NOW.sh scripts/build/*.sh scripts/config/*.sh; do
    if [ -f "$script" ]; then
        check_hardcoded_paths "$script"
    fi
done

print_status ""

# 5. Check for missing variables
print_header "5. Missing Variables Check"

for script in BUILD_NOW.sh scripts/build/*.sh scripts/config/*.sh; do
    if [ -f "$script" ]; then
        check_missing_vars "$script"
    fi
done

print_status ""

# 6. Check sudo usage
print_header "6. Sudo Usage Check"

for script in BUILD_NOW.sh scripts/build/*.sh scripts/config/*.sh; do
    if [ -f "$script" ]; then
        check_sudo_usage "$script"
    fi
done

print_status ""

# 7. Check rm usage
print_header "7. rm -rf Usage Check"

for script in BUILD_NOW.sh scripts/build/*.sh scripts/config/*.sh; do
    if [ -f "$script" ]; then
        check_rm_usage "$script"
    fi
done

print_status ""

# 8. Check for common issues in BUILD_NOW.sh
print_header "8. BUILD_NOW.sh Specific Checks"

# Check for debootstrap error handling
if grep -q "debootstrap" BUILD_NOW.sh; then
    if grep -q "if ! debootstrap" BUILD_NOW.sh; then
        print_success "debootstrap has error handling"
        ((PASS++))
    else
        print_warning "debootstrap missing error handling"
        ((WARN++))
    fi
fi

# Check space requirement
if grep -q "10000000" BUILD_NOW.sh; then
    print_warning "Space check may be too low (10GB)"
    ((WARN++))
fi

# Check for timeout
if grep -q "timeout" BUILD_NOW.sh; then
    print_success "Timeout handling present"
    ((PASS++))
else
    print_warning "No timeout handling for long operations"
    ((WARN++))
fi

print_status ""

# 9. Check for EFI support
print_header "9. EFI Boot Support Check"

if grep -q "EFI" scripts/build/create-live-system.sh; then
    print_success "EFI support detected"
    ((PASS++))
else
    print_warning "EFI support may be missing"
    ((WARN++))
fi

print_status ""

# 10. Check package lists
print_header "10. Package Lists Check"

# Check if packages exist in Ubuntu Focal
for pkg_list in packages/base/base-packages.txt packages/security/security-tools.txt packages/desktop/xfce4-packages.txt; do
    if [ -f "$pkg_list" ]; then
        print_status "Checking $pkg_list..."
        local_count=0
        remote_count=0
        
        while read pkg; do
            # Skip comments and empty lines
            if [[ "$pkg" =~ ^# ]] || [[ -z "$pkg" ]]; then
                continue
            fi
            
            ((local_count++))
            
            # Try to check if package exists (only works on Ubuntu/Debian)
            if command -v apt-cache &>/dev/null; then
                if apt-cache show "$pkg" &>/dev/null; then
                    ((remote_count++))
                else
                    print_warning "Package may not exist: $pkg (in $pkg_list)"
                    ((WARN++))
                fi
            fi
        done < "$pkg_list"
        
        print_success "Found $remote_count/$local_count packages in $pkg_list"
        ((PASS++))
    fi
done

print_status ""

# 11. Check configuration file
print_header "11. Configuration File Check"

if [ -f "config/build.conf" ]; then
    # Check for missing values
    if grep -q "LIBC_IMPLEMENTATION" config/build.conf; then
        print_success "LIBC_IMPLEMENTATION defined"
        ((PASS++))
    else
        print_warning "LIBC_IMPLEMENTATION not defined"
        ((WARN++))
    fi
    
    if grep -q "KERNEL_PATCHES" config/build.conf; then
        print_success "KERNEL_PATCHES defined"
        ((PASS++))
    else
        print_warning "KERNEL_PATCHES not defined"
        ((WARN++))
    fi
    
    if grep -q "OUTPUT_DIR" config/build.conf; then
        print_success "OUTPUT_DIR defined"
        ((PASS++))
    else
        print_warning "OUTPUT_DIR not defined"
        ((WARN++))
    fi
fi

print_status ""

# 12. Check for Windows compatibility
print_header "12. Windows Compatibility Check"

if grep -q -i "windows" IMPORTANT.md; then
    print_success "Windows instructions present in IMPORTANT.md"
    ((PASS++))
else
    print_warning "Windows instructions may be missing"
    ((WARN++))
fi

if grep -q -i "wsl" IMPORTANT.md; then
    print_success "WSL instructions present in IMPORTANT.md"
    ((PASS++))
else
    print_warning "WSL instructions may be missing"
    ((WARN++))
fi

print_status ""

# Final summary
print_header "SUMMARY"
print_status ""
print_status "Results:"
print_status "  Passed: $PASS"
print_status "  Warnings: $WARN"
print_status "  Failed: $FAIL"
print_status ""

TOTAL=$((PASS + WARN + FAIL))
SCORE=$((PASS * 100 / TOTAL))

print_status "Score: $SCORE%"
print_status ""

if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
    print_success "✅ All checks passed!"
    exit 0
elif [ $FAIL -eq 0 ]; then
    print_warning "⚠️  Some warnings found. Review and fix if needed."
    exit 0
else
    print_error "❌ Some checks failed. Fix these issues before release."
    exit 1
fi
