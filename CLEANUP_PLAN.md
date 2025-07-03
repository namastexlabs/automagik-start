# Automagik Makefile Cleanup Plan

## Quick Summary of Major Changes
1. **Fix automagik-tools**: Split into two PM2 services (sse on 8884, http on 8885)
2. **Remove redundancies**: Delete all `-local` and dev mode commands (-200 lines)
3. **Fix command naming**: Change `-all-services` to `-all` everywhere
4. **Fix port sync**: Correct the env var search patterns (looking for wrong ports)
5. **Fix PM2 safety**: Don't delete ALL PM2 processes, only Automagik ones
6. **Clean dead code**: Remove unused 60-line health check function
7. **Consolidate git ops**: Reduce ~300 lines of redundant git code to ~100

## Overview
This plan addresses the inconsistencies and redundancies found in the Makefile while ensuring the existing `./install.sh` workflow continues to function correctly. The `install.sh` script sets up pre-dependencies and then calls `make install`.

## Phase 1: Critical Fixes

### 1.1 Fix automagik-tools Service Structure
**Issue**: Currently treating automagik-tools as a single service, but it should be two separate PM2 processes.

**Current State**:
- automagik-tools ecosystem.config.js only spawns one service on port 8884 (SSE)
- Makefile references `automagik-tools-sse` and `automagik-tools-http` but they don't exist
- .env has PORT=8884 and AUTOMAGIK_TOOLS_PORT=8885 (confusing)

**Changes Required**:
1. Update automagik-tools ecosystem.config.js to spawn TWO services:
```javascript
apps: [
  {
    name: 'automagik-tools-sse',
    args: 'hub --host 0.0.0.0 --port 8884 --transport sse',
    // ... other config
  },
  {
    name: 'automagik-tools-http',
    args: 'hub --host 0.0.0.0 --port 8885 --transport http',
    // ... other config
  }
]
```

2. Update PM2_SERVICES list (line 80):
```makefile
PM2_SERVICES := am-agents-labs automagik-spark-api automagik-spark-worker automagik-tools-sse automagik-tools-http automagik-omni automagik-ui
```

3. Fix logs colorization patterns that are already correct but targeting non-existent services

### 1.2 Command Naming Convention Fix
**Issue**: Inconsistent naming with `restart-all-services` vs other commands using `-all`

**Changes**:
- Rename `start-all-services` → `start-all`
- Rename `stop-all-services` → `stop-all`
- Rename `restart-all-services` → `restart-all`
- Rename `status-all-services` → `status-all`
- Rename `install-all-services` → `install-all`
- Rename `uninstall-all-services` → `uninstall-all`
- Update all references throughout the Makefile

## Phase 2: Remove Redundancies

### 2.1 Remove Local Commands
**Commands to Remove**:
- `start-local` (line 1008)
- `stop-local` (line 1015)  
- `status-local` (line 1021)
- `install-local` (line 1227)

**Update References**:
- Any documentation referring to these commands
- Help text

### 2.2 Remove Development Mode
**Commands to Remove**:
- `start-all-dev` (line 744)
- `start-agents-dev` (line 831)
- `start-spark-dev` (line 840)
- `start-tools-dev` (line 851)
- `start-omni-dev` (line 859)
- `start-ui-dev` (line 867)
- `start-nosudo` (line 1352)
- `restart-nosudo` (line 1404)
- All references to 999x ports

### 2.3 Remove Build Commands
**Commands to Remove**:
- `build-agents` (line 584)
- `build-spark` (line 587)
- `build-tools` (line 590)
- `build-omni` (line 593)
- `build-essential-services` (line 579) - replace with no-op or remove entirely

## Phase 3: Fix Port Configuration

### 3.1 Environment Variable Port Sync
**Issue**: The sync-service-env-ports function is looking for wrong patterns in .env files

**Current Problems**:
- Lines 533-534 search for `PORT=18885` and `PORT=18888` which don't exist
- Should be searching for the actual env var names used in .env
- The default ports are 8881-8885, not 18881-18885

**The actual .env structure**:
```
AUTOMAGIK_AGENTS_API_PORT=8881
AUTOMAGIK_OMNI_API_PORT=8882
AUTOMAGIK_SPARK_API_PORT=8883
PORT=8884                    # For automagik-tools SSE
AUTOMAGIK_TOOLS_PORT=8885    # For automagik-tools HTTP
AUTOMAGIK_UI_PORT=8888
```

