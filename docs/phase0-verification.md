# Phase 0: Pre-Flight 검증 결과

> **프로젝트**: ROR-Hatchling — Rails 8 풀스택 범용 보일러플레이트
> **작성일**: 2026-02-22
> **상태**: **완료** — Phase 0 전체 검증 완료. Phase 1 시작 준비 완료.
> **참조**: [ROADMAP.md](ROADMAP.md) Phase 0, [PRD-v3.3.md](PRD-v3.3.md), [TSD-v1.3.md](TSD-v1.3.md)

---

## 개요

template.rb 구현 전 기술적 불확실성을 해소하기 위한 Pre-Flight 검증 단계다.
6개 tech-librarian 에이전트를 통해 이론적 조사를 완료했으며, 실행 검증(프로토타입)은 Task 2~4에서 수행한다.

### 조사 소스 목록

| # | 조사 파일 | 대상 |
|---|---|---|
| 1 | `template-api-research.md` | Rails Template API |
| 2 | `authentication-generator-detailed.md` | Rails 8.1 Auth Generator |
| 3 | `solid-stack-install-research.md` | Solid Stack Install 명령 |
| 4 | `tailwind-v4-research.md` | Tailwind CSS v4 + tailwindcss-rails |
| 5 | `viewcomponent-44-research.md` | ViewComponent 4.4 |
| 6 | `kamal-2-init-research.md` | Kamal 2.10 |
| 7 | `multidb-research.md` | 멀티DB database.yml |

> 조사 파일 위치: `.claude/agent-memory/tech-librarian/`

---

## 0-1. Rails Template API 동작 확인

**조사 상태**: 완료 (이론)
**실행 검증**: Task 2에서 프로토타입 실행 예정

### 핵심 발견 사항

1. **실행 컨텍스트**: template.rb는 `Rails::Generators::AppGenerator`의 `instance_eval`로 실행됨. ERB 파일이 아님
2. **after_bundle 필수**: gem 의존 generator는 반드시 `after_bundle` 블록 안에서 실행해야 함
3. **create_file 자동 디렉토리 생성**: 부모 디렉토리가 없어도 자동 생성
4. **heredoc 처리**: `<<~RUBY`(squiggly heredoc)는 String interpolation 실행됨. `<<~'RUBY'`(single-quote)는 실행 안 됨
5. **rails_command vs generate**: `rails_command`는 `bin/rails <cmd>` 실행, `generate`는 제너레이터 호출. 둘 다 `after_bundle` 내에서 안전

### 메서드 요약

| 메서드 | 용도 | 사용 시점 |
|---|---|---|
| `create_file(path, content)` | 파일 생성 (부모 디렉토리 자동) | 언제든 |
| `gsub_file(path, pattern, replacement)` | 정규식 기반 찾기-바꾸기 | 파일 존재 시 |
| `inject_into_file(path, content, after:/before:)` | 특정 위치에 코드 주입 | 파일 존재 시 |
| `remove_file(path)` | 파일 삭제 | 언제든 |
| `generate(name, args)` | 제너레이터 호출 | after_bundle 내 |
| `rails_command(cmd)` | Rails 태스크 실행 | after_bundle 내 |
| `gem(name, version)` | Gemfile에 gem 추가 | bundle 전 |
| `route(code)` | routes.rb에 라우트 추가 | 언제든 |
| `environment(code, env:)` | 환경 설정 추가 | 언제든 |

### 구현 시 주의점

- `gsub_file` 정규식은 첫 번째 매치만 교체 (루프 필요 시 별도 처리)
- `inject_into_file`의 `after:` / `before:` 대상 문자열이 정확해야 함 — 실행 검증에서 확정 필요
- `force: true` 옵션으로 기존 파일 덮어쓰기 가능

### 체크리스트

