# Environment Variable Standardization Plan
## Comprehensive Cleanup of All Automagik Repositories

## 🎯 **Objective**
Create a **bulletproof, consistent environment variable system** across all Automagik services that eliminates conflicts, reduces confusion, and enables seamless shared resource management.

## 📋 **Standardization Principles**

### **Category 1: Shared Resources (Generic Variables)**
These variables should be **identical across all services** to enable resource sharing:

```bash
# Folders/Directories (shared across services)
LOG_FOLDER=./logs                    # All services log to same folder
DATA_FOLDER=./data                   # All services store data in same folder  
TEMP_FOLDER=./tmp                    # All services use same temp folder
BACKUP_FOLDER=./backups              # All services backup to same folder

# Global Environment Settings (shared across services)
LOG_LEVEL=INFO                       # Same log level for all services
LOG_VERBOSITY=short                  # Same verbosity for all services
NODE_ENV=production                  # Node.js environment (where applicable)
PYTHON_ENV=production                # Python environment (where applicable)
AUTOMAGIK_ENV=production             # Global Automagik environment
AUTOMAGIK_TIMEZONE=UTC               # Global timezone for all services

# External Service Integration (shared across services)
OPENAI_API_KEY=                      # Shared OpenAI access
ANTHROPIC_API_KEY=                   # Shared Claude access
GEMINI_API_KEY=                      # Shared Gemini access
```

### **Category 2: Service-Specific Resources (Prefixed Variables)**
These variables should be **prefixed per service** to avoid conflicts:

```bash
# Database Connections (separate per service)
AUTOMAGIK_DATABASE_URL=              # Main service database
AUTOMAGIK_SPARK_DATABASE_URL=        # Spark service database  
AUTOMAGIK_OMNI_DATABASE_URL=         # Omni service database
AUTOMAGIK_UI_DATABASE_PATH=          # UI service database

# API Configuration (separate per service)
AUTOMAGIK_API_HOST=                  # Main service API
AUTOMAGIK_API_PORT=                  # Main service port
AUTOMAGIK_SPARK_API_HOST=            # Spark service API
AUTOMAGIK_SPARK_API_PORT=            # Spark service port

# Service-Specific Files (separate per service)
AUTOMAGIK_LOG_FILE_PATH=             # Main service log file
AUTOMAGIK_SPARK_LOG_FILE_PATH=       # Spark service log file
AUTOMAGIK_OMNI_LOG_FILE_PATH=        # Omni service log file
```

### **Category 3: Mixed Approach (Context-Dependent)**
Some variables need **both patterns** depending on usage:

```bash
# Database Paths - Service-specific but can share folders
AUTOMAGIK_SQLITE_DB_PATH=./data/automagik.db        # Main service
AUTOMAGIK_SPARK_SQLITE_DB_PATH=./data/spark.db      # Spark service  
AUTOMAGIK_OMNI_SQLITE_DB_PATH=./data/omnihub.db     # Omni service
# All use shared DATA_FOLDER=./data but have different filenames
```

## 🔍 **Current Issues Analysis**

### **Issue 1: automagik-omni Inconsistency**
**Problem**: Mixes generic and prefixed variables in same service
```bash
# Inconsistent pattern in .env.example:
LOG_LEVEL="INFO"                          # Generic (should stay)
AUTOMAGIK_OMNI_LOG_TO_FILE="false"        # Prefixed (correct)
SQLITE_DB_PATH="./data/omnihub.db"        # Generic (should be prefixed)
AUTOMAGIK_OMNI_TRACE_BATCH_SIZE="100"     # Prefixed (correct)
```

**Solution**: Follow standardization rules - shared resources generic, service-specific prefixed

### **Issue 2: automagik-ui Port Confusion**
**Problem**: Multiple port configuration methods
```bash
# Competing patterns:
AUTOMAGIK_DEV_PORT=9998               # Prefixed (correct for service-specific)
AUTOMAGIK_PROD_PORT=8887              # Prefixed (correct for service-specific)
PORT=3000                             # Generic (conflicts with above)
```

**Solution**: Remove generic `PORT`, use only prefixed service ports

