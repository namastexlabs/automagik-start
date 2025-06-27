# Automagik Environment Setup

This repository provides scripts to automatically generate environment files for all Automagik repositories with proper Docker-internal service URLs and variable mapping.

## 🚀 Quick Start (Standalone)

The easiest way to set up environments is using the standalone script that can be curled and run from any directory:

```bash
# Navigate to your directory containing cloned Automagik repositories
cd /path/to/your/automagik-repos

# Download and run the standalone environment setup
curl -fsSL https://raw.githubusercontent.com/namastexlabs/automagik-start/main/setup-envs-standalone.sh | bash
```

## 🏗️ What It Does

The script automatically:

1. **Detects Repository Structure**: Finds all Automagik repositories in the current directory
2. **Handles Different .env File Types**: 
   - Standard: `.env.example` → `.env`
   - UI v2: `.env.local.example` → `.env.local`
   - Omni: `.env-example` → `.env`
3. **Maps Variables**: Uses main `.env` file if present, falls back to defaults
4. **Configures Docker URLs**: Sets proper container-to-container communication URLs
5. **Generates Headers**: Adds generation timestamps and descriptions

## 📁 Supported Repositories

- **am-agents-labs**: PostgreSQL mode with agents configuration
- **automagik-spark**: Workflow engine with PostgreSQL and Redis
- **automagik-tools**: MCP tools with API configurations
- **automagik-evolution**: WhatsApp integration with Evolution API
- **automagik-omni**: Multi-tenant hub configuration
- **automagik-ui-v2**: Frontend application configuration

## 🔧 Configuration Options

### Using Main .env File (Recommended)

Create a main `.env` file in your repository root with your API keys:

```bash
# Main .env file
OPENAI_API_KEY=sk-your-openai-key
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key
AM_API_KEY=your-am-api-key
EVOLUTION_API_KEY=your-evolution-key
```

The script will automatically map these to the appropriate repositories.

### Default Values

If no main `.env` file is found, the script uses sensible defaults:
- API keys: `namastex888` (for development)
- Database URLs: Docker-internal container names
- Service URLs: Proper inter-service communication

## 🐳 Docker Integration

The generated environment files are configured for Docker deployment with:

### Service-to-Service URLs
- **am-agents-labs**: `http://am-agents-labs:8881`
- **automagik-spark**: `http://automagik-spark-api:8883`
- **automagik-evolution**: `http://automagik-evolution:9000`

### Database URLs
- **PostgreSQL**: `postgresql://user:pass@service-postgres:5432/database`
- **Redis**: `redis://service-redis:6379`
- **RabbitMQ**: `amqp://user:pass@service-rabbitmq:5672`

## 🔍 Example Output

```
Automagik Environment Setup
===========================
✅ Found main .env file: ./.env
ℹ️ Processing automagik-spark environment...
✅ Generated environment file for automagik-spark
ℹ️ Processing automagik-omni environment...
✅ Generated environment file for automagik-omni
ℹ️ Processing automagik-tools environment...
✅ Generated environment file for automagik-tools
ℹ️ Processing am-agents-labs environment...
✅ Generated environment file for am-agents-labs
ℹ️ Processing automagik-ui-v2 environment...
✅ Generated environment file for automagik-ui-v2
ℹ️ Processing automagik-evolution environment...
✅ Generated environment file for automagik-evolution

✅ Generated environment files for: automagik-spark automagik-omni automagik-tools am-agents-labs automagik-ui-v2 automagik-evolution
✅ Environment setup complete!
```

## 🛠️ Advanced Usage

### Local Development

If you've cloned this repository and want to use the local scripts:

```bash
# From the automagik-start directory
./scripts/setup/setup-envs.sh setup

# Or for verification
./scripts/setup/setup-envs.sh verify
```

### Manual Download

```bash
# Download the standalone script
curl -O https://raw.githubusercontent.com/namastexlabs/automagik-start/main/setup-envs-standalone.sh
chmod +x setup-envs-standalone.sh

# Run it
./setup-envs-standalone.sh
```

## 🚨 Important Notes

1. **Run from Repository Directory**: The script must be run from a directory containing the Automagik repositories
2. **Overwrites Existing Files**: Will overwrite any existing `.env` files
3. **Docker-Ready**: Generated files are optimized for Docker deployment
4. **No Root Required**: Script runs with user permissions

## 📋 Requirements

- **Bash**: Script requires bash shell
- **curl**: For downloading the script (if using curl method)
- **Repositories**: At least one Automagik repository in current directory

## 🔧 Troubleshooting

### "No Automagik repositories found"
- Ensure you're in a directory containing cloned Automagik repositories
- Check that repository names match exactly (case-sensitive)

### "Permission denied"
- Make sure the script is executable: `chmod +x setup-envs-standalone.sh`
- Ensure you have write permissions in the repository directories

### Variable not mapping correctly
- Check your main `.env` file syntax
- Ensure variable names match exactly
- Variables are case-sensitive

## 📝 Contributing

To modify the environment mapping:
1. Edit `setup-envs-standalone.sh`
2. Update the `get_mapped_value()` function
3. Add new repository configurations to `REPO_CONFIGS`
4. Test with your repository structure

This script is designed to be portable and work across different user setups without hardcoded paths or assumptions about directory structure.