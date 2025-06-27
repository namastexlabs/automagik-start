# 🚀 Automagik Start

**One-command installation for the complete Automagik Suite**

Automagik Start is the unified installer that sets up the entire Automagik ecosystem on your system with a single command. It handles dependency installation, repository cloning, environment configuration, and service deployment automatically.

## ✨ What's Included

- **am-agents-labs** - Main Orchestrator (PostgreSQL)
- **automagik-spark** - Workflow Engine (PostgreSQL + Redis)
- **automagik-tools** - MCP Tools (SSE + HTTP)
- **automagik-evolution** - WhatsApp API (PostgreSQL + Redis + RabbitMQ)
- **automagik-omni** - Multi-tenant Hub
- **automagik-ui-v2** - Main Interface (Production Build)
- **langflow** - Visual Flow Builder (Optional)

## 🎯 Quick Start

### One-Command Installation (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/namastexlabs/automagik-start/main/interactive.sh | bash
```

**That's it!** This single command will:
- Detect any `.env` file in your current directory
- Download the complete installer
- Set up all services with your configuration
- Launch the full Automagik suite

### With Your Own Configuration

```bash
# 1. Create your .env file with API keys
echo "OPENAI_API_KEY=sk-your-key-here" > .env
echo "ANTHROPIC_API_KEY=sk-ant-your-key" >> .env

# 2. Run the installer (it will find and use your .env)
curl -fsSL https://raw.githubusercontent.com/namastexlabs/automagik-start/main/interactive.sh | bash
```
*Downloads and runs installer with step-by-step prompts and full customization.*

### Manual Installation

```bash
git clone https://github.com/namastexlabs/automagik-start.git
cd automagik-start
./install.sh
```
*Manual download with full control over the installation process.*

## 📋 System Requirements

- **OS**: Ubuntu/Debian, macOS, or WSL
- **RAM**: 4GB+ recommended
- **Disk**: 10GB+ available space
- **Network**: Internet connection required

## 🔧 Installation Options

### Interactive Installation (Default)
```bash
./install.sh
```

### Non-Interactive Installation
```bash
./install.sh --non-interactive
```

### Skip Specific Components
```bash
./install.sh --skip-deps          # Skip dependency installation
./install.sh --skip-browser       # Skip browser tools
./install.sh --skip-clone         # Skip repository cloning
./install.sh --skip-envs          # Skip environment setup
./install.sh --skip-deploy        # Skip service deployment
```

### Install Specific Components Only
```bash
./install.sh dependencies         # Install dependencies only
./install.sh clone               # Clone repositories only
./install.sh keys                # Collect API keys only
./install.sh envs                # Setup environments only
./install.sh deploy              # Deploy services only
```

## 🎛️ Access Your Services

After installation, access your Automagik Suite at:

- **Main Interface**: http://localhost:8888
- **AM Agents Labs**: http://localhost:8881
- **Automagik Spark**: http://localhost:8883
- **Automagik Omni**: http://localhost:8882
- **MCP Tools SSE**: http://localhost:8884
- **MCP Tools HTTP**: http://localhost:8885
- **Evolution API**: http://localhost:9000
- **Langflow** (Optional): http://localhost:7860

## 🛠️ Management Commands

### Status and Monitoring
```bash
./scripts/deploy/status-display.sh         # Interactive dashboard
./scripts/deploy/start-services.sh status  # Quick status check
```

### Service Control
```bash
./scripts/deploy/start-services.sh start   # Start all services
./scripts/deploy/start-services.sh stop    # Stop all services
./scripts/deploy/start-services.sh restart # Restart all services
```

### System Verification
```bash
./install.sh verify                        # Verify installation
./scripts/system/detect-system.sh          # System compatibility check
```

## 🔑 API Key Configuration

During installation, you'll be prompted to configure API keys for:

- **OpenAI API** (Required for most agents)
- **Anthropic API** (For Claude integration)
- **Google API** (For Google services)
- **Azure OpenAI** (For Azure integration)
- **Groq API** (For Groq models)
- **Perplexity API** (For search capabilities)

API keys can be updated later by editing the `.env` files in each service directory.

## 🐳 Docker Services

The installer sets up these Docker services:

### Core Services
- **am-agents-labs-postgres** (Port: 5432)
- **automagik-spark-postgres** (Port: 5433)
- **automagik-spark-redis** (Port: 6379)
- **automagik-evolution-postgres** (Port: 5434)
- **automagik-evolution-redis** (Port: 6380)
- **automagik-evolution-rabbitmq** (Port: 5672, 15672)

### Application Services
- **am-agents-labs** (Port: 8881)
- **automagik-spark** (Port: 8883)
- **automagik-omni** (Port: 8882)
- **automagik-tools-sse** (Port: 8884)
- **automagik-tools-http** (Port: 8885)
- **automagik-evolution** (Port: 9000)
- **automagik-ui-v2** (Port: 8888)

## 🔍 Troubleshooting

### Common Issues

1. **Port Conflicts**: The installer automatically detects and resolves port conflicts
2. **Permission Issues**: Ensure you have sudo privileges for dependency installation
3. **Docker Issues**: Make sure Docker is running and accessible
4. **Network Issues**: Check internet connectivity for downloading dependencies

### Logs and Debugging

- Installation logs: `./automagik-install.log`
- Service logs: `docker-compose logs [service-name]`
- System detection: `./scripts/system/detect-system.sh`

### Getting Help

1. Check the logs for error details
2. Verify system compatibility: `./install.sh verify`
3. Run individual installation steps to isolate issues
4. Check service status: `./scripts/deploy/status-display.sh`

## 🗂️ Project Structure

```
automagik-start/
├── install.sh                 # Main installer
├── docker-compose.yml         # Service definitions
├── scripts/
│   ├── utils/                 # Utility functions
│   │   ├── colors.sh         # Terminal colors
│   │   ├── logging.sh        # Logging system
│   │   └── port-check.sh     # Port management
│   ├── system/               # System detection & deps
│   │   ├── detect-system.sh  # OS/hardware detection
│   │   ├── install-deps-ubuntu.sh
│   │   └── install-deps-macos.sh
│   ├── setup/                # Repository & environment setup
│   │   ├── clone-repos.sh    # Repository cloning
│   │   ├── collect-keys.sh   # API key collection
│   │   └── setup-envs.sh     # Environment generation
│   └── deploy/               # Deployment & monitoring
│       ├── start-services.sh # Service management
│       └── status-display.sh # Status dashboard
└── README.md
```

## 🤝 Contributing

We welcome contributions! Please feel free to submit issues, feature requests, or pull requests.

## 📄 License

This project is licensed under the MIT License - see the individual repository licenses for component-specific terms.

## 🔗 Related Projects

- [am-agents-labs](https://github.com/namastexlabs/am-agents-labs) - Main Orchestrator
- [automagik-ui-v2](https://github.com/namastexlabs/automagik-ui-v2) - Main Interface
- [automagik-omni](https://github.com/namastexlabs/automagik-omni) - Multi-tenant Hub
- [automagik-spark](https://github.com/namastexlabs/automagik-spark) - Workflow Engine
- [automagik-tools](https://github.com/namastexlabs/automagik-tools) - MCP Tools
- [automagik-evolution](https://github.com/namastexlabs/automagik-evolution) - WhatsApp API

---

**Made with ❤️ by the Namastex Labs team**