### **Issue 3: Database Naming Inconsistency**
**Problem**: Different services use different patterns for same concept
```bash
# Current inconsistent patterns:
AUTOMAGIK_DATABASE_URL=               # Main service
AUTOMAGIK_SPARK_DATABASE_URL=         # Spark service
DATABASE_URL=                         # Omni service (should be prefixed)
DATABASE_PATH=                        # UI service (should be AUTOMAGIK_UI_DATABASE_PATH)
```

**Solution**: Standardize all database variables with consistent naming

### **Issue 4: Log File vs Log Folder Confusion**
**Problem**: Mixing folder and file configurations
```bash
# Should be standardized as:
LOG_FOLDER=./logs                     # Generic shared folder
AUTOMAGIK_LOG_FILE_PATH=debug.log     # Service-specific file within folder
AUTOMAGIK_SPARK_LOG_FILE_PATH=worker.log  # Service-specific file within folder
```

## 📝 **Implementation Plan**

### **Phase 1: Define Standard Variable Schema** ⏱️ 30 minutes

#### **1.1 Create Master Variable Registry**
Create `ENV_VARIABLE_REGISTRY.md` with complete standardized schema:

```bash
# SHARED RESOURCES (identical across all services)
LOG_FOLDER=./logs
DATA_FOLDER=./data  
TEMP_FOLDER=./tmp
LOG_LEVEL=INFO
LOG_VERBOSITY=short
AUTOMAGIK_TIMEZONE=UTC
NODE_ENV=production
PYTHON_ENV=production

# SERVICE-SPECIFIC PATTERNS (prefixed per service)
# Main Service (am-agents-labs → automagik)
AUTOMAGIK_API_HOST=0.0.0.0
AUTOMAGIK_API_PORT=8881
AUTOMAGIK_DATABASE_URL=
AUTOMAGIK_SQLITE_DB_PATH=./data/automagik.db
AUTOMAGIK_LOG_FILE_PATH=automagik.log

# Spark Service
AUTOMAGIK_SPARK_API_HOST=localhost
AUTOMAGIK_SPARK_API_PORT=8883
AUTOMAGIK_SPARK_DATABASE_URL=
AUTOMAGIK_SPARK_SQLITE_DB_PATH=./data/spark.db
AUTOMAGIK_SPARK_LOG_FILE_PATH=spark.log

# Omni Service  
AUTOMAGIK_OMNI_API_HOST=0.0.0.0
AUTOMAGIK_OMNI_API_PORT=8882
AUTOMAGIK_OMNI_DATABASE_URL=
AUTOMAGIK_OMNI_SQLITE_DB_PATH=./data/omnihub.db
AUTOMAGIK_OMNI_LOG_FILE_PATH=omnihub.log

# Tools Service
AUTOMAGIK_TOOLS_HOST=127.0.0.1
AUTOMAGIK_TOOLS_SSE_PORT=8884
AUTOMAGIK_TOOLS_HTTP_PORT=8885

# UI Service
AUTOMAGIK_UI_PORT=8888
AUTOMAGIK_UI_DEV_PORT=9999
AUTOMAGIK_UI_PROD_PORT=8888
AUTOMAGIK_UI_DATABASE_PATH=./data/automagik-ui.db
```

#### **1.2 Create Migration Mapping**
Document exact changes needed for each service:

```bash
# automagik-omni changes:
LOG_LEVEL → Keep generic
SQLITE_DB_PATH → AUTOMAGIK_OMNI_SQLITE_DB_PATH
DATABASE_URL → AUTOMAGIK_OMNI_DATABASE_URL

# automagik-ui changes:
PORT → Remove (conflicts with prefixed ports)
DATABASE_PATH → AUTOMAGIK_UI_DATABASE_PATH

# automagik-spark changes:
Error message: "DATABASE_URL" → "AUTOMAGIK_SPARK_DATABASE_URL"
```

### **Phase 2: Update Service .env.example Files** ⏱️ 45 minutes

