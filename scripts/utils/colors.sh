#!/bin/bash

# ===================================================================
# 🎨 Color and Formatting Utilities
# ===================================================================

# Color codes
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export GRAY='\033[0;90m'
export NC='\033[0m' # No Color

# Text formatting
export BOLD='\033[1m'
export DIM='\033[2m'
export UNDERLINE='\033[4m'
export BLINK='\033[5m'
export REVERSE='\033[7m'
export RESET='\033[0m'

# Symbols
export CHECKMARK="✅"
export WARNING="⚠️"
export ERROR="❌"
export INFO="ℹ️"
export ROCKET="🚀"
export MAGIC="🪄"
export SPARKLES="✨"
export GEAR="⚙️"
export CONTAINER="🐳"
export DATABASE="🗄️"
export NETWORK="🌐"
export KEY="🔑"
export SHIELD="🔒"
export SEARCH="🔍"
export CLOCK="⏰"
export PARTY="🎉"

# Utility functions
print_banner() {
    local text="$1"
    local width=80
    local padding=$(( (width - ${#text}) / 2 ))
    
    echo -e "${PURPLE}"
    printf "╔"
    printf "%*s" $((width-2)) | tr ' ' '═'
    printf "╗\n"
    
    printf "║"
    printf "%*s" $padding ""
    printf "%s" "$text"
    printf "%*s" $((width - padding - ${#text} - 2)) ""
    printf "║\n"
    
    printf "╚"
    printf "%*s" $((width-2)) | tr ' ' '═'
    printf "╝\n"
    echo -e "${NC}"
}

print_section() {
    local title="$1"
    echo ""
    echo -e "${CYAN}${title}${NC}"
    printf "${CYAN}%*s${NC}\n" ${#title} | tr ' ' '='
}

print_step() {
    local step="$1"
    local description="$2"
    echo -e "${BLUE}${step}${NC} ${description}"
}

print_status() {
    local message="$1"
    echo -e "${PURPLE}${MAGIC}${NC} ${message}"
}

print_success() {
    local message="$1"
    echo -e "${GREEN}${CHECKMARK}${NC} ${message}"
}

print_warning() {
    local message="$1"
    echo -e "${YELLOW}${WARNING}${NC} ${message}"
}

print_error() {
    local message="$1"
    echo -e "${RED}${ERROR}${NC} ${message}"
}

print_info() {
    local message="$1"
    echo -e "${CYAN}${INFO}${NC} ${message}"
}

print_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    local percent=$((current * 100 / total))
    local filled=$((percent / 5))
    local empty=$((20 - filled))
    
    printf "\r${BLUE}["
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%% %s${NC}" $percent "$message"
}

# Spinner animation
show_spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1
    local spinstr='|/-\'
    
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf "\r${PURPLE}%c${NC} %s" "$spinstr" "$message"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r${GREEN}${CHECKMARK}${NC} %s\n" "$message"
}

# Loading dots animation
show_loading() {
    local message="$1"
    local duration="$2"
    local dots=""
    
    for i in $(seq 1 $duration); do
        dots="${dots}."
        printf "\r${BLUE}${message}${dots}${NC}"
        sleep 1
        if [ ${#dots} -gt 3 ]; then
            dots=""
        fi
    done
    echo ""
}

# Box drawing
draw_box() {
    local text="$1"
    local width=$((${#text} + 4))
    
    echo -e "${CYAN}┌$(printf "%*s" $((width-2)) | tr ' ' '─')┐${NC}"
    echo -e "${CYAN}│${NC} ${text} ${CYAN}│${NC}"
    echo -e "${CYAN}└$(printf "%*s" $((width-2)) | tr ' ' '─')┘${NC}"
}

# Table header
print_table_header() {
    printf "${PURPLE}%-20s %-15s %-10s %-15s${NC}\n" "Service" "Status" "Port" "URL"
    printf "${PURPLE}%-20s %-15s %-10s %-15s${NC}\n" "$(printf "%20s" | tr ' ' '-')" "$(printf "%15s" | tr ' ' '-')" "$(printf "%10s" | tr ' ' '-')" "$(printf "%15s" | tr ' ' '-')"
}

# Table row
print_table_row() {
    local service="$1"
    local status="$2"
    local port="$3"
    local url="$4"
    local status_color=""
    
    case "$status" in
        "Running"|"✅"|"healthy")
            status_color="${GREEN}"
            ;;
        "Starting"|"⏳"|"pending")
            status_color="${YELLOW}"
            ;;
        "Failed"|"❌"|"error")
            status_color="${RED}"
            ;;
        *)
            status_color="${NC}"
            ;;
    esac
    
    printf "%-20s ${status_color}%-15s${NC} %-10s %-15s\n" "$service" "$status" "$port" "$url"
}

# Clear line
clear_line() {
    printf "\r\033[K"
}

# Move cursor up
cursor_up() {
    local lines="${1:-1}"
    printf "\033[${lines}A"
}

# Show automagik logo
show_automagik_logo() {
    echo -e "${PURPLE}"
    echo "     -+*         -=@%*@@@@@@*  -#@@@%*  =@@*      -%@#+   -*       +%@@@@*-%@*-@@*  -+@@*   "
    echo "     =@#*  -@@*  -=@%+@@@@@@*-%@@#%*%@@+=@@@*    -+@@#+  -@@*   -#@@%%@@@*-%@+-@@* -@@#*    "
    echo "    -%@@#* -@@*  -=@@* -@%* -@@**   --@@=@@@@*  -+@@@#+ -#@@%* -*@%*-@@@@*-%@+:@@+#@@*      "
    echo "   -#@+%@* -@@*  -=@@* -@%* -@@*-+@#*-%@+@@=@@* +@%#@#+ =@##@* -%@#*-@@@@*-%@+-@@@@@*       "
    echo "  -*@#==@@*-@@*  -+@%* -@%* -%@#*   -+@@=@@++@%-@@=*@#=-@@*-@@*:+@@*  -%@*-%@+-@@#*@@**     "
    echo "  -@@* -+@%-+@@@@@@@*  -@%*  -#@@@@%@@%+=@@+-=@@@*    -%@*  -@@*-*@@@@%@@*#@@#=%*  -%@@*    "
    echo " -@@*+  -%@*  -#@%+    -@%+     =#@@*   =@@+          +@%+  -#@#   -*%@@@*@@@@%+     =@@+   "
    echo -e "${NC}"
}