**Fix sync-service-env-ports function**:
```makefile
# Extract correct port values:
AGENTS_PORT=$$(grep "^AUTOMAGIK_AGENTS_API_PORT=" .env | head -1 | cut -d'=' -f2 || echo "8881");
OMNI_PORT=$$(grep "^AUTOMAGIK_OMNI_API_PORT=" .env | head -1 | cut -d'=' -f2 || echo "8882");
SPARK_PORT=$$(grep "^AUTOMAGIK_SPARK_API_PORT=" .env | head -1 | cut -d'=' -f2 || echo "8883");
TOOLS_SSE_PORT=$$(grep "^PORT=" .env | head -1 | cut -d'=' -f2 || echo "8884");
TOOLS_HTTP_PORT=$$(grep "^AUTOMAGIK_TOOLS_PORT=" .env | head -1 | cut -d'=' -f2 || echo "8885");
UI_PORT=$$(grep "^AUTOMAGIK_UI_PORT=" .env | head -1 | cut -d'=' -f2 || echo "8888");
```

## Phase 4: Clean Docker Legacy

### 4.1 Docker Commands
**Approach**: Keep the commands but add clear warnings

```makefile
docker-full: ## 🐳 Start full Docker stack (DEPRECATED - legacy mode)
	$(call print_warning,This is a legacy command and may not work with current setup)
	@if [ -f "docker-compose.docker.yml" ]; then \
		# ... existing code
	else \
		$(call print_error,Legacy Docker mode is not available in this installation); \
		$(call print_info,Use 'make start' for the standard hybrid mode); \
		exit 1; \
	fi
```

## Phase 5: Command Organization

### 5.1 Consolidate .PHONY Declarations
Create a single .PHONY declaration at the top with all targets alphabetically organized:

```makefile
.PHONY: check-updates clean-all clean-fast clean-uv-cache clone-ui \
        docker-full docker-start docker-stop env env-status \
        git-status help install install-agents install-full \
        install-infrastructure install-omni install-spark \
        install-tools install-ui logs logs-agents logs-infrastructure \
        logs-omni logs-spark logs-spark-api logs-spark-worker \
        logs-tools logs-tools-http logs-tools-sse logs-ui \
        pull pull-agents pull-omni pull-spark pull-tools pull-ui \
        restart restart-agents restart-all restart-evolution \
        restart-infrastructure restart-langflow restart-omni \
        restart-spark restart-tools restart-ui restart-ui-with-build \
        setup-env-files setup-pm2 start start-agents start-all \
        start-evolution start-infrastructure start-langflow \
        start-omni start-spark start-tools start-ui status \
        status-agents status-all status-evolution status-full \
        status-infrastructure status-langflow status-omni \
        status-spark status-tools status-ui stop stop-agents \
        stop-all stop-evolution stop-infrastructure stop-langflow \
        stop-omni stop-spark stop-tools stop-ui sync-service-env-ports \
        uninstall uninstall-all uninstall-infrastructure update
```

## Phase 6: Fix Documentation

### 6.1 Help Text Corrections
- Fix service colors (AGENTS should be "Bright Blue" not "Orange")
- Update port documentation to show 8884 (SSE) and 8885 (HTTP) for tools
- Remove references to development mode
- Update command descriptions to reflect new structure

## Phase 7: Error Handling Analysis (Details as Requested)

### 7.1 Current Error Handling Patterns Explained

The Makefile uses several error handling patterns that make it work despite potential failures:

```makefile
# Pattern 1: Silent failure with continuation
pm2 stop service-name 2>/dev/null || true
```

**How this works**:
1. `2>/dev/null` - Redirects stderr (error messages) to /dev/null, making errors invisible
2. `|| true` - If the command fails (exit code != 0), run `true` which always succeeds
3. Result: The make command continues regardless of whether pm2 stop succeeded

**Pattern 2: Conditional execution**
```makefile
if pm2 list 2>/dev/null | grep -q "online\|stopped\|errored"; then
    pm2 stop all 2>/dev/null || true;
else
    echo "No PM2 processes found to stop";
fi
```

