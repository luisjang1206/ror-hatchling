# PRD: Rails 8 풀스택 범용 보일러플레이트 (v3)

> **버전**: 3.3
> **최종 수정**: 2026-02-21
> **변경 이력**:
> - v1 → v2: 리뷰 피드백 6건 반영 (generates_token_for, 에러 핸들링, Docker 하이브리드, CI 캐싱, Kamal 2 상세, ViewComponent)
> - v2 → v3: 공식 문서 기준 재평가 8건 반영 (인증 범위 정정, 토큰 중복 제거, rate_limit store 명시, 멀티 DB 설계, 헬스체크 역할 분리, Kamal error_pages, 비밀번호 정책, AR Encryption 위치 조정)
> - v3.0 → v3.1: TSD 문서와 정합성 수정 — Kamal 2 프록시를 Traefik에서 kamal-proxy로 교정
> - v3.1 → v3.2: 피드백 반영 3건 — Postgres-only 스케일 참고 노트(2.5절), README 포함 항목 확충(5.3절: jsbundling 전환 가이드, 스케일 전환 기준, Kamal SSL 체크리스트)
> - v3.2 → v3.3: TSD 교차검증 피드백 반영 2건 — Ruby 버전 표기 통일(3.3+→3.4+), 로컬 개발 PostgreSQL 버전 통일(16→17)

---

## 1. 개요

### 1.1 프로젝트 명
**ROR-Hatchling**

### 1.2 목적
새로운 Ruby on Rails 풀스택 프로젝트를 시작할 때, 반복적인 초기 설정 없이 즉시 비즈니스 로직 개발에 집중할 수 있는 범용 보일러플레이트를 구축한다.

### 1.3 타겟 사용자
- 중규모 이상으로 성장할 웹 앱을 시작하는 Rails 개발자 및 팀
- 단순 CRUD 수준이 아닌, 인증·인가·관리자·실시간 기능이 필요한 프로젝트

### 1.4 핵심 원칙
| 원칙 | 설명 |
|---|---|
| **내장 우선** | Rails 8 내장 기능을 최대한 활용하고, 외부 Gem 의존성을 최소화한다. |
| **풀스택** | API 모드가 아닌 서버 렌더링 + Hotwire 기반 풀스택 구조를 채택한다. |
| **범용성** | 특정 도메인에 종속되지 않으며, 웹 앱 전반에 적용 가능하다. |
| **즉시 실행** | `rails new -m template.rb` 한 줄로 전체 보일러플레이트가 셋업된다. |

### 1.5 기술 스택 요약
| 항목 | 선택 |
|---|---|
| 언어 | Ruby 3.4+ |
| 프레임워크 | Rails 8.x |
| 데이터베이스 | PostgreSQL (단일 서버, 논리 DB 분리) |
| 프론트엔드 | Hotwire (Turbo + Stimulus) |
| CSS | Tailwind CSS (순수, 플러그인 없음) |
| JS 번들링 | Import Maps |
| 에셋 파이프라인 | Propshaft |
| UI 컴포넌트 | ViewComponent |
| 테스트 | Minitest + Capybara |
| 컨테이너 | Docker (DB) + 로컬 bin/dev (앱) |
| CI/CD | GitHub Actions |
| 배포 | Kamal 2 |

---

## 2. 기능 요구사항

### 2.1 인증 (Authentication)

| 항목 | 상세 |
|---|---|
| Generator 제공 범위 | 로그인, 로그아웃, 세션 관리, 비밀번호 리셋 |
| Boilerplate 별도 제공 | 회원가입(Sign up) 플로우 (Generator가 제공하지 않으므로 직접 구현) |
| 비밀번호 | `has_secure_password` (bcrypt) |
| 비밀번호 정책 | 최소 8자, 추가 복잡도 규칙은 앱에서 커스터마이징 가능하도록 별도 Validation으로 분리 |
| 비밀번호 리셋 토큰 | Generator 기본 제공 흐름을 그대로 사용 (기본 15분 유효) |
| 추가 목적 토큰 | `generates_token_for` API로 앱별 토큰 정의 (이메일 인증, 매직 링크 등) |
| 속도 제한 | Rails 8 내장 `rate_limit` (로그인 시도 제한) |
| 뷰 | 로그인/회원가입/비밀번호 리셋 폼 (Tailwind 스타일링 적용) |

