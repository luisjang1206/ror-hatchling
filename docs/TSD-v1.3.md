# TSD: Rails 8 풀스택 범용 보일러플레이트

> **버전**: 1.3
> **기준일**: 2026-02-21
> **관련 문서**: PRD v3.3
> **변경 이력**:
> - v1.0: 초안 작성 (PRD v3 기반)
> - v1.1: 피드백 4건 반영 (Kamal 프록시 아키텍처 정합성, CI 도구 연결, Docker 멀티스테이지 설명 보강, Pagy 버전 체계 주석)
> - v1.2: 부록 B(PRD 정합성 수정 사항) 제거 — PRD v3.1에 직접 반영 완료
> - v1.3: 교차검증 피드백 4건 반영 — PostgreSQL 지원기간 교정(~2029), Thruster 역할 설명 교정(HTTP/2 → 압축/캐싱/X-Sendfile), Ruby 4.0 단정형 축소, Gem 버전 기준일 최신 반영

---

## 1. 버전 선택 원칙

| 원칙 | 설명 |
|---|---|
| **안정 우선** | RC/beta가 아닌 프로덕션 검증된 안정 릴리즈만 채택 |
| **호환성 검증** | Rails 공식 호환 매트릭스 기준, 주요 Gem과의 호환 확인 |
| **LTS 고려** | PostgreSQL 등 인프라는 최소 3년 이상 지원 보장 버전 우선 |
| **최소 외부 의존성** | Rails 8 내장 기능 최대 활용, 외부 Gem은 4개로 제한 |

---

## 2. Core Runtime

### 2.1 Ruby 3.4.x (3.4.8)

| 항목 | 내용 |
|---|---|
| 선택 버전 | 3.4.8 (2026-02-21 기준 3.4 시리즈 최신 패치) |
| 선택 근거 | Rails 8.1 공식 호환, YJIT 성능 개선, 프로덕션 검증 완료 |
| 대안 검토 | Ruby 4.0.x 출시되었으나 일부 Gem 호환 이슈 잔존, 안정화 후 전환 예정 |

> **Ruby 4.0 마이그레이션 참고**: Ruby 4.0은 메이저 버전 업그레이드로 행동 변화가 있을 수 있다. 현재 pundit, view_component 등 의존 Gem의 4.0 호환이 완전 검증된 후 전환을 권장한다. Gemfile에 `ruby "~> 3.4"` 지정으로 의도치 않은 4.0 업그레이드를 방지. 전환 시 Ruby 공식 릴리즈 노트(NEWS 파일)를 기준으로 변경 사항을 확인할 것.

### 2.2 Rails 8.1.x (8.1.2)

| 항목 | 내용 |
|---|---|
| 선택 버전 | 8.1.2 (2026-02-21 기준 최신 안정) |
| 선택 근거 | Solid 스택(Queue/Cache/Cable) 성숙, authentication generator 내장, Kamal 2 통합 |
| 주요 내장 기능 활용 | authentication generator, rate_limit, generates_token_for, Solid 스택, Propshaft, Import Maps |

### 2.3 PostgreSQL 17.x (17.8)

| 항목 | 내용 |
|---|---|
| 선택 버전 | 17.8 (2026-02-21 기준 17 시리즈 최신 패치) |
| 선택 근거 | 1년 이상 안정화, 공식 지원 ~2029-11, Solid 스택 완벽 호환 |
| 대안 검토 | PostgreSQL 18.x 출시되었으나 아직 초기 패치 단계, 안정화 후 전환 가능 |
| 멀티 DB 구성 | 단일 서버에서 primary/cache/queue/cable 논리 DB 분리 (PRD 2.5절 참조) |

---

## 3. Frontend

### 3.1 Hotwire (Turbo + Stimulus)

| 항목 | 내용 |
|---|---|
| Turbo | turbo-rails (Rails 8.1 내장) |
| Stimulus | stimulus-rails (Rails 8.1 내장) |
| 역할 | SPA 없이 서버 렌더링 기반 동적 UI 구현 |

### 3.2 Tailwind CSS 4.x

| 항목 | 내용 |
|---|---|
| 설치 방식 | `tailwindcss-rails` Gem (standalone CLI 내장, Node.js 불필요) |
| 설정 방식 | CSS-first configuration (v4 기본) — `tailwind.config.js` 대신 CSS `@theme` 디렉티브 사용 |
| 주요 변경 (v3 대비) | Node.js 의존성 완전 제거, 설정이 CSS 파일 내로 통합, Oxide 엔진(Rust) 기반 빌드 |

### 3.3 Propshaft + Import Maps

| 항목 | 내용 |
|---|---|
| Propshaft | 에셋 파이프라인 (Sprockets 대체, Rails 8 기본) |
| Import Maps | JS 번들러 없이 ES modules 직접 사용 (Rails 8 기본) |
| 역할 | Node.js/webpack/esbuild 없는 제로 빌드 JS 환경 |

---

## 4. Gem 의존성 상세

### 4.1 내장/공식 Gems

PRD의 기술 스택 요약에 해당하는 Gem들. Rails 8.1 기본 생성 또는 공식 지원.