#### **2.1 automagik-omni (.env.example)**
```bash
# Update inconsistent variables:
SQLITE_DB_PATH="./data/omnihub.db" → AUTOMAGIK_OMNI_SQLITE_DB_PATH="./data/omnihub.db"
DATABASE_URL="" → AUTOMAGIK_OMNI_DATABASE_URL=""

# Keep shared variables as-is:
LOG_LEVEL="INFO" ✅ (shared)
LOG_VERBOSITY="short" ✅ (shared)  
LOG_FOLDER="" ✅ (shared)
```

#### **2.2 automagik-ui (.env.local.example)**
```bash
# Fix port configuration:
Remove: PORT=3000
Keep: AUTOMAGIK_DEV_PORT, AUTOMAGIK_PROD_PORT

# Update database path:
AUTOMAGIK_UI_DATABASE_PATH=./tmp/automagik.db → ./data/automagik-ui.db
```

#### **2.3 am-agents-labs (.env.example)**
```bash
# Verify current variables match standard:
AUTOMAGIK_API_PORT=8881 ✅
AUTOMAGIK_SQLITE_DATABASE_PATH=./data/automagik.db ✅
AUTOMAGIK_LOG_LEVEL=INFO → Change to LOG_LEVEL=INFO (shared)
```

#### **2.4 automagik-spark (.env.example)**
```bash
# Verify current variables match standard:
AUTOMAGIK_SPARK_DATABASE_URL ✅
AUTOMAGIK_SPARK_API_PORT=8883 ✅
AUTOMAGIK_SPARK_LOG_LEVEL=DEBUG → Change to LOG_LEVEL=DEBUG (shared)
```

#### **2.5 automagik-tools (.env.example)**  
```bash
# Verify current variables match standard:
AUTOMAGIK_TOOLS_HOST=localhost ✅
AUTOMAGIK_TOOLS_SSE_PORT=8884 ✅
```

### **Phase 3: Update Service Source Code** ⏱️ 90 minutes

#### **3.1 automagik-omni Source Code Updates**
**Files to update:**
- `src/config.py` - Update environment variable references

```python
# Current code (inconsistent):
os.getenv("SQLITE_DB_PATH", "./data/omnihub.db")
os.getenv("DATABASE_URL", "")

# New code (standardized):
os.getenv("AUTOMAGIK_OMNI_SQLITE_DB_PATH", "./data/omnihub.db")
os.getenv("AUTOMAGIK_OMNI_DATABASE_URL", "")

# Keep shared variables:
os.getenv("LOG_LEVEL", "INFO") ✅ (shared)
os.getenv("LOG_FOLDER", "") ✅ (shared)
```

#### **3.2 automagik-ui Source Code Updates**
**Files to update:**
- `lib/env-config.ts` - Update database path variable
- Next.js config files - Remove PORT references

```typescript
// Current code:
process.env.DATABASE_PATH

// New code:
process.env.AUTOMAGIK_UI_DATABASE_PATH

// Remove PORT handling, keep prefixed ports:
process.env.AUTOMAGIK_DEV_PORT ✅
process.env.AUTOMAGIK_PROD_PORT ✅
```

#### **3.3 automagik-spark Source Code Updates**
**Files to update:**
- `automagik_spark/core/database/session.py` - Fix error message

```python
# Current misleading error:
raise ValueError("DATABASE_URL environment variable is not set")

# Fixed error message:
raise ValueError("AUTOMAGIK_SPARK_DATABASE_URL environment variable is not set")
```

#### **3.4 am-agents-labs Source Code Updates**
**Files to update:**
- `src/config.py` - Update logging variable

```python
# Current code:
os.getenv("AUTOMAGIK_LOG_LEVEL", "INFO")

# New code (use shared variable):
os.getenv("LOG_LEVEL", "INFO")
```

### **Phase 4: Update Main .env File** ⏱️ 30 minutes

#### **4.1 Add Missing Standard Variables**
```bash
# Add shared resource variables:
LOG_FOLDER=./logs
DATA_FOLDER=./data
TEMP_FOLDER=./tmp

# Update service-specific variables:
AUTOMAGIK_OMNI_SQLITE_DB_PATH=./data/omnihub.db
AUTOMAGIK_OMNI_DATABASE_URL=
AUTOMAGIK_UI_DATABASE_PATH=./data/automagik-ui.db

# Remove conflicting variables:
# Remove: SQLITE_DB_PATH=./data/omnihub.db (use prefixed version)
# Remove: DATABASE_URL= (use prefixed versions)
```

