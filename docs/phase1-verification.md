# Phase 1: Pre-Implementation 검증 결과

> **작성일**: 2026-02-22
> **목적**: Phase 0 검증 결과와 신규 조사 간 충돌 해소
> **상태**: **완료** -- 3개 충돌 항목 모두 해소

## 검증 환경

- Ruby 버전: `ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]`
- Rails 버전: `Rails 8.1.2`
- 명령: `rails new verify_app -d postgresql -c tailwind`
- 실행 위치: `/tmp/ror-verify/`
- 실행 시 `--skip-bundle` 미사용 (전체 번들 + 자동 설치 포함)

---

## 충돌 해소 결과

### 1. pool vs max_connections

- **확정**: `max_connections:` (Phase 0 검증 결과가 정확했음)
- **근거**: `config/database.yml` 20번째 줄 확인

```yaml
# database.yml 실제 내용 (default 섹션)
default: &default
  adapter: postgresql
  encoding: unicode
  # For details on connection pooling, see Rails configuration guide
  # https://guides.rubyonrails.org/configuring.html#database-pooling
  max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

- **결론**: Rails 8.1.2는 `pool:` 대신 `max_connections:` 키를 사용한다. Phase 0 검증이 정확했고, "여전히 `pool:`이다"라는 신규 조사가 잘못되었다.
- **template.rb 시사점**: database.yml 생성 시 `max_connections:` 키 사용해야 함. TSD/PRD 문서에서 `pool:` 언급이 있다면 `max_connections:`로 대체 필요.

### 2. Solid Stack 자동 포함

- **확정**: **자동 포함** (Phase 0 검증 결과가 정확했음)
- **근거**: `rails new` 실행 로그 + Gemfile + bin/ 디렉토리 확인

#### 증거 1: rails new 실행 로그

```
       rails  solid_cache:install solid_queue:install solid_cable:install
      create  config/cache.yml
      create  db/cache_schema.rb
        gsub  config/environments/production.rb
      create  config/queue.yml
      create  config/recurring.yml
      create  db/queue_schema.rb
      create  bin/jobs
        gsub  config/environments/production.rb
      create  db/cable_schema.rb
       force  config/cable.yml
```

#### 증거 2: Gemfile 내용 (28-31줄)

```ruby
# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
```

#### 증거 3: bin/jobs 존재 확인

```
$ ls verify_app/bin/
brakeman  bundler-audit  ci  dev  docker-entrypoint  importmap  jobs  kamal  rails  rake  rubocop  setup  thrust
```

`bin/jobs` 파일이 자동 생성되었다.

#### 증거 4: production.rb에 Solid Stack 설정 자동 삽입

```ruby
# config/environments/production.rb (49-54줄)
config.cache_store = :solid_cache_store
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

#### 증거 5: Solid Stack 설정 파일 자동 생성

```
config/cache.yml       -- SolidCache 설정
config/queue.yml       -- SolidQueue 설정
config/recurring.yml   -- SolidQueue 반복 작업 설정
config/cable.yml       -- SolidCable 설정 (production만)
db/cache_schema.rb     -- SolidCache 스키마
db/queue_schema.rb     -- SolidQueue 스키마
db/cable_schema.rb     -- SolidCable 스키마
```

- **결론**: Rails 8.1.2의 `rails new`는 Solid Stack 3개 gem을 Gemfile에 자동 포함하고, `solid_cache:install`, `solid_queue:install`, `solid_cable:install` 3개 install 명령도 자동 실행한다. 별도의 `rails generate` 명령이 불필요하다.
- **template.rb 시사점**: template.rb에서 Solid Stack install 명령을 별도로 실행할 필요 없음. 이미 `rails new`가 처리하므로, template.rb는 기본 생성된 설정 파일을 수정/확장하는 역할만 수행.

### 3. ruby 지시문

- **확정**: Gemfile에는 `ruby` 지시문 **미생성**. 대신 `.ruby-version` 파일이 자동 생성됨
- **근거**: Gemfile 전체 내용 + `.ruby-version` 파일 확인

#### Gemfile 상단 (1-4줄)

```ruby
source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2"
```

Gemfile에 `ruby "3.4.8"` 또는 `ruby file: ".ruby-version"` 같은 지시문이 **없다**.

#### .ruby-version 파일 내용

```
ruby-3.4.8
```

`.ruby-version` 파일이 프로젝트 루트에 자동 생성되었다.

- **결론**: Rails 8.1.2는 Gemfile에 ruby 버전 지시문을 넣지 않고, `.ruby-version` 파일로 버전 관리를 위임한다.
- **template.rb 시사점**: TSD에서 요구하는 ruby 버전 고정(`~> 3.4`)은 `.ruby-version` 파일을 수정하거나, Gemfile에 `ruby` 지시문을 명시적으로 추가하는 방식으로 구현해야 함. PRD에서 `ruby file: ".ruby-version"` 방식을 기대한다면 template.rb에서 해당 라인을 Gemfile에 inject해야 한다.