> **v2 대비 변경**:
> - "회원가입 포함"을 Generator 범위에서 분리. Generator는 로그인/세션/비밀번호 리셋만 제공하며, 회원가입은 Boilerplate가 별도 구현.
> - `generates_token_for :password_reset` 중복 정의 제거. 비밀번호 리셋은 Generator 기본 흐름 사용.
> - 비밀번호 최소 길이 정책 추가 (`has_secure_password`는 존재 여부만 검증).

**추가 목적 토큰 예시:**
```ruby
class User < ApplicationRecord
  generates_token_for :email_confirmation, expires_in: 24.hours do
    email  # 이메일 변경 시 기존 토큰 자동 무효화
  end

  generates_token_for :magic_link, expires_in: 5.minutes do
    updated_at.to_f  # 어떤 변경이든 기존 토큰 무효화
  end
end
```

### 2.2 인가 (Authorization)

| 항목 | 상세 |
|---|---|
| 방식 | Pundit |
| 역할 모델 | User 모델에 `enum :role, { user: 0, admin: 1, super_admin: 2 }` |
| 기본 정책 | `ApplicationPolicy` 베이스 클래스 제공 |
| 관리자 접근 | Admin 네임스페이스에 역할 기반 접근 제어 |

### 2.3 프론트엔드

#### 2.3.1 Hotwire 구성
- **Turbo Drive**: 전체 페이지 리로드 없는 내비게이션 (기본 활성)
- **Turbo Frames**: 부분 페이지 업데이트 패턴 예시 포함
- **Turbo Streams**: 실시간 업데이트 패턴 예시 포함
- **Stimulus**: 인터랙티브 UI 동작 처리

#### 2.3.2 UI 컴포넌트 시스템 (ViewComponent)

외부 UI 라이브러리(DaisyUI, shadcn 등)를 사용하지 않는다.
순수 Tailwind + ViewComponent 기반 재사용 가능한 UI 컴포넌트를 제공한다.

**채택 근거:**
- 타겟이 중규모 이상 앱이므로 컴포넌트가 수십 개로 증가할 것을 전제
- ERB partial의 local variables 관리 한계 (파라미터 검증 불가, 오타 시 nil 허용)
- Ruby 클래스 기반으로 컴포넌트 단위 테스트 가능
- GitHub 프로덕션 검증 완료, ERB 문법 그대로 사용하여 학습 곡선 최소

**디렉토리 구조:**
```
app/components/
├── application_component.rb
├── button_component.rb
├── button_component.html.erb
├── card_component.rb
├── card_component.html.erb
├── modal_component.rb
├── modal_component.html.erb
├── flash_component.rb
├── flash_component.html.erb
├── form_field_component.rb
├── form_field_component.html.erb
├── empty_state_component.rb
├── empty_state_component.html.erb
├── badge_component.rb
├── badge_component.html.erb
├── dropdown_component.rb
├── dropdown_component.html.erb
├── pagination_component.rb
├── pagination_component.html.erb
├── navbar_component.rb
└── navbar_component.html.erb
```

**컴포넌트 목록:**

| 컴포넌트 | 설명 | Variant | Stimulus 연동 |
|---|---|---|---|
| Button | 버튼, 링크 버튼 | primary, secondary, danger | ❌ |
| Card | 콘텐츠 컨테이너 | default, bordered | ❌ |
| Badge | 상태 표시 태그 | success, warning, error, info | ❌ |
| Flash | 알림 메시지 (Turbo 호환) | notice, alert, error | ✅ 자동 닫기 |
| Modal | 확인/입력 대화상자 | default | ✅ 열기/닫기/ESC |
| Dropdown | 메뉴, 선택지 | default | ✅ 토글/외부클릭 |
| Form Field | 라벨 + 인풋 + 에러 묶음 | text, email, password, select, textarea | ❌ |
| Empty State | 데이터 없을 때 안내 | default | ❌ |
| Pagination | Pagy 연동 페이지네이션 | default | ❌ |
| Navbar | 반응형 네비게이션 바 | default | ✅ 모바일 토글 |

#### 2.3.3 Stimulus 컨트롤러
```
app/javascript/controllers/
├── flash_controller.js
├── modal_controller.js
├── dropdown_controller.js
└── navbar_controller.js
```

### 2.4 관리자 페이지

