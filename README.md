[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/Lullabot/ddev-gitleaks/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/Lullabot/ddev-gitleaks/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/Lullabot/ddev-gitleaks)](https://github.com/Lullabot/ddev-gitleaks/commits)
[![release](https://img.shields.io/github/v/release/Lullabot/ddev-gitleaks)](https://github.com/Lullabot/ddev-gitleaks/releases/latest)

# DDEV Gitleaks

## Overview

This add-on integrates Gitleaks into your [DDEV](https://ddev.com/) project.

## Installation

```bash
ddev add-on get Lullabot/ddev-gitleaks
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View service status and used ports for Gitleaks |
| `ddev logs -s gitleaks` | Check Gitleaks logs |

## Advanced Customization

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.gitleaks --gitleaks-docker-image="ddev/ddev-utilities:latest"
ddev add-on get Lullabot/ddev-gitleaks
ddev restart
```

Make sure to commit the `.ddev/.env.gitleaks` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `GITLEAKS_DOCKER_IMAGE` | `--gitleaks-docker-image` | `ddev/ddev-utilities:latest` |

## Credits

**Contributed and maintained by [@Lullabot](https://github.com/Lullabot)**
