#!/bin/bash
# ===================================================================
# 🔧 Automagik Suite - Local Configuration Setup
# ===================================================================
# This script sets up proper .env files for each service to connect
# to Docker infrastructure using localhost networking

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Symbols
CHECKMARK="✅"
WARNING="⚠️"
ERROR="❌"
INFO="ℹ️"
GEAR="⚙️"

print_status() {
    echo -e "${PURPLE}${GEAR} $1${RESET}"
}

print_success() {
    echo -e "${GREEN}${CHECKMARK} $1${RESET}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} $1${RESET}"
}

print_error() {
    echo -e "${RED}${ERROR} $1${RESET}"
}

print_info() {
    echo -e "${CYAN}${INFO} $1${RESET}"
}

# Project paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_DIR="${PROJECT_ROOT}/tmp/automagik-start"

print_status "Setting up local configuration for Automagik Suite services"
echo ""

# ===========================================
# Create service-specific .env files
# ===========================================

# am-agents-labs
print_info "Configuring am-agents-labs..."
cat > "${SERVICES_DIR}/am-agents-labs/.env" << 'EOF'
# ===================================================================
# 🤖 am-agents-labs - Local Service Configuration
# ===================================================================

# Database Configuration (PostgreSQL in Docker)
DATABASE_TYPE=postgresql
DATABASE_URL=postgresql://postgres:postgres@localhost:5401/am_agents_labs

# Service Configuration
AM_PORT=8881
HOST=127.0.0.1
AM_LOG_LEVEL=INFO
AM_LOG_SQL=false

# API Keys (UPDATE WITH YOUR KEYS)
OPENAI_API_KEY=sk-your-openai-api-key-here
ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key-here
GEMINI_API_KEY=your-gemini-api-key-here
GROQ_API_KEY=gsk_your-groq-api-key-here

# Internal API Key
AUTOMAGIK_API_KEY=namastex888

# Optional: Neo4j (if using advanced memory features)
# NEO4J_URI=bolt://localhost:7474
# NEO4J_USERNAME=neo4j
# NEO4J_PASSWORD=password

# Optional: Graphiti (if using AI memory)
# GRAPHITI_URL=http://localhost:8000
EOF

# automagik-spark
print_info "Configuring automagik-spark..."
cat > "${SERVICES_DIR}/automagik-spark/.env" << 'EOF'
# ===================================================================
# ⚡ automagik-spark - Local Service Configuration
# ===================================================================

# Database Configuration (PostgreSQL in Docker)
POSTGRES_HOST=localhost
POSTGRES_PORT=5402
POSTGRES_USER=automagik
POSTGRES_PASSWORD=automagik
POSTGRES_DB=automagik
DATABASE_URL=postgresql://automagik:automagik@localhost:5402/automagik

# Redis Configuration (Redis in Docker)
REDIS_URL=redis://localhost:5412
CELERY_BROKER_URL=redis://localhost:5412
CELERY_RESULT_BACKEND=redis://localhost:5412

# Service Configuration
AUTOMAGIK_HOST=127.0.0.1
AUTOMAGIK_PORT=8883
HOST=127.0.0.1
PORT=8883
LOG_LEVEL=info

# API Keys (UPDATE WITH YOUR KEYS)
OPENAI_API_KEY=sk-your-openai-api-key-here
ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key-here
GEMINI_API_KEY=your-gemini-api-key-here
GROQ_API_KEY=gsk_your-groq-api-key-here
EOF

# automagik-tools
print_info "Configuring automagik-tools..."
cat > "${SERVICES_DIR}/automagik-tools/.env" << 'EOF'
# ===================================================================
# 🛠️ automagik-tools - Local Service Configuration
# ===================================================================

# Service Configuration
HOST=127.0.0.1
PORT=8884

# API Keys (UPDATE WITH YOUR KEYS)
OPENAI_API_KEY=sk-your-openai-api-key-here
ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key-here
GEMINI_API_KEY=your-gemini-api-key-here
GROQ_API_KEY=gsk_your-groq-api-key-here

# Evolution API Configuration
EVOLUTION_API_KEY=namastex888
EVOLUTION_API_URL=http://localhost:9000

# MCP Configuration
MCP_LOG_LEVEL=info
EOF

# automagik-omni
print_info "Configuring automagik-omni..."
cat > "${SERVICES_DIR}/automagik-omni/.env" << 'EOF'
# ===================================================================
# 🔗 automagik-omni - Local Service Configuration
# ===================================================================

# Service Configuration
API_HOST=127.0.0.1
API_PORT=8882

# Database Configuration (SQLite for omni-hub)
DATABASE_URL=sqlite:///./data/omnihub.db
SQLITE_DB_PATH=./data/omnihub.db

# Agent API Configuration (am-agents-labs)
AGENT_API_URL=http://127.0.0.1:8881
AGENT_API_KEY=namastex888
DEFAULT_AGENT_NAME=simple_agent