| 항목 | 상세 |
|---|---|
| 방식 | 직접 구축 (외부 Gem 없음) |
| 네임스페이스 | `Admin::` 컨트롤러 네임스페이스 |
| 라우팅 | `/admin/*` |
| 접근 제어 | `Admin::BaseController`에서 Pundit 기반 역할 확인 |
| 레이아웃 | 별도 관리자 레이아웃 (`layouts/admin.html.erb`) |
| 기본 기능 | 대시보드 페이지, 사용자 목록 조회 |

### 2.5 백그라운드 처리 & 인프라

| 영역 | 솔루션 | 비고 |
|---|---|---|
| 백그라운드 잡 | Solid Queue | Rails 공식, DB 기반 |
| 캐시 | Solid Cache | Rails 공식, DB 기반 |
| WebSocket | Solid Cable | Rails 공식, DB 기반 |
| 메일 | Action Mailer | 내장 |
| 파일 업로드 | Active Storage | 내장 |
| 리치 텍스트 | Action Text | 내장 (필요 시 활성화) |

**데이터베이스 구성:**

Redis 없이 PostgreSQL 기반으로 큐, 캐시, WebSocket을 운영한다. 단, Solid 스택은 기본적으로 메인 앱과 논리 DB(또는 별도 커넥션)를 분리하는 것이 Rails 공식 권장 구성이다.

```yaml
# config/database.yml 구조 (개요)
production:
  primary:
    <<: *default
    database: ror_hatchling_production
  cache:
    <<: *default
    database: ror_hatchling_production_cache
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: ror_hatchling_production_queue
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    database: ror_hatchling_production_cable
    migrations_paths: db/cable_migrate
```

> **v2 대비 변경**: "PostgreSQL 단일 DB만으로 모두 처리"라는 표현을 교정. 단일 PostgreSQL 서버(인스턴스)로 운영 가능하되, 논리 DB를 분리하는 것이 기본 권장. 트랜잭션 결합/락 리스크를 사전에 방지.

> **스케일 참고**: Postgres-only 구성은 초기 운영 복잡도를 크게 낮추지만, Solid 스택 전체가 DB에 의존하므로 트래픽 증가 시 DB가 단일 병목이 될 수 있다. 아래 증상이 나타나면 해당 영역을 Redis 또는 외부 서비스로 분리를 검토한다:
> - WebSocket 동시접속/메시지량 증가로 Solid Cable 폴링 부하 발생
> - 백그라운드 잡 처리 지연(큐 적체) 발생
> - 캐시 hit ratio 저하 또는 응답 레이턴시 증가
>
> 전환 방법은 README의 "스케일 전환 가이드"에서 안내한다.

### 2.6 속도 제한 (Rate Limiting)

| 항목 | 상세 |
|---|---|
| 방식 | Rails 8 내장 `rate_limit` |
| 적용 대상 | 로그인 시도, 회원가입, 비밀번호 리셋 요청 |
| Cache Store 의존성 | `config.cache_store`를 따름. Solid Cache 사용 시 자동으로 DB-backed |
| 커스터마이징 | 필요 시 `rate_limit store:` 옵션으로 별도 store 분리 가능 |

```ruby
class SessionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_session_url, alert: "Try again later."
  }
end
```

> **v2 대비 변경**: rate_limit의 cache store 의존성을 명시. Solid Cache와의 연결 고리를 PRD에 포함.

### 2.7 국제화 (I18n)

**디렉토리 구조:**
```
config/locales/
├── en.yml
├── ko.yml
├── defaults/
│   ├── en.yml         # 공통 UI 텍스트 (버튼, 상태, 에러)
│   └── ko.yml
└── models/
    ├── en.yml         # 모델/속성 번역
    └── ko.yml
```

- 기본 로케일: `ko` (설정에서 변경 가능)
- Flash 메시지, 폼 라벨, 에러 메시지 등 모든 사용자 노출 텍스트는 I18n 키로 관리

### 2.8 에러 처리

**공통 에러 핸들링 (ApplicationController):**
- `ActiveRecord::RecordNotFound` → 404
- `Pundit::NotAuthorizedError` → 403

**500 에러는 ApplicationController에서 rescue하지 않는다.**
- Rails 기본 예외 처리 미들웨어(PublicExceptions)에 위임
- 개발 환경: Rails 디버깅 화면(Error traceback) 정상 표시
- 프로덕션 환경: Sentry 등 에러 트래킹 도구로 예외 전달 보장