- [x] 핵심 메서드 시그니처 확인 (`create_file`, `gsub_file`, `inject_into_file`, `remove_file`)
- [x] `after_bundle` 블록 내 generator 실행 가능 확인
- [x] `rails_command` vs `rake` vs `generate` 차이 확인
- [x] 최소 template.rb 작성 후 `rails new test_app -m template.rb` 실행 검증 → Task 2 완료 (9/10 통과)

---

## 0-2. Rails 8.1 Authentication Generator 출력 확인

**조사 상태**: 완료 (이론)
**실행 검증**: Task 3에서 실제 실행 예정

### 핵심 발견 사항

1. **생성 파일 20+개**: User/Session/Current 모델, SessionsController, PasswordsController, Authentication concern, Mailer, Views, Migrations
2. **rate_limit 이미 포함**: SessionsController에 `rate_limit to: 10, within: 3.minutes, only: :create` 포함
3. **Registration 미포함**: 회원가입(sign-up) 컨트롤러/뷰는 별도 구현 필요
4. **User 컬럼**: `email_address`, `password_digest` (username 아님, email 아님)
5. **Session 컬럼**: `user_id`, `ip_address`, `user_agent`, `token`
6. **generates_token_for**: `has_secure_password(reset_token: true)` 숏핸드 또는 명시적 정의 가능

### 생성 파일 목록

```
Models:       app/models/user.rb, session.rb, current.rb
Controllers:  app/controllers/sessions_controller.rb, passwords_controller.rb
Concerns:     app/controllers/concerns/authentication.rb
Mailers:      app/mailers/passwords_mailer.rb
Views:        app/views/sessions/new.html.erb
              app/views/passwords/new.html.erb, edit.html.erb
              app/views/passwords_mailer/reset.html.erb, reset.text.erb
Tests:        test/mailers/previews/passwords_mailer_preview.rb
Migrations:   db/migrate/*_create_users.rb, *_create_sessions.rb
Modified:     Gemfile (bcrypt), application_controller.rb, routes.rb
```

### inject_into_file 타겟 후보 (Task 3에서 확정)

| 대상 파일 | 주입 내용 | 예상 타겟 문자열 |
|---|---|---|
| `app/models/user.rb` | role enum, password validation | `has_secure_password` 다음 줄 |
| `app/models/user.rb` | `generates_token_for` | `has_secure_password` 다음 줄 |
| `app/controllers/sessions_controller.rb` | `reset_session` 추가 | `start_new_session_for` 앞 |
| `config/routes.rb` | 회원가입 라우트 | `resource :session` 아래 |

### 체크리스트

- [x] 생성 파일 목록 문서화 (이론 + 실증)
- [x] User/Session 모델 컬럼 구조 파악
- [x] Authentication concern 메서드 시그니처 확인
- [x] rate_limit 포함 여부 확인 — Sessions **및** Passwords 모두 포함 (to:10, within:3.minutes)
- [x] 실제 `rails generate authentication` 실행 후 파일 캡처 완료 → `docs/generator-outputs/authentication-output.md`
- [x] inject_into_file 타겟 문자열 4개 확정 (User model, routes, migration, ApplicationController)

---

## 0-3. Solid Stack Install 명령 출력 확인

**조사 상태**: 완료 (이론 + 실행 검증)
**실행 검증**: 완료 → `docs/generator-outputs/solid-stack-output.md`

### 핵심 발견 사항

1. **database.yml 미수정 (R1 리스크 해소)**: 3개 install 명령 모두 `config/database.yml`을 수정하지 않음
2. **schema 파일 사용**: timestamped migration이 아닌 `db/queue_schema.rb`, `db/cache_schema.rb`, `db/cable_schema.rb` 생성
3. **설치 순서 독립**: 3개 generator 간 의존성 없음. 어떤 순서로든 실행 가능
4. **cable.yml force:true (R7 신규 리스크)**: `solid_cable:install`은 `config/cable.yml`을 `force: true`로 생성. 기존 파일 무경고 덮어씀
5. **production.rb만 수정**: `solid_queue:install`은 `config/environments/production.rb`에 `config.active_job.queue_adapter` + `config.solid_queue.connects_to` 추가