#### **4.2 Organize Variables by Category**
```bash
# =================================================================
# 🌐 Shared Resources (All Services)
# =================================================================
LOG_LEVEL=INFO
LOG_VERBOSITY=short
LOG_FOLDER=./logs
DATA_FOLDER=./data
TEMP_FOLDER=./tmp
AUTOMAGIK_TIMEZONE=UTC
NODE_ENV=production
PYTHON_ENV=production

# =================================================================
# 🔧 Service-Specific Configuration
# =================================================================
# Main Service (Port 8881)
AUTOMAGIK_API_HOST=0.0.0.0
AUTOMAGIK_API_PORT=8881
AUTOMAGIK_DATABASE_URL=
AUTOMAGIK_SQLITE_DB_PATH=./data/automagik.db

# Spark Service (Port 8883)  
AUTOMAGIK_SPARK_API_HOST=localhost
AUTOMAGIK_SPARK_API_PORT=8883
AUTOMAGIK_SPARK_DATABASE_URL=
AUTOMAGIK_SPARK_SQLITE_DB_PATH=./data/spark.db

# Omni Service (Port 8882)
AUTOMAGIK_OMNI_API_HOST=0.0.0.0
AUTOMAGIK_OMNI_API_PORT=8882
AUTOMAGIK_OMNI_DATABASE_URL=
AUTOMAGIK_OMNI_SQLITE_DB_PATH=./data/omnihub.db

# Tools Service (Ports 8884/8885)
AUTOMAGIK_TOOLS_HOST=127.0.0.1
AUTOMAGIK_TOOLS_SSE_PORT=8884
AUTOMAGIK_TOOLS_HTTP_PORT=8885

# UI Service (Port 8888)
AUTOMAGIK_UI_PORT=8888
AUTOMAGIK_UI_DEV_PORT=9999
AUTOMAGIK_UI_PROD_PORT=8888
AUTOMAGIK_UI_DATABASE_PATH=./data/automagik-ui.db
```

### **Phase 5: Update env-manager.sh** ⏱️ 30 minutes

#### **5.1 Add New Variable Mappings**
```bash
# Add mappings for updated variables:
VARIABLE_MAPPINGS["automagik-omni:SQLITE_DB_PATH"]="AUTOMAGIK_OMNI_SQLITE_DB_PATH"
VARIABLE_MAPPINGS["automagik-omni:DATABASE_URL"]="AUTOMAGIK_OMNI_DATABASE_URL"
VARIABLE_MAPPINGS["automagik-ui:DATABASE_PATH"]="AUTOMAGIK_UI_DATABASE_PATH"

# Remove obsolete mappings:
# Remove: AUTOMAGIK_OMNI_LOG_LEVEL mappings (now shared)
```

#### **5.2 Add Shared Variable Propagation**
```bash
# Ensure shared variables propagate to all services:
echo "LOG_LEVEL=$LOG_LEVEL" >> "$service_env"
echo "LOG_FOLDER=$LOG_FOLDER" >> "$service_env"
echo "DATA_FOLDER=$DATA_FOLDER" >> "$service_env"
echo "AUTOMAGIK_TIMEZONE=$AUTOMAGIK_TIMEZONE" >> "$service_env"
```

### **Phase 6: Testing & Validation** ⏱️ 60 minutes

#### **6.1 Environment File Validation**
```bash
# Test environment file creation:
make setup-env-files

# Verify all service .env files created correctly:
ls -la */env* */.*env*

# Test environment variable sync:
make env

# Verify sync completed without errors for all 5 services
```