# Evolution API Configuration (WhatsApp)
EVOLUTION_TRANSCRIPT_API=http://localhost:9000
EVOLUTION_TRANSCRIPT_API_KEY=namastex888
WHATSAPP_INSTANCE=default

# Session Configuration
SESSION_ID_PREFIX=instance-

# Logging
LOG_LEVEL=DEBUG
LOG_VERBOSITY=full

# Python Path
PYTHONPATH=/app
EOF

# automagik-ui-v2
print_info "Configuring automagik-ui-v2..."
cat > "${SERVICES_DIR}/automagik-ui-v2/.env" << 'EOF'
# ===================================================================
# 🎨 automagik-ui-v2 - Local Service Configuration
# ===================================================================

# Node.js Configuration
NODE_ENV=production
PORT=8888
HOSTNAME=127.0.0.1
NEXT_TELEMETRY_DISABLED=1

# API URLs (connecting to local services)
NEXT_PUBLIC_API_URL=http://127.0.0.1:8881
NEXT_PUBLIC_SPARK_URL=http://127.0.0.1:8883
NEXT_PUBLIC_OMNI_URL=http://127.0.0.1:8882
NEXT_PUBLIC_TOOLS_SSE_URL=http://127.0.0.1:8884
NEXT_PUBLIC_TOOLS_HTTP_URL=http://127.0.0.1:8885
NEXT_PUBLIC_EVOLUTION_URL=http://localhost:9000

# Database (SQLite for frontend data)
DATABASE_URL=sqlite:///./data/automagik-ui.db
EOF

print_success "Service configurations created successfully!"
echo ""

# ===========================================
# Create data directories
# ===========================================
print_status "Creating data directories..."

for service in am-agents-labs automagik-spark automagik-tools automagik-omni automagik-ui-v2; do
    data_dir="${SERVICES_DIR}/${service}/data"
    if [ ! -d "$data_dir" ]; then
        mkdir -p "$data_dir"
        print_info "Created data directory for $service"
    fi
done

print_success "Data directories created!"
echo ""

# ===========================================
# API Keys Setup Reminder
# ===========================================
print_warning "IMPORTANT: Update API Keys"
echo ""
echo -e "${YELLOW}You need to update the following API keys in the .env files:${RESET}"
echo ""
echo -e "  ${CYAN}OpenAI API Key:${RESET}     OPENAI_API_KEY=sk-your-openai-api-key-here"
echo -e "  ${CYAN}Anthropic API Key:${RESET}  ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key-here"
echo -e "  ${CYAN}Gemini API Key:${RESET}     GEMINI_API_KEY=your-gemini-api-key-here"
echo -e "  ${CYAN}Groq API Key:${RESET}       GROQ_API_KEY=gsk_your-groq-api-key-here"
echo ""
echo -e "${CYAN}Files to update:${RESET}"
for service in am-agents-labs automagik-spark automagik-tools; do
    echo -e "  - ${SERVICES_DIR}/${service}/.env"
done
echo ""

# ===========================================
# Network Configuration Summary
# ===========================================
print_info "Network Configuration Summary"
echo ""
echo -e "${CYAN}Docker Infrastructure (accessible via localhost):${RESET}"
echo -e "  PostgreSQL (am-agents-labs):  ${GREEN}localhost:5401${RESET}"
echo -e "  PostgreSQL (automagik-spark): ${GREEN}localhost:5402${RESET}"
echo -e "  PostgreSQL (evolution):       ${GREEN}localhost:5403${RESET}"
echo -e "  Redis (automagik-spark):      ${GREEN}localhost:5412${RESET}"
echo -e "  Redis (evolution):            ${GREEN}localhost:5413${RESET}"
echo -e "  RabbitMQ:                     ${GREEN}localhost:5431${RESET}"
echo -e "  Evolution API:                ${GREEN}localhost:9000${RESET}"
echo ""
echo -e "${CYAN}Local Services:${RESET}"
echo -e "  am-agents-labs:               ${GREEN}localhost:8881${RESET}"
echo -e "  automagik-spark:              ${GREEN}localhost:8883${RESET}"
echo -e "  automagik-tools:              ${GREEN}localhost:8884${RESET}"
echo -e "  automagik-omni:               ${GREEN}localhost:8882${RESET}"
echo -e "  automagik-ui-v2:              ${GREEN}localhost:8888${RESET}"
echo ""

print_success "Local configuration setup completed!"
echo ""
echo -e "${GREEN}Next steps:${RESET}"
echo -e "  1. Update API keys in the .env files"
echo -e "  2. Run: ${CYAN}make setup-infrastructure${RESET} to start Docker infrastructure"
echo -e "  3. Run: ${CYAN}make install-all-services${RESET} to install systemd services"
echo -e "  4. Run: ${CYAN}make start-all-services${RESET} to start all services"
echo ""