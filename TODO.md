# PM2 Migration Epic - TODO List

## Overview
Complete migration from systemd to PM2 for all Automagik services, cleaning up old code and creating a streamlined deployment system.

## Tasks

### ✅ Completed
- [x] Create centralized PM2 ecosystem.config.js in main repo
- [x] Create minimal install.sh script for pre-dependencies
- [x] Start updating main Makefile with PM2 functions
- [x] Remove systemd references from main Makefile service management
- [x] Clean up remaining systemd references from main Makefile
- [x] Update help text to reference PM2 instead of systemd

### 🔄 In Progress
- [ ] Finish updating main Makefile
  - [x] Complete individual status commands
  - [x] Add setup-pm2 target
  - [x] Add PM2 log commands
  - [x] Update start-all-services to use PM2 ecosystem

### 📋 Pending Tasks

#### Update Service Makefiles
- [ ] **am-agents-labs/Makefile**
  - [ ] Remove all systemd service creation/management code
  - [ ] Remove service file generation
  - [ ] Update install-service to use PM2
  - [ ] Update start-service, stop-service, restart-service targets
  - [ ] Add PM2 log targets
  - [ ] Clean up any systemd references

- [ ] **automagik-spark/Makefile**
  - [ ] Remove systemd service file creation
  - [ ] Remove worker service handling
  - [ ] Update all service management targets to PM2
  - [ ] Clean up systemd references
  - [ ] Add PM2 specific targets

- [ ] **automagik-omni/Makefile**
  - [ ] Remove systemd service installation
  - [ ] Update service management to PM2
  - [ ] Add PM2 log targets
  - [ ] Clean up old code

- [ ] **automagik-tools/Makefile**
  - [ ] Remove systemd service code
  - [ ] Add PM2 service management (even though it's a library)
  - [ ] Clean up old references

- [ ] **automagik-ui/Makefile**
  - [ ] Update to reference centralized PM2 config
  - [ ] Remove local PM2 production config reference
  - [ ] Keep dev ecosystem file only

#### Cleanup Tasks
- [ ] **Remove obsolete files**
  - [ ] Delete Makefile.local
  - [ ] Delete automagik-ui/ecosystem.production.config.js
  - [ ] Clean up scripts/setup-local-services.sh (systemd references)
  - [ ] Review and clean scripts/system/install-deps-*.sh files

- [ ] **Clean redundant scripts**
  - [ ] Remove duplicate installation scripts
  - [ ] Consolidate OS-specific dependencies
  - [ ] Remove old systemd setup scripts
  - [ ] Clean up unused shell scripts

#### Testing & Validation
- [ ] Test complete installation flow on fresh system
- [ ] Verify all services start with PM2
- [ ] Test individual service controls
- [ ] Verify logs are working properly
- [ ] Test service restarts and crash recovery
- [ ] Validate memory limits and restart policies

#### Documentation Updates
- [ ] Update README with new PM2-based instructions
- [ ] Document PM2 commands for users
- [ ] Update any service-specific documentation
- [ ] Create migration guide from systemd to PM2

## Implementation Order
1. Complete main Makefile updates
2. Update each service Makefile (use delegation pattern)
3. Clean up obsolete files and scripts
4. Test full installation flow
5. Update documentation

## Notes
- Main goal: Remove ALL systemd dependencies
- Keep installation minimal and user-friendly
- No sudo required for service management
- Maintain clean hierarchy: install.sh → Makefile → ecosystem.config.js
- Use PM2 for all Python services, not just UI