# 🚀 Automagik Suite

**Production-grade AI orchestration platform with unified installation**

Automagik Suite is a comprehensive AI workflow automation platform that combines multiple services into a cohesive ecosystem. This repository provides a streamlined installation process that sets up the entire suite with minimal configuration.

## ✨ Architecture Overview

The Automagik Suite uses a hybrid architecture:
- **Infrastructure**: Docker containers with host networking for databases and message queues
- **Application Services**: PM2-managed processes for better performance and native integration
- **Optional Services**: LangFlow and Evolution API can be enabled during installation

## 📦 Components

### Core Services
- **am-agents-labs** - Main AI orchestrator and agent management (Port: 8881)
- **automagik-spark** - Workflow engine with Celery workers (Port: 8883)
- **automagik-tools** - MCP tools hub with SSE/HTTP endpoints (Ports: 8884/8885)
- **automagik-omni** - Multi-tenant hub for instance management (Port: 8882)
- **automagik-ui** - Next.js web interface (Port: 8888)

### Optional Services
- **langflow** - Visual AI workflow builder (Port: 7860)
- **automagik-evolution** - WhatsApp API integration (Port: 9000)

### Infrastructure (Docker)
- **PostgreSQL** databases for each service (Ports: 5401-5403)
- **Redis** instances for caching and queues (Ports: 5411-5413)
- **RabbitMQ** for Evolution API messaging (Port: 5431)

## 🎯 Quick Start

### Prerequisites
- Ubuntu/Debian or macOS
- Git
- Sudo access (for system dependencies only)

### One-Command Installation

```bash
git clone https://github.com/namastexlabs/automagik-suite.git
cd automagik-suite
./install.sh
```

The installer will:
1. Install system dependencies (Python 3.12, Node.js 22 LTS, Docker, PM2)
2. Prompt for optional services (LangFlow, Evolution API)
3. Clone all service repositories
4. Set up Docker infrastructure
5. Build and configure all services
6. Start everything with PM2

## 🔧 Configuration

### Environment Variables

All configuration is managed through a single `.env` file in the root directory:

```bash
# Copy the example file
cp .env.example .env

# Edit with your API keys
nano .env
```

Key configurations:
- **AI Providers**: OpenAI, Anthropic, Google Gemini API keys
- **Database URLs**: All use localhost with specific ports
- **Service URLs**: All services accessible on localhost
- **API Keys**: Internal service authentication keys

### PM2 Process Management

Services are managed by PM2 using `ecosystem.config.js`:

```bash
# View all services
make status

# Start all services
make start

# Stop all services
make stop

# View logs
make logs

# Restart specific service
make restart-agents
```

## 📋 Makefile Commands

### Essential Commands
- `make install` - Complete installation (infrastructure + services)
- `make start` - Start everything
- `make stop` - Stop everything
- `make restart` - Restart all services
- `make update` - Git pull and restart
- `make logs` - View colorized logs
- `make status` - Check service status

### Service-Specific Commands
- `make start-[service]` - Start specific service (agents, spark, tools, omni, ui)
- `make stop-[service]` - Stop specific service
- `make restart-[service]` - Restart specific service
- `make logs-[service]` - View specific service logs

### Optional Services
- `make start-langflow` - Start LangFlow
- `make stop-langflow` - Stop LangFlow
- `make start-evolution` - Start Evolution API
- `make stop-evolution` - Stop Evolution API

### Infrastructure
- `make start-infrastructure` - Start Docker containers
- `make stop-infrastructure` - Stop Docker containers

## 🐳 Docker Architecture

All Docker services use **host network mode** for simplified networking:
- No port mapping required
- Direct access to localhost
- Full LAN connectivity (e.g., 192.168.x.x)
- Better performance

Docker compose files:
- `docker-infrastructure.yml` - Core databases and Redis
- `docker-langflow.yml` - LangFlow service (optional)
- `docker-evolution.yml` - Evolution API and dependencies (optional)

