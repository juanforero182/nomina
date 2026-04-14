# AGENTS.md

## Versions

- **Ruby**: 3.3.10
- **Rails**: 8.1.1
- **PostgreSQL**: 15
- **Docker**: `ruby:3.3.10` (dev image)

## Critical Conventions

- **Code in English**: Models, migrations, tables, views, controllers, and all code-level naming must be in English. Never use Spanish in Ruby code, ERB, or migrations.
- **Spanish only in i18n**: Default locale is `:es`. All user-facing text must use `I18n.t()` — never hardcoded Spanish in templates or Ruby code.

## Rails 8 Conventions

- **Asset Pipeline**: Uses Propshaft (not Sprockets)
- **Cache**: Solid Cache (SQLite-backed)
- **Queue**: Solid Queue (SQLite-backed)
- **Cable**: Solid Cable (Redis optional)
- **Auth**: Devise
- **Deployment**: Kamal

### Rails 8 Patterns

- `bin/rails` wrapper replaces `rails` and `rake` commands
- `config/boot.rb` uses Bootsnap for require acceleration
- Active Job uses Solid Queue (database-backed)
- Credentials stored in `config/credentials.yml.enc` (edit with `bin/rails credentials:edit`)

## Development Commands

```bash
bin/setup           # Install deps, prepare DB, start dev server
bin/setup --reset   # Full reset with db:reset
bin/dev             # Start development server (Hotwire)
```

## Testing

```bash
bin/rails test                        # Unit/integration tests
bin/rails test test/models/          # Run model tests only
bin/rails test:system                 # System tests (Capybara/Selenium)
```

## Linting & Security

```bash
bin/rubocop            # Rails-omakase style
bin/brakeman           # Security static analysis
bin/bundler-audit      # Gem vulnerability audit
bin/importmap audit    # JS dependency audit
```

## Docker

- Web runs on port 3000, PostgreSQL 15 on port 5432
- Docker command runs: `bundle install && db:prepare && tailwindcss:build && server`

## Architecture

- **Frontend**: Turbo Frames (partial page updates), Stimulus controllers in `app/javascript/controllers/`
- **Forms**: SimpleForm
- **Pagination**: Pagy

## Application Features

### Core Models
- **Company** (company): `nit`, `name` — empresas
- **Employee** (employees): datos personales, tipos de documento (CC, TI, CE, NIT, PAS, RC, TE, DIE)
- **Contract** (contracts): contratos laborales, estados (active/inactive), tipos (término fijo, indefinido, obra/labor, aprendizaje, prácticas)
- **Document**: archivos subidos para conversión
- **User**: autenticación Devise

### Excel Import Workflows

1. **Importar empleados a empresa** (`POST /companies/:id/import_employees`)
   - Archivo Excel "Directorio" de Syscafe
   - `SyscafeDirectoryParser` (`app/services/converters/syscafe_directory_parser.rb`)
   - Extrae: datos empleado + datos contrato (EPS, AFP, ARL, cuenta bancaria, salario, área, cargo)
   - Crea/actualiza empleados y contratos en la DB
   - Columns 24 mapping: `contract_type` (ley 50=indefinido, término fijo, obra/labor, aprendizaje, prácticas)

2. **Convertir nómina Syscafe → Minomina** (`POST /documents/convert`)
   - Archivo Excel de nómina Syscafe
   - `SyscafeParser` (`app/services/converters/syscafe_parser.rb`)
   - Genera CSV formato Minomina
   - Enriquecer con datos de DB si se selecciona empresa
   - `MinominaCsvGenerator` genera CSV de salida

### Key Services (app/services/)

- `DocumentConverterService`: convierte entre formatos (syscafe → minomina)
- `Converters::SyscafeParser`: parsing payroll Excel (PERIOD_ROW=5, DATA_START_ROW=8)
- `Converters::SyscafeDirectoryParser`: parsing directorio empleados (HEADER_ROW=5, DATA_START_ROW=6)
- `Converters::MinominaCsvGenerator`: genera CSV Minomina

### Routes

```
/auth                 → Devise
/companies            → CRUD empresas
/companies/:id/import_employees → importar empleados Excel
/employees            → listar empleados
/documents            → converter
/documents/convert    → convertir nómina
/dashboard           → home
```

## Key Files to Reference

- `CLAUDE.md` — Full project overview and additional details
- `config/locales/es.yml` — Spanish translation strings