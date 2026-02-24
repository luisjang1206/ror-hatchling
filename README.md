# ror-hatchling

![Ruby](https://img.shields.io/badge/Ruby-~>_3.4-CC342D?logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-~>_8.1-CC0000?logo=ruby-on-rails&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17.x-316192?logo=postgresql&logoColor=white)

**Production-ready Rails 8 boilerplate delivered as a single template**

Generate a production-ready Rails 8 full-stack application with authentication, authorization, UI components, background jobs, and deployment pipeline — all with a single `rails new` command. Following the "Built-in First" philosophy, it maximizes Rails 8 native features while limiting external gem dependencies to just 4.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Key Features](#key-features)
  - [Authentication & Authorization](#authentication--authorization)
  - [UI Components](#ui-components)
  - [Admin Panel](#admin-panel)
  - [Solid Stack](#solid-stack)
  - [Deployment Pipeline](#deployment-pipeline)
  - [Developer Experience](#developer-experience)
- [Tech Stack](#tech-stack)
- [Proxy Architecture](#proxy-architecture)
- [Generated Directory Structure](#generated-directory-structure)
- [Generated App README Guide](#generated-app-readme-guide)
- [Template Architecture](#template-architecture)
- [Template Verification](#template-verification)
- [Specification Documents](#specification-documents)
- [Out of Scope](#out-of-scope)

---

## Quick Start

### Prerequisites

- Ruby 3.4.x (managed with rbenv, asdf, or mise)
- Rails 8.1.x
- Docker (for running PostgreSQL 17)

### Create App with Template

```bash
# Clone this repository, then specify the template.rb path
git clone https://github.com/<org>/ror-hatchling.git
rails new my_app -d postgresql -c tailwind -m ror-hatchling/template.rb
```

### 3-Step Setup After Generation

```bash
# Step 1: Start PostgreSQL 17 (Docker runs DB only)
docker-compose up db -d

# Step 2: Install dependencies, create DBs, run migrations, seed data
bin/setup

# Step 3: Start development server (Foreman: Rails + Tailwind watcher + SolidQueue worker)
bin/dev
```

Visit `http://localhost:3000` in your browser to see the generated app.

---

## Key Features

### Authentication & Authorization

| Item | Details |
|---|---|
| **Authentication** | Rails 8 `authentication` generator (login/logout/session/password reset) + custom sign-up flow |
| **Password** | `has_secure_password` (bcrypt), minimum 8 characters policy |
| **Tokens** | `generates_token_for` API for email verification, magic links, and other custom token purposes |
| **Rate Limiting** | Rails 8 built-in `rate_limit` (applied to login, sign-up, password reset endpoints, SolidCache backend) |
| **Authorization** | Pundit policy-based, User role enum (user/admin/super_admin) |

### UI Components

10 reusable UI components built with ViewComponent. Implemented with pure Tailwind CSS + ViewComponent, without external UI libraries (DaisyUI, shadcn).

| # | Component | Description | Variants |
|---|---|---|---|
| 1 | **ButtonComponent** | Button, link button | primary, secondary, danger |
| 2 | **CardComponent** | Content container (title/body/footer slots) | default, bordered |
| 3 | **BadgeComponent** | Status indicator tag | info, success, warning, error |
| 4 | **FlashComponent** | Notification message (auto-dismiss with Stimulus) | notice, alert, error |
| 5 | **ModalComponent** | Confirmation/input dialog (trigger + body slots) | default |
| 6 | **DropdownComponent** | Menu, options (trigger + items slots) | default |
| 7 | **FormFieldComponent** | Label + input + error bundle | text, email, password, select, textarea |
| 8 | **EmptyStateComponent** | Empty data state guidance (icon + action slots) | default |
| 9 | **PaginationComponent** | Pagy-integrated pagination (auto-hide if 1 page or less) | default |
| 10 | **NavbarComponent** | Responsive navigation bar (hamburger menu with Stimulus) | default |

### Admin Panel

- **Namespace**: `Admin::` controllers (`/admin/*` routes)
- **Access Control**: Pundit role-based (requires admin or super_admin role)
- **Layout**: Separate admin layout (`layouts/admin.html.erb`)
- **Core Features**: Dashboard, user list view
- **No External Gems**: Custom-built (no ActiveAdmin, Administrate, etc.)

### Solid Stack

Background jobs, cache, and WebSocket operations powered by PostgreSQL instead of Redis. Four logical databases separated on a single PostgreSQL server.

| Component | Role | Logical DB | Migration Path |
|---|---|---|---|
| **SolidQueue** | Background jobs (Active Job) | `queue` | `db/queue_migrate/` |
| **SolidCache** | Cache store (rate_limit backend) | `cache` | `db/cache_migrate/` |
| **SolidCable** | WebSocket (Action Cable) | `cable` | `db/cable_migrate/` |
| **Primary DB** | App data (User, Session, etc.) | `primary` | `db/migrate/` |

### Deployment Pipeline

| Area | Details |
|---|---|
| **Deployment Tool** | Kamal 2 (~> 2.10), kamal-proxy (Rust-based, replaces Traefik) |
| **Container** | Docker multi-stage build (`ruby:3.4-slim` base) |
| **CI/CD** | GitHub Actions 7-step pipeline (Ruby setup, asset caching, DB, lint, security scan, unit tests, system tests) |
| **Server Roles** | `web` (Thruster + Puma), `job` (SolidQueue worker) |
| **Health Checks** | `/up` (liveness, Rails built-in), `/health` (readiness, custom DB check) |
| **SSL** | Let's Encrypt auto-renewal (kamal-proxy, provided commented out in config files) |

### Developer Experience

- **Hybrid Docker**: PostgreSQL only runs in Docker, Rails app runs natively (`bin/dev`)
- **Procfile.dev**: Foreman runs 3 processes in parallel (web, css, jobs)
- **Testing**: Minitest (unit/integration) + Capybara (system, headless Chrome)
- **Code Quality**: rubocop-rails-omakase (Rails official style guide) + Brakeman (security scan)
- **Zero-Build JS**: Import Maps + Propshaft (Node.js not required)
- **Tailwind CSS v4**: Standalone Rust CLI (CSS-first config, `@theme` directives)

---

## Tech Stack

### Complete Version Pins (Based on TSD-v1.3)

| Layer | Choice | Version |
|---|---|---|
| **Ruby** | MRI | ~> 3.4 |
| **Rails** | Full-stack | ~> 8.1 |
| **Database** | PostgreSQL | 17.x (supported until ~2029-11) |
| **Frontend** | Hotwire (Turbo + Stimulus) | turbo-rails ~> 2.0, stimulus-rails ~> 1.3 |
| **CSS** | Tailwind CSS v4 (standalone CLI) | tailwindcss-rails ~> 4.2 |
| **Asset Pipeline** | Propshaft + Import Maps | propshaft ~> 1.1, importmap-rails ~> 2.1 |
| **Background Jobs** | SolidQueue | ~> 1.3 |
| **Cache** | SolidCache | ~> 1.0 |
| **WebSocket** | SolidCable | ~> 3.0 |
| **Authentication** | bcrypt (has_secure_password) | ~> 3.1 |
| **Deployment** | Kamal 2 | ~> 2.10 |
| **Web Server** | Puma (behind Thruster) | puma ~> 6.5, thruster ~> 0.1 |

### External Gems (Limited to 4)

| Gem | Version | Role | Adoption Rationale |
|---|---|---|---|
| **pundit** | ~> 2.5 | Authorization (Policy-based) | No built-in alternative, lightweight, convention-based |
| **pagy** | ~> 43.0 | Pagination | No built-in alternative, best performance, minimal memory |
| **lograge** | ~> 0.14 | Structured logging (JSON) | Production operations essential, Rails default logging insufficient |
| **view_component** | ~> 4.4 | UI components | GitHub official, type-safe parameters, unit testable |

> Pagy uses its own versioning scheme (not SemVer), so 43.x is the correct version.

---

## Proxy Architecture

```
[Internet] → [kamal-proxy] → [Thruster] → [Puma]
             ↓                ↓             ↓
             SSL termination  Compression   Ruby app server
             HTTP/2           Asset caching (workers/threads)
             Zero-downtime    X-Sendfile
             routing
             Error pages
             Let's Encrypt
```

### Layer Responsibilities

| Layer | Location | Role |
|---|---|---|
| **kamal-proxy** | Host level | SSL termination (Let's Encrypt auto-renewal), HTTP/2, blue-green deployment routing, error page serving |
| **Thruster** | Inside container | gzip compression, asset caching, X-Sendfile handling (supports HTTP/2 natively but primarily handles compression/caching behind kamal-proxy) |
| **Puma** | Inside container | Rails application server (multi-worker + multi-thread) |

---

## Generated Directory Structure

```
my_app/
├── app/
│   ├── components/              # ViewComponent (10 components + ApplicationComponent)
│   │   ├── application_component.rb
│   │   ├── button_component.rb
│   │   ├── card_component.rb
│   │   ├── badge_component.rb
│   │   ├── flash_component.rb
│   │   ├── modal_component.rb
│   │   ├── dropdown_component.rb
│   │   ├── form_field_component.rb
│   │   ├── empty_state_component.rb
│   │   ├── pagination_component.rb
│   │   └── navbar_component.rb
│   ├── controllers/
│   │   ├── admin/               # Admin namespace (Pundit role check)
│   │   ├── concerns/
│   │   │   └── authentication.rb       # Rails 8 auth generator
│   │   ├── application_controller.rb
│   │   ├── health_controller.rb        # Health check (/health)
│   │   ├── registrations_controller.rb # Custom sign-up
│   │   ├── sessions_controller.rb      # Rails 8 auth generator
│   │   └── passwords_controller.rb     # Rails 8 auth generator
│   ├── javascript/
│   │   └── controllers/         # Stimulus controllers (4 types)
│   │       ├── flash_controller.js
│   │       ├── modal_controller.js
│   │       ├── dropdown_controller.js
│   │       └── navbar_controller.js
│   ├── models/
│   │   ├── current.rb
│   │   └── user.rb              # role enum, password validation
│   ├── policies/                # Pundit policies
│   │   ├── application_policy.rb
│   │   └── admin/
│   └── views/
│       ├── layouts/
│       │   ├── application.html.erb
│       │   └── admin.html.erb
│       └── components/          # ViewComponent ERB templates
├── config/
│   ├── database.yml             # Multi-DB (primary/cache/queue/cable)
│   ├── deploy.yml               # Kamal 2 deployment config
│   ├── initializers/
│   │   ├── pagy.rb
│   │   ├── pundit.rb
│   │   └── lograge.rb
│   └── locales/
│       ├── defaults/            # General UI translations (ko.yml, en.yml)
│       └── models/              # Model attribute translations
├── db/
│   ├── migrate/                 # Primary DB migrations
│   ├── cache_migrate/           # SolidCache schema
│   ├── queue_migrate/           # SolidQueue schema
│   ├── cable_migrate/           # SolidCable schema
│   └── seeds/
│       ├── admin_user.rb
│       └── sample_data.rb
├── test/
│   ├── components/              # ViewComponent tests
│   ├── integration/
│   ├── models/
│   ├── policies/                # Pundit policy tests
│   └── system/                  # Capybara E2E tests
├── .github/
│   └── workflows/
│       └── ci.yml               # 7-step CI pipeline
├── .kamal/
│   ├── secrets                  # Runtime secrets (gitignored)
│   ├── secrets.example          # Secret template (committed)
│   └── hooks/
│       └── pre-deploy           # Git clean state check
├── Procfile.dev                 # Foreman: web + css + jobs
└── docker-compose.yml           # PostgreSQL 17 only
```

---

## Generated App README Guide

The app generated by the template includes an auto-generated README.md with detailed usage guides. It consists of 10 sections (A-J), each covering the following content:

| Section | Title | PRD 5.3 | Key Content |
|---|---|---|---|
| **A** | Project Introduction & Tech Stack | 1 | Built-in First philosophy, complete tech stack table, proxy architecture |
| **B** | Local Development Setup | 2 | Prerequisites, 3-step setup, multi-DB structure, Hybrid Docker explanation |
| **C** | UI Components (ViewComponent) | 3 | Usage and ERB example code for 10 components |
| **D** | Testing | 4 | Unit/integration/system test execution, rubocop, brakeman |
| **E** | Deployment (Kamal 2) | 5 | Proxy architecture, config files, deployment commands, SSL, health checks |
| **F** | Directory Structure | 6 | Complete file tree (with comments) |
| **G** | Optional Features Guide | 7 | Active Record Encryption, rate_limit store customization, password policy strengthening |
| **H** | Scaling Guide | 8 | Solid Stack → Redis migration timing and procedure (SolidQueue → Sidekiq/GoodJob, SolidCache → Redis, SolidCable → Redis) |
| **I** | Frontend Expansion Guide | 9 | Import Maps → jsbundling-rails(esbuild) migration, Procfile.dev, CI workflow changes |
| **J** | Kamal Deployment Checklist | 10 | SSL configuration (Let's Encrypt), forward_headers setup, health check validation |

> For detailed usage guides, refer to the `README.md` in the generated app. This file provides step-by-step instructions from development environment setup to production deployment and scaling migration.

---

## Template Architecture

`template.rb` sequentially executes 20 steps organized into 6 phases.

| Phase | PRD Steps | Key Tasks |
|---|---|---|
| **Phase 0: Pre-Flight** | — | Verify prerequisites (Ruby 3.4+, Rails 8.1+, Docker) |
| **Phase 1: Foundation** | 1, 6, 11, 14 | Modify Gemfile, create directories, multi-DB setup, Procfile.dev |
| **Phase 2: Authentication & User Model** | 2, 3, 4, 18 | `rails generate authentication`, sign-up flow, User role enum, rate_limit |
| **Phase 3: UI Components, Error Handling & I18n** | 5, 7(error/health), 8, 9, 10 | ViewComponent 10 types + Stimulus 4 types, error handling (404/403), I18n default locale ko |
| **Phase 4: Authorization, Admin & Seed Data** | 7(admin), 12, 17 | Pundit setup, Admin namespace, seed data |
| **Phase 5: Infrastructure, CI/CD & Deployment** | 13, 15, 16, 19 | Docker, GitHub Actions CI (7 steps), Kamal 2 deploy.yml, run migrations |
| **Phase 6: Documentation & Integration** | 20 | Generate README.md (Sections A-J) |

### Detailed Step Mapping

<details>
<summary>Expand to see all 20 steps from PRD 5.2</summary>

| PRD Step | Phase | Task |
|---|---|---|
| 1 | 1 | Modify Gemfile (add `pundit`, `pagy`, `lograge`, `view_component`) + `bundle install` |
| 2 | 2 | Run `bin/rails generate authentication` |
| 3 | 2 | Add sign-up controller/views/routes (`RegistrationsController`) |
| 4 | 2 | Extend User model (role enum, password validation, `generates_token_for`) |
| 5 | 3 | Install ViewComponent + create 10 components |
| 6 | 1 | Create directory structure (`app/components/`, `app/policies/`, `db/seeds/`, etc.) |
| 7 | 3/4 | Common controllers (ApplicationController error handling, Admin::BaseController, HealthController) |
| 8 | 3 | Create 4 Stimulus controllers (flash, modal, dropdown, navbar) |
| 9 | 3 | Create I18n locale files (ko/en, defaults/ + models/) |
| 10 | 3 | Custom error pages (404, 422, 500) |
| 11 | 1 | Multi-DB `database.yml` setup (primary/cache/queue/cable) |
| 12 | 4 | Seed data (`db/seeds.rb` → `admin_user.rb` + `sample_data.rb`) |
| 13 | 5 | Create Docker files (multi-stage Dockerfile + docker-compose.yml) |
| 14 | 1 | Create `Procfile.dev` (web, css, jobs processes) |
| 15 | 5 | GitHub Actions CI workflow (7-step pipeline) |
| 16 | 5 | Kamal 2 deployment setup (`config/deploy.yml`, `.kamal/secrets`, hooks) |
| 17 | 4 | Pundit, Pagy, Lograge initial setup (3 initializers) |
| 18 | 2 | rate_limit setup (SessionsController, RegistrationsController, PasswordsController) |
| 19 | 5 | Run initial migrations (`rails db:prepare` + Solid Stack migrations) |
| 20 | 6 | Generate README.md (Sections A-J, complete guide) |

</details>

---

## Template Verification

Verify that all 20 steps complete successfully by running the template in a clean environment.

```bash
# 1. Create app with template
rails new test_app -d postgresql -c tailwind -m path/to/template.rb

# 2. Navigate to generated app directory
cd test_app

# 3. Start PostgreSQL (Docker)
docker-compose up db -d

# 4. Install dependencies + create DBs + run migrations + seed
bin/setup

# 5. Unit/integration tests
bin/rails test

# 6. System tests (Capybara + headless Chrome)
bin/rails test:system

# 7. Lint (rubocop-rails-omakase)
bundle exec rubocop

# 8. Security scan (Brakeman)
bundle exec brakeman
```

### Verification Checklist

- [ ] All 20 steps complete without errors
- [ ] `bin/setup` succeeds (create 4 DBs, migrations, seeds)
- [ ] `bin/dev` starts 3 processes normally (web, css, jobs)
- [ ] `bin/rails test` all pass (0 failures)
- [ ] `bin/rails test:system` all pass (0 failures)
- [ ] `bundle exec rubocop` 0 violations
- [ ] `bundle exec brakeman` 0 security issues (or within acceptable range)
- [ ] Verify 4-gem limit compliance (`pundit`, `pagy`, `lograge`, `view_component`)
- [ ] Verify Korean default locale works (UI text displays in Korean)
- [ ] Verify 10 ViewComponents render
- [ ] Verify Admin page access control (requires admin role)
- [ ] Verify rate_limit works (login/sign-up attempt limiting)
- [ ] Verify idempotence: running the same template twice produces identical results

---

## Specification Documents

All project requirements, tech stack, and implementation roadmap are defined in the following documents:

| Document | Description |
|---|---|
| [docs/PRD-v3.3.md](docs/PRD-v3.3.md) | Product Requirements Document (Korean). Defines feature scope, auth/authorization, UI components, admin, Solid Stack, deployment, CI/CD requirements. |
| [docs/TSD-v1.3.md](docs/TSD-v1.3.md) | Technical Stack Document (Korean). Exact version pins, compatibility matrix, upgrade policies, complete Gemfile. TSD version pins take precedence when conflicting with PRD. |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Implementation Roadmap (Korean). Detailed mapping of 6 phases / 20 steps, work items, verification methods, estimated effort, risks. |
| [CLAUDE.md](CLAUDE.md) | AI Assistant Guide (English). Proxy architecture, architectural decisions, development commands, Git protocol. |

---

## Out of Scope

The following items are explicitly excluded as they fall outside the scope of a general-purpose boilerplate. They can be added individually in the generated app as needed:

- Social login (OmniAuth)
- Payment systems (Stripe, PayPal, etc.)
- S3 file uploads (local Active Storage only)
- Mobile app integration (Strada)
- Automatic locale switching (I18n structure only, no locale switching logic)
- APM/error tracking integration (Sentry, Datadog, etc. — guide only in README)
- Domain-specific business logic (e-commerce, CMS, reservation systems, etc.)

---

**Built-in First.** Leverage the full power of Rails 8.
