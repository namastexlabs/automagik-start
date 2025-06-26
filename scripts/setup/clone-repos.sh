#!/bin/bash

# ===================================================================
# 📁 Repository Cloning Automation
# ===================================================================

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/colors.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Repository definitions
declare -A REPOSITORIES=(
    ["am-agents-labs"]="https://github.com/namastexlabs/am-agents-labs.git"
    ["automagik-ui-v2"]="https://github.com/namastexlabs/automagik-ui-v2.git"
    ["automagik-omni"]="https://github.com/namastexlabs/automagik-omni.git"
    ["automagik-spark"]="https://github.com/namastexlabs/automagik-spark.git"
    ["automagik-tools"]="https://github.com/namastexlabs/automagik-tools.git"
    ["automagik-evolution"]="https://github.com/namastexlabs/automagik-evolution.git"
)

# Branch settings (empty means default branch)
declare -A REPOSITORY_BRANCHES=(
    ["am-agents-labs"]=""  # Will be set by user selection
    ["automagik-ui-v2"]=""
    ["automagik-omni"]=""
    ["automagik-spark"]=""
    ["automagik-tools"]=""
    ["automagik-evolution"]=""
)

# Repository order for cloning (dependency-based)
CLONE_ORDER=(
    "am-agents-labs"
    "automagik-spark"
    "automagik-tools"
    "automagik-evolution"
    "automagik-omni"
    "automagik-ui-v2"
)

# Base directory for cloning
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPOS_DIR="$BASE_DIR"

# Git configuration
GIT_TIMEOUT=300  # 5 minutes per repository
GIT_DEPTH=1      # Shallow clone for faster cloning

# Check if git is available
check_git() {
    log_info "Checking Git availability..."
    
    if ! command -v git >/dev/null 2>&1; then
        log_error "Git is not installed"
        log_info "Please install Git first using your system's package manager"
        return 1
    fi
    
    local git_version=$(git --version 2>/dev/null | cut -d' ' -f3)
    log_success "Git $git_version is available"
    return 0
}

# Check network connectivity
check_network_connectivity() {
    log_info "Checking network connectivity..."
    
    if ! ping -c 1 -W 3 github.com >/dev/null 2>&1; then
        log_error "Cannot reach GitHub (network connectivity issue)"
        log_info "Please check your internet connection"
        return 1
    fi
    
    log_success "Network connectivity confirmed"
    return 0
}

# Get available branches for a repository
get_repo_branches() {
    local repo_url="$1"
    
    git ls-remote --heads "$repo_url" 2>/dev/null | \
        sed 's/.*refs\/heads\///' | \
        sort
}

