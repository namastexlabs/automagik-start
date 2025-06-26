#!/bin/bash

# ===================================================================
# 🔍 System Detection and Analysis
# ===================================================================

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/colors.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# System detection results
export OS_TYPE=""
export OS_NAME=""
export OS_VERSION=""
export ARCHITECTURE=""
export PACKAGE_MANAGER=""
export SHELL_TYPE=""
export PYTHON_VERSION=""
export NODE_VERSION=""
export DOCKER_VERSION=""
export AVAILABLE_RAM=""
export AVAILABLE_DISK=""
export CPU_CORES=""

# Detect operating system
detect_os() {
    log_info "Detecting operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        
        # Check for WSL
        if [ -f /proc/version ] && grep -q "Microsoft\|WSL" /proc/version; then
            OS_TYPE="wsl"
            OS_NAME="WSL"
            
            # WSL uses the same package manager as the underlying Linux distribution
            if [ -f /etc/os-release ]; then
                source /etc/os-release
                case "$ID" in
                    ubuntu|debian|pop|linuxmint)
                        PACKAGE_MANAGER="apt"
                        ;;
                    centos|rhel|fedora|rocky|almalinux)
                        PACKAGE_MANAGER="yum"
                        ;;
                    *)
                        PACKAGE_MANAGER="apt"  # Default to apt for WSL
                        ;;
                esac
            else
                PACKAGE_MANAGER="apt"  # Default to apt for WSL
            fi
            
            # Get Windows version info
            if command -v powershell.exe >/dev/null 2>&1; then
                OS_VERSION=$(powershell.exe -Command "Get-ComputerInfo | Select-Object WindowsProductName" 2>/dev/null | tail -n1 | tr -d '\r')
            else
                OS_VERSION="Windows Subsystem for Linux"
            fi
        elif [ -f /etc/os-release ]; then
            # Read OS information from os-release
            source /etc/os-release
            OS_NAME="$NAME"
            OS_VERSION="$VERSION"
            
            # Determine package manager based on distribution
            case "$ID" in
                ubuntu|debian|pop|linuxmint)
                    PACKAGE_MANAGER="apt"
                    ;;
                centos|rhel|fedora|rocky|almalinux)
                    PACKAGE_MANAGER="yum"
                    ;;
                arch|manjaro)
                    PACKAGE_MANAGER="pacman"
                    ;;
                opensuse*|suse)
                    PACKAGE_MANAGER="zypper"
                    ;;
                alpine)
                    PACKAGE_MANAGER="apk"
                    ;;
                *)
                    PACKAGE_MANAGER="unknown"
                    ;;
            esac
        else
            OS_NAME="Linux (Unknown Distribution)"
            OS_VERSION="Unknown"
            PACKAGE_MANAGER="unknown"
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        OS_NAME="macOS"
        OS_VERSION=$(sw_vers -productVersion 2>/dev/null)
        PACKAGE_MANAGER="brew"
        
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        OS_TYPE="freebsd"
        OS_NAME="FreeBSD"
        OS_VERSION=$(freebsd-version 2>/dev/null)
        PACKAGE_MANAGER="pkg"
        
    else
        OS_TYPE="unknown"
        OS_NAME="Unknown OS"
        OS_VERSION="Unknown"
        PACKAGE_MANAGER="unknown"
    fi
    
    log_success "OS detected: $OS_NAME $OS_VERSION ($OS_TYPE)"
}

# Detect system architecture
detect_architecture() {
    log_info "Detecting system architecture..."
    
    ARCHITECTURE=$(uname -m)
    
    # Normalize architecture names
    case "$ARCHITECTURE" in
        x86_64|amd64)
            ARCHITECTURE="x86_64"
            ;;
        aarch64|arm64)
            ARCHITECTURE="arm64"
            ;;
        armv7l|armv6l)
            ARCHITECTURE="arm"
            ;;
        i386|i686)
            ARCHITECTURE="i386"
            ;;
    esac
    
    log_success "Architecture: $ARCHITECTURE"
}

# Detect shell
detect_shell() {
    SHELL_TYPE=$(basename "$SHELL")
    log_info "Shell: $SHELL_TYPE"
}