---

## 캡처 데이터

### Gemfile

```ruby
source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
```

### database.yml

```yaml
# PostgreSQL. Versions 9.3 and up are supported.
#
# Install the pg driver:
#   gem install pg
# On macOS with Homebrew:
#   gem install pg -- --with-pg-config=/opt/homebrew/bin/pg_config
# On Windows:
#   gem install pg
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.
#
# Configure Using Gemfile
# gem "pg"
#
default: &default
  adapter: postgresql
  encoding: unicode
  # For details on connection pooling, see Rails configuration guide
  # https://guides.rubyonrails.org/configuring.html#database-pooling
  max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>


development:
  <<: *default
  database: verify_app_development

  # The specified database role being used to connect to PostgreSQL.
  # To create additional roles in PostgreSQL see `$ createuser --help`.
  # When left blank, PostgreSQL will use the default role. This is
  # the same name as the operating system user running Rails.
  #username: verify_app

  # The password associated with the PostgreSQL role (username).
  #password:

  # Connect on a TCP socket. Omitted by default since the client uses a
  # domain socket that doesn't need configuration. Windows does not have
  # domain sockets, so uncomment these lines.
  #host: localhost

  # The TCP port the server listens on. Defaults to 5432.
  # If your server runs on a different port number, change accordingly.
  #port: 5432

  # Schema search path. The server defaults to $user,public
  #schema_search_path: myapp,sharedapp,public

  # Minimum log levels, in increasing order:
  #   debug5, debug4, debug3, debug2, debug1,
  #   log, notice, warning, error, fatal, and panic
  # Defaults to warning.
  #min_messages: notice

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: verify_app_test

# As with config/credentials.yml, you never want to store sensitive information,
# like your database password, in your source code. If your source code is
# ever seen by anyone, they now have access to your database.
#
# Instead, provide the password or a full connection URL as an environment
# variable when you boot the app. For example:
#
#   DATABASE_URL="postgres://myuser:mypass@localhost/somedatabase"
#
# If the connection URL is provided in the special DATABASE_URL environment
# variable, Rails will automatically merge its configuration values on top of
# the values provided in this file. Alternatively, you can specify a connection
# URL environment variable explicitly:
#
#   production:
#     url: <%= ENV["MY_APP_DATABASE_URL"] %>
#
# Connection URLs for non-primary databases can also be configured using
# environment variables. The variable name is formed by concatenating the
# connection name with `_DATABASE_URL`. For example:
#
#   CACHE_DATABASE_URL="postgres://cacheuser:cachepass@localhost/cachedatabase"
#
# Read https://guides.rubyonrails.org/configuring.html#configuring-a-database
# for a full overview on how database connection configuration can be specified.
#
production:
  primary: &primary_production
    <<: *default
    database: verify_app_production
    username: verify_app
    password: <%= ENV["VERIFY_APP_DATABASE_PASSWORD"] %>
  cache:
    <<: *primary_production
    database: verify_app_production_cache
    migrations_paths: db/cache_migrate
  queue:
    <<: *primary_production
    database: verify_app_production_queue
    migrations_paths: db/queue_migrate
  cable:
    <<: *primary_production
    database: verify_app_production_cable
    migrations_paths: db/cable_migrate
```

### Procfile.dev

```
web: bin/rails server
css: bin/rails tailwindcss:watch
```

### bin/ 디렉토리

```
brakeman  bundler-audit  ci  dev  docker-entrypoint  importmap  jobs  kamal  rails  rake  rubocop  setup  thrust
```

### db/ 디렉토리

```
cable_schema.rb
cache_schema.rb
queue_schema.rb
seeds.rb
```

### config/cable.yml

```yaml
# Async adapter only works within the same process, so for manually triggering cable updates from a console,
# and seeing results in the browser, you must do so from the web console (running inside the dev process),
# not a terminal started via bin/rails console! Add "console" to any action or any ERB template view
# to make the web console appear.
development:
  adapter: async

test:
  adapter: test

production:
  adapter: solid_cable
  connects_to:
    database:
      writing: cable
  polling_interval: 0.1.seconds
  message_retention: 1.day
```

### config/environments/production.rb (Solid Stack 관련)

