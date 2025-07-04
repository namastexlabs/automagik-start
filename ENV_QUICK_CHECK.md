# 🚀 Quick Environment Variable Check Commands

## Critical Pattern Searches (Run from automagik root)

```bash
# 1. Find ALL legacy patterns that should NOT exist
find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -exec grep -l "AM_PORT\|AM_ENV\|AM_LOG\|AGENT_API\|AUTOMAGIK_AGENTS_" {} \; 2>/dev/null

# 2. Find generic variables that should be prefixed
find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -exec grep -l "getenv.*['\"]DATABASE_URL['\"]" {} \; 2>/dev/null | grep -v AUTOMAGIK

# 3. Check for PORT/HOST without prefix
find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -exec grep -l "getenv.*['\"]PORT['\"]" {} \; 2>/dev/null

# 4. Verify all config files use new patterns
for dir in am-agents-labs automagik-spark automagik-omni automagik-tools automagik-ui; do
  echo "=== Checking $dir ==="
  grep -n "getenv\|environ" $dir/src/config.py 2>/dev/null || \
  grep -n "process.env" $dir/lib/env-config.ts 2>/dev/null || \
  echo "Config file not found"
done
```

## Service-Specific Quick Checks

### am-agents-labs
```bash
cd am-agents-labs && grep -r "AM_" scripts/ | grep -v ".env"
```

### automagik-spark  
```bash
cd automagik-spark && grep "DATABASE_URL.*not set" automagik_spark/core/database/session.py
```

### automagik-omni
```bash
cd automagik-omni && grep -c "AUTOMAGIK_OMNI_" src/config.py
# Should return 15+ matches
```

### automagik-tools
```bash
cd automagik-tools && grep "getenv.*PORT" src/automagik_tools/cli.py
# Should show AUTOMAGIK_TOOLS_SSE_PORT
```

### automagik-ui
```bash
cd automagik-ui && grep "DATABASE_PATH" lib/env-config.ts
# Should show AUTOMAGIK_UI_DATABASE_PATH
```

## One-Line Health Check
```bash
# Run from automagik root - should return 0 if all clean
find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -name "*.example" \
  -exec grep -E "AM_PORT|AM_ENV|AGENT_API_|_AGENTS_API_|[^_]DATABASE_URL|[^_]PORT['\"]" {} \; | wc -l
```