# Check system resources
check_system_resources() {
    log_info "Checking system resources..."
    
    # CPU cores
    if command -v nproc >/dev/null 2>&1; then
        CPU_CORES=$(nproc)
    elif [ -f /proc/cpuinfo ]; then
        CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
    elif command -v sysctl >/dev/null 2>&1; then
        CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null)
    else
        CPU_CORES="unknown"
    fi
    
    # Available RAM (in GB)
    if [ -f /proc/meminfo ]; then
        local ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        AVAILABLE_RAM=$(echo "scale=1; $ram_kb/1024/1024" | bc 2>/dev/null || echo "unknown")
        AVAILABLE_RAM="${AVAILABLE_RAM}GB"
    elif command -v sysctl >/dev/null 2>&1; then
        local ram_bytes=$(sysctl -n hw.memsize 2>/dev/null)
        if [ -n "$ram_bytes" ]; then
            AVAILABLE_RAM=$(echo "scale=1; $ram_bytes/1024/1024/1024" | bc 2>/dev/null || echo "unknown")
            AVAILABLE_RAM="${AVAILABLE_RAM}GB"
        else
            AVAILABLE_RAM="unknown"
        fi
    else
        AVAILABLE_RAM="unknown"
    fi
    
    # Available disk space (in GB) for current directory
    if command -v df >/dev/null 2>&1; then
        local disk_kb=$(df . | tail -1 | awk '{print $4}')
        if [ -n "$disk_kb" ] && [ "$disk_kb" != "Avail" ]; then
            AVAILABLE_DISK=$(echo "scale=1; $disk_kb/1024/1024" | bc 2>/dev/null || echo "unknown")
            AVAILABLE_DISK="${AVAILABLE_DISK}GB"
        else
            AVAILABLE_DISK="unknown"
        fi
    else
        AVAILABLE_DISK="unknown"
    fi
    
    log_info "System resources: CPU: $CPU_CORES cores, RAM: $AVAILABLE_RAM, Disk: $AVAILABLE_DISK"
}

# Check installed software versions
check_software_versions() {
    log_info "Checking installed software versions..."
    
    # Python version
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    elif command -v python >/dev/null 2>&1; then
        PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2)
    else
        PYTHON_VERSION="not installed"
    fi
    
    # Node.js version
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version 2>/dev/null | sed 's/^v//')
    else
        NODE_VERSION="not installed"
    fi
    
    # Docker version
    if command -v docker >/dev/null 2>&1; then
        DOCKER_VERSION=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,$//')
    else
        DOCKER_VERSION="not installed"
    fi
    
    log_info "Software versions: Python: $PYTHON_VERSION, Node.js: $NODE_VERSION, Docker: $DOCKER_VERSION"
}

# Check package manager availability
check_package_manager() {
    log_info "Verifying package manager: $PACKAGE_MANAGER"
    
    case "$PACKAGE_MANAGER" in
        apt)
            if command -v apt >/dev/null 2>&1; then
                log_success "APT package manager available"
                return 0
            else
                log_error "APT not found"
                return 1
            fi
            ;;
        yum)
            if command -v yum >/dev/null 2>&1; then
                log_success "YUM package manager available"
                return 0
            elif command -v dnf >/dev/null 2>&1; then
                PACKAGE_MANAGER="dnf"
                log_success "DNF package manager available (using instead of YUM)"
                return 0
            else
                log_error "YUM/DNF not found"
                return 1
            fi
            ;;
        brew)
            if command -v brew >/dev/null 2>&1; then
                log_success "Homebrew package manager available"
                return 0
            else
                log_warning "Homebrew not found (will install if needed)"
                return 1
            fi
            ;;
        pacman)
            if command -v pacman >/dev/null 2>&1; then
                log_success "Pacman package manager available"
                return 0
            else
                log_error "Pacman not found"
                return 1
            fi
            ;;
        *)
            log_warning "Unknown or unsupported package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
}

# Check if running with sufficient privileges
check_privileges() {
    log_info "Checking user privileges..."
    
    local current_user=$(whoami)
    
    if [ "$current_user" = "root" ]; then
        log_warning "Running as root user (not recommended for development)"
        export USER_PRIVILEGES="root"
    elif groups "$current_user" 2>/dev/null | grep -q '\bsudo\b\|\bwheel\b\|\badmin\b'; then
        log_success "User has sudo privileges"
        export USER_PRIVILEGES="sudo"
    else
        log_warning "User may not have sudo privileges (some operations may fail)"
        export USER_PRIVILEGES="limited"
    fi
}

