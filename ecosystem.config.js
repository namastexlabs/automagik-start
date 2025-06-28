// ===================================================================
// 🚀 Automagik Suite - Centralized PM2 Configuration
// ===================================================================
// This file manages all Automagik services in production using PM2
// Services are dynamically configured based on the installation path

const path = require('path');
const fs = require('fs');

// Get the installation root directory
const INSTALL_ROOT = __dirname;

// ===================================================================
// Version extraction utilities
// ===================================================================

/**
 * Extract version from pyproject.toml file using standardized approach
 * @param {string} projectPath - Path to the project directory
 * @returns {string} Version string or 'unknown'
 */
function extractVersionFromPyproject(projectPath) {
  const pyprojectPath = path.join(projectPath, 'pyproject.toml');
  
  if (!fs.existsSync(pyprojectPath)) {
    return 'unknown';
  }
  
  try {
    const content = fs.readFileSync(pyprojectPath, 'utf8');
    
    // Standard approach: Static version in [project] section
    const projectVersionMatch = content.match(/\[project\][\s\S]*?version\s*=\s*["']([^"']+)["']/);
    if (projectVersionMatch) {
      return projectVersionMatch[1];
    }
    
    // Fallback: Simple version = "..." pattern anywhere in file
    const simpleVersionMatch = content.match(/^version\s*=\s*["']([^"']+)["']/m);
    if (simpleVersionMatch) {
      return simpleVersionMatch[1];
    }
    
    return 'unknown';
  } catch (error) {
    console.warn(`Failed to read version from ${pyprojectPath}:`, error.message);
    return 'unknown';
  }
}

/**
 * Enhanced version extraction for Python projects with multiple fallbacks
 * @param {string} projectPath - Path to the project directory
 * @returns {string} Version string or git commit hash
 */
function extractVersionFromPython(projectPath) {
  // Try pyproject.toml first
  let version = extractVersionFromPyproject(projectPath);
  if (version !== 'unknown') return version;
  
  // Try __init__.py in src directory
  const srcInitPath = path.join(projectPath, 'src', '__init__.py');
  if (fs.existsSync(srcInitPath)) {
    try {
      const content = fs.readFileSync(srcInitPath, 'utf8');
      const match = content.match(/__version__\s*=\s*["']([^"']+)["']/);
      if (match) return match[1];
    } catch (error) {
      console.warn(`Failed to read version from ${srcInitPath}`);
    }
  }
  
  // Try main package __init__.py
  const projectName = path.basename(projectPath);
  const packageInitPath = path.join(projectPath, projectName.replace('-', '_'), '__init__.py');
  if (fs.existsSync(packageInitPath)) {
    try {
      const content = fs.readFileSync(packageInitPath, 'utf8');
      const match = content.match(/__version__\s*=\s*["']([^"']+)["']/);
      if (match) return match[1];
    } catch (error) {
      console.warn(`Failed to read version from ${packageInitPath}`);
    }
  }
  
  // Fallback to git commit hash (first 7 characters)
  try {
    const { execSync } = require('child_process');
    const commit = execSync('git rev-parse --short HEAD', {
      cwd: projectPath,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore']
    }).trim();
    return `git-${commit}`;
  } catch (error) {
    return 'unknown';
  }
}

/**
 * Extract version from package.json file
 * @param {string} projectPath - Path to the project directory
 * @returns {string} Version string or 'unknown'
 */