### 각 install 명령 출력

| 명령 | 생성 파일 | 수정 파일 |
|---|---|---|
| `solid_queue:install` | `config/queue.yml`, `config/recurring.yml`, `db/queue_schema.rb`, `bin/jobs` | `config/environments/production.rb` |
| `solid_cache:install` | `config/cache.yml`, `db/cache_schema.rb` | `config/environments/production.rb` |
| `solid_cable:install` | `config/cable.yml` (force:true), `db/cable_schema.rb` | 없음 |

### production.rb에 추가되는 설정

```ruby
# solid_queue:install이 추가
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }

# solid_cache:install이 추가
config.cache_store = :solid_cache_store
```

### template.rb 구현 전략

1. **database.yml을 먼저 생성** (install이 수정하지 않으므로 안전)
2. **3개 install 명령 실행** (순서 무관)
3. **cable.yml 주의**: solid_cable:install이 force:true로 덮어쓰므로, 커스텀 설정은 install 후에 적용
4. **development.rb에도 설정 필요**: install은 production.rb만 수정하므로, development.rb 설정은 template.rb에서 직접 추가

### 체크리스트

- [x] 3개 install 명령의 생성 파일 목록 확인
- [x] database.yml 미수정 확인 (소스코드 레벨 검증)
- [x] 멀티DB 설정과의 충돌 여부 확인 → 충돌 없음
- [x] 설치 순서 의존성 확인 → 없음 (독립)
- [x] schema 파일 vs migration 차이 파악
- [x] test_app에서 3개 install 실제 실행 + 파일 캡처 → `docs/generator-outputs/solid-stack-output.md`
- [x] db:prepare로 4개 DB + schema 로드 검증 → 8개 DB 생성, 4환경 schema 정상 로드
- [x] Rails 8.1 `rails new`는 Solid Stack 자동 설치 (별도 generate 불필요)
- [x] `pool:` → `max_connections:` 키 이름 변경 확인 (Rails 8.1)
- [x] production만 멀티DB 자동 설정 → dev/test는 template.rb에서 직접 추가 필요

---

## 0-4. Tailwind CSS v4 + tailwindcss-rails 동작 확인

**조사 상태**: 완료 (이론)
**실행 검증**: Task 2에서 `rails new -c tailwind` 실행 시 자동 검증

### 핵심 발견 사항

1. **CSS-first 설정**: `tailwind.config.js` 불필요. `@import "tailwindcss"` + `@theme {}` 디렉티브로 모든 설정
2. **파일 구조**: 입력 `app/assets/tailwind/application.css` → 출력 `app/assets/builds/tailwind.css`
3. **자동 콘텐츠 감지**: `content: []` 배열 불필요. `.erb`, `.js` 등 자동 스캔. 필요 시 `@source` 디렉티브로 명시
4. **Standalone CLI**: Node.js 불필요. Rust 기반 바이너리가 gem을 통해 제공
5. **Propshaft 통합**: `config.assets.excluded_paths`에 `app/assets/tailwind` 추가 필요 (소스 파일 제외)

### 파일 구조

```
app/assets/
├── builds/
│   └── tailwind.css          # 컴파일 출력 (Propshaft 서빙)
└── tailwind/
    └── application.css       # 소스 입력 (@import "tailwindcss")
```

### CSS-first 설정 예시

```css
@import "tailwindcss";

@theme {
  --color-primary: #3b82f6;
  --color-secondary: #8b5cf6;
  --font-sans: "Inter", sans-serif;
}
```

### Procfile.dev 구성

```
web:  bin/rails server -p 3000
css:  bin/rails tailwindcss:watch
jobs: bin/rails solid_queue:start
```

### 체크리스트

