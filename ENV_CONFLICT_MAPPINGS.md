# Environment Variable Conflict Resolution Mappings

## 🚨 **DRY RUN - CONFLICT ANALYSIS**

Based on comprehensive scanning of all Automagik services, here are the **generic environment variables that could cause conflicts** between services or with other projects:

## 🔍 **Identified Conflicts**

### **Critical Conflicts** (High Priority)

#### 1. **automagik-omni** - Multiple Generic Variables
- `LOG_LEVEL` → Should be `AUTOMAGIK_OMNI_LOG_LEVEL`
- `LOG_VERBOSITY` → Should be `AUTOMAGIK_OMNI_LOG_VERBOSITY`  
- `LOG_FOLDER` → Should be `AUTOMAGIK_OMNI_LOG_FOLDER`
- `SQLITE_DB_PATH` → Should be `AUTOMAGIK_OMNI_SQLITE_DB_PATH`
- `DATABASE_URL` → Should be `AUTOMAGIK_OMNI_DATABASE_URL`

**Impact**: These generic variables could conflict with any other service or project using the same names.
**Files to update**: `automagik-omni/src/config.py`

#### 2. **automagik-ui** - Generic Runtime Variables
- `NODE_ENV` → Should be `AUTOMAGIK_UI_NODE_ENV` 
- `PORT` → Should be `AUTOMAGIK_UI_PORT` (might already be handled)

**Impact**: NODE_ENV is extremely common and will conflict with any Node.js project.
**Files to update**: `automagik-ui/lib/env-config.ts`, Next.js config files

#### 3. **automagik-spark** - Misleading Error Message
- Error message mentions `DATABASE_URL` but actually uses `AUTOMAGIK_SPARK_DATABASE_URL` ✅
- **Fix needed**: Update error message for clarity

**Files to update**: `automagik-spark/automagik_spark/core/database/session.py` (line 22)

### **External Variables** (No Conflict)
These are external service variables and should remain unchanged:
- `LANGFLOW_API_URL` ✅ (external service)
- `LANGFLOW_API_KEY` ✅ (external service)
- `OPENAI_API_KEY` ✅ (external service)
- `ANTHROPIC_API_KEY` ✅ (external service)

### **Already Properly Prefixed** ✅
- am-agents-labs: Uses `AUTOMAGIK_*` pattern correctly
- automagik-tools: Uses `AUTOMAGIK_TOOLS_*` pattern correctly
- automagik-spark: Uses `AUTOMAGIK_SPARK_*` pattern correctly

## 📋 **Resolution Plan**

### **Phase 1: automagik-omni** (Critical)
```python
# Current (CONFLICT RISK)
os.getenv("LOG_LEVEL", "INFO")
os.getenv("LOG_VERBOSITY", "short") 
os.getenv("LOG_FOLDER", "")
os.getenv("SQLITE_DB_PATH", "./data/omnihub.db")
os.getenv("DATABASE_URL", "")

# Target (CONFLICT-FREE)  
os.getenv("AUTOMAGIK_OMNI_LOG_LEVEL", "INFO")
os.getenv("AUTOMAGIK_OMNI_LOG_VERBOSITY", "short")
os.getenv("AUTOMAGIK_OMNI_LOG_FOLDER", "")
os.getenv("AUTOMAGIK_OMNI_SQLITE_DB_PATH", "./data/omnihub.db")
os.getenv("AUTOMAGIK_OMNI_DATABASE_URL", "")
```

### **Phase 2: automagik-ui** (Medium Priority)
```typescript
// Current (CONFLICT RISK)
process.env.NODE_ENV
process.env.PORT

// Target (CONFLICT-FREE)
process.env.AUTOMAGIK_UI_NODE_ENV  
process.env.AUTOMAGIK_UI_PORT
```

### **Phase 3: automagik-spark** (Low Priority - Error Message Fix)
```python
# Current (misleading error)
raise ValueError("DATABASE_URL environment variable is not set")

# Target (accurate error)
raise ValueError("AUTOMAGIK_SPARK_DATABASE_URL environment variable is not set")
```

## 🔄 **env-manager.sh Updates Needed**