| Gem | 버전 | 역할 | 비고 |
|---|---|---|---|
| `rails` | ~> 8.1 | 프레임워크 | 코어 |
| `pg` | ~> 1.5 | PostgreSQL 어댑터 | |
| `puma` | ~> 6.5 | 웹 서버 | Rails 기본 |
| `thruster` | ~> 0.1 | 압축, 에셋 캐싱, X-Sendfile 처리 | 컨테이너 내부 Puma 앞단. HTTP/2 자체 지원하나 kamal-proxy 뒤에서는 압축/캐싱이 주 역할 |
| `propshaft` | ~> 1.1 | 에셋 파이프라인 | |
| `turbo-rails` | ~> 2.0 | Turbo | |
| `stimulus-rails` | ~> 1.3 | Stimulus | |
| `importmap-rails` | ~> 2.1 | Import Maps | |
| `tailwindcss-rails` | ~> 4.2 | Tailwind CSS standalone CLI | v4 CSS-first |
| `solid_queue` | ~> 1.3 | 백그라운드 잡 (DB 기반) | 기준일 최신: 1.3.2 |
| `solid_cache` | ~> 1.0 | 캐시 (DB 기반) | |
| `solid_cable` | ~> 3.0 | WebSocket (DB 기반) | |
| `bcrypt` | ~> 3.1 | 비밀번호 해싱 | has_secure_password 의존 |

### 4.2 외부 Gems (4개)

PRD "최소 외부 의존성" 원칙에 따라 4개로 제한.

| Gem | 버전 | 역할 | 채택 근거 |
|---|---|---|---|
| `pundit` | ~> 2.5 | 인가 (Policy 기반) | 내장 대안 없음, 경량, 관례 기반 |
| `pagy` | ~> 43.0 | 페이지네이션 | 내장 대안 없음, 최고 성능, 최소 메모리 |
| `lograge` | ~> 0.14 | 구조화 로깅 (JSON) | 프로덕션 운영 필수, Rails 기본 로깅 불충분 |
| `view_component` | ~> 4.4 | UI 컴포넌트 프레임워크 | GitHub 공식, 타입 안전 파라미터, 단위 테스트. 기준일 최신: 4.4.0 |

> **Pagy 버전 참고**: Pagy는 SemVer가 아닌 독자적 버전 체계를 사용합니다. 43.x는 실제 최신 안정 버전이며, 메이저 버전이 높은 것은 릴리즈 정책의 차이입니다.

### 4.3 Development & Test Gems

| Gem | 버전 | 역할 | 비고 |
|---|---|---|---|
| `debug` | ~> 1.9 | 디버거 | Rails 내장, ruby/debug |
| `brakeman` | ~> 7.0 | 보안 정적 분석 | CI Step 5에서 실행 (5.3절 참조) |
| `rubocop-rails-omakase` | ~> 1.0 | 코드 스타일 | Rails 공식 스타일 가이드, CI Step 4에서 실행 |
| `capybara` | ~> 3.40 | 시스템 테스트 (E2E) | |
| `selenium-webdriver` | ~> 4.27 | 브라우저 드라이버 | headless Chrome |

### 4.4 Gemfile 전체

```ruby
source "https://rubygems.org"

ruby "~> 3.4"

# --- Core ---
gem "rails", "~> 8.1"
gem "pg", "~> 1.5"
gem "puma", "~> 6.5"
gem "thruster", "~> 0.1"

# --- Frontend ---
gem "propshaft", "~> 1.1"
gem "turbo-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3"
gem "importmap-rails", "~> 2.1"
gem "tailwindcss-rails", "~> 4.2"

# --- Infrastructure (Solid Stack) ---
gem "solid_queue", "~> 1.3"
gem "solid_cache", "~> 1.0"
gem "solid_cable", "~> 3.0"

# --- Auth & Security ---
gem "bcrypt", "~> 3.1"
gem "pundit", "~> 2.5"

# --- Utilities ---
gem "pagy", "~> 43.0"
gem "lograge", "~> 0.14"
gem "view_component", "~> 4.4"

# --- Deployment ---
gem "kamal", "~> 2.10", require: false

group :development, :test do
  gem "debug", "~> 1.9"
  gem "brakeman", "~> 7.0", require: false
  gem "rubocop-rails-omakase", "~> 1.0", require: false
end

group :test do
  gem "capybara", "~> 3.40"
  gem "selenium-webdriver", "~> 4.27"
end
```

---

## 5. 배포 & 인프라

### 5.1 Kamal 2.10.1

| 항목 | 내용 |
|---|---|
| 역할 | Docker 기반 제로 다운타임 배포 |
| 프록시 | kamal-proxy (Rust 기반, Kamal 2 내장) — Kamal 1의 Traefik을 대체 |
| 컨테이너 구성 | kamal-proxy → Thruster → Puma (3계층) |

**프록시 아키텍처:**
```
[인터넷] → [kamal-proxy] → [Thruster] → [Puma]
             │                │             │
             │                │             └─ Ruby 앱 서버 (워커/스레드)
             │                └─ 에셋 캐싱, gzip 압축, X-Sendfile (컨테이너 내부)
             └─ SSL 종단(Let's Encrypt), HTTP/2, 무중단 배포 라우팅, 에러 페이지 서빙 (호스트 레벨)
```