```ruby
# 49-54줄
config.cache_store = :solid_cache_store

config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

### config/environments/development.rb (Solid Stack 관련)

development.rb에는 Solid Stack 관련 설정이 **없다**. 기본값:
- `config.cache_store = :memory_store` (SolidCache 미사용)
- Active Job adapter: 기본값 `:async` (SolidQueue 미사용)
- Action Cable: `adapter: async` (SolidCable 미사용)

### .ruby-version

```
ruby-3.4.8
```

### Gemfile 버전 비교 (기본 생성 vs TSD 명세)

| Gem | rails new 기본 | TSD 명세 | 차이 |
|---|---|---|---|
| rails | `~> 8.1.2` | `~> 8.1` | 범위 다름 (8.1.2 vs 8.1) |
| pg | `~> 1.1` | `~> 1.5` | TSD가 더 좁음 |
| puma | `>= 5.0` | `~> 6.5` | TSD가 더 좁음 |
| propshaft | 버전 미지정 | `~> 1.1` | TSD가 버전 고정 |
| importmap-rails | 버전 미지정 | `~> 2.1` | TSD가 버전 고정 |
| turbo-rails | 버전 미지정 | `~> 2.0` | TSD가 버전 고정 |
| stimulus-rails | 버전 미지정 | `~> 1.3` | TSD가 버전 고정 |
| tailwindcss-rails | 버전 미지정 | `~> 4.2` | TSD가 버전 고정 |
| solid_cache | 버전 미지정 | `~> 1.0` | TSD가 버전 고정 |
| solid_queue | 버전 미지정 | `~> 1.3` | TSD가 버전 고정 |
| solid_cable | 버전 미지정 | `~> 3.0` | TSD가 버전 고정 |
| kamal | 버전 미지정 | `~> 2.10` | TSD가 버전 고정 |
| thruster | 버전 미지정 | `~> 0.1` | TSD가 버전 고정 |
| bcrypt | (주석처리) | `~> 3.1` | template.rb에서 주석 해제 + 버전 고정 필요 |
| jbuilder | 포함 | 미포함 | template.rb에서 제거 고려 |
| bootsnap | 포함 | 미포함 | TSD에 미언급, 유지 가능 |
| image_processing | `~> 1.2` | 미포함 | template.rb에서 제거 고려 |
| web-console | 포함 | 미포함 | 유지 (Rails 기본) |
| bundler-audit | 포함 | 미포함 | 유지 (Rails 8.1 기본 추가) |

---

## 추가 발견 사항

### database.yml의 dev/test 멀티DB 부재

`rails new`가 생성하는 database.yml은 **production 환경에만** 멀티DB(primary/cache/queue/cable) 구성을 제공한다. development와 test는 단일 DB만 설정되어 있다.

```yaml
# production만 멀티DB
production:
  primary: &primary_production
    <<: *default
    database: verify_app_production
  cache:
    <<: *primary_production
    database: verify_app_production_cache
    migrations_paths: db/cache_migrate
  queue:
    ...
  cable:
    ...

# development/test는 단일 DB
development:
  <<: *default
  database: verify_app_development
test:
  <<: *default
  database: verify_app_test
```

**template.rb 시사점**: PRD에서 dev/test에서도 멀티DB 사용을 요구하므로, template.rb에서 database.yml을 덮어써서 3개 환경 모두 4개 논리 DB를 설정해야 한다.

### Procfile.dev에 jobs 프로세스 부재

`rails new`가 생성하는 Procfile.dev에는 SolidQueue 워커가 포함되어 있지 않다:

```
web: bin/rails server
css: bin/rails tailwindcss:watch
```

`bin/jobs` 파일은 생성되었지만, Procfile.dev에 `jobs: bin/jobs` 라인이 없다.

**template.rb 시사점**: Procfile.dev에 `jobs: bin/jobs` 라인을 추가해야 한다. CLAUDE.md에 명시된 3프로세스 구성(web + css + jobs) 구현 필요.

### Kamal deploy.yml 기본 구성

`rails new`가 `kamal init`을 자동 실행하여 기본 deploy.yml을 생성한다. 주요 특징:
- `registry.server: localhost:5555` (기본값, 변경 필요)
- `SOLID_QUEUE_IN_PUMA: true` (Puma 프로세스 내 SolidQueue 실행)
- SSL/proxy 설정은 주석처리 상태
- builder arch: `amd64` 고정

### CI 워크플로우 기본 구성

Rails 8.1.2는 `.github/workflows/ci.yml`을 자동 생성한다. 4개 job 구성:
- `scan_ruby`: Brakeman + bundler-audit
- `scan_js`: importmap audit
- `lint`: RuboCop
- `test` / `system-test`: PostgreSQL 서비스 포함

**template.rb 시사점**: 기본 CI가 이미 생성되므로, PRD의 7-step 파이프라인과의 차이를 분석하여 수정/확장해야 한다.

### Dockerfile 구성

Thruster가 기본 CMD에 포함되어 있다:

```dockerfile
CMD ["./bin/thrust", "./bin/rails", "server"]
```

프록시 체인: `kamal-proxy -> Thruster -> Puma` 아키텍처가 이미 기본 구성에 반영되어 있다.

---

## template.rb 구현 시사점

### 1. Gemfile 수정 전략 변경

`rails new`가 이미 대부분의 기본 gem을 포함하므로, template.rb의 Step 1(Gemfile 수정)은 다음 작업만 수행:

1. **버전 고정**: 느슨한 버전(예: `gem "pg", "~> 1.1"`)을 TSD 명세 버전으로 교체
2. **bcrypt 주석 해제**: `# gem "bcrypt", "~> 3.1.7"` -> `gem "bcrypt", "~> 3.1"`
3. **4개 외부 gem 추가**: `pundit`, `pagy`, `lograge`, `view_component`
4. **불필요 gem 제거 고려**: `jbuilder`, `image_processing` (TSD에 미포함)
5. **테스트 gem 버전 고정**: `capybara`, `selenium-webdriver`, `debug`, `brakeman`

### 2. Solid Stack install 불필요

`rails new`가 3개 install을 자동 실행하므로, template.rb에서 `rails_command "solid_cache:install"` 등을 호출할 필요 없다. 대신:
- 기본 생성된 `config/cache.yml`, `config/queue.yml`, `config/cable.yml` 수정
- `config/environments/development.rb`에 Solid Stack 설정 추가 (기본 미포함)

### 3. database.yml 전체 덮어쓰기 필요

production만 멀티DB인 기본 database.yml을 dev/test도 포함하는 완전한 멀티DB 설정으로 교체해야 한다.

### 4. Procfile.dev 수정 필요

`jobs: bin/jobs` 라인 추가가 필요하다.

### 5. ruby 지시문 전략

Gemfile에 `ruby file: ".ruby-version"` 추가 여부 결정 필요. Rails 8.1 기본은 `.ruby-version` 파일만 사용하고 Gemfile에는 ruby 지시문을 넣지 않는다. TSD에서 `ruby "~> 3.4"` 고정을 요구하는 경우, Gemfile에 명시적으로 추가하는 방식이 더 적합할 수 있다.

### 6. Kamal/CI 설정은 수정 방식

기본 생성된 deploy.yml과 ci.yml을 기반으로 수정하는 전략이 효율적이다. 전체 덮어쓰기보다 `gsub_file`/`inject_into_file`로 필요한 부분만 변경.

---

## Phase 1 통합 테스트 결과

> **실행일**: 2026-02-22
> **명령**: `rails new test_final2 -d postgresql -c tailwind -m template.rb`
> **실행 위치**: `/tmp/ror-phase1-final2/`
> **상태**: **전체 PASS**

### ROADMAP 7개 검증 기준

| # | 검증 기준 | 결과 | 비고 |
|---|-----------|------|------|
| 1 | rails new -m template.rb 성공 | **PASS** | Phase 5 Step 19(db:prepare)만 PG 미실행으로 에러, Phase 1 범위 정상 |
| 2 | Gemfile TSD 전수 일치 | **PASS** | 24개 gem 버전 핀 일치, jbuilder/image_processing 제거 확인 |
| 3 | database.yml 4DB x 3환경 | **PASS** | dev/test/prod 각 4DB(primary/queue/cache/cable), max_connections 키 |
| 4 | rails db:create | **SKIP** | PostgreSQL 미실행 환경 — Phase 5에서 별도 검증 예정 |
| 5 | app 디렉토리 존재 | **PASS** | app/services/, app/policies/, app/components/ 모두 존재 |
| 6 | db migrate 디렉토리 존재 | **PASS** | db/cache_migrate/, db/queue_migrate/, db/cable_migrate/ 모두 존재 |
| 7 | Procfile.dev 3프로세스 | **PASS** | web: bin/rails server, css: bin/rails tailwindcss:watch, jobs: bin/jobs |

### 추가 검증 항목

| 항목 | 결과 | 비고 |
|------|------|------|
| .env.example | **PASS** | DB_USER, DB_PASSWORD, RAILS_MAX_THREADS, ADMIN_EMAIL/PASSWORD 포함 |
| .gitignore .env 패턴 | **PASS** | .env, .env.local 패턴 추가 확인 |
| bin/jobs 존재 | **PASS** | solid_queue:install 자동 생성 확인 |

### 수정 이력

통합 테스트 중 발견된 이슈 3건을 수정 후 재검증:

1. **jbuilder/image_processing 주석 잔존** — gsub_file 패턴을 주석+gem+후행빈줄 포함으로 확장
2. **외부 gem 위치** — `gem` 메서드 대신 `inject_into_file before: /^group :development, :test/`로 group 블록 앞에 배치
3. **inject_into_file 중복 매칭** — `before: /^group :development/` → `before: /^group :development, :test/`로 구체화하여 중복 삽입 방지