# Check network connectivity
check_network() {
    log_info "Checking network connectivity..."
    
    local test_hosts=("8.8.8.8" "1.1.1.1" "github.com")
    local connected=false
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 3 "$host" >/dev/null 2>&1; then
            connected=true
            break
        fi
    done
    
    if [ "$connected" = true ]; then
        log_success "Network connectivity confirmed"
        export NETWORK_AVAILABLE=true
    else
        log_warning "Network connectivity issues detected"
        export NETWORK_AVAILABLE=false
    fi
}

# Check for virtualization environment
check_virtualization() {
    log_info "Checking virtualization environment..."
    
    local virt_type="none"
    
    # Check for common virtualization indicators
    if [ -f /proc/cpuinfo ] && grep -q "hypervisor" /proc/cpuinfo; then
        virt_type="vm"
    elif [ -d /proc/vz ]; then
        virt_type="openvz"
    elif [ -f /proc/xen/capabilities ]; then
        virt_type="xen"
    elif [ "$OS_TYPE" = "wsl" ]; then
        virt_type="wsl"
    elif command -v systemd-detect-virt >/dev/null 2>&1; then
        local detected=$(systemd-detect-virt 2>/dev/null)
        if [ "$detected" != "none" ]; then
            virt_type="$detected"
        fi
    elif command -v dmesg >/dev/null 2>&1; then
        if dmesg 2>/dev/null | grep -qi "virtualbox\|vmware\|kvm\|qemu\|xen"; then
            virt_type="vm"
        fi
    fi
    
    export VIRTUALIZATION_TYPE="$virt_type"
    
    if [ "$virt_type" != "none" ]; then
        log_info "Virtualization detected: $virt_type"
    else
        log_info "No virtualization detected (bare metal)"
    fi
}