- **kamal-proxy**: 호스트에서 실행. SSL 종단, HTTP/2, Let's Encrypt 자동 갱신, 블루-그린 배포 라우팅, `error_pages_path` 에러 페이지 서빙
- **Thruster**: 컨테이너 내부에서 Puma 앞에 위치. gzip 압축, 에셋 캐싱, X-Sendfile 처리. (HTTP/2를 자체 지원하나 kamal-proxy 뒤에서는 압축/캐싱이 주 역할)
- **Puma**: Ruby 앱 서버. 멀티 워커 + 멀티 스레드

### 5.2 Docker

| 항목 | 내용 |
|---|---|
| 베이스 이미지 | `ruby:3.4.8-slim` (빌드/런타임 모두) |
| 빌드 전략 | 멀티스테이지 (빌드 의존성과 런타임 분리, 최소 이미지 크기) |
| 포함 | Thruster, Puma, 앱 코드, 프리컴파일된 에셋 |

**멀티스테이지 구조:**
- **빌드 스테이지**: `ruby:3.4.8-slim` 기반, build-essential/libpq-dev 설치 → `bundle install` → 에셋 프리컴파일
- **런타임 스테이지**: 동일 `ruby:3.4.8-slim` 기반, 최소 런타임 의존성(libpq5 등)만 포함 → 빌드 스테이지에서 gems/에셋 복사

### 5.3 CI/CD (GitHub Actions)

**파이프라인 Steps:**

| Step | 작업 | 도구 |
|---|---|---|
| 1 | Ruby 설정 + 의존성 캐싱 | `ruby/setup-ruby` (bundler-cache: true) |
| 2 | 에셋 캐싱 | Tailwind CLI 빌드 결과 + Propshaft 에셋 캐시 |
| 3 | DB 생성 + 마이그레이션 | 서비스 컨테이너 postgres, 멀티 DB 포함 |
| 4 | 린트 | `bundle exec rubocop` (rubocop-rails-omakase) |
| 5 | 보안 스캔 | `bundle exec brakeman` |
| 6 | 단위/통합 테스트 | `bin/rails test` (Minitest) |
| 7 | 시스템 테스트 | `bin/rails test:system` (Capybara + headless Chrome) |

---

## 6. 테스트

| 도구 | 버전 | 역할 |
|---|---|---|
| Minitest | Rails 내장 | 단위/통합 테스트 |
| Capybara | ~> 3.40 | 시스템 테스트 (E2E) |
| Selenium | ~> 4.27 | headless Chrome 드라이버 |
| Fixtures | Rails 내장 | 테스트 데이터 |

---

## 7. 호환성 매트릭스

| Ruby | Rails | PostgreSQL | Tailwind | 상태 |
|---|---|---|---|---|
| 3.4.x | 8.1.x | 17.x | 4.x | ✅ **권장 (본 문서 기준)** |
| 3.4.x | 8.1.x | 18.x | 4.x | ✅ 호환 (안정화 후 전환 가능) |
| 4.0.x | 8.1.x | 17.x | 4.x | ⚠️ 기본 호환되나 일부 Gem 이슈 잔존 |

---

## 8. 버전 업그레이드 정책

| 대상 | 정책 | 주기 |
|---|---|---|
| Ruby 패치 (3.4.x) | 즉시 적용 | 릴리즈 후 1주 내 |
| Rails 패치 (8.1.x) | 즉시 적용 | 릴리즈 후 1주 내 |
| PostgreSQL 패치 (17.x) | 즉시 적용 | 릴리즈 후 2주 내 |
| Ruby 마이너/메이저 | CI 검증 후 적용 | 릴리즈 후 1~3개월 |
| Rails 마이너 | CI 검증 후 적용 | 릴리즈 후 1~2개월 |
| PostgreSQL 메이저 | 충분한 안정화 후 | 릴리즈 후 6개월~1년 |
| 외부 Gem | 호환성 확인 후 | 분기별 점검 |

> **Gemfile 버전 제약과의 관계**: Gemfile의 pessimistic operator(`~>`)는 마이너 버전 범위 내 자동 업데이트를 허용한다. 실제 고정은 `Gemfile.lock`으로 통제하며, 업그레이드 시 `bundle update <gem>` → CI 검증 → 머지 흐름을 따른다.

---

## 부록 A. 참고 링크

| 항목 | URL |
|---|---|
| Ruby 릴리즈 | https://www.ruby-lang.org/en/downloads/ |
| Rails 릴리즈 | https://rubyonrails.org/category/releases |
| PostgreSQL 버전 정책 | https://www.postgresql.org/support/versioning/ |
| Kamal 공식 문서 | https://kamal-deploy.org/ |
| Tailwind CSS v4 | https://tailwindcss.com/blog/tailwindcss-v4 |
| Solid Queue | https://github.com/rails/solid_queue |
| Solid Cache | https://github.com/rails/solid_cache |
| Solid Cable | https://github.com/rails/solid_cable |
