# Epic: Comprehensive Environment Management System for Automagik Suite

## Problem Statement

The current environment variable management in the Automagik Suite has critical issues:

1. **No Automatic Distribution**: The main `.env` file contains all configuration, but variables are NOT automatically distributed to subprojects
2. **Manual Duplication Hell**: Users must manually copy API keys to each subproject's `.env` file
3. **Inconsistent Naming**: Variables have different prefixes and naming conventions across projects
4. **Missing Variables**: Some required variables are not documented or have incorrect names
5. **No Validation**: No checks if required variables are present or valid
6. **No Change Detection**: No way to know when main `.env` changes need propagation
7. **Breaking Issues**: Wrong variable names or missing env vars cause runtime failures

## Success Criteria

1. **Single Source of Truth**: Main `.env` file becomes the master configuration
2. **Automatic Distribution**: `make env` command correctly distributes ALL variables to subprojects
3. **Zero Manual Steps**: After setting main `.env`, all subprojects work without manual intervention
4. **Validation**: System validates all required variables are present and correctly named
5. **Change Detection**: System detects when updates are needed and reports status
6. **Perfect am-agents-labs**: First milestone - am-agents-labs works perfectly with ALL required variables

## Technical Architecture

### Phase 1: Deep Environment Analysis (Current Focus)

#### 1.1 am-agents-labs Environment Audit
- [ ] Scan entire codebase for `os.getenv()`, `os.environ`, config access patterns
- [ ] Document every environment variable actually used in code
- [ ] Compare against `.env.example` to find:
  - Missing variables in example
  - Wrong variable names in example
  - Unused variables in example
  - Default values and fallbacks
- [ ] Create definitive variable mapping

#### 1.2 Environment Variable Categories

**Category 1: AI Provider Keys**
- Pattern: Direct usage across all services
- Examples: OPENAI_API_KEY, ANTHROPIC_API_KEY
- Distribution: Copy to all services that use AI

**Category 2: Service-Specific Config**
- Pattern: Prefixed variables (AUTOMAGIK_AGENTS_*)
- Examples: AUTOMAGIK_AGENTS_API_PORT, AUTOMAGIK_AGENTS_DATABASE_URL
- Distribution: Only to matching service

**Category 3: Infrastructure URLs**
- Pattern: Service endpoints and databases
- Examples: DATABASE_URL, REDIS_URL
- Distribution: Transform to service-specific names

**Category 4: Shared Secrets**
- Pattern: Authentication and encryption
- Examples: JWT_SECRET, API_KEY
- Distribution: Copy to services that need auth

**Category 5: Integration Keys**
- Pattern: Third-party service credentials
- Examples: EVOLUTION_API_KEY, LANGFLOW_API_KEY
- Distribution: Only to services using the integration

### Phase 2: Environment Management System Design

#### 2.1 Core Components

**env-manager.sh** - Main orchestration script
```bash
#!/bin/bash
# Core functions:
# - parse_env_file()
# - validate_variables()
# - generate_service_env()
# - detect_changes()
# - backup_existing()
# - apply_changes()
```

**env-mappings.yaml** - Variable mapping rules
```yaml
# Defines how variables map from main to services
mappings:
  am-agents-labs:
    direct:
      - OPENAI_API_KEY
      - ANTHROPIC_API_KEY
    prefix_match: AUTOMAGIK_AGENTS_
    transforms:
      DATABASE_URL: AUTOMAGIK_AGENTS_DATABASE_URL
    required:
      - OPENAI_API_KEY
      - AUTOMAGIK_AGENTS_API_KEY
```

**env-validator.py** - Python validation script
```python
# Validates:
# - Required variables present
# - Format validation (API keys, URLs)
# - Connection testing (optional)
# - Cross-service compatibility
```

#### 2.2 Makefile Integration

```makefile
# New targets
env: env-check env-sync        ## Manage environment variables
env-check:                      ## Check env status and differences  
env-sync:                       ## Sync main .env to all services
env-validate:                   ## Validate all configurations
env-status:                     ## Show comprehensive env status
env-backup:                     ## Backup current env files
env-restore:                    ## Restore from backup
env-diff:                       ## Show detailed differences
```

### Phase 3: Implementation Plan

#### Step 1: Complete am-agents-labs Analysis (TODAY)
1. Scan all Python files for environment usage
2. Document every variable with:
   - Actual name used in code
   - Expected name in .env
   - Default value
   - Required/Optional status
   - Usage context
3. Create perfect `.env.example` for am-agents-labs

#### Step 2: Build Core env-manager.sh (NEXT)
1. Implement parsing and validation logic
2. Create backup/restore functionality
3. Build change detection system
4. Add dry-run mode

#### Step 3: Create Mapping System
1. Design YAML schema for mappings
2. Implement transformation rules
3. Add validation rules
4. Support custom mappings

#### Step 4: Integration and Testing
1. Integrate with Makefile
2. Test with am-agents-labs
3. Validate all variables work
4. Test update scenarios

#### Step 5: Extend to Other Services
1. Analyze automagik-spark
2. Analyze automagik-tools  
3. Analyze automagik-omni
4. Create complete mapping set

### Phase 4: Advanced Features

1. **Secret Management**
   - Detect sensitive variables
   - Support `.env.encrypted`
   - Key rotation helpers

2. **Environment Profiles**
   - Development vs Production
   - Local vs Docker
   - Testing environments

3. **Monitoring**
   - Track which services use which variables
   - Alert on missing required variables
   - Usage analytics

4. **Documentation Generation**
   - Auto-generate env documentation
   - Create setup guides
   - Variable dependency graphs

## Current Status: Starting Phase 1.1

Next immediate action: Deep scan of am-agents-labs codebase for all environment variables.