# Generate system compatibility report
generate_compatibility_report() {
    log_section "System Compatibility Analysis"
    
    local compatible=true
    local warnings=()
    local errors=()
    
    # Check minimum requirements
    
    # Architecture compatibility
    case "$ARCHITECTURE" in
        x86_64|arm64)
            log_success "Architecture $ARCHITECTURE is supported"
            ;;
        *)
            log_warning "Architecture $ARCHITECTURE may have limited support"
            warnings+=("Unsupported architecture: $ARCHITECTURE")
            ;;
    esac
    
    # OS compatibility
    case "$OS_TYPE" in
        linux|macos|wsl)
            log_success "Operating system $OS_TYPE is supported"
            ;;
        *)
            log_error "Operating system $OS_TYPE is not supported"
            errors+=("Unsupported OS: $OS_TYPE")
            compatible=false
            ;;
    esac
    
    # Package manager compatibility
    case "$PACKAGE_MANAGER" in
        apt|brew|yum|dnf)
            log_success "Package manager $PACKAGE_MANAGER is supported"
            ;;
        *)
            log_error "Package manager $PACKAGE_MANAGER is not supported"
            errors+=("Unsupported package manager: $PACKAGE_MANAGER")
            compatible=false
            ;;
    esac
    
    # Resource requirements
    if [ "$AVAILABLE_RAM" != "unknown" ]; then
        local ram_gb=$(echo "$AVAILABLE_RAM" | sed 's/GB//')
        if [ "$(echo "$ram_gb >= 4" | bc 2>/dev/null)" = "1" ]; then
            log_success "RAM requirement met: $AVAILABLE_RAM"
        else
            log_warning "Low RAM detected: $AVAILABLE_RAM (minimum 4GB recommended)"
            warnings+=("Low RAM: $AVAILABLE_RAM")
        fi
    fi
    
    if [ "$AVAILABLE_DISK" != "unknown" ]; then
        local disk_gb=$(echo "$AVAILABLE_DISK" | sed 's/GB//')
        if [ "$(echo "$disk_gb >= 10" | bc 2>/dev/null)" = "1" ]; then
            log_success "Disk space requirement met: $AVAILABLE_DISK"
        else
            log_warning "Low disk space: $AVAILABLE_DISK (minimum 10GB recommended)"
            warnings+=("Low disk space: $AVAILABLE_DISK")
        fi
    fi
    
    # Network requirement
    if [ "$NETWORK_AVAILABLE" = false ]; then
        log_error "Network connectivity required for installation"
        errors+=("No network connectivity")
        compatible=false
    fi
    
    # Export compatibility results
    export SYSTEM_COMPATIBLE="$compatible"
    export COMPATIBILITY_WARNINGS=("${warnings[@]}")
    export COMPATIBILITY_ERRORS=("${errors[@]}")
    
    # Print summary
    echo ""
    if [ "$compatible" = true ]; then
        if [ ${#warnings[@]} -gt 0 ]; then
            log_warning "System is compatible with warnings"
        else
            log_success "System is fully compatible"
        fi
    else
        log_error "System compatibility issues detected"
    fi
    
    return $([ "$compatible" = true ])
}

# Display system information
display_system_info() {
    print_section "SYSTEM ANALYSIS"
    
    print_table_header
    print_table_row "Operating System" "$OS_NAME $OS_VERSION" "-" "-"
    print_table_row "Architecture" "$ARCHITECTURE" "-" "-"
    print_table_row "Package Manager" "$PACKAGE_MANAGER" "-" "-"
    print_table_row "CPU Cores" "$CPU_CORES" "-" "-"
    print_table_row "Available RAM" "$AVAILABLE_RAM" "-" "-"
    print_table_row "Available Disk" "$AVAILABLE_DISK" "-" "-"
    print_table_row "Python" "$PYTHON_VERSION" "-" "-"
    print_table_row "Node.js" "$NODE_VERSION" "-" "-"
    print_table_row "Docker" "$DOCKER_VERSION" "-" "-"
    
    if [ "$VIRTUALIZATION_TYPE" != "none" ]; then
        print_table_row "Virtualization" "$VIRTUALIZATION_TYPE" "-" "-"
    fi
    
    echo ""
}

# Export all detected information
export_system_info() {
    {
        echo "# Automagik Suite System Detection Results"
        echo "# Generated on $(date)"
        echo ""
        echo "export OS_TYPE='$OS_TYPE'"
        echo "export OS_NAME='$OS_NAME'"
        echo "export OS_VERSION='$OS_VERSION'"
        echo "export ARCHITECTURE='$ARCHITECTURE'"
        echo "export PACKAGE_MANAGER='$PACKAGE_MANAGER'"
        echo "export SHELL_TYPE='$SHELL_TYPE'"
        echo "export PYTHON_VERSION='$PYTHON_VERSION'"
        echo "export NODE_VERSION='$NODE_VERSION'"
        echo "export DOCKER_VERSION='$DOCKER_VERSION'"
        echo "export AVAILABLE_RAM='$AVAILABLE_RAM'"
        echo "export AVAILABLE_DISK='$AVAILABLE_DISK'"
        echo "export CPU_CORES='$CPU_CORES'"
        echo "export VIRTUALIZATION_TYPE='$VIRTUALIZATION_TYPE'"
        echo "export USER_PRIVILEGES='$USER_PRIVILEGES'"
        echo "export NETWORK_AVAILABLE='$NETWORK_AVAILABLE'"
        echo "export SYSTEM_COMPATIBLE='$SYSTEM_COMPATIBLE'"
    } > "system-info.env"
    
    log_info "System information exported to system-info.env"
}

# Main detection function
detect_system() {
    log_section "System Detection"
    
    detect_os
    detect_architecture
    detect_shell
    check_system_resources
    check_software_versions
    check_package_manager
    check_privileges
    check_network
    check_virtualization
    
    display_system_info
    generate_compatibility_report
    export_system_info
    
    return $?
}

# Main function when script is run directly
main() {
    case "${1:-detect}" in
        "detect"|"")
            detect_system
            ;;
        "info")
            display_system_info
            ;;
        "export")
            export_system_info
            ;;
        "test")
            # Test specific detection functions
            case "$2" in
                "os") detect_os ;;
                "arch") detect_architecture ;;
                "resources") check_system_resources ;;
                "software") check_software_versions ;;
                "network") check_network ;;
                *) echo "Usage: $0 test {os|arch|resources|software|network}" ;;
            esac
            ;;
        *)
            echo "Usage: $0 {detect|info|export|test}"
            echo "  detect  - Run full system detection (default)"
            echo "  info    - Display system information"
            echo "  export  - Export system info to file"
            echo "  test    - Test specific detection functions"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi