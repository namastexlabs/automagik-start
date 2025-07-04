# Environment Variable Review Guide - Post-Standardization Sweep

## 🎯 Purpose
This guide provides comprehensive instructions for reviewing each Automagik service to ensure the environment variable standardization didn't break any functionality.

## 📋 Review Checklist by Repository

### 1. automagik (Main Repository)
**Priority: HIGH**

#### Files to Check:
- `Makefile`
- `env-manager.sh`
- `.env`
- `docker-compose*.yml`

#### Verification Commands:
```bash
# Check Makefile for old variable names
grep -n "AUTOMAGIK_AGENTS_API_PORT\|AM_PORT\|PORT" Makefile

# Verify env-manager.sh mappings
grep -n "VARIABLE_MAPPINGS\[" env-manager.sh | grep -E "(AM_|AGENT_|DATABASE_URL|SQLITE_DB_PATH)"

# Test environment setup flow
make clean-env
make setup-env-files
make env

# Check for successful .env file creation in each service
find . -name ".env" -type f | xargs ls -la
```

#### Expected Results:
- ✅ No references to AUTOMAGIK_AGENTS_API_PORT in Makefile
- ✅ env-manager.sh has correct mappings for all new variable names
- ✅ All service .env files created successfully
- ✅ No errors during make env

---

### 2. am-agents-labs (Main API Service - Port 8881)
**Priority: HIGH**

#### Files to Check:
- `src/config.py`
- `scripts/*.py`
- `scripts/*.sh`
- `.env.example`
- `Dockerfile`

#### Verification Commands:
```bash
cd am-agents-labs

# Search for legacy AM_* patterns
grep -r "AM_" --include="*.py" --include="*.sh" --include="*.yml" . | grep -v ".env.example"

# Check for old AGENTS references
grep -r "AUTOMAGIK_AGENTS_" --include="*.py" --include="*.sh" .

# Verify config.py uses correct variables
grep -n "os.getenv\|os.environ" src/config.py

# Test critical scripts
python scripts/health_check.py  # Should use AUTOMAGIK_API_PORT
./scripts/start_agent_servers.sh  # Should use AUTOMAGIK_* variables
```

#### Known Changes to Verify:
- `AM_PORT` → `AUTOMAGIK_API_PORT`
- `AM_AGENT_NAME` → `AUTOMAGIK_AGENT_NAME`
- `AM_BASE_URL` → `AUTOMAGIK_API_URL`
- `AM_API_KEY` → `AUTOMAGIK_API_KEY`
- `AUTOMAGIK_LOG_LEVEL` → `LOG_LEVEL` (shared variable)

---

### 3. automagik-spark (Workflow Service - Port 8883)
**Priority: HIGH**

#### Files to Check:
- `automagik_spark/api/config.py`
- `automagik_spark/core/database/session.py`
- `tests/api/test_config.py`
- `docker-compose*.yml`
- `.env.example`

#### Verification Commands:
```bash
cd automagik-spark

# Check for old AGENTS patterns
grep -r "AUTOMAGIK_AGENTS_" --include="*.py" .

# Check for AGENT_API references
grep -r "AGENT_API" --include="*.py" .

# Verify database error messages
grep -r "DATABASE_URL.*not set" --include="*.py" .

# Check docker files for AM_ENV
grep -r "AM_ENV" docker-compose*.yml

# Test configuration loading
python -c "from automagik_spark.api.config import settings; print(f'API Port: {settings.api_port}')"
```

#### Known Changes to Verify:
- `AUTOMAGIK_AGENTS_API_PORT` → `AUTOMAGIK_API_PORT`
- `AUTOMAGIK_AGENTS_API_HOST` → `AUTOMAGIK_API_HOST`
- Error message should reference `AUTOMAGIK_SPARK_DATABASE_URL`
- `AUTOMAGIK_SPARK_LOG_LEVEL` → `LOG_LEVEL` (shared variable)

---

### 4. automagik-omni (Multi-Channel Service - Port 8882)
**Priority: HIGH**

#### Files to Check:
- `src/config.py`
- `src/database/*.py`
- `src/services/*.py`
- `.env.example`

#### Verification Commands:
```bash
cd automagik-omni

# Check for generic variable names that should be prefixed
grep -r "os.getenv.*['\"]DATABASE_URL['\"]" --include="*.py" .
grep -r "os.getenv.*['\"]SQLITE_DB_PATH['\"]" --include="*.py" .
grep -r "os.getenv.*['\"]LOG_LEVEL['\"]" --include="*.py" . | grep -v "AUTOMAGIK_OMNI_"

# Check for old AGENT_API patterns
grep -r "AGENT_API" --include="*.py" .

# Verify all variables are prefixed
grep -r "os.getenv" src/config.py | grep -v "AUTOMAGIK_OMNI_" | grep -v "AUTOMAGIK_API_"

# Test config loading
python -c "from src.config import config; print(f'DB Path: {config.database.sqlite_db_path}')"
```