**커스텀 에러 페이지:**
- `public/404.html` — Not Found (Tailwind 스타일링)
- `public/422.html` — Unprocessable Entity (Tailwind 스타일링)
- `public/500.html` — Internal Server Error (Tailwind 스타일링)

> Kamal 배포 시 `error_pages_path` 설정과 연동하여 kamal-proxy가 에러 페이지를 직접 서빙할 수 있도록 구성 (4.1절 참조).

### 2.9 헬스체크 & 모니터링

| 엔드포인트 | 역할 | 구현 |
|---|---|---|
| `GET /up` | **Liveness** — 앱 부팅 성공 여부 확인 | Rails 기본 제공 (`Rails::HealthController`). 의존성(DB 등) 상태는 확인하지 않음 |
| `GET /health` | **Readiness** — 서비스 준비 상태 확인 | Boilerplate 제공. DB 연결 등 핵심 의존성 확인 포함 |

- Kamal 헬스체크는 기본적으로 `/up`을 사용
- 로드밸런서/오케스트레이터에서 readiness probe가 필요한 경우 `/health` 활용

> **v2 대비 변경**: Rails 기본 `/up`을 무시하고 `/health`만 제공하던 것에서, `/up`(liveness) + `/health`(readiness) 2단 구조로 역할 분리.

**로깅:**
- `lograge` Gem으로 구조화된 JSON 로그 출력
- 요청당 한 줄 로그 (method, path, status, duration, params)

### 2.10 시드 데이터

```
db/seeds.rb                    # 진입점 (환경별 분기)
db/seeds/admin_user.rb         # 기본 관리자 계정 생성
db/seeds/sample_data.rb        # 개발용 샘플 데이터 (development만)
```

---

## 3. 비기능 요구사항

### 3.1 프로젝트 구조

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── registrations_controller.rb  # 회원가입 (Boilerplate 제공)
│   ├── admin/
│   │   └── base_controller.rb
│   └── health_controller.rb         # Readiness 체크
├── models/
│   └── user.rb
├── views/
│   ├── layouts/
│   │   ├── application.html.erb
│   │   └── admin.html.erb
│   ├── registrations/               # 회원가입 뷰
│   └── shared/                      # 공통 partial
├── components/                      # ViewComponent UI 컴포넌트
├── services/                        # 비즈니스 로직 서비스 객체
├── policies/                        # Pundit 정책
├── javascript/
│   └── controllers/                 # Stimulus 컨트롤러
├── jobs/                            # Active Job
├── mailers/
└── helpers/
config/
├── database.yml                     # 멀티 DB (primary/cache/queue/cable)
├── locales/                         # I18n
├── initializers/
│   ├── pagy.rb
│   └── pundit.rb
├── deploy.yml                       # Kamal 2 배포 설정
public/
├── 404.html                         # 커스텀 에러 페이지
├── 422.html
└── 500.html
db/
├── seeds.rb
├── seeds/
├── cache_migrate/                   # Solid Cache 마이그레이션
├── queue_migrate/                   # Solid Queue 마이그레이션
└── cable_migrate/                   # Solid Cable 마이그레이션
.kamal/
├── secrets                          # 환경변수 주입 스크립트
└── hooks/                           # 배포 전/후 훅
.github/
└── workflows/
    └── ci.yml                       # GitHub Actions CI
