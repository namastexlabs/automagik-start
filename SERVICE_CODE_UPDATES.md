# Service Code Updates for Environment Variable Standardization

## Overview
This document details the specific code changes needed in each service to support the standardized AUTOMAGIK_ environment variables.

## 🚀 am-agents-labs Service (Port 8881)
**Changes Needed:**
1. Update all references from `AUTOMAGIK_AGENTS_*` to `AUTOMAGIK_*`
2. Rename service-specific variables to match new pattern

### Files to Update:
- `.env` / `.env.example` - Update variable names
- Python files using `os.getenv()` or `os.environ`
- Configuration files loading environment variables
- Docker-related files

### Specific Changes:
```python
# Old
AGENTS_PORT = os.getenv("AUTOMAGIK_AGENTS_API_PORT", "8881")
AGENTS_HOST = os.getenv("AUTOMAGIK_AGENTS_API_HOST", "0.0.0.0")

# New
API_PORT = os.getenv("AUTOMAGIK_API_PORT", "8881")
API_HOST = os.getenv("AUTOMAGIK_API_HOST", "0.0.0.0")
```

## 🔥 automagik-spark Service (Port 8883)
**Changes Needed:**
1. Update `AGENT_API_*` references to `AUTOMAGIK_API_*`
2. Fix incorrect references to agents service

### Files to Update:
- Configuration files with agent API references
- Code that connects to the main Automagik API

### Specific Changes:
```python
# Old
AGENT_API_URL = os.getenv("AGENT_API_URL", "http://localhost:8881")
AGENT_API_KEY = os.getenv("AGENT_API_KEY", "namastex888")

# New
AUTOMAGIK_API_URL = os.getenv("AUTOMAGIK_API_URL", "http://localhost:8881")
AUTOMAGIK_API_KEY = os.getenv("AUTOMAGIK_API_KEY", "namastex888")
```

## 🌐 automagik-omni Service (Port 8882)
**Changes Needed:**
1. Update `AGENT_API_*` to `AUTOMAGIK_API_*`
2. Update generic variable names with AUTOMAGIK_OMNI_ prefix
3. Update database and logging variable names

### Files to Update:
- Configuration loading code
- Database connection setup
- Logging configuration

### Specific Changes:
```python
# Old
AGENT_API_URL = os.getenv("AGENT_API_URL")
DATABASE_URL = os.getenv("DATABASE_URL")
SQLITE_DB_PATH = os.getenv("SQLITE_DB_PATH", "./data/omnihub.db")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

# New
AUTOMAGIK_API_URL = os.getenv("AUTOMAGIK_API_URL")
AUTOMAGIK_OMNI_DATABASE_URL = os.getenv("AUTOMAGIK_OMNI_DATABASE_URL")
AUTOMAGIK_OMNI_SQLITE_DB_PATH = os.getenv("AUTOMAGIK_OMNI_SQLITE_DB_PATH", "./data/omnihub.db")
AUTOMAGIK_OMNI_LOG_LEVEL = os.getenv("AUTOMAGIK_OMNI_LOG_LEVEL", "INFO")
```

## 🛠️ automagik-tools Service (Ports 8884/8885)
**Changes Needed:**
1. Update `PORT` and `HOST` to prefixed versions
2. Ensure dual-port configuration is maintained

### Files to Update:
- Server startup configuration
- Transport layer configuration

### Specific Changes:
```python
# Old
HOST = os.getenv("HOST", "127.0.0.1")
PORT = int(os.getenv("PORT", "8884"))

# New
HOST = os.getenv("AUTOMAGIK_TOOLS_HOST", "127.0.0.1")
SSE_PORT = int(os.getenv("AUTOMAGIK_TOOLS_SSE_PORT", "8884"))
HTTP_PORT = int(os.getenv("AUTOMAGIK_TOOLS_HTTP_PORT", "8885"))
```

## 🎨 automagik-ui Service (Port 8888)
**Changes Needed:**
1. Update database path variables
2. Ensure client-side environment variables are updated

### Files to Update:
- `.env.local` configuration
- Next.js configuration files
- Database initialization code

### Specific Changes:
```javascript
// Old
const dbPath = process.env.DATABASE_PATH || process.env.DB_PATH || './data/automagik.db';

// New
const dbPath = process.env.AUTOMAGIK_UI_DATABASE_PATH || './data/automagik.db';
```

## 📝 env-manager.sh Updates
The env-manager.sh script needs to be updated to handle the new variable mappings:

### Changes Needed:
1. Update variable name mappings in the sync functions
2. Add migration logic for old variable names
3. Ensure proper variable propagation to service-specific .env files

### Example Mapping Update:
```bash
# Old mapping
echo "AUTOMAGIK_AGENTS_API_PORT=$AUTOMAGIK_AGENTS_API_PORT" >> "$service_env"

# New mapping
echo "AUTOMAGIK_API_PORT=$AUTOMAGIK_API_PORT" >> "$service_env"
```

## 🔄 Migration Strategy

### Phase 1: Backward Compatibility
Initially support both old and new variable names:
```python
# Support both during migration
API_PORT = os.getenv("AUTOMAGIK_API_PORT") or os.getenv("AUTOMAGIK_AGENTS_API_PORT", "8881")
```

### Phase 2: Deprecation Warnings
Add warnings when old variables are detected:
```python
if os.getenv("AUTOMAGIK_AGENTS_API_PORT"):
    logger.warning("AUTOMAGIK_AGENTS_API_PORT is deprecated. Use AUTOMAGIK_API_PORT instead.")
```

### Phase 3: Complete Migration
Remove support for old variable names after migration period.

## 🧪 Testing Checklist

For each service, verify:
- [ ] Service starts with new environment variables
- [ ] API endpoints are accessible on correct ports
- [ ] Cross-service communication works (especially to main API on 8881)
- [ ] Database connections work with new variable names
- [ ] Logging configuration is applied correctly
- [ ] No errors in service logs about missing environment variables

## 🚨 Critical Path Items

1. **am-agents-labs**: Must update first as it's the core API
2. **automagik-spark & omni**: Must update agent API references to maintain connectivity
3. **env-manager.sh**: Must update to propagate new variables correctly
4. **Documentation**: Update all README files and setup guides

## 📋 Implementation Order

1. Update env-manager.sh to support both old and new variables
2. Update am-agents-labs service code
3. Update automagik-spark and automagik-omni (they depend on agents)
4. Update automagik-tools and automagik-ui
5. Test full suite integration
6. Remove backward compatibility after verification