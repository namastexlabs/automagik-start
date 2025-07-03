# Environment Variable Standardization Mapping
## Automagik Suite - Variable Migration Guide

This document maps old environment variable names to new standardized AUTOMAGIK_ prefixed names.

## Core Principles
1. All service-specific variables use `AUTOMAGIK_` prefix
2. Service 8881 (am-agents-labs) will be renamed to just "automagik" 
3. Use "AGENTS" (plural) consistently in variable names
4. Keep third-party API keys without prefix (e.g., OPENAI_API_KEY)

## Variable Mapping

### 🚀 Core Automagik Service (Port 8881) - Currently am-agents-labs
| Old Variable | New Variable | Value | Notes |
|--------------|--------------|-------|-------|
| AUTOMAGIK_API_PORT | AUTOMAGIK_API_PORT | 8881 | Keep as-is (main service port) |
| AUTOMAGIK_AGENTS_API_PORT | Remove | - | Duplicate of AUTOMAGIK_API_PORT |
| AUTOMAGIK_AGENTS_API_HOST | AUTOMAGIK_API_HOST | 0.0.0.0 | Simplify naming |
| AUTOMAGIK_AGENTS_URL | AUTOMAGIK_API_URL | http://localhost:8881 | Simplify naming |
| AM_PORT | Remove | - | Legacy variable from setup scripts |
| AM_LOG_LEVEL | AUTOMAGIK_LOG_LEVEL | INFO | Already exists |

### 🔥 Automagik Spark Service (Port 8883)
| Old Variable | New Variable | Value | Notes |
|--------------|--------------|-------|-------|
| AUTOMAGIK_SPARK_API_PORT | AUTOMAGIK_SPARK_API_PORT | 8883 | Keep as-is |
| AGENT_API_URL | AUTOMAGIK_API_URL | http://localhost:8881 | Reference to main service |
| AGENT_API_KEY | AUTOMAGIK_API_KEY | namastex888 | Reference to main service |

### 🌐 Automagik Omni Service (Port 8882)
| Old Variable | New Variable | Value | Notes |
|--------------|--------------|-------|-------|
| AUTOMAGIK_OMNI_API_PORT (line 193) | AUTOMAGIK_OMNI_API_PORT | 8882 | Keep first occurrence |
| AUTOMAGIK_OMNI_API_PORT (line 735) | Remove | - | Duplicate |
| AGENT_API_URL | AUTOMAGIK_API_URL | http://localhost:8881 | Reference to main service |
| AGENT_API_KEY | AUTOMAGIK_API_KEY | namastex888 | Reference to main service |
| DATABASE_URL | AUTOMAGIK_OMNI_DATABASE_URL | - | Service-specific database |
| SQLITE_DB_PATH | AUTOMAGIK_OMNI_SQLITE_DB_PATH | ./data/omnihub.db | Service-specific |
| LOG_LEVEL | AUTOMAGIK_OMNI_LOG_LEVEL | INFO | Service-specific |

### 🛠️ Automagik Tools Service (Ports 8884/8885)
| Old Variable | New Variable | Value | Notes |
|--------------|--------------|-------|-------|
| PORT | AUTOMAGIK_TOOLS_SSE_PORT | 8884 | SSE transport port |
| HOST | AUTOMAGIK_TOOLS_HOST | 127.0.0.1 | Service host |
| AUTOMAGIK_TOOLS_PORT | AUTOMAGIK_TOOLS_HTTP_PORT | 8885 | HTTP transport port |

### 🎨 Automagik UI Service (Port 8888)
| Old Variable | New Variable | Value | Notes |
|--------------|--------------|-------|-------|
| AUTOMAGIK_UI_PORT (line 443) | AUTOMAGIK_UI_PORT | 8888 | Keep first occurrence |
| AUTOMAGIK_UI_PORT (line 736) | Remove | - | Duplicate |
| DATABASE_PATH | AUTOMAGIK_UI_DATABASE_PATH | ./data/automagik.db | Service-specific |
| DB_PATH | Remove | - | Duplicate of DATABASE_PATH |

### 🔗 Cross-Service References
All services that reference the main Automagik API should use:
- `AUTOMAGIK_API_URL` instead of `AUTOMAGIK_AGENTS_URL` or `AGENT_API_URL`
- `AUTOMAGIK_API_KEY` instead of `AGENT_API_KEY`
- `AUTOMAGIK_API_HOST` and `AUTOMAGIK_API_PORT` for connection details

### 📊 Duplicate Variables to Remove
1. Line 34: `AUTOMAGIK_API_PORT=8881` (keep)
2. Line 132: `AUTOMAGIK_AGENTS_API_PORT=8881` (remove - duplicate)
3. Line 733: `AUTOMAGIK_API_PORT=8881` (remove - duplicate)
4. Line 735: `AUTOMAGIK_OMNI_API_PORT=8882` (remove - duplicate of line 193)
5. Line 736: `AUTOMAGIK_UI_PORT=8888` (remove - duplicate of line 443)

## Implementation Steps

### Phase 1: Environment File Cleanup
1. Remove all duplicate variable definitions
2. Rename variables according to mapping above
3. Ensure consistent AUTOMAGIK_ prefix usage

### Phase 2: Makefile Updates
1. Update variable references:
   - `AUTOMAGIK_AGENTS_API_PORT` → `AUTOMAGIK_API_PORT`
   - `PORT` → `AUTOMAGIK_TOOLS_SSE_PORT`

### Phase 3: Service Codebase Updates
1. **am-agents-labs**: Update to use `AUTOMAGIK_` prefix (not `AUTOMAGIK_AGENTS_`)
2. **automagik-spark**: Update `AGENT_API_*` references to `AUTOMAGIK_API_*`
3. **automagik-omni**: Update `AGENT_API_*` references to `AUTOMAGIK_API_*`
4. **automagik-tools**: Update `PORT` and `HOST` to prefixed versions
5. **automagik-ui**: Update `DATABASE_PATH` to prefixed version

### Phase 4: Configuration Scripts
1. Update `env-manager.sh` to handle new variable names
2. Update `setup-local-config.sh` scripts in each service
3. Create migration script for existing installations

## Validation Checklist
- [ ] No duplicate port definitions in .env
- [ ] All service-specific variables use AUTOMAGIK_ prefix
- [ ] Main service (8881) uses AUTOMAGIK_API_* (not AGENTS)
- [ ] All services reference main API consistently
- [ ] Makefile uses correct variable names
- [ ] Service codebases updated to match new names
- [ ] env-manager.sh handles new mappings correctly