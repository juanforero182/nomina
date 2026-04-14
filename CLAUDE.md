# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Nomina is a Rails 8.1 payroll management system. Built with Hotwire (Turbo + Stimulus), Tailwind CSS, and PostgreSQL.

## Commands

### Development
```bash
bin/setup                    # Install deps, prepare DB, start dev server
bin/setup --reset            # Same but with full db:reset
bin/dev                      # Start development server
docker-compose up            # Run with Docker (web + PostgreSQL)
```

### Testing
```bash
bin/rails test               # Run unit/integration tests (Minitest)
bin/rails test test/models/  # Run model tests
bin/rails test:system        # Run system tests (Capybara/Selenium)
```

### Linting & Security
```bash
bin/rubocop                  # RuboCop (rails-omakase style)
bin/brakeman                 # Security static analysis
bin/bundler-audit            # Gem vulnerability audit
bin/importmap audit          # JS dependency audit
```

### Database
```bash
bin/rails db:prepare         # Create + migrate (idempotent)
bin/rails db:migrate         # Run pending migrations
bin/rails db:seed            # Seed data
bin/rails db:reset           # Drop + create + schema load + seed
```

## Architecture

### Conventions

- **Language**: Models, migrations, tables, views, presenters, controllers, and all code-level naming must be in **English**. Spanish labels are handled exclusively through i18n translation files (`config/locales/`).
- **i18n**: Default locale is Spanish (`:es`). Week starts on Monday. All user-facing text (view labels, flash messages, menu items) goes through `I18n.t()` — never hardcoded Spanish in templates or Ruby code.

### Key Patterns

- **Views**: ERB templates with Tailwind CSS. SimpleForm for forms.
- **Frontend interactivity**: Turbo Frames for partial page updates, Stimulus controllers in `app/javascript/controllers/`.
- **Pagination**: Pagy gem.

### Docker

- `Dockerfile.dev` — development image
- `Dockerfile` — production multi-stage build with Thruster
- `docker-compose.yml` — web (port 3000) + PostgreSQL 15 (port 5432)
- Environment variables in `.env`: `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DATABASE_URL`
