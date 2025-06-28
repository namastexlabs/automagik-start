// ===================================================================
// 🚀 Automagik Suite - Centralized PM2 Configuration
// ===================================================================
// This file manages all Automagik services in production using PM2
// Services are dynamically configured based on the installation path

const path = require('path');
const fs = require('fs');

// Get the installation root directory
const INSTALL_ROOT = __dirname;

// Load environment variables from .env file if it exists
const envPath = path.join(INSTALL_ROOT, '.env');
let envVars = {};
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  envContent.split('\n').forEach(line => {
    const [key, value] = line.split('=');
    if (key && value) {
      envVars[key.trim()] = value.trim().replace(/^["']|["']$/g, '');
    }
  });
}

module.exports = {
  apps: [
    // ================================
    // AM-Agents-Labs (Core Orchestrator)
    // ================================
    {
      name: 'am-agents-labs',
      cwd: path.join(INSTALL_ROOT, 'am-agents-labs'),
      script: '.venv/bin/python',
      args: '-m src',
      interpreter: 'none',
      env: {
        ...envVars,
        PYTHONPATH: path.join(INSTALL_ROOT, 'am-agents-labs'),
        AM_PORT: envVars.AM_PORT || '8881',
        AM_HOST: envVars.AM_HOST || '0.0.0.0',
        AM_ENV: envVars.AM_ENV || 'production',
        NODE_ENV: 'production'
      },
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 1000,
      kill_timeout: 5000,
      error_file: path.join(INSTALL_ROOT, 'am-agents-labs/logs/err.log'),
      out_file: path.join(INSTALL_ROOT, 'am-agents-labs/logs/out.log'),
      log_file: path.join(INSTALL_ROOT, 'am-agents-labs/logs/combined.log'),
      merge_logs: true,
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    
    // ================================
    // Automagik-Spark (Workflow Engine)
    // ================================
    {
      name: 'automagik-spark',
      cwd: path.join(INSTALL_ROOT, 'automagik-spark'),
      script: '.venv/bin/uvicorn',
      args: 'automagik_spark.api.app:app --host 0.0.0.0 --port ' + (envVars.AUTOMAGIK_SPARK_PORT || '8883'),
      interpreter: 'none',
      env: {
        ...envVars,
        PYTHONPATH: path.join(INSTALL_ROOT, 'automagik-spark'),
        AUTOMAGIK_SPARK_PORT: envVars.AUTOMAGIK_SPARK_PORT || '8883',
        HOST: envVars.HOST || '0.0.0.0',
        AUTOMAGIK_ENV: envVars.AUTOMAGIK_ENV || 'production',
        NODE_ENV: 'production'
      },
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 1000,
      kill_timeout: 5000,
      error_file: path.join(INSTALL_ROOT, 'automagik-spark/logs/err.log'),
      out_file: path.join(INSTALL_ROOT, 'automagik-spark/logs/out.log'),
      log_file: path.join(INSTALL_ROOT, 'automagik-spark/logs/combined.log'),
      merge_logs: true,
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    
    // ================================
    // Automagik-Omni (Multi-tenant Hub)
    // ================================
    {
      name: 'automagik-omni',
      cwd: path.join(INSTALL_ROOT, 'automagik-omni'),
      script: '.venv/bin/uvicorn',
      args: 'src.api.app:app --host 0.0.0.0 --port ' + (envVars.AUTOMAGIK_OMNI_PORT || '8882'),
      interpreter: 'none',
      env: {
        ...envVars,
        PYTHONPATH: path.join(INSTALL_ROOT, 'automagik-omni'),
        API_PORT: envVars.AUTOMAGIK_OMNI_PORT || '8882',
        API_HOST: envVars.API_HOST || '0.0.0.0',
        NODE_ENV: 'production'
      },
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 1000,
      kill_timeout: 5000,
      error_file: path.join(INSTALL_ROOT, 'automagik-omni/logs/err.log'),
      out_file: path.join(INSTALL_ROOT, 'automagik-omni/logs/out.log'),
      log_file: path.join(INSTALL_ROOT, 'automagik-omni/logs/combined.log'),
      merge_logs: true,
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    
    // ================================
    // Automagik-Tools (MCP Hub)
    // ================================
    {
      name: 'automagik-tools',
      cwd: path.join(INSTALL_ROOT, 'automagik-tools'),
      script: '.venv/bin/automagik-tools',
      args: 'hub --host 0.0.0.0 --port ' + (envVars.AUTOMAGIK_TOOLS_PORT || '8884') + ' --transport sse',
      interpreter: 'none',
      env: {
        ...envVars,
        PYTHONPATH: path.join(INSTALL_ROOT, 'automagik-tools'),
        AUTOMAGIK_TOOLS_PORT: envVars.AUTOMAGIK_TOOLS_PORT || '8884',
        HOST: envVars.HOST || '0.0.0.0',
        NODE_ENV: 'production'
      },
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 1000,
      kill_timeout: 5000,
      error_file: path.join(INSTALL_ROOT, 'automagik-tools/logs/err.log'),
      out_file: path.join(INSTALL_ROOT, 'automagik-tools/logs/out.log'),
      log_file: path.join(INSTALL_ROOT, 'automagik-tools/logs/combined.log'),
      merge_logs: true,
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    
    // ================================
    // Automagik-UI (Next.js Frontend)
    // ================================
    {
      name: 'automagik-ui',
      cwd: path.join(INSTALL_ROOT, 'automagik-ui'),
      script: 'pnpm',
      args: 'start',
      interpreter: 'none',
      env: {
        ...envVars,
        NODE_ENV: 'production',
        PORT: envVars.AUTOMAGIK_UI_PORT || '8888'
      },
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 1000,
      kill_timeout: 5000,
      error_file: path.join(INSTALL_ROOT, 'automagik-ui/logs/err.log'),
      out_file: path.join(INSTALL_ROOT, 'automagik-ui/logs/out.log'),
      log_file: path.join(INSTALL_ROOT, 'automagik-ui/logs/combined.log'),
      merge_logs: true,
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    }
  ],
  
  // PM2 deployment configuration
  deploy: {
    production: {
      'pre-deploy-local': 'echo "Starting deployment..."',
      'post-deploy': 'pm2 reload ecosystem.config.js --env production',
      'pre-setup': 'echo "Setting up PM2 deployment..."'
    }
  }
};