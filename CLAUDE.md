# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ror-hatchling** is a specification-driven project for building a Rails 8 full-stack boilerplate ("RailsStarter"). It is currently in the **specification/documentation phase** — no Rails application code exists yet. The project will be delivered as a Rails Application Template (`template.rb`) that scaffolds a complete production-ready app via:

```bash
rails new my_app -d postgresql -c tailwind -m path/to/template.rb
```

## Specification Documents (Source of Truth)

All implementation decisions must be derived from these two documents (written in Korean):

- **[docs/PRD-v3.3.md](docs/PRD-v3.3.md)** — Product Requirements Document. Defines features (auth, authorization, admin, components, i18n, error handling, health checks), project structure, test strategy, CI/CD pipeline, and deployment.
- **[docs/TSD-v1.3.md](docs/TSD-v1.3.md)** — Technical Stack Document. Exact versions, compatibility matrix, and upgrade policies.

When PRD and TECH-STACK conflict, TECH-STACK version pins take precedence (they were cross-validated in later revisions).

## Target Stack

| Layer | Choice |
|---|---|
| Ruby | 3.4.x (~> 3.4), pinned to prevent Ruby 4.0 auto-upgrade |
| Rails | 8.1.x (~> 8.1) |
| Database | PostgreSQL 17.x, single server with logical DB separation (primary/cache/queue/cable) |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS v4 (CSS-first config), Import Maps, Propshaft |
| UI Components | ViewComponent (10 components, no external UI libraries like DaisyUI/shadcn) |
| Infrastructure | Solid Stack (SolidQueue, SolidCache, SolidCable) — no Redis |
| Auth | Rails 8 authentication generator + custom sign-up flow |
| Authorization | Pundit (policy-based) |
| Deployment | Kamal 2 with kamal-proxy (not Traefik) → Thruster → Puma |

**External Gems limited to 4**: pundit, pagy, lograge, view_component.

## Gemfile Version Pins

```ruby
# Core
gem "rails", "~> 8.1"
gem "pg", "~> 1.5"
gem "puma", "~> 6.5"
gem "thruster", "~> 0.1"

# Frontend (zero-build: no Node.js/webpack/esbuild needed)
gem "propshaft", "~> 1.1"
gem "turbo-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3"
gem "importmap-rails", "~> 2.1"
gem "tailwindcss-rails", "~> 4.2"    # Standalone CLI, Rust-based Oxide engine

# Infrastructure (Solid Stack — all DB-backed, no Redis)
gem "solid_queue", "~> 1.3"
gem "solid_cache", "~> 1.0"
gem "solid_cable", "~> 3.0"

# Auth & Security
gem "bcrypt", "~> 3.1"
gem "pundit", "~> 2.5"

# Utilities
gem "pagy", "~> 43.0"               # Non-SemVer versioning (43.x is correct)
gem "lograge", "~> 0.14"
gem "view_component", "~> 4.4"

# Deployment
gem "kamal", "~> 2.10", require: false

# Dev/Test: debug ~> 1.9, brakeman ~> 7.0, rubocop-rails-omakase ~> 1.0
# Test: capybara ~> 3.40, selenium-webdriver ~> 4.27
```

## Development Commands (Once Implemented)

```bash
# Local setup
docker-compose up db          # PostgreSQL 17 via Docker (DB only, app runs natively)
bin/setup                     # Install deps, create DBs, run migrations
bin/dev                       # Foreman: Rails server + Tailwind watcher + SolidQueue worker

# Testing
bin/rails test                        # All unit/integration tests (Minitest)
bin/rails test test/models/user_test.rb       # Single test file
bin/rails test test/models/user_test.rb:42    # Single test by line number
bin/rails test:system                 # System tests (Capybara + headless Chrome)

# Quality
bundle exec rubocop                   # Lint (rubocop-rails-omakase)
bundle exec brakeman                  # Security scan
```

`Procfile.dev` runs three processes: `web` (Rails server :3000), `css` (Tailwind watcher), `jobs` (SolidQueue worker).

## Architecture Decisions

- **Built-in First**: Maximize Rails 8 native features. Every external dependency must be justified.
- **Zero-Build JS**: No Node.js required. Tailwind v4 uses a standalone Rust CLI (`tailwindcss-rails`), Import Maps serve ES modules directly, Propshaft replaces Sprockets. Tailwind v4 uses CSS-first config (`@theme` directives) instead of `tailwind.config.js`.
- **Hybrid Docker**: Only PostgreSQL runs in Docker locally; the Rails app runs natively via `bin/dev` (Foreman + Procfile.dev).
- **Multi-DB**: Four logical databases on one PostgreSQL server — `primary`, `cache` (SolidCache), `queue` (SolidQueue), `cable` (SolidCable). Migration directories: `db/migrate/`, `db/cache_migrate/`, `db/queue_migrate/`, `db/cable_migrate/`.
- **Error handling**: Only rescue `RecordNotFound` (404) and `Pundit::NotAuthorizedError` (403) in ApplicationController. Never rescue 500s — let Rails middleware handle them.
- **Health checks**: `/up` (liveness, Rails built-in) + `/health` (readiness, custom with DB check).
- **Auth scope**: Rails generator provides login/logout/session/password-reset. Boilerplate adds sign-up separately.
- **Rate limiting**: Rails 8 built-in `rate_limit` applied to login, sign-up, and password-reset endpoints. Backed by SolidCache (DB-based).
- **Admin**: Custom-built under `Admin::` namespace at `/admin/*` with Pundit role checks, not an admin gem.
- **I18n**: Default locale is `ko`. All user-facing text uses I18n keys. Locale files split into `defaults/` and `models/` subdirectories.
- **Seed data**: `db/seeds.rb` delegates to `db/seeds/admin_user.rb` and `db/seeds/sample_data.rb`.

## Template Implementation Scope

The `template.rb` must perform 20 sequential steps (PRD 5.2). Key ones:
1. Modify Gemfile + `bundle install`
2. Run `bin/rails generate authentication`
3. Create sign-up controller/views/routes
4. Add User role enum, password validation, `generates_token_for`
5. Install ViewComponent + 10 UI components with Stimulus controllers
6. Set up multi-DB `database.yml` (primary/cache/queue/cable)
7. Configure Kamal 2 deployment (deploy.yml + .kamal/secrets + hooks + SSL/error_pages comments)
8. Set up GitHub Actions CI workflow (7-step pipeline)
9. Configure Pundit, Pagy, Lograge initializers
10. Generate README with setup, scaling, and migration guides

## Proxy Architecture

```
[Internet] → [kamal-proxy] → [Thruster] → [Puma]
               SSL/HTTP2       compression    Rails app
               routing         asset caching
               error pages     X-Sendfile
```

## Out of Scope

Explicitly excluded from the boilerplate — do not implement:

- Domain-specific business logic (e-commerce, CMS, etc.)
- Social login (OmniAuth)
- Payment systems
- File upload to S3 (local storage only)
- Mobile apps (Strada)
- Automatic locale switching (I18n structure only)
- APM/error tracking integration (Sentry, Datadog) — README guide only
