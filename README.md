# MHF WordPress Configuration

This repository contains configuration files and utility scripts for the Masumi Hayashi Foundation WordPress site.

## Contents

- `scripts/` - Utility scripts for site maintenance
  - `wp-theme-sync.sh` - Sync WordPress themes between local and production
  - `wp-plugins-sync.sh` - Sync WordPress plugins between local and production
- `wp-cli.yml` - WP-CLI configuration
- `.windsurfrules` - Windsurf IDE configuration

## Usage

### Theme Sync

```bash
# Pull themes from production (dry run)
./scripts/wp-theme-sync.sh -d

# Pull themes from production
./scripts/wp-theme-sync.sh

# Push themes to production (dry run)
./scripts/wp-theme-sync.sh push -d

# Push themes to production
./scripts/wp-theme-sync.sh push
```

### Plugin Sync

```bash
# Pull plugins from production (dry run)
./scripts/wp-plugins-sync.sh -d

# Pull plugins from production
./scripts/wp-plugins-sync.sh
```

## Note

This repository is specifically for site configuration and maintenance scripts. The actual theme code is maintained in a separate repository within the `themes/mhf_tw` directory.