#### Known Changes to Verify:
- ALL variables now use `AUTOMAGIK_OMNI_*` prefix
- `DATABASE_URL` → `AUTOMAGIK_OMNI_DATABASE_URL`
- `SQLITE_DB_PATH` → `AUTOMAGIK_OMNI_SQLITE_DB_PATH`
- `LOG_LEVEL` → `AUTOMAGIK_OMNI_LOG_LEVEL`
- `AGENT_API_*` → `AUTOMAGIK_API_*`

---

### 5. automagik-tools (MCP Tools - Ports 8884/8885)
**Priority: MEDIUM**

#### Files to Check:
- `src/automagik_tools/cli.py`
- `.env.example`
- `setup.py` or `pyproject.toml`

#### Verification Commands:
```bash
cd automagik-tools

# Check for generic PORT and HOST
grep -r "['\"]PORT['\"]" --include="*.py" .
grep -r "['\"]HOST['\"]" --include="*.py" .

# Verify correct variable usage
grep -r "AUTOMAGIK_TOOLS_" --include="*.py" .

# Test CLI with new variables
AUTOMAGIK_TOOLS_HOST=127.0.0.1 AUTOMAGIK_TOOLS_SSE_PORT=8884 python -m automagik_tools.cli
```

#### Known Changes to Verify:
- `PORT` → `AUTOMAGIK_TOOLS_SSE_PORT`
- `HOST` → `AUTOMAGIK_TOOLS_HOST`
- `AUTOMAGIK_TOOLS_PORT` → `AUTOMAGIK_TOOLS_HTTP_PORT`

---

### 6. automagik-ui (Web Interface - Port 8888)
**Priority: MEDIUM**

#### Files to Check:
- `lib/env-config.ts`
- `next.config.js`
- `.env.local.example`
- Any files using process.env

#### Verification Commands:
```bash
cd automagik-ui

# Check for generic DATABASE_PATH
grep -r "DATABASE_PATH" --include="*.ts" --include="*.js" --include="*.tsx" . | grep -v "AUTOMAGIK_UI_"

# Check for generic PORT usage
grep -r "process.env.PORT" --include="*.ts" --include="*.js" --include="*.tsx" .

# Verify API variable usage
grep -r "NEXT_PUBLIC_.*API" --include="*.ts" --include="*.js" --include="*.tsx" .

# Test build with new variables
npm run build
```

#### Known Changes to Verify:
- `DATABASE_PATH` → `AUTOMAGIK_UI_DATABASE_PATH`
- No generic `PORT` (use `AUTOMAGIK_UI_DEV_PORT` and `AUTOMAGIK_UI_PROD_PORT`)
- All API refs use `NEXT_PUBLIC_AUTOMAGIK_*` variables

---

## 🧪 Integration Testing

### Full System Test:
```bash
# 1. Clean everything
make clean-env
docker-compose down -v

# 2. Setup environment
make setup-env-files
make env

# 3. Start all services
docker-compose up -d

# 4. Check service health
curl http://localhost:8881/health  # Main API
curl http://localhost:8882/health  # Omni
curl http://localhost:8883/health  # Spark
curl http://localhost:8888         # UI

# 5. Check logs for env errors
docker-compose logs | grep -i "undefined\|not set\|missing.*env"
```

### Communication Test:
```bash
# Test Omni → Main API communication
curl -X POST http://localhost:8882/test-agent-connection

# Test Spark → Main API communication  
curl -X POST http://localhost:8883/test-workflow

# Test UI → All APIs
# Open http://localhost:8888 and check console for API errors
```

---

## ⚠️ Common Issues to Watch For

1. **Undefined Variables**: Services failing to start due to missing env vars
2. **Wrong Port Binding**: Services binding to wrong ports due to variable name changes
3. **Database Connection Failures**: Wrong database URL variable names
4. **Cross-Service Communication**: Services unable to find each other
5. **Logging Issues**: Logs not appearing due to changed log level variables

## 🔍 Quick Diagnostic Commands

```bash
# Find all env variable usage across all repos
find . -name "*.py" -o -name "*.js" -o -name "*.ts" | xargs grep -h "getenv\|process.env\|environ" | sort | uniq

# Check for potential missed conversions
grep -r "AM_\|AGENT_\|_AGENTS_" --include="*.py" --include="*.js" --include="*.ts" --include="*.sh" . | grep -v ".env" | grep -v "example"

# Verify all services have .env files
find . -maxdepth 2 -name ".env" -type f -exec echo "Found: {}" \; -exec head -5 {} \;
```

## ✅ Success Criteria

- All services start without environment errors
- Services can communicate with each other
- No "undefined" or "not set" errors in logs
- All health checks pass
- UI can connect to all backend services
- Database connections work properly
- Logging outputs to correct locations with proper levels

## 📝 Final Verification

After completing all reviews, document any issues found in `ENV_REVIEW_RESULTS.md` with:
- Service name
- File and line number
- Old variable name
- New variable name
- Whether it was fixed
- Any remaining concerns