#### **6.2 Service Startup Testing**
```bash
# Test each service starts with new variables:
# (Note: Don't actually start services, just test configuration loading)

# Check am-agents-labs config loading:
cd am-agents-labs
python -c "from src.config import config; print('Config loaded:', config.api.port)"

# Check automagik-spark config loading:  
cd automagik-spark
python -c "from automagik_spark.api.config import get_database_url; print('DB config loaded')"

# Check automagik-omni config loading:
cd automagik-omni  
python -c "from src.config import config; print('Config loaded:', config.database.database_url)"

# Check automagik-ui config loading:
cd automagik-ui
node -e "const env = require('./lib/env-config'); console.log('Config loaded:', env.databasePath())"
```

#### **6.3 Variable Conflict Testing**
```bash
# Test for variable conflicts:
# 1. Check no duplicate variable names across services
# 2. Verify shared variables actually shared
# 3. Verify prefixed variables properly isolated

# Create test script to validate:
# - No conflicting variable names
# - Proper variable inheritance  
# - Correct service isolation
```

### **Phase 7: Documentation & Cleanup** ⏱️ 30 minutes

#### **7.1 Update Documentation**
```bash
# Update files:
- ENV_VARIABLE_MAPPING.md (new standardized mappings)
- CRITICAL_FIXES_IMPLEMENTATION.md (final status)
- README files (if they reference environment variables)
```

#### **7.2 Create Migration Guide**
```bash
# Create user migration guide for existing installations:
- Document breaking changes
- Provide migration script for existing .env files
- Document new variable patterns
```

## 🎯 **Success Criteria**

### **Validation Checklist**
- [ ] All services use consistent variable naming patterns
- [ ] Shared resources (folders, log levels) use identical variable names
- [ ] Service-specific resources use properly prefixed variables  
- [ ] No variable naming conflicts between services
- [ ] `make setup-env-files` creates all .env files successfully
- [ ] `make env` syncs variables to all services without errors
- [ ] All services can load their configuration without errors
- [ ] Main .env file is organized and well-documented

### **Quality Gates**
- [ ] No generic database URLs (all prefixed per service)
- [ ] No port configuration conflicts (prefixed vs generic)
- [ ] No service-specific variables without prefixes
- [ ] All shared folder variables use same names across services
- [ ] Error messages reference correct variable names

## 📊 **Impact Assessment**

### **Benefits**
✅ **Eliminates conflicts**: No more variable naming collisions  
✅ **Enables resource sharing**: Shared folders work across all services  
✅ **Reduces confusion**: Clear ownership of each variable  
✅ **Improves maintainability**: Consistent patterns across all services  
✅ **Better documentation**: Self-documenting variable names  

### **Breaking Changes**
⚠️ **Service configuration updates required**  
⚠️ **Existing .env files need migration**  
⚠️ **Some variables renamed for consistency**  

### **Risk Mitigation**
🛡️ **Comprehensive testing plan**  
🛡️ **Backward compatibility support during transition**  
🛡️ **Detailed migration documentation**  
🛡️ **Step-by-step rollback plan if issues occur**

## ⏱️ **Timeline Estimate**
- **Total Time**: ~5 hours
- **Phase 1-2**: 1.25 hours (planning and .env.example updates)
- **Phase 3**: 1.5 hours (source code updates)  
- **Phase 4-5**: 1 hour (.env and env-manager.sh updates)
- **Phase 6**: 1 hour (testing and validation)
- **Phase 7**: 0.25 hours (documentation)

## 🚀 **Implementation Strategy**

### **Incremental Approach**
1. **Start with least risky service** (automagik-tools - minimal changes)
2. **Progress to medium risk** (automagik-spark - error message fix)
3. **End with highest risk** (automagik-omni - most changes)
4. **Test after each service** to catch issues early

### **Rollback Plan**
- **Keep backups** of all .env.example files  
- **Document all changes** for easy reversal
- **Test rollback procedure** before starting implementation

## 🎉 **Final Result**

A **bulletproof environment variable system** where:
- 🎯 **Shared resources** (folders, log levels) use identical names across services
- 🔒 **Service isolation** through proper prefixing eliminates conflicts  
- 📖 **Self-documenting** variable names make ownership clear
- 🔄 **Seamless synchronization** through improved env-manager.sh
- 🛠️ **Developer-friendly** setup with `make setup-env-files` → `make env`