- [x] `rails new -c tailwind` 시 기본 파일 구조 확인
- [x] `application.css` 초기 내용 (`@import "tailwindcss"`) 확인
- [x] `@theme` 디렉티브 문법 확인
- [x] Propshaft + Tailwind 통합 설정 확인
- [x] `bin/rails tailwindcss:watch` 정상 동작 확인 → Task 2에서 `rails new -c tailwind` 성공 (자동 설치)

---

## 0-5. ViewComponent 4.4 설치 및 Generator 확인

**조사 상태**: 완료 (이론)
**실행 검증**: Task 2에서 gem 설치 후 확인

### 핵심 발견 사항

1. **`--stimulus` 플래그 존재**: ViewComponent 2.38.0+ 에서 Stimulus 컨트롤러 동시 생성 지원
2. **Sidecar 기본 비활성**: `--sidecar` 플래그 또는 전역 설정으로 활성화 필요
3. **ApplicationComponent 자동 감지**: `ApplicationComponent` 클래스가 있으면 제너레이터가 자동으로 부모 클래스로 사용
4. **제너레이터 명령**: `bin/rails generate view_component:component ComponentName [props]`

### 권장 전역 설정 (config/application.rb)

```ruby
config.view_component.generate.sidecar = true
config.view_component.generate.stimulus_controller = true
config.view_component.parent_class = "ApplicationComponent"
```

### Sidecar 디렉토리 구조

```
app/components/
  button_component.rb
  button_component/
    button_component.html.erb
    button_component_controller.js    # --stimulus 시
```

### 체크리스트

- [x] `bin/rails generate view_component:component` 사용법 확인
- [x] Sidecar 패턴 기본 설정 확인 (비활성, 명시적 설정 필요)
- [x] `--stimulus` 플래그 존재 확인
- [x] ApplicationComponent 베이스 클래스 패턴 확인
- [x] 실제 컴포넌트 생성 테스트 → skeleton에 create_component 헬퍼 정의. Phase 3에서 실구현

---

## 0-6. Kamal 2 초기 설정 확인

**조사 상태**: 완료 (이론)
**실행 검증**: 해당 없음 (배포 설정은 파일 생성만, 서버 연결 불필요)

### 핵심 발견 사항

1. **kamal-proxy 사용 (Traefik 아님)**: Kamal 2는 Basecamp 제작 kamal-proxy를 기본 사용
2. **SSL 자동**: `proxy.ssl: true`로 Let's Encrypt 자동 발급 (단일 서버)
3. **secrets dotenv 형식**: `.kamal/secrets`는 KEY=VALUE 형식 (dotenv 라이브러리 사용)
4. **hooks 확장자 없음**: `.kamal/hooks/pre-deploy` (`.sh` 없음)
5. **환경변수 치환 지원**: `REGISTRY_PASSWORD=$REGISTRY_PASSWORD` (셸 환경변수 참조)

### kamal init 생성 파일

```
config/deploy.yml          # 메인 배포 설정
.kamal/secrets             # 시크릿 (gitignore 필수)
.kamal/hooks/              # 훅 디렉토리
```

### deploy.yml 핵심 구조

```yaml
service: app_name
image: app_name

servers:
  web:
    hosts:
      - 192.168.1.100
  job:
    hosts:
      - 192.168.1.100
    cmd: bundle exec solid_queue:start

registry:
  server: docker.io
  username: deploy
  password:
    - KAMAL_REGISTRY_PASSWORD

proxy:
  host: app.example.com
  app_port: 3000
  ssl: true
  healthcheck:
    path: /up
    interval: 3
    timeout: 3
```

### 사용 가능 hooks

| Hook | 실행 시점 |
|---|---|
| `pre-build` | Docker 빌드 전 |
| `post-build` | Docker 빌드 후 |
| `pre-deploy` | 배포 시작 전 |
| `post-deploy` | 배포 완료 후 |
| `pre-connect` | SSH 연결 전 |
| `post-connect` | SSH 연결 후 |

### 체크리스트

