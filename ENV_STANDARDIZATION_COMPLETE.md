# Automagik Environment Variable Standardization - Complete Documentation

## 🎯 Project Overview

This document consolidates the entire environment variable standardization effort for the Automagik suite. This was a major refactoring project that standardized ALL environment variables across 5 services to use consistent AUTOMAGIK_* prefixing patterns.

## ✅ Implementation Status: 100% COMPLETE

### What Was Implemented

1. **Complete Variable Renaming**: All legacy patterns (AM_*, AGENT_*, generic names) replaced with AUTOMAGIK_* prefixes
2. **Service Isolation**: Each service uses its own prefixed namespace
3. **Codebase Updates**: All service code updated to use new variable names
4. **Infrastructure Updates**: Makefile, env-manager.sh, and all config files updated
5. **Documentation**: All .env.example files updated across services

## 📋 Final Variable Pattern

```
Main Service (Port 8881):    AUTOMAGIK_*
Spark Service (Port 8883):   AUTOMAGIK_SPARK_*
Omni Service (Port 8882):    AUTOMAGIK_OMNI_*
Tools Service (Port 8884/5): AUTOMAGIK_TOOLS_*
UI Service (Port 8888):      AUTOMAGIK_UI_*
```

## 🔄 Major Changes Implemented

### 1. Service-Specific Updates

#### **am-agents-labs → automagik (Main Service)**
- `AUTOMAGIK_AGENTS_API_PORT` → `AUTOMAGIK_API_PORT`
- `AUTOMAGIK_AGENTS_API_HOST` → `AUTOMAGIK_API_HOST`
- `AM_PORT` → `AUTOMAGIK_API_PORT`
- `AM_LOG_LEVEL` → `AUTOMAGIK_LOG_LEVEL`
- All AM_* patterns removed from scripts

#### **automagik-spark**
- Fixed all references from `AUTOMAGIK_AGENTS_*` to `AUTOMAGIK_*`
- Updated database error messages to reference correct variables
- All logging now uses `LOG_LEVEL` (shared) with service-specific paths

#### **automagik-omni** (Major Refactor)
- ALL variables now prefixed with `AUTOMAGIK_OMNI_*`
- `LOG_LEVEL` → `AUTOMAGIK_OMNI_LOG_LEVEL`
- `DATABASE_URL` → `AUTOMAGIK_OMNI_DATABASE_URL`
- `SQLITE_DB_PATH` → `AUTOMAGIK_OMNI_SQLITE_DB_PATH`
- `AGENT_API_*` → `AUTOMAGIK_API_*` (references to main service)

#### **automagik-tools**
- `PORT` → `AUTOMAGIK_TOOLS_SSE_PORT`
- `HOST` → `AUTOMAGIK_TOOLS_HOST`
- `AUTOMAGIK_TOOLS_PORT` → `AUTOMAGIK_TOOLS_HTTP_PORT`

#### **automagik-ui**
- `DATABASE_PATH` → `AUTOMAGIK_UI_DATABASE_PATH`
- Added `AUTOMAGIK_UI_DEV_PORT` and `AUTOMAGIK_UI_PROD_PORT`
- Removed generic `PORT` variable

### 2. Global Variables

Only these variables are shared across services:
- `ENVIRONMENT` - Python environment control
- `NODE_ENV` - Node.js environment control
- `AUTOMAGIK_TIMEZONE` - Global timezone
- `AUTOMAGIK_API_KEY` - Shared API key for service communication
- `LOG_LEVEL` - Shared logging level (though some services override)

### 3. Infrastructure Updates

#### **Makefile**
- Updated all variable references to new names
- Fixed port mapping for all services
- Verified all make targets work correctly

#### **env-manager.sh**
- Complete variable mapping system implemented
- Handles transformation from main .env to service-specific .env files
- Properly propagates shared variables

## 📊 Variable Mapping Reference

### Cross-Service Communication
All services that need to communicate with the main Automagik API use:
- `AUTOMAGIK_API_URL` (not AGENT_API_URL or AUTOMAGIK_AGENTS_URL)
- `AUTOMAGIK_API_KEY` (not AGENT_API_KEY)
- `AUTOMAGIK_API_HOST` and `AUTOMAGIK_API_PORT`

### Service Ports
- Main API: `AUTOMAGIK_API_PORT=8881`
- Omni: `AUTOMAGIK_OMNI_API_PORT=8882`
- Spark: `AUTOMAGIK_SPARK_API_PORT=8883`
- Tools SSE: `AUTOMAGIK_TOOLS_SSE_PORT=8884`
- Tools HTTP: `AUTOMAGIK_TOOLS_HTTP_PORT=8885`
- UI: `AUTOMAGIK_UI_PORT=8888`

## 🧹 Final .env Cleanup Requirements

1. **Remove all duplicates** - Each variable should be defined only once
2. **Fix inconsistencies**:
   - Remove duplicate API keys
   - Remove duplicate port definitions
   - Remove old variable forms (SQLITE_DB_PATH, DATABASE_URL without prefixes)
3. **Ensure proper organization**:
   - Group by service
   - Clear comments
   - Consistent formatting

## 🚀 Usage

1. **Initial Setup**: `make setup-env-files` - Creates .env files from templates
2. **Sync Variables**: `make env` - Syncs from main .env to service .env files
3. **Start Services**: Each service reads its own .env file with properly mapped variables

## 📝 Important Notes

- This was a "big bang" approach - all variables changed at once
- No backward compatibility maintained
- All services must be updated together
- The env-manager.sh handles all variable mapping during sync

## ✅ Validation Checklist

- [x] No AM_* patterns remain in any codebase
- [x] All services use AUTOMAGIK_* prefix pattern
- [x] No duplicate variable definitions
- [x] All service code updated to use new names
- [x] env-manager.sh properly maps all variables
- [x] Installation flow works correctly
- [x] All .env.example files updated

This completes the environment variable standardization project for the Automagik suite.