# Select branch for am-agents-labs
select_agents_branch() {
    local repo_url="${REPOSITORIES[am-agents-labs]}"
    
    log_section "Branch Selection for am-agents-labs"
    log_info "This allows deploying specific agent configurations"
    
    # Check if GitHub CLI is available for better branch fetching
    if ! command -v gh >/dev/null 2>&1; then
        log_warning "GitHub CLI not available - using default branch (main)"
        REPOSITORY_BRANCHES["am-agents-labs"]=""
        return 0
    fi
    
    # Get available branches using GitHub CLI (more reliable)
    log_info "Fetching available branches..."
    local branches=()
    
    # First try GitHub CLI with authentication check
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        log_info "Using GitHub CLI to fetch branches..."
        # Try to get branches via GitHub API
        if gh repo view namastexlabs/am-agents-labs >/dev/null 2>&1; then
            branches=($(gh api repos/namastexlabs/am-agents-labs/branches --jq '.[].name' 2>/dev/null | sort))
            if [ ${#branches[@]} -gt 0 ]; then
                log_success "Fetched ${#branches[@]} branches via GitHub CLI"
            fi
        fi
    fi
    
    # Fallback to git ls-remote if GitHub CLI fails or no branches found
    if [ ${#branches[@]} -eq 0 ]; then
        log_info "Fallback: using git ls-remote to fetch branches..."
        # Ensure we can reach the repository
        if git ls-remote --heads "$repo_url" >/dev/null 2>&1; then
            branches=($(get_repo_branches "$repo_url"))
            if [ ${#branches[@]} -gt 0 ]; then
                log_success "Fetched ${#branches[@]} branches via git ls-remote"
            fi
        else
            log_error "Cannot access repository: $repo_url"
        fi
    fi
    
    if [ ${#branches[@]} -eq 0 ]; then
        log_warning "Could not fetch branches for am-agents-labs"
        log_info "Using default branch (main)"
        REPOSITORY_BRANCHES["am-agents-labs"]=""
        return 0
    fi
    
    # Show available branches
    echo -e "${CYAN}Available branches for am-agents-labs:${NC}"
    echo "0) main (default)"
    
    local i=1
    for branch in "${branches[@]}"; do
        if [ "$branch" != "main" ]; then
            echo "$i) $branch"
            ((i++))
        fi
    done
    
    echo ""
    
    # Get user selection
    while true; do
        read -p "Select branch [0-$((i-1))]: " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -lt "$i" ]; then
            if [ "$choice" -eq 0 ]; then
                REPOSITORY_BRANCHES["am-agents-labs"]=""
                log_success "Selected: main (default branch)"
            else
                local selected_branch=""
                local branch_index=1
                for branch in "${branches[@]}"; do
                    if [ "$branch" != "main" ]; then
                        if [ "$branch_index" -eq "$choice" ]; then
                            selected_branch="$branch"
                            break
                        fi
                        ((branch_index++))
                    fi
                done
                
                REPOSITORY_BRANCHES["am-agents-labs"]="$selected_branch"
                log_success "Selected: $selected_branch"
            fi
            break
        else
            print_warning "Invalid selection. Please enter a number between 0 and $((i-1))."
        fi
    done
    
    return 0
}

# Validate repository URL
validate_repo_url() {
    local url="$1"
    
    if [[ ! "$url" =~ ^https://github\.com/[^/]+/[^/]+\.git$ ]]; then
        log_error "Invalid repository URL format: $url"
        return 1
    fi
    
    return 0
}

# Check if repository exists remotely
check_repo_exists() {
    local repo_name="$1"
    local repo_url="$2"
    
    log_info "Checking if $repo_name repository exists..."
    
    if ! git ls-remote --heads "$repo_url" >/dev/null 2>&1; then
        log_error "Repository $repo_name not accessible: $repo_url"
        log_info "Please check if the repository exists and you have access"
        return 1
    fi
    
    log_success "Repository $repo_name is accessible"
    return 0
}

# Clone a single repository
clone_repository() {
    local repo_name="$1"
    local repo_url="$2"
    local target_dir="$REPOS_DIR/$repo_name"
    local branch="${REPOSITORY_BRANCHES[$repo_name]}"
    
    if [ -n "$branch" ]; then
        log_info "Cloning $repo_name (branch: $branch)..."
    else
        log_info "Cloning $repo_name..."
    fi
    
    # Check if directory already exists
    if [ -d "$target_dir" ]; then
        if [ -d "$target_dir/.git" ]; then
            log_warning "Repository $repo_name already exists"
            return handle_existing_repo "$repo_name" "$repo_url" "$target_dir"
        else
            log_warning "Directory $target_dir exists but is not a Git repository"
            
            # Ask user what to do
            echo -e "${YELLOW}Options:${NC}"
            echo "1) Remove directory and clone fresh"
            echo "2) Skip this repository"
            echo "3) Exit"
            
            while true; do
                read -p "Choose option [1-3]: " choice
                case $choice in
                    1)
                        log_info "Removing existing directory..."
                        rm -rf "$target_dir"
                        break
                        ;;
                    2)
                        log_warning "Skipping $repo_name"
                        return 0
                        ;;
                    3)
                        log_info "Exiting at user request"
                        exit 0
                        ;;
                    *)
                        print_warning "Invalid choice. Please enter 1, 2, or 3."
                        ;;
                esac
            done
        fi
    fi
    
    # Validate repository URL
    if ! validate_repo_url "$repo_url"; then
        return 1
    fi
    
    # Check if repository exists
    if ! check_repo_exists "$repo_name" "$repo_url"; then
        return 1
    fi
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$target_dir")"
    
    # Clone the repository
    if [ -n "$branch" ]; then
        log_info "Cloning $repo_name from $repo_url (branch: $branch)..."
    else
        log_info "Cloning $repo_name from $repo_url..."
    fi
    
    local clone_cmd="git clone"
    
    # Add depth option for shallow clone
    if [ "$GIT_DEPTH" -gt 0 ]; then
        clone_cmd="$clone_cmd --depth $GIT_DEPTH"
    fi
    
    # Add branch option if specified
    if [ -n "$branch" ]; then
        clone_cmd="$clone_cmd --branch '$branch'"
    fi
    
    # Add URL and target directory
    clone_cmd="$clone_cmd '$repo_url' '$target_dir'"
    
    # Execute clone with timeout
    if timeout "$GIT_TIMEOUT" bash -c "$clone_cmd" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Successfully cloned $repo_name"
        
        # Verify clone
        if [ -d "$target_dir/.git" ]; then
            local commit_hash=$(cd "$target_dir" && git rev-parse --short HEAD 2>/dev/null)
            local branch=$(cd "$target_dir" && git branch --show-current 2>/dev/null)
            log_info "$repo_name: $branch @ $commit_hash"
            return 0
        else
            log_error "Clone verification failed for $repo_name"
            return 1
        fi
    else
        log_error "Failed to clone $repo_name (timeout or error)"
        return 1
    fi
}

# Handle existing repository
handle_existing_repo() {
    local repo_name="$1"
    local repo_url="$2"
    local target_dir="$3"
    
    log_info "Handling existing repository: $repo_name"
    
    # Check if it's the correct repository
    local current_url=$(cd "$target_dir" && git config --get remote.origin.url 2>/dev/null)
    
    if [ "$current_url" != "$repo_url" ]; then
        log_warning "Repository URL mismatch:"
        log_warning "  Expected: $repo_url"
        log_warning "  Current:  $current_url"
        
        echo -e "${YELLOW}Options:${NC}"
        echo "1) Remove and clone fresh"
        echo "2) Update remote URL"
        echo "3) Skip this repository"
        echo "4) Exit"
        
        while true; do
            read -p "Choose option [1-4]: " choice
            case $choice in
                1)
                    log_info "Removing existing repository..."
                    rm -rf "$target_dir"
                    return clone_repository "$repo_name" "$repo_url"
                    ;;
                2)
                    log_info "Updating remote URL..."
                    cd "$target_dir"
                    git remote set-url origin "$repo_url"
                    log_success "Remote URL updated"
                    return update_existing_repo "$repo_name" "$target_dir"
                    ;;
                3)
                    log_warning "Skipping $repo_name"
                    return 0
                    ;;
                4)
                    log_info "Exiting at user request"
                    exit 0
                    ;;
                *)
                    print_warning "Invalid choice. Please enter 1, 2, 3, or 4."
                    ;;
            esac
        done
    else
        log_success "Repository URL matches"
        return update_existing_repo "$repo_name" "$target_dir"
    fi
}