- [x] `kamal init` 생성 파일 확인
- [x] `deploy.yml` 기본 구조와 PRD 요구사항 대조
- [x] `.kamal/secrets` 파일 형식 확인 (dotenv)
- [x] hooks 디렉토리 구조 확인
- [x] kamal-proxy SSL 설정 방법 확인
- [x] 프록시 아키텍처 확인: kamal-proxy → Thruster → Puma

---

## 0-7. database.yml 멀티DB 설정 검증

**조사 상태**: 완료 (이론 + 실행 검증)
**실행 검증**: 완료 — 4개 DB × 2환경(dev/test) = 8개 DB 생성 및 schema 로드 성공

### 핵심 발견 사항

1. **YAML 앵커 패턴**: `&primary_dev` 앵커 + `<<: *primary_dev` 병합으로 DRY 유지
2. **migrations_paths 자동 인식**: `database.yml`에 명시하면 Rails가 자동으로 각 DB별 마이그레이션 디렉토리 사용
3. **db:prepare 4개 DB 처리**: `bin/rails db:prepare`가 모든 DB를 자동으로 create + migrate + seed
4. **db:create도 4개 모두**: `bin/rails db:create`도 현재 환경의 모든 DB 생성
5. **Primary는 migrations_paths 생략 가능**: 기본값 `db/migrate` 자동 사용

### 권장 database.yml 패턴

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>  # Rails 8.1: pool → max_connections

development:
  primary: &primary_dev
    <<: *default
    database: <%= app_name %>_development
  queue:
    <<: *primary_dev
    database: <%= app_name %>_development_queue
    migrations_paths: db/queue_migrate
  cache:
    <<: *primary_dev
    database: <%= app_name %>_development_cache
    migrations_paths: db/cache_migrate
  cable:
    <<: *primary_dev
    database: <%= app_name %>_development_cable
    migrations_paths: db/cable_migrate