**Why the script works despite errors**:
- These patterns prevent the Makefile from aborting on expected failures
- Common expected failures:
  - Stopping a service that isn't running
  - Deleting a PM2 process that doesn't exist
  - Starting infrastructure that's already running
- By hiding these errors, the installation appears smooth

**Real problems this can hide**:
- Missing dependencies (e.g., PM2 not installed)
- Permission issues (e.g., can't access Docker)
- Network failures (e.g., can't download packages)
- Actual PM2 crashes or errors

**Recommendation**: Keep the patterns but add informative messages for debugging

## Phase 8: Utility Functions - Enhanced Analysis

### 8.1 Unused Functions to Remove
**The `check_service_health_pm2` function (lines 172-231)**:
- 60 lines of complex code that's NEVER called
- Appears to be from an older version when health checks were done differently
- Uses jq to parse PM2 JSON output
- Calculates uptime, memory usage, CPU, etc.
- REMOVE: Dead code that adds confusion

### 8.2 Functions That Should Be Used More
**The `delegate_to_service` function (line 156)**:
- Good abstraction for calling make targets in service directories
- Currently used by install commands
- Could be used by: clean commands, build commands, test commands

**The `ensure_repository` function (line 120)**:
- Handles GitHub authentication and cloning
- Used by install and pull commands
- Good error handling and user guidance

### 8.3 Redundant Code Patterns to Consolidate

**Pattern 1: Git operations in multiple places**
```makefile
# This pattern appears in git-status, check-updates, update, pull-*
if [ -d "$$service_dir/.git" ]; then
    cd $$service_dir;
    # do git operation
    cd - >/dev/null;
fi
```

**Create unified git operation function**:
```makefile
define git_operation
	@service_dir="$(1)"; \
	operation="$(2)"; \
	if [ -d "$$service_dir/.git" ]; then \
		cd $$service_dir && $$operation; \
		cd - >/dev/null; \
	fi
endef

# Usage:
$(call git_operation,$(AM_AGENTS_LABS_DIR),git pull)
$(call git_operation,$(AM_AGENTS_LABS_DIR),git status --porcelain)
```

## Phase 9: Installation Flow Clarification (Detailed Explanation)

### 9.1 Current Installation Flow - How It Really Works

**The complete flow**:
1. User runs `./install.sh`
2. `install.sh` does:
   - Installs pre-dependencies (Docker, Node.js, PM2, GitHub CLI, etc.)
   - Starts Docker infrastructure containers
   - Waits for containers to be healthy
   - Calls `make install`
3. `make install` (line 1250) does:
   - Clones all 5 repositories if missing
   - Sets up .env files from templates
   - Checks if infrastructure is running, starts it if not
   - Calls `make install-all-services`
   - Syncs port configuration
   - Syncs environment variables

**The "dependency order" issue explained**:
- Line 604 says: `# Install services in dependency order`
- But it just does:
  ```makefile
  @$(MAKE) install-agents
  @$(MAKE) install-spark
  @$(MAKE) install-omni
  @$(MAKE) install-ui
  @$(MAKE) install-tools
  ```
- This is a FIXED order, not based on actual dependencies
- For example, it doesn't check if agents needs tools, or if UI needs spark
- The comment is misleading - it implies smart dependency resolution

### 9.2 PM2 Setup Issue - Why This Is Dangerous

**Current code (line 637)**:
```makefile
@pm2 delete all >/dev/null 2>&1 || true
```

**Why this is problematic**:
1. `pm2 delete all` deletes EVERY PM2 process on the system
2. If user has other Node.js apps managed by PM2, they get deleted too
3. Example: User might have a personal project using PM2 that gets wiped out

**The fix makes it safe**:
```makefile
# Delete only Automagik services
@for service in am-agents-labs automagik-spark-api automagik-spark-worker \
              automagik-tools-sse automagik-tools-http automagik-omni automagik-ui; do \
    pm2 delete $$service 2>/dev/null || true; \
done
```

This only deletes the specific Automagik services, leaving other PM2 processes alone.

## Phase 10: Git Operations - Enhanced Analysis

### 10.1 Current Redundancies

**Commands doing similar git operations**:
1. `git-status` (line 1075) - Checks uncommitted changes in all repos
2. `check-updates` (line 1121) - Fetches and checks if repos are behind remote
3. `update` (line 1411) - Pulls and restarts only updated services
4. `pull` (line 1470) - Pulls all repos without restarting
5. `pull-agents`, `pull-spark`, `pull-tools`, `pull-omni`, `pull-ui` - Individual pulls

**Redundant code example**:
- Both `git-status` and `check-updates` loop through all repos
- Both check if directory exists and if it's a git repo
- Both have similar error handling
- ~100 lines of code that could be ~30 lines with proper functions

### 10.2 Proposed Consolidation

**Single function for all git operations**:
```makefile
define git_foreach_repo
	@operation="$(1)"; \
	callback="$(2)"; \
	for service_dir in . $(AM_AGENTS_LABS_DIR) $(AUTOMAGIK_SPARK_DIR) \
	                     $(AUTOMAGIK_TOOLS_DIR) $(AUTOMAGIK_OMNI_DIR) $(AUTOMAGIK_UI_DIR); do \
		if [ -d "$$service_dir/.git" ]; then \
			repo_name=$$(basename $$service_dir); \
			cd $$service_dir; \
			$$operation; \
			cd - >/dev/null; \
		fi; \
	done
endef

# Then commands become simple:
git-status:
	$(call git_foreach_repo, check_git_status)

check-updates:
	$(call git_foreach_repo, check_git_updates)
```

### 10.3 Benefits
- Reduces ~300 lines to ~100 lines
- Consistent behavior across all git commands
- Easier to add new git operations
- Single place to fix bugs

## Implementation Order

1. **Phase 1**: Fix automagik-tools service structure (CRITICAL)
2. **Phase 3**: Fix port configuration (CRITICAL)
3. **Phase 2**: Remove redundancies (SAFE)
4. **Phase 5**: Command organization (COSMETIC)
5. **Phase 6**: Fix documentation (COSMETIC)
6. **Phase 8**: Clean utility functions (OPTIMIZATION)
7. **Phase 9**: Fix installation flow issues (CAREFUL)
8. **Phase 4**: Clean Docker legacy (LOW PRIORITY)
9. **Phase 10**: Consolidate git operations (OPTIMIZATION)

## Post-Cleanup: File Splitting Strategy (Without Rewriting Code)

After cleanup, if the file is still too large for AI context windows, we can split it using GNU Make's include directive. This requires NO code rewriting, just extraction:

### Proposed Structure:
```makefile
# Main Makefile (minimal)
include make/00-variables.mk      # Lines 1-100: Variables, paths, colors
include make/01-utilities.mk      # Lines 101-300: Utility functions
include make/02-infrastructure.mk # Lines 301-500: Docker/infrastructure
include make/03-services.mk       # Lines 501-1000: Service management
include make/04-commands.mk       # Lines 1001-1558: User commands
```

### Extraction Commands (no code changes):
```bash
# Create directory
mkdir -p make

# Extract sections using sed
sed -n '1,100p' Makefile > make/00-variables.mk
sed -n '101,300p' Makefile > make/01-utilities.mk
sed -n '301,500p' Makefile > make/02-infrastructure.mk
sed -n '501,1000p' Makefile > make/03-services.mk
sed -n '1001,1558p' Makefile > make/04-commands.mk

# Create new minimal Makefile
cat > Makefile << 'EOF'
# Automagik Suite - Master Makefile
# This file includes all components
include make/00-variables.mk
include make/01-utilities.mk
include make/02-infrastructure.mk
include make/03-services.mk
include make/04-commands.mk
EOF
```

### Benefits:
- Each file is under 500 lines (fits in AI context)
- No code rewriting needed
- Easy to revert (just restore original Makefile)
- Logical separation of concerns

### Expected File Size After Cleanup:
- Current: 1558 lines
- After removing dev mode: -200 lines
- After removing redundant commands: -150 lines
- After consolidating git operations: -100 lines
- After removing unused functions: -60 lines
- **Target: ~1050 lines** (may still benefit from splitting)

## Success Criteria

- `./install.sh` continues to work exactly as before
- All PM2 services start correctly
- automagik-tools spawns both SSE and HTTP services
- No development mode references remain
- Cleaner, more maintainable code
- Reduced file size