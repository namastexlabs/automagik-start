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

## Current Status: Phase 5 - Repository Standardization (Parallel Execution)

### ✅ COMPLETED: am-agents-labs Standardization
- **Perfect .env.example**: 134 lines, comprehensive structure
- **Gold Standard Achieved**: Excellent documentation, clear sections, proper naming
- **Ready for Replication**: Serves as template for all other repositories

### 🚀 PHASE 5: Parallel Repository Standardization

**Repository-Specific Standardization Tasks (Execute in Parallel):**

#### 5.1 automagik-spark Standardization Agent
**Repository Path**: `/home/namastex/prod/automagik-start/automagik-spark/`
**Current Status**: 56 lines, needs major work
**Tasks**:
- [ ] Scan codebase for all `os.getenv()`, `config.*`, environment usage
- [ ] Standardize variable naming to follow am-agents pattern
- [ ] Implement emoji section headers matching am-agents structure
- [ ] Add comprehensive documentation for each variable
- [ ] Resolve naming conflicts (rename variables in code if needed)
- [ ] Add missing standard variables (AI keys, logging, etc.)
- [ ] Create proper required vs optional categorization

#### 5.2 automagik-omni Standardization Agent  
**Repository Path**: `/home/namastex/prod/automagik-start/automagik-omni/`
**Current Status**: 12 lines, needs complete overhaul
**Tasks**:
- [ ] Scan codebase for all environment variable usage
- [ ] Create comprehensive .env.example from scratch using am-agents template
- [ ] Add all missing integration variables (agent API, tracing, etc.)
- [ ] Implement proper structure with emoji sections
- [ ] Add detailed documentation and usage examples
- [ ] Ensure compatibility with main orchestration system

#### 5.3 automagik-tools Standardization Agent
**Repository Path**: `/home/namastex/prod/automagik-start/automagik-tools/`
**Current Status**: 145 lines, good content but inconsistent structure
**Tasks**:
- [ ] Restructure to match am-agents emoji section format
- [ ] Standardize variable naming patterns
- [ ] Consolidate scattered configuration sections
- [ ] Add missing standard variables for consistency
- [ ] Improve documentation clarity and examples
- [ ] Align with main suite variable naming conventions

#### 5.4 automagik-ui Standardization Agent
**Repository Path**: `/home/namastex/prod/automagik-start/automagik-ui/`
**Current Status**: Missing .env.example file entirely
**Tasks**:
- [ ] Scan Next.js codebase for `process.env.*` usage
- [ ] Create .env.example from scratch using am-agents template
- [ ] Add Next.js specific variables (NEXT_PUBLIC_*, etc.)
- [ ] Include database configuration for frontend data
- [ ] Add API endpoint configurations for all services
- [ ] Implement proper development vs production settings

### 🎯 Standardization Requirements for All Agents

**Mandatory Standards** (Based on am-agents-labs gold standard):
1. **Structure**: Use emoji section headers exactly like am-agents
2. **Documentation**: Every variable needs clear description and usage notes
3. **Naming**: Follow `AUTOMAGIK_{SERVICE}_*` pattern consistently
4. **Categories**: Core → Database → Logging → AI Providers → Performance → Integrations
5. **Required vs Optional**: Clear indication of what's needed vs nice-to-have
6. **Examples**: Provide sample values and format guidance
7. **Conflict Resolution**: Rename variables in code when needed for standardization

**Variable Renaming Strategy**:
- When conflicts arise, update both .env.example AND source code
- Maintain backward compatibility where possible
- Document all renamed variables in commit messages
- Test after renaming to ensure functionality

### 🔄 Parallel Execution Plan

**Execute simultaneously**:
1. Deploy 4 specialized agents to their respective repository paths
2. Each agent works independently on their repository
3. All agents follow the am-agents-labs gold standard template  
4. Coordinate naming conflicts through shared documentation
5. Validate each repository's changes before finalizing

Next immediate action: Deploy 4 parallel standardization agents.