```

### connects_to 연동 흐름

```
database.yml              config/environments/*.rb          config/cable.yml
├── queue: ──────────── → solid_queue.connects_to ────── → :queue
├── cache: ──────────── → cache_store :solid_cache_store → 자동 인식
└── cable: ──────────── → ──────────────────────────────── → adapter: solid_cable
```

### 체크리스트

- [x] 4개 논리 DB 설정 문법 확인 (YAML 앵커 + 별칭)
- [x] `migrations_paths` 설정으로 디렉토리 분리 확인
- [x] Solid Stack `connects_to` 연동 패턴 확인
- [x] 환경별(dev/test/prod) 설정 패턴 확인
- [x] `rails db:create`로 4개 DB 실제 생성 검증 → 8개 DB 생성 성공 (dev 4 + test 4)
- [x] `rails db:prepare`로 schema 로드 검증 → primary(3), queue(13), cache(3), cable(3) 테이블
- [x] `max_connections:` 키 이름 확인 (Rails 8.1, `pool:` 대체)

---

## 0-8. template.rb 파일 크기 및 구조 전략 수립

**조사 상태**: 완료 (분석)
**실행 검증**: Task 5에서 skeleton 작성

### 구조 전략

1. **예상 크기**: ~2,500줄 (20단계 × 평균 125줄)
2. **헬퍼 메서드 상단 정의**: template.rb 상단에 재사용 메서드 정의
3. **Phase별 섹션 구분**: 주석으로 Phase 경계 명시
4. **실행 순서**: bundle 전(gem 추가) → bundle 후(after_bundle 내 36단계)

### 헬퍼 메서드 후보

```ruby
# template.rb 상단에 정의
def say_phase(number, name)
  say "\n#{'=' * 60}", :cyan
  say "Phase #{number}: #{name}", :cyan
  say "#{'=' * 60}\n", :cyan
end

def create_component(name, ruby_content, erb_content, stimulus_content = nil)
  # ViewComponent 파일 3개 일괄 생성
end

def create_locale(path, content)
  # I18n 로케일 파일 생성
end
```

### 실행 순서 최적화 (의존성 기반)

```
[Bundle 전]
  1. Gemfile 수정 (gem 추가)

[after_bundle 내]
  Phase 1: Foundation
    2. database.yml 멀티DB 설정
    3. generate authentication
    4. Solid Stack install (3개)
    5. Tailwind 커스텀 설정

  Phase 2: Auth & User
    6. User 모델 확장 (role enum, validation)
    7. 회원가입 컨트롤러/뷰 생성
    8. rate_limit 추가 (Registrations, Passwords)

  Phase 3: UI & I18n
    9. ApplicationComponent 생성
    10. 10개 ViewComponent 생성
    11. Stimulus 컨트롤러 4개
    12. I18n 로케일 파일
    13. 에러 처리

  Phase 4: Authorization & Admin
    14. Pundit 설정
    15. Admin 네임스페이스
    16. Seed 데이터

  Phase 5: Infrastructure
    17. Kamal 배포 설정
    18. GitHub Actions CI
    19. Initializers (Lograge, Pagy)

  Phase 6: Documentation
    20. README 생성
```

### 에러 처리 전략

- **기본**: `abort_on_failure: false` (실패해도 계속 진행)
- **필수 단계만 abort**: `rails_command "db:prepare", abort_on_failure: true`
- **say_status로 진행 상황 출력**: 각 Phase/Step 시작/완료 알림

### 체크리스트

- [x] heredoc 기반 파일 생성 시 가독성 방안 결정 (squiggly heredoc + 헬퍼 메서드)
- [x] 헬퍼 메서드 정의 위치 결정 (template.rb 상단)
- [x] 20단계 실행 순서 최적화
- [x] 에러 처리 전략 결정 (계속 진행, 필수만 abort)
- [x] skeleton template.rb 실제 작성 → Task 5 완료 (812줄, 헬퍼 5개, Phase 1-6 구조)

---

## 리스크 레지스터 업데이트

### 해소된 리스크

| ID | 리스크 | 상태 | 근거 |
|---|---|---|---|
| R1 | Solid Stack install이 database.yml 덮어쓰기 | **해소** | 소스코드 확인: 3개 모두 database.yml 미수정 |

### 신규 리스크

| ID | 리스크 | 확률 | 영향 | 완화 전략 |
|---|---|---|---|---|
| R7 | solid_cable:install이 cable.yml을 force:true로 덮어씀 | 높음 | 중간 | cable.yml 커스텀 설정은 install 이후에 적용 |
| R8 | Schema 파일(queue_schema.rb 등) vs migration 혼동 | 중간 | 낮음 | 문서에 schema 파일 기반임을 명시 |

### 기존 리스크 (변경 없음)

| ID | 리스크 | 상태 |
|---|---|---|
| R2 | Tailwind v4 + Propshaft 호환성 | **해소** — `rails new -c tailwind` 정상 동작 확인 |
| R3 | Auth generator 출력 변동 | **해소** — 실제 출력 캡처 완료, inject 타겟 4개 확정 |
| R4 | ViewComponent + Stimulus + Import Maps 충돌 | 조사 완료, 실행 검증 대기 |
| R5 | template.rb 크기 제한 | 구조 전략 수립 완료 |
| R6 | heredoc 내 ERB 이스케이프 | heredoc 종류별 처리 방법 확인 |

---

## 다음 단계

| Task | 내용 | 의존성 | 상태 |
|---|---|---|---|
| Task 2 | 개발 환경 확인 + Template API 프로토타입 | 이 문서 | **완료** |
| Task 3 | Auth Generator 실행 + inject 타겟 확정 | Task 2 | **완료** |
| Task 4 | Solid Stack Install + 멀티DB 검증 | Task 2 | **완료** |
| Task 5 | template.rb skeleton 작성 | Task 3, 4 | 대기 |
| Task 6 | Phase 0 최종 검증 + ROADMAP 업데이트 | Task 1, 5 | 대기 |
