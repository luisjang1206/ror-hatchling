# ror-hatchling

![Ruby](https://img.shields.io/badge/Ruby-~>_3.4-CC342D?logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-~>_8.1-CC0000?logo=ruby-on-rails&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17.x-316192?logo=postgresql&logoColor=white)

**Rails 8 프로덕션 보일러플레이트를 단일 템플릿으로 제공**

`rails new` 명령어 한 줄로 인증, 인가, UI 컴포넌트, 백그라운드 잡, 배포 파이프라인이 포함된 프로덕션 레디 Rails 8 풀스택 애플리케이션을 생성합니다. "Built-in First" 철학을 따라 Rails 8 내장 기능을 최대한 활용하며, 외부 Gem 의존성을 4개로 제한합니다.

---

## 목차

- [빠른 시작](#빠른-시작)
- [주요 기능](#주요-기능)
  - [인증 & 인가](#인증--인가)
  - [UI 컴포넌트](#ui-컴포넌트)
  - [관리자 패널](#관리자-패널)
  - [Solid Stack](#solid-stack)
  - [배포 파이프라인](#배포-파이프라인)
  - [개발자 경험](#개발자-경험)
- [기술 스택](#기술-스택)
- [프록시 아키텍처](#프록시-아키텍처)
- [생성되는 디렉토리 구조](#생성되는-디렉토리-구조)
- [생성된 앱의 README 가이드](#생성된-앱의-readme-가이드)
- [템플릿 아키텍처](#템플릿-아키텍처)
- [템플릿 검증 방법](#템플릿-검증-방법)
- [스펙 문서](#스펙-문서)
- [범위 외 항목](#범위-외-항목)

---

## 빠른 시작

### 사전 요구사항

- Ruby 3.4.x (rbenv, asdf, 또는 mise로 관리)
- Rails 8.1.x
- Docker (PostgreSQL 17 실행용)

### 템플릿으로 앱 생성

```bash
# 이 저장소를 클론한 후, template.rb 경로를 지정합니다
git clone https://github.com/<org>/ror-hatchling.git
rails new my_app -d postgresql -c tailwind -m ror-hatchling/template.rb
```

### 생성 후 3단계 셋업

```bash
# 1단계: PostgreSQL 17 시작 (Docker로 DB만 실행)
docker-compose up db -d

# 2단계: 의존성 설치, DB 생성, 마이그레이션, 시드 데이터
bin/setup

# 3단계: 개발 서버 시작 (Foreman: Rails + Tailwind watcher + SolidQueue worker)
bin/dev
```

브라우저에서 `http://localhost:3000`으로 접속하면 생성된 앱을 확인할 수 있습니다.

---

## 주요 기능

### 인증 & 인가

| 항목 | 상세 |
|---|---|
| **인증** | Rails 8 `authentication` generator (로그인/로그아웃/세션/비밀번호 리셋) + 커스텀 회원가입 플로우 |
| **비밀번호** | `has_secure_password` (bcrypt), 최소 8자 정책 |
| **토큰** | `generates_token_for` API로 이메일 인증, 매직 링크 등 추가 목적 토큰 정의 가능 |
| **속도 제한** | Rails 8 내장 `rate_limit` (로그인, 회원가입, 비밀번호 리셋 엔드포인트에 적용, SolidCache 백엔드) |
| **인가** | Pundit policy 기반, User 역할 enum (user/admin/super_admin) |

### UI 컴포넌트

ViewComponent 기반 10종 재사용 가능한 UI 컴포넌트 제공. 외부 UI 라이브러리(DaisyUI, shadcn) 없이 순수 Tailwind CSS + ViewComponent로 구현.

| # | 컴포넌트 | 설명 | Variants |
|---|---|---|---|
| 1 | **ButtonComponent** | 버튼, 링크 버튼 | primary, secondary, danger |
| 2 | **CardComponent** | 콘텐츠 컨테이너 (title/body/footer slots) | default, bordered |
| 3 | **BadgeComponent** | 상태 표시 태그 | info, success, warning, error |
| 4 | **FlashComponent** | 알림 메시지 (자동 닫기 Stimulus 연동) | notice, alert, error |
| 5 | **ModalComponent** | 확인/입력 대화상자 (trigger + body slots) | default |
| 6 | **DropdownComponent** | 메뉴, 선택지 (trigger + items slots) | default |
| 7 | **FormFieldComponent** | 라벨 + 인풋 + 에러 묶음 | text, email, password, select, textarea |
| 8 | **EmptyStateComponent** | 데이터 없을 때 안내 (icon + action slots) | default |
| 9 | **PaginationComponent** | Pagy 연동 페이지네이션 (1페이지 이하 시 자동 숨김) | default |
| 10 | **NavbarComponent** | 반응형 네비게이션 바 (햄버거 메뉴 Stimulus 연동) | default |

### 관리자 패널

- **네임스페이스**: `Admin::` 컨트롤러 (`/admin/*` 경로)
- **접근 제어**: Pundit role 기반 (admin, super_admin 역할 필요)
- **레이아웃**: 별도 관리자 레이아웃 (`layouts/admin.html.erb`)
- **기본 기능**: 대시보드, 사용자 목록 조회
- **외부 Gem 미사용**: 직접 구축 (ActiveAdmin, Administrate 등 불사용)

### Solid Stack

Redis 없이 PostgreSQL 기반으로 백그라운드 잡, 캐시, WebSocket 운영. 단일 PostgreSQL 서버에서 4개 논리 DB 분리.

| 컴포넌트 | 역할 | 논리 DB | 마이그레이션 경로 |
|---|---|---|---|
| **SolidQueue** | 백그라운드 잡 (Active Job) | `queue` | `db/queue_migrate/` |
| **SolidCache** | 캐시 스토어 (rate_limit 백엔드) | `cache` | `db/cache_migrate/` |
| **SolidCable** | WebSocket (Action Cable) | `cable` | `db/cable_migrate/` |
| **Primary DB** | 앱 데이터 (User, Session 등) | `primary` | `db/migrate/` |

### 배포 파이프라인

| 영역 | 상세 |
|---|---|
| **배포 도구** | Kamal 2 (~> 2.10), kamal-proxy (Rust 기반, Traefik 대체) |
| **컨테이너** | Docker 멀티스테이지 빌드 (`ruby:3.4-slim` 베이스) |
| **CI/CD** | GitHub Actions 7단계 파이프라인 (Ruby 셋업, 에셋 캐싱, DB, 린트, 보안 스캔, 단위 테스트, 시스템 테스트) |
| **서버 역할** | `web` (Thruster + Puma), `job` (SolidQueue worker) |
| **헬스체크** | `/up` (liveness, Rails 내장), `/health` (readiness, 커스텀 DB 체크) |
| **SSL** | Let's Encrypt 자동 갱신 (kamal-proxy, 설정 파일에 주석 처리 상태로 제공) |

### 개발자 경험

- **Hybrid Docker**: PostgreSQL만 Docker 실행, Rails 앱은 네이티브 실행 (`bin/dev`)
- **Procfile.dev**: Foreman으로 3개 프로세스 병렬 실행 (web, css with `[always]`, jobs in async mode)
- **테스트**: Minitest (단위/통합) + Capybara (시스템, headless Chrome)
- **코드 품질**: rubocop-rails-omakase (Rails 공식 스타일 가이드) + Brakeman (보안 스캔)
- **제로 빌드 JS**: Import Maps + Propshaft (Node.js 불필요)
- **Tailwind CSS v4**: standalone Rust CLI (CSS-first config, `@theme` 디렉티브)

---

## 기술 스택

### 전체 버전 핀 (TSD-v1.3 기준)

| 레이어 | 선택 | 버전 |
|---|---|---|
| **Ruby** | MRI | ~> 3.4 |
| **Rails** | Full-stack | ~> 8.1 |
| **데이터베이스** | PostgreSQL | 17.x (지원 ~2029-11) |
| **프론트엔드** | Hotwire (Turbo + Stimulus) | turbo-rails ~> 2.0, stimulus-rails ~> 1.3 |
| **CSS** | Tailwind CSS v4 (standalone CLI) | tailwindcss-rails ~> 4.2 |
| **에셋 파이프라인** | Propshaft + Import Maps | propshaft ~> 1.1, importmap-rails ~> 2.1 |
| **백그라운드 잡** | SolidQueue | ~> 1.3 |
| **캐시** | SolidCache | ~> 1.0 |
| **WebSocket** | SolidCable | ~> 3.0 |
| **인증** | bcrypt (has_secure_password) | ~> 3.1 |
| **배포** | Kamal 2 | ~> 2.10 |
| **웹 서버** | Puma (뒤에 Thruster) | puma ~> 6.5, thruster ~> 0.1 |

### 외부 Gems (4개 제한)

| Gem | 버전 | 역할 | 채택 근거 |
|---|---|---|---|
| **pundit** | ~> 2.5 | 인가 (Policy 기반) | 내장 대안 없음, 경량, 관례 기반 |
| **pagy** | ~> 43.0 | 페이지네이션 | 내장 대안 없음, 최고 성능, 최소 메모리 |
| **lograge** | ~> 0.14 | 구조화 로깅 (JSON) | 프로덕션 운영 필수, Rails 기본 로깅 불충분 |
| **view_component** | ~> 4.4 | UI 컴포넌트 | GitHub 공식, 타입 안전 파라미터, 단위 테스트 |

> Pagy는 SemVer가 아닌 독자적 버전 체계를 사용하므로 43.x가 정상 버전입니다.

---

## 프록시 아키텍처

```
[인터넷] → [kamal-proxy] → [Thruster] → [Puma]
             ↓                ↓             ↓
             SSL 종단         압축          Ruby 앱 서버
             HTTP/2           에셋 캐싱     (워커/스레드)
             무중단 라우팅    X-Sendfile
             에러 페이지
             Let's Encrypt
```

### 각 레이어 역할

| 레이어 | 위치 | 역할 |
|---|---|---|
| **kamal-proxy** | 호스트 레벨 | SSL 종단 (Let's Encrypt 자동 갱신), HTTP/2, 블루-그린 배포 라우팅, 에러 페이지 서빙 |
| **Thruster** | 컨테이너 내부 | gzip 압축, 에셋 캐싱, X-Sendfile 처리 (HTTP/2 자체 지원하나 kamal-proxy 뒤에서는 압축/캐싱이 주 역할) |
| **Puma** | 컨테이너 내부 | Rails 애플리케이션 서버 (멀티 워커 + 멀티 스레드) |

---

## 생성되는 디렉토리 구조

```
my_app/
├── app/
│   ├── components/              # ViewComponent (10종 + ApplicationComponent)
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
│   │   ├── admin/               # Admin 네임스페이스 (Pundit role 체크)
│   │   ├── concerns/
│   │   │   └── authentication.rb       # Rails 8 auth generator
│   │   ├── application_controller.rb
│   │   ├── health_controller.rb        # 헬스체크 (/health)
│   │   ├── registrations_controller.rb # 커스텀 회원가입
│   │   ├── sessions_controller.rb      # Rails 8 auth generator
│   │   └── passwords_controller.rb     # Rails 8 auth generator
│   ├── javascript/
│   │   └── controllers/         # Stimulus 컨트롤러 (4종)
│   │       ├── flash_controller.js
│   │       ├── modal_controller.js
│   │       ├── dropdown_controller.js
│   │       └── navbar_controller.js
│   ├── models/
│   │   ├── current.rb
│   │   └── user.rb              # role enum, password validation
│   ├── policies/                # Pundit 정책
│   │   ├── application_policy.rb
│   │   └── admin/
│   └── views/
│       ├── layouts/
│       │   ├── application.html.erb
│       │   └── admin.html.erb
│       └── components/          # ViewComponent ERB 템플릿
├── config/
│   ├── database.yml             # 멀티 DB (primary/cache/queue/cable)
│   ├── deploy.yml               # Kamal 2 배포 설정
│   ├── initializers/
│   │   ├── pagy.rb
│   │   ├── pundit.rb
│   │   └── lograge.rb
│   └── locales/
│       ├── defaults/            # 일반 UI 번역 (ko.yml, en.yml)
│       └── models/              # 모델 속성 번역
├── db/
│   ├── migrate/                 # Primary DB 마이그레이션
│   ├── cache_migrate/           # SolidCache 스키마
│   ├── queue_migrate/           # SolidQueue 스키마
│   ├── cable_migrate/           # SolidCable 스키마
│   └── seeds/
│       ├── admin_user.rb
│       └── sample_data.rb
├── test/
│   ├── components/              # ViewComponent 테스트
│   ├── integration/
│   ├── models/
│   ├── policies/                # Pundit policy 테스트
│   └── system/                  # Capybara E2E 테스트
├── .github/
│   └── workflows/
│       └── ci.yml               # 7단계 CI 파이프라인
├── .kamal/
│   ├── secrets                  # 런타임 시크릿 (gitignored)
│   ├── secrets.example          # 시크릿 템플릿 (커밋됨)
│   └── hooks/
│       └── pre-deploy           # Git 깨끗한 상태 체크
├── Procfile.dev                 # Foreman: web + css + jobs
└── docker-compose.yml           # PostgreSQL 17만 실행
```

---

## 생성된 앱의 README 가이드

템플릿이 생성하는 앱에는 상세 사용 가이드가 포함된 README.md가 자동 생성됩니다. 10개 섹션(A-J)으로 구성되어 있으며, 각 섹션은 다음 내용을 다룹니다.

| 섹션 | 제목 | PRD 5.3 | 주요 내용 |
|---|---|---|---|
| **A** | 프로젝트 소개 & 기술 스택 | 1 | Built-in First 철학, 전체 기술 스택 테이블, 프록시 아키텍처 |
| **B** | 로컬 개발 환경 셋업 | 2 | 사전 요구사항, 3단계 셋업, 멀티 DB 구조, Hybrid Docker 설명 |
| **C** | UI 컴포넌트 (ViewComponent) | 3 | 10종 컴포넌트 사용법 및 ERB 예시 코드 |
| **D** | 테스트 | 4 | 단위/통합/시스템 테스트 실행, rubocop, brakeman |
| **E** | 배포 (Kamal 2) | 5 | 프록시 아키텍처, 설정 파일, 배포 명령어, SSL, 헬스체크 |
| **F** | 디렉토리 구조 | 6 | 전체 파일 트리 (주석 포함) |
| **G** | 선택적 기능 가이드 | 7 | Active Record Encryption, rate_limit store 커스터마이징, 비밀번호 정책 강화 |
| **H** | 스케일 가이드 | 8 | Solid Stack → Redis 전환 시점, 절차 (SolidQueue → Sidekiq/GoodJob, SolidCache → Redis, SolidCable → Redis) |
| **I** | 프론트엔드 확장 가이드 | 9 | Import Maps → jsbundling-rails(esbuild) 전환, Procfile.dev, CI 워크플로우 변경 |
| **J** | Kamal 배포 체크리스트 | 10 | SSL 구성 (Let's Encrypt), forward_headers 설정, 헬스체크 검증 |

> 상세 사용 가이드는 생성된 앱의 `README.md`를 참조하세요. 해당 파일은 개발 환경 셋업부터 프로덕션 배포, 스케일 전환까지 모든 과정을 단계별로 안내합니다.

---

## 템플릿 아키텍처

`template.rb`는 6개 Phase로 구성된 20개 Step을 순차 실행합니다.

| Phase | PRD Steps | 주요 작업 |
|---|---|---|
| **Phase 0: Pre-Flight** | — | 사전 요구사항 검증 (Ruby 3.4+, Rails 8.1+, Docker) |
| **Phase 1: Foundation** | 1, 6, 11, 14 | Gemfile 수정, 디렉토리 생성, 멀티 DB 설정, Procfile.dev |
| **Phase 2: Authentication & User Model** | 2, 3, 4, 18 | `rails generate authentication`, 회원가입 플로우, User role enum, rate_limit |
| **Phase 3: UI Components, Error Handling & I18n** | 5, 7(에러/헬스), 8, 9, 10 | ViewComponent 10종 + Stimulus 4종, 에러 핸들링 (404/403), I18n 기본 로케일 ko |
| **Phase 4: Authorization, Admin & Seed Data** | 7(admin), 12, 17 | Pundit 설정, Admin 네임스페이스, 시드 데이터 |
| **Phase 5: Infrastructure, CI/CD & Deployment** | 13, 15, 16, 19 | Docker, GitHub Actions CI (7단계), Kamal 2 deploy.yml, 마이그레이션 실행 |
| **Phase 6: Documentation & Integration** | 20 | README.md 생성 (Sections A-J) |

### Step 상세 매핑

<details>
<summary>PRD 5.2 전체 20개 Step 매핑 펼쳐보기</summary>

| PRD Step | Phase | 작업 |
|---|---|---|
| 1 | 1 | Gemfile 수정 (`pundit`, `pagy`, `lograge`, `view_component` 추가) + `bundle install` |
| 2 | 2 | `bin/rails generate authentication` 실행 |
| 3 | 2 | 회원가입 컨트롤러/뷰/라우트 추가 (`RegistrationsController`) |
| 4 | 2 | User 모델 확장 (role enum, password validation, `generates_token_for`) |
| 5 | 3 | ViewComponent 설치 + 10종 컴포넌트 생성 |
| 6 | 1 | 디렉토리 구조 생성 (`app/components/`, `app/policies/`, `db/seeds/` 등) |
| 7 | 3/4 | 공통 컨트롤러 (ApplicationController 에러 핸들링, Admin::BaseController, HealthController) |
| 8 | 3 | Stimulus 컨트롤러 4종 생성 (flash, modal, dropdown, navbar) |
| 9 | 3 | I18n 로케일 파일 생성 (ko/en, defaults/ + models/) |
| 10 | 3 | 커스텀 에러 페이지 (404, 422, 500) |
| 11 | 1 | `database.yml` 멀티 DB 설정 (primary/cache/queue/cable) |
| 12 | 4 | 시드 데이터 (`db/seeds.rb` → `admin_user.rb` + `sample_data.rb`) |
| 13 | 5 | Docker 파일 생성 (Dockerfile 멀티스테이지 + docker-compose.yml) |
| 14 | 1 | `Procfile.dev` 생성 (web, css, jobs 프로세스) |
| 15 | 5 | GitHub Actions CI 워크플로우 (7단계 파이프라인) |
| 16 | 5 | Kamal 2 배포 설정 (`config/deploy.yml`, `.kamal/secrets`, hooks) |
| 17 | 4 | Pundit, Pagy, Lograge 초기 설정 (이니셜라이저 3종) |
| 18 | 2 | rate_limit 설정 (SessionsController, RegistrationsController, PasswordsController) |
| 19 | 5 | 초기 마이그레이션 실행 (`rails db:prepare` + Solid Stack 마이그레이션) |
| 20 | 6 | README.md 생성 (Sections A-J, 전체 가이드) |

</details>

---

## 템플릿 검증 방법

클린 환경에서 템플릿을 실행하여 전체 20단계가 정상 완료되는지 확인합니다.

```bash
# 1. 템플릿으로 앱 생성
rails new test_app -d postgresql -c tailwind -m path/to/template.rb

# 2. 생성된 앱 디렉토리로 이동
cd test_app

# 3. PostgreSQL 시작 (Docker)
docker-compose up db -d

# 4. 의존성 설치 + DB 생성 + 마이그레이션 + 시드 (프롬프트로 복귀)
bin/setup

# 5. 단위/통합 테스트
bin/rails test

# 6. 시스템 테스트 (Capybara + headless Chrome)
bin/rails test:system

# 7. 린트 (rubocop-rails-omakase)
bundle exec rubocop

# 8. 보안 스캔 (Brakeman)
bundle exec brakeman
```

### 검증 체크리스트

- [ ] 전체 20단계 에러 없이 완료
- [ ] `bin/setup` 성공 (4개 DB 생성, 마이그레이션, 시드)
- [ ] `bin/dev` 실행 시 3개 프로세스 정상 기동 (web, css, jobs)
- [ ] `bin/rails test` 전체 통과 (실패 0건)
- [ ] `bin/rails test:system` 전체 통과 (실패 0건)
- [ ] `bundle exec rubocop` 위반 0건
- [ ] `bundle exec brakeman` 보안 이슈 0건 (또는 허용 범위)
- [ ] 외부 Gem 4개 제한 준수 확인 (`pundit`, `pagy`, `lograge`, `view_component`)
- [ ] 한국어 기본 로케일 동작 확인 (UI 텍스트 한글 표시)
- [ ] ViewComponent 10종 렌더링 확인
- [ ] Admin 페이지 접근 제어 확인 (admin 역할 필요)
- [ ] rate_limit 동작 확인 (로그인/회원가입 시도 제한)
- [ ] 멱등성 확인: 동일 템플릿을 두 번 실행해도 동일 결과

---

## 스펙 문서

프로젝트의 모든 요구사항, 기술 스택, 구현 로드맵은 아래 문서에 정의되어 있습니다.

| 문서 | 설명 |
|---|---|
| [docs/PRD-v3.3.md](docs/PRD-v3.3.md) | 제품 요구사항 정의서 (한국어). 기능 범위, 인증/인가, UI 컴포넌트, 관리자, Solid Stack, 배포, CI/CD 전체 요구사항 정의. |
| [docs/TSD-v1.3.md](docs/TSD-v1.3.md) | 기술 스택 문서 (한국어). 정확한 버전 핀, 호환성 매트릭스, 업그레이드 정책, Gemfile 전체. PRD와 충돌 시 TSD 버전 핀이 우선. |
| [docs/ROADMAP.md](docs/ROADMAP.md) | 구현 로드맵 (한국어). 6개 Phase / 20개 Step 상세 매핑, 작업 항목, 검증 방법, 예상 공수, 리스크. |
| [CLAUDE.md](CLAUDE.md) | AI 어시스턴트 가이드 (영어). 프록시 아키텍처, 아키텍처 결정사항, 개발 명령어, Git 프로토콜. |

---

## 범위 외 항목

다음 항목은 범용 보일러플레이트 범위를 벗어나므로 명시적으로 제외됩니다. 필요 시 생성된 앱에서 개별적으로 추가할 수 있습니다.

- 소셜 로그인 (OmniAuth)
- 결제 시스템 (Stripe, PayPal 등)
- S3 파일 업로드 (로컬 Active Storage만 포함)
- 모바일 앱 연동 (Strada)
- 자동 다국어 전환 (I18n 구조만 제공, locale 전환 로직 미포함)
- APM/에러 트래킹 통합 (Sentry, Datadog 등 — README에 가이드만 제공)
- 도메인 특화 비즈니스 로직 (전자상거래, CMS, 예약 시스템 등)

---

**Built-in First.** Rails 8의 힘을 최대한 활용하세요.
