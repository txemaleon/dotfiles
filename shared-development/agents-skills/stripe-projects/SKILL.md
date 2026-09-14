---
name: stripe-projects
description: Set up and manage Stripe Projects - provision infrastructure, manage providers, sync env vars. Use when creating a new project with Stripe, adding services (databases, auth, analytics), or managing project resources. Triggers on "stripe project", "new project setup", "provision database", "add auth provider".
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
user-invocable: true
---

# Stripe Projects

Stripe Projects provisions and manages third-party infrastructure (databases, auth, hosting, analytics) from a single CLI. Think of it as a unified control plane for your project's services.

## Prerequisites

Before anything else, verify the setup:

```bash
# 1. Check Stripe CLI
stripe --version

# 2. Install projects plugin (if missing)
stripe plugin install projects

# 3. Verify plugin works
stripe projects --help
```

If Stripe CLI is not installed: `brew install stripe/stripe-cli/stripe` (macOS).

## Core Concepts

| Concept | Description |
|---------|-------------|
| **Provider** | A vendor (Vercel, Supabase, Neon, Clerk, etc.) |
| **Service** | An offering from a provider (database, auth, analytics) |
| **Resource** | An instantiated service with credentials and env vars |
| **`.projects/`** | Auto-created directory tracking project state |
| **`state.json`** | Provider accounts, resources, and config (commit this) |
| **`state.local.json`** | Resource IDs - keep private for team collab |

## New Project Setup

```bash
# Initialize project (creates .projects/ directory, authenticates)
stripe projects init <project-name>

# Browse available services
stripe projects catalog

# Add services you need
stripe projects add <provider>/<service>

# Pull environment variables into .env
stripe projects env --pull
```

## Available Providers

Vercel, Railway, Supabase, Neon, PlanetScale, Turso, Chroma, Clerk, PostHog, Runloop.

Use `stripe projects catalog` for the current full list with categories.

## Common Workflows

### Add a database

```bash
stripe projects catalog          # Find database providers
stripe projects add neon/postgres    # Or supabase/postgres, turso/libsql, etc.
stripe projects env --pull           # Sync DATABASE_URL to .env
```

### Add authentication

```bash
stripe projects add clerk/auth
stripe projects env --pull       # Sync auth keys to .env
```

### Add hosting

```bash
stripe projects add vercel/hosting
stripe projects env --pull
```

### Add analytics

```bash
stripe projects add posthog/analytics
stripe projects env --pull
```

### Connect existing provider account (no new resource)

```bash
stripe projects link <provider>
```

## Management Commands

```bash
# Project status and health
stripe projects status

# List all services in your project
stripe projects services list

# List/sync environment variables
stripe projects env              # List all env vars
stripe projects env --pull       # Sync to .env file

# Rotate credentials
stripe projects rotate <resource>

# Update a service to a different one from the same provider
stripe projects update <service_reference> [service]

# Upgrade/downgrade service tier
stripe projects upgrade <resource>
stripe projects downgrade <resource>

# Remove a service
stripe projects remove <resource>

# Unlink a provider account
stripe projects unlink <provider>

# Open provider dashboard
stripe projects open <provider>

# Switch Stripe account
stripe projects switch-account

# Billing
stripe projects billing show     # View current billing
stripe projects billing add      # Add payment method
```

## LLM Context Generation

Generate a combined context file for AI tools:

```bash
stripe projects llm-context
```

## CI/Non-Interactive Usage

All commands support automation flags:

```bash
stripe projects add neon/postgres -y --json
```

| Flag | Purpose |
|------|---------|
| `--json` | JSON output for parsing |
| `-y, --yes` | Skip confirmation prompts |
| `--accept-tos` | Accept provider ToS without prompting |
| `--stream` | Enable streaming output animations |
| `--debug` | Debug logging for Stripe API requests |

## Project Structure

After init, your project gets:

```
your-project/
  .projects/
    state.json         # Commit - tracks providers and config
    state.local.json   # Gitignore - contains resource IDs
  .env                 # Gitignore - synced credentials
```

## Checklist for New Projects

1. [ ] `stripe projects init <name>`
2. [ ] Add required services (`stripe projects add ...`)
3. [ ] Pull env vars (`stripe projects env --pull`)
4. [ ] Add `.projects/state.local.json` and `.env` to `.gitignore`
5. [ ] Commit `.projects/state.json`
6. [ ] Verify with `stripe projects status`

## Rules

- Always run `stripe projects env --pull` after adding/removing services
- Never commit `.env` or `state.local.json`
- Always commit `state.json` for team collaboration
- Use `--json` flag when parsing output programmatically
- Check `stripe projects catalog` for current providers - the list grows frequently
- This is a developer preview - APIs and commands may change