### **Add New Mappings**
```bash
# Automagik Omni Service mappings (restore with correct prefixes)
VARIABLE_MAPPINGS["automagik-omni:LOG_LEVEL"]="AUTOMAGIK_OMNI_LOG_LEVEL"
VARIABLE_MAPPINGS["automagik-omni:LOG_VERBOSITY"]="AUTOMAGIK_OMNI_LOG_VERBOSITY"
VARIABLE_MAPPINGS["automagik-omni:LOG_FOLDER"]="AUTOMAGIK_OMNI_LOG_FOLDER"
VARIABLE_MAPPINGS["automagik-omni:SQLITE_DB_PATH"]="AUTOMAGIK_OMNI_SQLITE_DB_PATH"
VARIABLE_MAPPINGS["automagik-omni:DATABASE_URL"]="AUTOMAGIK_OMNI_DATABASE_URL"

# Automagik UI Service mappings
VARIABLE_MAPPINGS["automagik-ui:NODE_ENV"]="AUTOMAGIK_UI_NODE_ENV"
VARIABLE_MAPPINGS["automagik-ui:PORT"]="AUTOMAGIK_UI_PORT"
```

## 📝 **Main .env Updates Needed**

### **Add New Variables**
```bash
# Automagik Omni Configuration (Conflict-Free)
AUTOMAGIK_OMNI_LOG_LEVEL=INFO
AUTOMAGIK_OMNI_LOG_VERBOSITY=short
AUTOMAGIK_OMNI_LOG_FOLDER=
AUTOMAGIK_OMNI_SQLITE_DB_PATH=./data/omnihub.db
AUTOMAGIK_OMNI_DATABASE_URL=

# Automagik UI Configuration (Conflict-Free)
AUTOMAGIK_UI_NODE_ENV=production
AUTOMAGIK_UI_PORT=8888
```

### **Remove Conflicting Variables**
```bash
# Remove these generic variables (will be replaced by prefixed ones)
# LOG_LEVEL=INFO                     # → AUTOMAGIK_OMNI_LOG_LEVEL
# LOG_VERBOSITY=short                # → AUTOMAGIK_OMNI_LOG_VERBOSITY  
# LOG_FOLDER=                        # → AUTOMAGIK_OMNI_LOG_FOLDER
# SQLITE_DB_PATH=./data/omnihub.db   # → AUTOMAGIK_OMNI_SQLITE_DB_PATH
# DATABASE_URL=                      # → AUTOMAGIK_OMNI_DATABASE_URL
```

## ⚠️ **Risk Assessment**

### **Before Fix**
- ❌ **High conflict risk**: Generic variables could interfere with other projects
- ❌ **Service isolation broken**: Multiple services using same generic names
- ❌ **Deployment confusion**: Unclear which service owns which variables

### **After Fix**  
- ✅ **Zero conflict risk**: All variables properly namespaced
- ✅ **Clean service isolation**: Each service has distinct variable namespace
- ✅ **Clear ownership**: Variable names clearly indicate owning service

## 🧪 **Testing Strategy**

### **Verification Steps**
1. **Backup current .env files** for all services
2. **Update service code** to use prefixed variables
3. **Update main .env** with new prefixed variables
4. **Update env-manager.sh** with new mappings
5. **Test sync**: `make env` should work correctly
6. **Test services**: Each service should start with new variables
7. **Rollback plan**: Keep backups for quick reversion if issues

### **Success Criteria**
- [ ] All services start successfully with new prefixed variables
- [ ] No environment variable conflicts between services
- [ ] `make env` syncs all variables correctly
- [ ] No generic variable names in use except external services

## 🎯 **Implementation Priority**

1. **Phase 1**: automagik-omni (highest conflict risk)
2. **Phase 2**: automagik-ui (medium conflict risk)  
3. **Phase 3**: automagik-spark error message (cosmetic fix)

## 🔄 **Backward Compatibility**

**Option A**: Support both old and new variables during transition
```python
# Example transition code
log_level = os.getenv("AUTOMAGIK_OMNI_LOG_LEVEL") or os.getenv("LOG_LEVEL", "INFO")
```

**Option B**: Clean break (recommended)
- Update all at once for clean architecture
- Less maintenance overhead
- Clear variable ownership