# Update existing repository
update_existing_repo() {
    local repo_name="$1"
    local target_dir="$2"
    
    log_info "Updating existing repository: $repo_name"
    
    cd "$target_dir"
    
    # Check if working directory is clean
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        log_warning "Repository $repo_name has uncommitted changes"
        
        echo -e "${YELLOW}Options:${NC}"
        echo "1) Stash changes and update"
        echo "2) Skip update (keep as is)"
        echo "3) Show changes and decide"
        
        while true; do
            read -p "Choose option [1-3]: " choice
            case $choice in
                1)
                    log_info "Stashing changes..."
                    git stash push -m "Automagik installer stash $(date)"
                    break
                    ;;
                2)
                    log_warning "Skipping update for $repo_name"
                    return 0
                    ;;
                3)
                    echo -e "${CYAN}Uncommitted changes:${NC}"
                    git status --porcelain
                    echo ""
                    ;;
                *)
                    print_warning "Invalid choice. Please enter 1, 2, or 3."
                    ;;
            esac
        done
    fi
    
    # Fetch latest changes
    log_info "Fetching latest changes for $repo_name..."
    if git fetch origin 2>&1 | tee -a "$LOG_FILE"; then
        # Get current branch
        local current_branch=$(git branch --show-current 2>/dev/null)
        
        if [ -n "$current_branch" ]; then
            # Check if branch exists on remote
            if git ls-remote --heads origin "$current_branch" | grep -q "$current_branch"; then
                log_info "Updating $current_branch branch..."
                if git pull origin "$current_branch" 2>&1 | tee -a "$LOG_FILE"; then
                    local commit_hash=$(git rev-parse --short HEAD 2>/dev/null)
                    log_success "Updated $repo_name to $commit_hash"
                else
                    log_warning "Failed to update $repo_name"
                fi
            else
                log_warning "Branch $current_branch not found on remote"
            fi
        else
            log_warning "Not on any branch in $repo_name"
        fi
    else
        log_warning "Failed to fetch changes for $repo_name"
    fi
    
    return 0
}