function extractVersionFromPackageJson(projectPath) {
  const packageJsonPath = path.join(projectPath, 'package.json');
  
  if (!fs.existsSync(packageJsonPath)) {
    return 'unknown';
  }
  
  try {
    const content = fs.readFileSync(packageJsonPath, 'utf8');
    const packageData = JSON.parse(content);
    return packageData.version || 'unknown';
  } catch (error) {
    console.warn(`Failed to read version from ${packageJsonPath}:`, error.message);
    return 'unknown';
  }
}

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
      version: extractVersionFromPython(path.join(INSTALL_ROOT, 'am-agents-labs')),
      env: {
        ...envVars,
        PYTHONPATH: path.join(INSTALL_ROOT, 'am-agents-labs'),
        AUTOMAGIK_AGENTS_API_PORT: envVars.AUTOMAGIK_AGENTS_API_PORT || '8881',
        AUTOMAGIK_AGENTS_API_HOST: envVars.AUTOMAGIK_AGENTS_API_HOST || '0.0.0.0',
        AUTOMAGIK_AGENTS_API_KEY: envVars.AUTOMAGIK_AGENTS_API_KEY || 'namastex888',
        AUTOMAGIK_AGENTS_ENV: envVars.AUTOMAGIK_AGENTS_ENV || 'production',
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
    // Automagik-Spark API (Workflow Engine)
    // ================================
    {
      name: 'automagik-spark-api',
      cwd: path.join(INSTALL_ROOT, 'automagik-spark'),
      script: '.venv/bin/uvicorn',
      args: 'automagik_spark.api.app:app --host 0.0.0.0 --port ' + (envVars.AUTOMAGIK_SPARK_API_PORT || '8883'),
      interpreter: 'none',
      version: extractVersionFromPython(path.join(INSTALL_ROOT, 'automagik-spark')),
      env: {
        ...envVars,
        PYTHONPATH: path.join(INSTALL_ROOT, 'automagik-spark'),
        AUTOMAGIK_SPARK_API_PORT: envVars.AUTOMAGIK_SPARK_API_PORT || '8883',
        AUTOMAGIK_SPARK_API_HOST: envVars.AUTOMAGIK_SPARK_API_HOST || '0.0.0.0',
        AUTOMAGIK_SPARK_API_KEY: envVars.AUTOMAGIK_SPARK_API_KEY || 'namastex888',
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
      error_file: path.join(INSTALL_ROOT, 'automagik-spark/logs/api-err.log'),
      out_file: path.join(INSTALL_ROOT, 'automagik-spark/logs/api-out.log'),
      log_file: path.join(INSTALL_ROOT, 'automagik-spark/logs/api-combined.log'),
      merge_logs: true,
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    
    // ================================
    // Automagik-Spark Worker (Background Tasks)
    // ================================
    {
      name: 'automagik-spark-worker',
      cwd: path.join(INSTALL_ROOT, 'automagik-spark'),
      script: '.venv/bin/python',
      args: '-m automagik_spark.worker.app',
      interpreter: 'none',
      version: extractVersionFromPython(path.join(INSTALL_ROOT, 'automagik-spark')),
      env: {
        ...envVars,
        PYTHONPATH: path.join(INSTALL_ROOT, 'automagik-spark'),
        AUTOMAGIK_SPARK_API_KEY: envVars.AUTOMAGIK_SPARK_API_KEY || 'namastex888',
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
      error_file: path.join(INSTALL_ROOT, 'automagik-spark/logs/worker-err.log'),
      out_file: path.join(INSTALL_ROOT, 'automagik-spark/logs/worker-out.log'),
      log_file: path.join(INSTALL_ROOT, 'automagik-spark/logs/worker-combined.log'),
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
      args: 'src.api.app:app --host 0.0.0.0 --port ' + (envVars.AUTOMAGIK_OMNI_API_PORT || '8882'),
      interpreter: 'none',
      version: extractVersionFromPython(path.join(INSTALL_ROOT, 'automagik-omni')),
      env: {
        ...envVars,
        PYTHONPATH: path.join(INSTALL_ROOT, 'automagik-omni'),
        AUTOMAGIK_OMNI_API_PORT: envVars.AUTOMAGIK_OMNI_API_PORT || '8882',
        AUTOMAGIK_OMNI_API_HOST: envVars.AUTOMAGIK_OMNI_API_HOST || '0.0.0.0',
        AUTOMAGIK_OMNI_API_KEY: envVars.AUTOMAGIK_OMNI_API_KEY || 'namastex888',
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
    // Automagik-Tools SSE (MCP Hub - SSE Transport)
    // ================================
    {
      name: 'automagik-tools-sse',
      cwd: path.join(INSTALL_ROOT, 'automagik-tools'),
      script: '.venv/bin/automagik-tools',
      args: 'hub --host 0.0.0.0 --port ' + (envVars.AUTOMAGIK_TOOLS_SSE_PORT || '8884') + ' --transport sse',
      interpreter: 'none',
      version: extractVersionFromPython(path.join(INSTALL_ROOT, 'automagik-tools')),
      env: {
        ...envVars,
        PYTHONPATH: path.join(INSTALL_ROOT, 'automagik-tools'),
        AUTOMAGIK_TOOLS_SSE_PORT: envVars.AUTOMAGIK_TOOLS_SSE_PORT || '8884',
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
      error_file: path.join(INSTALL_ROOT, 'automagik-tools/logs/sse-err.log'),
      out_file: path.join(INSTALL_ROOT, 'automagik-tools/logs/sse-out.log'),
      log_file: path.join(INSTALL_ROOT, 'automagik-tools/logs/sse-combined.log'),
      merge_logs: true,
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    
    // ================================
    // Automagik-Tools HTTP (MCP Hub - HTTP Transport)
    // ================================
    {
      name: 'automagik-tools-http',
      cwd: path.join(INSTALL_ROOT, 'automagik-tools'),
      script: '.venv/bin/automagik-tools',
      args: 'hub --host 0.0.0.0 --port ' + (envVars.AUTOMAGIK_TOOLS_HTTP_PORT || '8885') + ' --transport http',
      interpreter: 'none',
      version: extractVersionFromPython(path.join(INSTALL_ROOT, 'automagik-tools')),
      env: {
        ...envVars,
        PYTHONPATH: path.join(INSTALL_ROOT, 'automagik-tools'),
        AUTOMAGIK_TOOLS_HTTP_PORT: envVars.AUTOMAGIK_TOOLS_HTTP_PORT || '8885',
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
      error_file: path.join(INSTALL_ROOT, 'automagik-tools/logs/http-err.log'),
      out_file: path.join(INSTALL_ROOT, 'automagik-tools/logs/http-out.log'),
      log_file: path.join(INSTALL_ROOT, 'automagik-tools/logs/http-combined.log'),
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
      version: extractVersionFromPackageJson(path.join(INSTALL_ROOT, 'automagik-ui')),
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