## 🗂️ Project Structure

```
automagik-suite/
├── .env                        # Main configuration file
├── .env.example               # Configuration template
├── Makefile                   # Service orchestration commands
├── ecosystem.config.js        # PM2 configuration
├── install.sh                 # Installation script
├── docker-infrastructure.yml  # Core Docker services
├── docker-langflow.yml       # LangFlow Docker service
├── docker-evolution.yml      # Evolution API Docker services
├── scripts/                   # Utility scripts
│   ├── utils/                # Shared utilities
│   ├── system/              # OS-specific installers
│   └── deploy/              # Deployment scripts
├── am-agents-labs/           # Main orchestrator
├── automagik-spark/         # Workflow engine
├── automagik-tools/         # MCP tools
├── automagik-omni/          # Multi-tenant hub
└── automagik-ui/            # Web interface
```

## 🔍 Service Details

### am-agents-labs (Port 8881)
- Main AI orchestration service
- Agent management and routing
- PostgreSQL database on port 5401
- Redis cache on port 5411

### automagik-spark (Port 8883)
- Workflow automation engine
- Celery task processing
- PostgreSQL database on port 5402
- Redis queue on port 5412

### automagik-tools (Ports 8884/8885)
- MCP (Model Context Protocol) tools
- SSE endpoint on port 8884
- HTTP endpoint on port 8885
- No database required

### automagik-omni (Port 8882)
- Multi-tenant instance management
- API gateway for multiple services
- Uses spark database

### automagik-ui (Port 8888)
- Next.js 15 web interface
- Real-time updates via SSE
- Production build served by PM2

## 🚀 Development Workflow

### Local Development
```bash
# Start in development mode
make dev

# Follow logs
make logs-follow

# Check specific service
make status-spark
```

### Updating Services
```bash
# Pull latest changes
make pull

# Update and restart
make update
```

### Adding New Services
1. Clone repository to root directory
2. Add to `ecosystem.config.js`
3. Update Makefile targets
4. Run `make install-[service]`

## 🛠️ Troubleshooting

### Common Issues

**Port Conflicts**
```bash
# Check what's using a port
lsof -i :8881

# Kill process using port
kill -9 $(lsof -t -i:8881)
```

**PM2 Issues**
```bash
# Reset PM2
pm2 kill
pm2 resurrect

# Clear logs
pm2 flush
```

**Docker Issues**
```bash
# Reset Docker containers
make stop-infrastructure
docker system prune -a
make start-infrastructure
```

### Logs Location
- PM2 logs: `~/.pm2/logs/`
- Service logs: `[service]/logs/`
- Install log: `automagik-install.log`

### Health Checks
- Infrastructure: `make status-infrastructure`
- Services: `make status`
- Specific service: `curl http://localhost:[port]/health`

## 📡 API Endpoints

### Service URLs
- Main Orchestrator: http://localhost:8881
- Workflow Engine: http://localhost:8883
- Tools SSE: http://localhost:8884
- Tools HTTP: http://localhost:8885
- Multi-tenant Hub: http://localhost:8882
- Web Interface: http://localhost:8888
- LangFlow (optional): http://localhost:7860
- Evolution API (optional): http://localhost:9000

### Authentication
All services use API key authentication via `x-api-key` header.
Default key: `namastex888` (configure in `.env`)

## 🔐 Security Notes

- Change default API keys in production
- Use strong database passwords
- Configure firewall rules for exposed ports
- Enable HTTPS in production environments
- Regularly update dependencies

## 📚 Additional Resources

- [Service Documentation](docs/)
- [API Reference](docs/api/)
- [Deployment Guide](docs/deployment.md)
- [Contributing Guidelines](CONTRIBUTING.md)

## 📄 License

MIT License - see LICENSE file for details.

---

Built with ❤️ by NamasteX Labs