```

### 3.2 Gem 의존성

**원칙: 외부 Gem은 최소한으로, 내장/공식 우선**

#### Production Gems
| Gem | 용도 | 분류 |
|---|---|---|
| `rails` ~> 8.0 | 프레임워크 | 공식 |
| `pg` | PostgreSQL 어댑터 | 필수 |
| `propshaft` | 에셋 파이프라인 | 내장 |
| `turbo-rails` | Turbo | 내장 |
| `stimulus-rails` | Stimulus | 내장 |
| `tailwindcss-rails` | Tailwind CSS | 공식 지원 |
| `solid_queue` | 백그라운드 잡 | 공식 |
| `solid_cache` | 캐시 | 공식 |
| `solid_cable` | WebSocket | 공식 |
| `bcrypt` | 비밀번호 해싱 | has_secure_password 의존 |
| `pundit` | 인가 | 검증된 외부 |
| `pagy` | 페이지네이션 | 검증된 외부 |
| `lograge` | 구조화 로깅 | 검증된 외부 |
| `view_component` | UI 컴포넌트 | GitHub 공식 |

#### Development & Test Gems
| Gem | 용도 |
|---|---|
| `debug` | 디버거 (내장) |
| `brakeman` | 보안 정적 분석 |
| `rubocop-rails-omakase` | 코드 스타일 (Rails 공식) |
| `capybara` | 시스템 테스트 |
| `selenium-webdriver` | 브라우저 드라이버 |

**외부 Gem 총 4개**: pundit, pagy, lograge, view_component

### 3.3 테스트

| 도구 | 용도 |
|---|---|
| Minitest | 단위/통합 테스트 (Rails 내장) |
| Fixtures | 테스트 데이터 (Rails 내장) |
| Capybara | 시스템 테스트 (E2E) |

**테스트 디렉토리 구조:**
```
test/
├── models/
├── controllers/
├── integration/
├── system/              # Capybara E2E
├── components/          # ViewComponent 단위 테스트
├── services/
├── policies/
├── fixtures/
└── test_helper.rb
```

**CI에서 실행할 체크:**
1. `bin/rails test` — 전체 테스트
2. `bin/rails test:system` — 시스템 테스트
3. `bundle exec rubocop` — 코드 스타일
4. `bundle exec brakeman` — 보안 스캔

### 3.4 Docker & 개발 환경

**전략: 하이브리드 방식**
- **DB만 Docker**: `docker-compose.yml`에 PostgreSQL만 포함
- **앱은 로컬 실행**: `bin/dev` (Foreman 기반)으로 Rails 서버, Tailwind 워처, Solid Queue 워커를 실행
- **프로덕션 Dockerfile**: Rails 8 기본 제공 멀티스테이지 빌드 활용 (Thruster 포함)

**파일 구성:**

| 파일 | 용도 |
|---|---|
| `Dockerfile` | 프로덕션 배포용 (멀티스테이지 빌드, Thruster 포함) |
| `docker-compose.yml` | 로컬 개발 DB 전용 (PostgreSQL 17) |
| `.dockerignore` | 불필요 파일 제외 |
| `Procfile.dev` | bin/dev 프로세스 정의 |

**Procfile.dev:**
```
web: bin/rails server -p 3000
css: bin/rails tailwindcss:watch[always]
jobs: bin/jobs --mode=async
```

**변경 사유:**
- `tailwindcss:watch[always]`: foreman 환경에서 stdin이 닫혀도 watcher가 종료되지 않도록 보장
- `--mode=async`: Ruby 3.4 + pg precompiled gem + fork 모드 조합에서 발생하는 Segmentation fault 방지

### 3.5 CI/CD (GitHub Actions)

**워크플로우: `.github/workflows/ci.yml`**

```
트리거: push (main), pull_request