# Clone all repositories
clone_all_repositories() {
    log_section "Repository Cloning"
    
    # Check prerequisites
    if ! check_git; then
        return 1
    fi
    
    if ! check_network_connectivity; then
        return 1
    fi
    
    # Select branch for am-agents-labs
    select_agents_branch
    
    # Show repositories to be cloned
    log_info "Repositories to clone:"
    for repo in "${CLONE_ORDER[@]}"; do
        local url="${REPOSITORIES[$repo]}"
        local branch="${REPOSITORY_BRANCHES[$repo]}"
        if [ -n "$branch" ]; then
            echo "  • $repo: $url (branch: $branch)"
        else
            echo "  • $repo: $url"
        fi
    done
    echo ""
    
    # Confirm with user
    while true; do
        read -p "Proceed with cloning? [y/N]: " confirm
        case $confirm in
            [Yy]|[Yy][Ee][Ss])
                break
                ;;
            [Nn]|[Nn][Oo]|"")
                log_info "Cloning cancelled by user"
                return 0
                ;;
            *)
                print_warning "Please answer yes or no."
                ;;
        esac
    done
    
    # Clone repositories in order
    local total_repos=${#CLONE_ORDER[@]}
    local current_repo=0
    local failed_repos=()
    
    for repo in "${CLONE_ORDER[@]}"; do
        ((current_repo++))
        local url="${REPOSITORIES[$repo]}"
        
        print_progress "$current_repo" "$total_repos" "Cloning $repo..."
        
        if ! clone_repository "$repo" "$url"; then
            failed_repos+=("$repo")
            log_error "Failed to clone $repo"
        fi
    done
    
    # Report results
    echo ""
    if [ ${#failed_repos[@]} -gt 0 ]; then
        log_error "Failed to clone repositories: ${failed_repos[*]}"
        log_info "You may need to clone these manually or check your access permissions"
        return 1
    else
        log_success "All repositories cloned successfully!"
        return 0
    fi
}

# Verify all repositories
verify_repositories() {
    log_section "Repository Verification"
    
    local missing_repos=()
    local invalid_repos=()
    
    for repo in "${CLONE_ORDER[@]}"; do
        local target_dir="$REPOS_DIR/$repo"
        
        if [ ! -d "$target_dir" ]; then
            missing_repos+=("$repo")
            print_table_row "$repo" "❌ Missing" "-" "-"
        elif [ ! -d "$target_dir/.git" ]; then
            invalid_repos+=("$repo")
            print_table_row "$repo" "❌ Invalid" "-" "-"
        else
            local commit_hash=$(cd "$target_dir" && git rev-parse --short HEAD 2>/dev/null)
            local branch=$(cd "$target_dir" && git branch --show-current 2>/dev/null)
            local url=$(cd "$target_dir" && git config --get remote.origin.url 2>/dev/null)
            
            if [ "$url" = "${REPOSITORIES[$repo]}" ]; then
                print_table_row "$repo" "✅ Valid" "$branch@$commit_hash" "$url"
            else
                invalid_repos+=("$repo")
                print_table_row "$repo" "❌ Wrong URL" "$branch@$commit_hash" "$url"
            fi
        fi
    done
    
    echo ""
    
    if [ ${#missing_repos[@]} -gt 0 ]; then
        log_error "Missing repositories: ${missing_repos[*]}"
    fi
    
    if [ ${#invalid_repos[@]} -gt 0 ]; then
        log_error "Invalid repositories: ${invalid_repos[*]}"
    fi
    
    if [ ${#missing_repos[@]} -eq 0 ] && [ ${#invalid_repos[@]} -eq 0 ]; then
        log_success "All repositories verified successfully!"
        return 0
    else
        return 1
    fi
}

# Clean up repositories (remove all)
clean_repositories() {
    log_section "Repository Cleanup"
    
    log_warning "This will remove all Automagik repositories"
    log_warning "Any uncommitted changes will be lost!"
    
    while true; do
        read -p "Are you sure you want to continue? [y/N]: " confirm
        case $confirm in
            [Yy]|[Yy][Ee][Ss])
                break
                ;;
            [Nn]|[Nn][Oo]|"")
                log_info "Cleanup cancelled by user"
                return 0
                ;;
            *)
                print_warning "Please answer yes or no."
                ;;
        esac
    done
    
    local removed_count=0
    
    for repo in "${CLONE_ORDER[@]}"; do
        local target_dir="$REPOS_DIR/$repo"
        
        if [ -d "$target_dir" ]; then
            log_info "Removing $repo..."
            if rm -rf "$target_dir"; then
                log_success "Removed $repo"
                ((removed_count++))
            else
                log_error "Failed to remove $repo"
            fi
        else
            log_info "$repo not found (already removed)"
        fi
    done
    
    log_success "Removed $removed_count repositories"
    return 0
}

# Main function when script is run directly
main() {
    case "${1:-clone}" in
        "clone")
            clone_all_repositories
            ;;
        "verify")
            verify_repositories
            ;;
        "clean")
            clean_repositories
            ;;
        "update")
            # Update existing repositories
            log_section "Repository Update"
            for repo in "${CLONE_ORDER[@]}"; do
                local target_dir="$REPOS_DIR/$repo"
                if [ -d "$target_dir/.git" ]; then
                    update_existing_repo "$repo" "$target_dir"
                else
                    log_warning "$repo not found or not a Git repository"
                fi
            done
            ;;
        *)
            echo "Usage: $0 {clone|verify|clean|update}"
            echo "  clone   - Clone all repositories (default)"
            echo "  verify  - Verify all repositories are present and valid"
            echo "  clean   - Remove all repositories"
            echo "  update  - Update existing repositories"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi