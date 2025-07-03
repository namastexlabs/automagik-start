# automagik-ui Environment Variable Standardization Plan
## Phase 1: UI Service Cleanup

## 🎯 **Objective**
Clean up automagik-ui environment variables to eliminate conflicts while respecting UI-specific frameworks and shared global variables.

## 📋 **UI-Specific Analysis**

### **Current Issues in automagik-ui**

#### **Issue 1: Missing UI Prefix on Port Variables**
```bash
# Current (.env.local.example):
AUTOMAGIK_DEV_PORT=9999     # Missing UI prefix
AUTOMAGIK_PROD_PORT=8888    # Missing UI prefix

# Should be:
AUTOMAGIK_UI_DEV_PORT=9999  # Properly prefixed
AUTOMAGIK_UI_PROD_PORT=8888 # Properly prefixed
```

#### **Issue 2: Conflicting Port Configuration**
```bash
# Current (.env.local.example):
PORT=3000                   # Generic override conflicts with above
AUTOMAGIK_DEV_PORT=9999     # Specific dev port
AUTOMAGIK_PROD_PORT=8887    # Specific prod port

# Problem: PORT=3000 overrides the specific ports, causing confusion
```

#### **Issue 3: Database Path Redundancy**
```bash
# Current:
AUTOMAGIK_UI_DATABASE_PATH=./tmp/automagik.db

# Your point: If we have DATA_FOLDER=./data, then using:
# AUTOMAGIK_UI_DATABASE_PATH=./data/automagik-ui.db
# Creates redundant "data" references

# Better approach: Use complete paths without folder variables
AUTOMAGIK_UI_DATABASE_PATH=./data/automagik-ui.db  # Clean, complete path
```

## 🔍 **Variable Categorization for UI**

### **Category 1: Framework-Specific (Don't Touch)**
These are framework requirements and should remain unchanged:
```bash
# Next.js Framework Variables
NODE_ENV=development                    # Node.js environment (framework requirement)
NEXT_TELEMETRY_DISABLED=1              # Next.js telemetry (framework setting)
NEXT_PUBLIC_*                          # Next.js public variables (framework pattern)

# Auth0 Integration (UI-specific feature)
# AUTH0_DOMAIN=                         # Keep commented (UI-specific)
# AUTH0_CLIENT_ID=                      # Keep commented (UI-specific) 
# AUTH0_CLIENT_SECRET=                  # Keep commented (UI-specific)
# AUTH0_SECRET=                         # Keep commented (UI-specific)
# APP_BASE_URL=                         # Keep commented (UI-specific)
```

### **Category 2: Shared Global Variables**
These should be identical across all services:
```bash
# Shared across all Automagik services
ENCRYPTION_KEY=change-this-in-production     # Can be shared encryption key
```

### **Category 3: UI Service-Specific (Need Prefixing)**
These should be prefixed with AUTOMAGIK_UI_:
```bash
# Port Configuration
AUTOMAGIK_UI_DEV_PORT=9999              # UI development port
AUTOMAGIK_UI_PROD_PORT=8888             # UI production port

# Database Configuration  
AUTOMAGIK_UI_DATABASE_PATH=./data/automagik-ui.db  # UI-specific database

# UI-Specific Settings
AUTOMAGIK_UI_LOADING_SPLASH_TIME=500    # UI loading time
```

### **Category 4: Remove (Conflicts)**
These variables cause conflicts and should be removed:
```bash
# Remove these:
PORT=3000                               # Conflicts with prefixed ports
# AUTOMAGIK_PROD_PORT=8887             # Wrong prefix (missing UI)
# AUTOMAGIK_DEV_PORT=9998              # Wrong prefix (missing UI)
```

## 📝 **Implementation Steps**

### **Step 1: Update .env.local.example** ⏱️ 10 minutes

#### **1.1 Fix Port Configuration**
```bash
# Remove conflicting generic port:
# PORT=3000                  # REMOVE - conflicts with specific ports

# Fix prefixes (add UI):
AUTOMAGIK_UI_DEV_PORT=9999   # Was: AUTOMAGIK_DEV_PORT
AUTOMAGIK_UI_PROD_PORT=8888  # Was: AUTOMAGIK_PROD_PORT

# Keep framework variables as-is:
NODE_ENV=development         # ✅ Framework requirement
NEXT_TELEMETRY_DISABLED=1    # ✅ Framework setting
```

#### **1.2 Standardize Database Path**
```bash
# Update database path (consistent with other services):
AUTOMAGIK_UI_DATABASE_PATH=./data/automagik-ui.db  # Was: ./tmp/automagik.db
```

#### **1.3 Keep Auth0 Variables Commented**
```bash
# Auth0 Configuration (v4 Server-Side) - Keep these as-is:
# AUTH0_DOMAIN=your-tenant.us.auth0.com
# AUTH0_CLIENT_ID=your-client-id  
# AUTH0_CLIENT_SECRET=your-client-secret
# AUTH0_SECRET=your-32-byte-hex-secret
# APP_BASE_URL=http://localhost:9999
```

### **Step 2: Update UI Source Code** ⏱️ 15 minutes

#### **2.1 Update lib/env-config.ts**
```typescript
// Current code:
databasePath: () => getEnv('AUTOMAGIK_UI_DATABASE_PATH'),

// This is already correct! ✅

// Check for port references and update:
// Look for any references to AUTOMAGIK_DEV_PORT or AUTOMAGIK_PROD_PORT
// Update to AUTOMAGIK_UI_DEV_PORT and AUTOMAGIK_UI_PROD_PORT
```

#### **2.2 Update Next.js Configuration Files**
Check these files for port variable references:
- `next.config.js` (if exists)
- `package.json` scripts
- Any server startup files