Steps:
1. Ruby 설정 (ruby/setup-ruby, bundler-cache: true)
2. 에셋 캐싱 (Tailwind CLI 빌드 결과, Propshaft 에셋 캐시)
3. DB 생성 + 마이그레이션 (서비스 컨테이너: postgres, 멀티 DB 포함)
4. RuboCop 린트
5. Brakeman 보안 스캔
6. Minitest 실행
7. 시스템 테스트 실행 (headless Chrome)
```

**캐싱 전략:**
| 대상 | 캐시 키 |
|---|---|
| Bundler gems | `Gemfile.lock` 해시 |
| Tailwind 빌드 | `app/assets/tailwind/**` 해시 |
| Propshaft 에셋 | `app/assets/**` 해시 |

### 3.6 환경 관리

| 방식 | 용도 |
|---|---|
| `credentials.yml.enc` | 시크릿 키, API 키 등 민감 정보 |
| `.env.example` | 필요한 환경변수 문서화 (커밋 포함) |
| `.env` | 로컬 환경변수 (커밋 제외) |

### 3.7 보안

- HTTPS 강제 (`force_ssl`, production)
- Content Security Policy 설정
- Rails 8 `rate_limit` 활용 (로그인, 회원가입, 비밀번호 리셋)
- 비밀번호 정책: 최소 8자 (커스텀 Validation으로 분리, 앱별 강화 가능)
- `credentials.yml.enc`로 시크릿 관리
- Brakeman 정기 스캔 (CI 포함)

---

## 4. 배포 전략

### 4.1 기본 배포 도구: Kamal 2

Rails 공식 배포 도구. Docker 기반 자체 서버 배포.

**보일러플레이트에 포함할 설정:**

| 파일 | 용도 |
|---|---|
| `config/deploy.yml` | Kamal 메인 설정 (서버, 이미지, 헬스체크, kamal-proxy 등) |
| `.kamal/secrets` | 환경변수 주입 스크립트 (DB URL, Rails Master Key 등) |
| `.kamal/hooks/` | 배포 전/후 훅 (마이그레이션 자동 실행 등) |

**헬스체크 연동:**
- Kamal 기본 헬스체크: `/up` (Rails 기본 liveness)
- `deploy.yml`의 `healthcheck` 섹션에 설정

**에러 페이지 연동:**
- `error_pages_path` 설정으로 `public/` 내 커스텀 에러 페이지(404, 422, 500)를 kamal-proxy가 직접 서빙
- `deploy.yml`에 주석 형태로 포함

**SSL 설정:**
- kamal-proxy 내장 Let's Encrypt 자동 SSL 발급 설정을 주석 형태로 포함
- 프로덕션 배포 시 주석 해제만으로 HTTPS 활성화

> **v3.0 대비 변경**: Kamal 2는 v1의 Traefik을 대체하는 자체 Rust 기반 kamal-proxy를 내장. SSL 종단, 무중단 배포 라우팅을 kamal-proxy가 처리하며, 별도 Traefik 설치가 불필요.

### 4.2 대안 배포 옵션

| 옵션 | 설명 |
|---|---|
| Render / Fly.io | PaaS 대안 (Dockerfile 활용) |
| AWS ECS | 엔터프라이즈 환경 |

---

## 5. 제공 형태

### 5.1 Rails Application Template

`template.rb` 파일로 제공하여 아래 한 줄로 전체 셋업을 완료한다.

```bash
rails new my_app -d postgresql -c tailwind -m path/to/template.rb
```

### 5.2 Template이 수행할 작업

1. Gemfile 수정 및 `bundle install`
2. `bin/rails generate authentication` 실행
3. 회원가입(Sign up) 컨트롤러/뷰/라우트 생성
4. User 모델에 role enum, 비밀번호 정책 Validation, 추가 목적 `generates_token_for` 추가
5. ViewComponent 설치 및 베이스 클래스 + 10종 컴포넌트 생성
6. 디렉토리 구조 생성 (`services/`, `policies/`, `components/` 등)
7. 공통 컨트롤러 생성 (`ApplicationController` 에러 핸들링, `Admin::BaseController`, `HealthController`)
8. Stimulus 컨트롤러 생성 (4종)
9. I18n 로케일 파일 생성
10. 커스텀 에러 페이지 생성 (`public/404.html`, `422.html`, `500.html`)
11. `database.yml` 멀티 DB 설정 (primary/cache/queue/cable)
12. 시드 데이터 구조 생성
13. Docker 파일 생성 (Dockerfile + docker-compose.yml DB 전용)
14. Procfile.dev 생성
15. GitHub Actions 워크플로우 생성 (캐싱 최적화 포함)
16. Kamal 2 배포 설정 생성 (`deploy.yml` + `.kamal/secrets` + `.kamal/hooks/` + SSL/error_pages 주석)
17. Pundit, Pagy, Lograge 초기 설정
18. rate_limit 설정 (SessionsController, RegistrationsController)
19. 초기 마이그레이션 실행 (멀티 DB 포함)
20. README.md 생성

### 5.3 README 포함 내용

- 프로젝트 소개 및 기술 스택
- 로컬 개발 환경 셋업 가이드 (`docker-compose up db` → `bin/setup` → `bin/dev`)
- ViewComponent 기반 UI 컴포넌트 사용법 및 예시
- 테스트 실행 방법
- Kamal 2 배포 가이드
- 디렉토리 구조 설명
- **선택적 기능 활성화 가이드:**
  - Active Record Encryption 활성화 (`bin/rails db:encryption:init` → credentials 주입 → 사용법)
  - rate_limit store 커스터마이징
  - 비밀번호 정책 강화
- **스케일 전환 가이드:**
  - Postgres-only → Redis 분리 시점 판단 기준 (Solid Cable/Queue/Cache 각각)
  - Solid Cable → Redis adapter 전환 절차
  - Solid Queue → Sidekiq/GoodJob 전환 절차
  - Solid Cache → Redis cache store 전환 절차
- **프론트엔드 확장 가이드:**
  - Import Maps → jsbundling-rails(esbuild) 전환 체크리스트 (TS 도입, 대형 라이브러리 번들링이 필요해질 때)
  - 전환 시 Procfile.dev / CI 워크플로우 변경 사항
- **Kamal 배포 체크리스트:**
  - kamal-proxy SSL 구성 시 확인 사항 (Let's Encrypt 챌린지용 80/443 포트, host 설정)
  - `proxy.ssl` 활성화 시 `forward_headers` 설정 필요 여부
  - healthcheck URL/포트 검증 (SSL 환경에서 `/up` 접근성 확인)

---

## 6. 범위 외 (Out of Scope)

- 특정 도메인 비즈니스 로직 (이커머스, CMS 등)
- 소셜 로그인 (OmniAuth) — 필요 시 별도 추가
- 결제 시스템
- 파일 업로드 상세 설정 (S3 등) — 기본 로컬 스토리지만 포함
- 모바일 앱 (Strada)
- 다국어 자동 전환 (I18n 구조만 제공, 로케일 전환 로직은 미포함)
- APM/에러 트래킹 서비스 연동 (Sentry, Datadog 등) — README에 가이드만 제공

---

## 부록 A. 전체 변경 이력 (v1 → v3.3)

| # | 항목 | v1 | v2 | v3 | v3.1 | v3.2 | v3.3 | 근거 |
|---|---|---|---|---|---|---|---|---|
| 1 | 토큰 방식 | `has_secure_token` | `generates_token_for` (password_reset 포함) | `generates_token_for` (추가 목적만) | 유지 | 유지 | 유지 | password_reset은 generator 기본 제공 |
| 2 | 에러 핸들링 | 500 포함 전역 rescue | 404, 403만 rescue | 유지 | 유지 | 유지 | 유지 | — |
| 3 | 개발 환경 Docker | app + postgres | postgres만, 앱은 bin/dev | 유지 | 유지 | 유지 | 유지 | — |
| 4 | CI 캐싱 | 미포함 | bundler-cache + 에셋 캐싱 | 유지 | 유지 | 유지 | 유지 | — |
| 5 | Kamal 2 설정 | deploy.yml만 | + secrets + SSL | + hooks + error_pages_path | Traefik → kamal-proxy 교정 | 유지 | 유지 | Kamal 2는 자체 kamal-proxy 내장 |
| 6 | UI 컴포넌트 | ERB partial | ViewComponent | 유지 | 유지 | 유지 | 유지 | — |
| 7 | 인증 범위 | "회원가입 포함" | 유지 (오류) | Generator/Boilerplate 범위 분리 | 유지 | 유지 | 유지 | 공식 문서상 generator는 회원가입 미제공 |
| 8 | rate_limit | store 전략 없음 | 유지 (누락) | cache store 의존성 명시 | 유지 | 유지 | 유지 | Solid Cache → DB-backed 연결 |
| 9 | DB 구성 | 단일 DB | "단일 DB" 표현 | 단일 서버 + 논리 DB 분리 | 유지 | + 스케일 참고 노트 | 유지 | Postgres-only 병목 리스크 명시 |
| 10 | 헬스체크 | /health만 | 유지 | /up (liveness) + /health (readiness) | 유지 | 유지 | 유지 | Rails 기본 /up과 역할 분리 |
| 11 | 비밀번호 정책 | 없음 | 없음 | 최소 8자 + 커스텀 Validation | 유지 | 유지 | 유지 | has_secure_password는 존재 여부만 검증 |
| 12 | AR Encryption | — | PRD 본문에 "활성화 준비" | README 선택적 가이드로 이동 | 유지 | 유지 | 유지 | 범용 보일러플레이트에 기본 활성화는 과도 |
| 13 | Kamal 프록시 | — | Traefik 언급 | Traefik 언급 유지 (오류) | kamal-proxy로 교정 | 유지 | 유지 | TSD 정합성 수정 |
| 14 | README 가이드 확충 | — | — | 선택적 가이드만 | 유지 | + 스케일 전환/jsbundling 전환/Kamal SSL 체크리스트 | 유지 | 중규모 이상 대응력 강화 |
| 15 | Ruby 버전 표기 | — | — | 3.3+ | 유지 | 유지 | 3.4+ (TSD 정합) | TSD 3.4.x와 통일 |
| 16 | 로컬 DB 버전 | — | — | PostgreSQL 16 | 유지 | 유지 | PostgreSQL 17 (TSD 정합) | TSD 17.x와 통일 |