```javascript
// Update any references like:
process.env.AUTOMAGIK_DEV_PORT    // → process.env.AUTOMAGIK_UI_DEV_PORT
process.env.AUTOMAGIK_PROD_PORT   // → process.env.AUTOMAGIK_UI_PROD_PORT
```

#### **2.3 Update PM2 Configuration**
Check for PM2 ecosystem files or startup scripts:
```bash
# Look for references to port variables in:
- ecosystem.config.js (if exists)
- package.json scripts
- Any PM2 startup commands
```

### **Step 3: Update Main .env File** ⏱️ 5 minutes

#### **3.1 Add Corrected UI Variables**
```bash
# Add to main .env file:
AUTOMAGIK_UI_DEV_PORT=9999
AUTOMAGIK_UI_PROD_PORT=8888  
AUTOMAGIK_UI_DATABASE_PATH=./data/automagik-ui.db

# Add shared global variable:
ENCRYPTION_KEY=eW91ci10ZXN0LWVuY3J5cHRpb24ta2V5LS0tLS0tLS0=
```

### **Step 4: Update env-manager.sh** ⏱️ 5 minutes

#### **4.1 Add UI Variable Mappings**
```bash
# Add to env-manager.sh variable mappings:
VARIABLE_MAPPINGS["automagik-ui:AUTOMAGIK_DEV_PORT"]="AUTOMAGIK_UI_DEV_PORT"
VARIABLE_MAPPINGS["automagik-ui:AUTOMAGIK_PROD_PORT"]="AUTOMAGIK_UI_PROD_PORT"
VARIABLE_MAPPINGS["automagik-ui:DATABASE_PATH"]="AUTOMAGIK_UI_DATABASE_PATH"
```

### **Step 5: Testing** ⏱️ 10 minutes

#### **5.1 Test Environment Setup**
```bash
# Test .env.local creation:
make setup-env-files

# Check automagik-ui/.env.local was created correctly:
cat automagik-ui/.env.local

# Test variable sync:
make env

# Verify UI service variables synced correctly
```

#### **5.2 Test UI Service Startup**
```bash
# Test configuration loading:
cd automagik-ui
node -e "
const envConfig = require('./lib/env-config.js');
console.log('Database path:', envConfig.databasePath());
console.log('Config loaded successfully');
"

# Test development server startup (don't leave running):
cd automagik-ui
npm run dev --port=9999
# Verify it starts on correct port, then stop it
```

## 📋 **Final .env.local.example Structure**

```bash
# Automagik UI Environment Variables

# =================================================================
# 🔧 UI Service Configuration (REQUIRED)
# =================================================================

# Database encryption key (shared global variable)
ENCRYPTION_KEY=change-this-in-production

# Database path
AUTOMAGIK_UI_DATABASE_PATH=./data/automagik-ui.db

# Port configuration
AUTOMAGIK_UI_DEV_PORT=9999    # Development server port
AUTOMAGIK_UI_PROD_PORT=8888   # Production server port

# UI-specific settings
NEXT_PUBLIC_LOADING_SPLASH_TIME=500

# =================================================================
# 🌐 Framework Configuration (Next.js - Don't Touch)
# =================================================================

# Next.js Framework Settings
NODE_ENV=development
NEXT_TELEMETRY_DISABLED=1

# Omni API settings (Next.js public variables)
OMNI_MOCK_DATA=false
NEXT_PUBLIC_OMNI_MOCK_DATA=false

# =================================================================
# 🔐 Auth0 Configuration (Optional - UI Specific)
# =================================================================
# DUAL-MODE AUTHENTICATION:
# - If these variables are NOT set → Opensource Mode (no authentication)  
# - If these variables are SET → Organization Mode (Auth0 authentication)

# Required for Auth0 Mode:
# AUTH0_DOMAIN=your-tenant.us.auth0.com
# AUTH0_CLIENT_ID=your-client-id
# AUTH0_CLIENT_SECRET=your-client-secret
# AUTH0_SECRET=your-32-byte-hex-secret-generated-with-openssl-rand-hex-32
# APP_BASE_URL=http://localhost:9999

# Default Organization (automatically passed to Auth0 login):
# AUTH0_ORGANIZATION=flashed

# Optional for Organization Features:
# AUTH0_MANAGEMENT_CLIENT_ID=your-management-client-id
# AUTH0_MANAGEMENT_CLIENT_SECRET=your-management-client-secret
```

## ✅ **Success Criteria for UI**

### **Before Implementation**
❌ Port configuration conflicts (`PORT=3000` vs `AUTOMAGIK_DEV_PORT`)  
❌ Missing UI prefix on port variables  
❌ Inconsistent database path location  

### **After Implementation**  
✅ Clean port configuration (only `AUTOMAGIK_UI_*_PORT` variables)  
✅ Proper UI prefixing on all service-specific variables  
✅ Consistent database path in `./data/` folder  
✅ Framework variables (Next.js, Node.js) untouched  
✅ Auth0 variables remain commented and UI-specific  
✅ Shared global variables (like `ENCRYPTION_KEY`) identified  

## 🚀 **Next Steps After UI**

Once UI is complete and tested:
1. **automagik-tools** (minimal changes - cleanest)
2. **automagik-spark** (error message fix)  
3. **am-agents-labs** (log level standardization)
4. **automagik-omni** (most complex - database and logging variables)

## ⏱️ **Time Estimate: 45 minutes**
- Planning: ✅ Done
- .env.local.example update: 10 minutes
- Source code updates: 15 minutes  
- Main .env update: 5 minutes
- env-manager.sh update: 5 minutes
- Testing: 10 minutes