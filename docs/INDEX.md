# docs/ 문서 인덱스

> **프로젝트**: ROR-Hatchling — Rails 8 풀스택 범용 보일러플레이트
> **현재 단계**: 사양/문서 작성 (코드 미구현)

---

## 문서 목록

| 문서 | 버전 | 최종 수정 | 설명 |
|---|---|---|---|
| [PRD-v3.3.md](PRD-v3.3.md) | v3.3 | 2026-02-21 | Product Requirements Document — 기능·비기능 요구사항 정의 |
| [TSD-v1.3.md](TSD-v1.3.md) | v1.3 | 2026-02-21 | Technical Stack Document — 기술 스택 버전·호환성·업그레이드 정책 |
| [ROADMAP.md](ROADMAP.md) | v1.0 | 2026-02-21 | Implementation Roadmap — template.rb 구현 로드맵 (7 Phase, 20 Steps 매핑) |
| [phase0-verification.md](phase0-verification.md) | v1.0 | 2026-02-22 | Phase 0 Pre-Flight 검증 결과 — 8개 항목 기술 조사 통합 |

> **충돌 시 우선순위**: PRD와 TSD가 충돌할 경우, TSD의 버전 핀이 우선한다 (교차 검증 완료).

---

## PRD-v3.3 — 제품 요구사항 문서

`rails new my_app -d postgresql -c tailwind -m path/to/template.rb` 한 줄로 셋업되는 프로덕션 레디 보일러플레이트의 전체 요구사항을 정의한다.

### 주요 섹션

| # | 섹션 | 핵심 내용 |
|---|---|---|
| 1 | 개요 | 프로젝트 목적, 타겟 사용자, 핵심 원칙(내장 우선·풀스택·범용성·즉시 실행) |
| 2 | 기능 요구사항 | 인증, 인가, 프론트엔드, 관리자, 인프라, Rate Limiting, I18n, 에러 처리, 헬스체크, 시드 데이터 |
| 3 | 비기능 요구사항 | 프로젝트 구조, Gem 의존성, 테스트 전략, Docker/개발환경, CI/CD, 환경관리, 보안 |
| 4 | 배포 전략 | Kamal 2 설정(deploy.yml, secrets, hooks, SSL, error_pages), 대안 배포 옵션 |
| 5 | 제공 형태 | template.rb 20단계 작업 목록, README 포함 내용 |
| 6 | 범위 외 | 소셜 로그인, 결제, S3, 모바일, APM 등 명시적 제외 항목 |

### 기능 요구사항 요약

- **인증**: Rails 8 authentication generator + 커스텀 회원가입, bcrypt, rate_limit, generates_token_for
- **인가**: Pundit, User role enum (user/admin/super_admin)
- **프론트엔드**: Hotwire(Turbo+Stimulus), Tailwind v4, ViewComponent 10종, Stimulus 컨트롤러 4종
- **관리자**: Admin:: 네임스페이스, /admin/*, Pundit 역할 체크, 별도 레이아웃
- **인프라**: Solid Stack(Queue/Cache/Cable), 단일 PostgreSQL 서버 + 논리 DB 4개 분리
- **I18n**: 기본 로케일 ko, defaults/ + models/ 하위 디렉토리 구조
- **에러 처리**: RecordNotFound(404) + NotAuthorizedError(403)만 rescue, 500은 미들웨어 위임
- **헬스체크**: /up (liveness, Rails 내장) + /health (readiness, 커스텀)

---

## TSD-v1.3 — 기술 스택 문서

모든 기술 선택의 정확한 버전, 호환성, 업그레이드 정책을 정의한다.

### 주요 섹션

| # | 섹션 | 핵심 내용 |
|---|---|---|
| 1 | 버전 선택 원칙 | 안정 우선, 호환성 검증, LTS 고려, 최소 외부 의존성 |
| 2 | Core Runtime | Ruby 3.4.8, Rails 8.1.2, PostgreSQL 17.8 |
| 3 | Frontend | Hotwire, Tailwind CSS 4.x(CSS-first), Propshaft + Import Maps |
| 4 | Gem 의존성 상세 | 내장/공식 13종 + 외부 4종 + Dev/Test 5종, 전체 Gemfile |
| 5 | 배포 & 인프라 | Kamal 2.10.1, 프록시 아키텍처, Docker 멀티스테이지, CI 7단계 파이프라인 |
| 6 | 테스트 | Minitest, Capybara, Selenium, Fixtures |
| 7 | 호환성 매트릭스 | Ruby × Rails × PostgreSQL × Tailwind 조합별 상태 |
| 8 | 업그레이드 정책 | 패치/마이너/메이저별 적용 주기 및 절차 |

### 핵심 버전 핀

| 항목 | 버전 | Gemfile 제약 |
|---|---|---|
| Ruby | 3.4.8 | `~> 3.4` |
| Rails | 8.1.2 | `~> 8.1` |
| PostgreSQL | 17.8 | — |
| Tailwind CSS | 4.x | `tailwindcss-rails ~> 4.2` |
| Kamal | 2.10.1 | `~> 2.10` |

### 프록시 아키텍처

```
[Internet] → [kamal-proxy] → [Thruster] → [Puma]
               SSL/HTTP2       압축/캐싱     Rails 앱
               라우팅          X-Sendfile
               에러 페이지
```

---

## 문서 간 관계

```
PRD-v3.3 (무엇을 만들 것인가)
  │
  ├─ 기능/비기능 요구사항 정의
  ├─ template.rb 20단계 작업 명세
  └─ 프로젝트 구조, 테스트 전략, CI/CD 파이프라인
        │
        ▼
TSD-v1.3 (어떤 기술로 만들 것인가)
  │
  ├─ 정확한 버전 핀 (PRD보다 우선)
  ├─ 호환성 매트릭스
  └─ 업그레이드 정책
        │
        ▼
ROADMAP-v1.0 (어떤 순서로 만들 것인가)
  │
  ├─ 7 Phase 구현 계획 (Phase 0-6)
  ├─ PRD 20단계 → Phase 매핑
  ├─ 의존성 그래프 및 Critical Path
  └─ 공수 추정, 리스크 레지스터
        │
        ▼
Phase 0 Verification (기술 조사 결과)
  │
  ├─ 8개 항목별 조사 완료 상태
  ├─ 핵심 발견 사항 및 구현 주의점
  └─ 리스크 레지스터 업데이트 (R1 해소, R7/R8 신규)
```

---

## ROADMAP-v1.0 — 구현 로드맵

template.rb 구현을 7개 Phase로 분할하고, PRD 5.2의 20단계를 빠짐없이 매핑한다.

### Phase 구성

| Phase | 이름 | Template Steps | 예상 공수 |
|-------|------|---------------|----------|
| 0 | Pre-Flight 검증 | — | 10.4h |
| 1 | Foundation | 1, 6, 11, 14 | 11.7h |
| 2 | Authentication & User Model | 2, 3, 4, 18 | 18.2h |
| 3 | UI Components, Error Handling & I18n | 5, 7(일부), 8, 9, 10 | 42.9h |
| 4 | Authorization, Admin & Seed Data | 7(admin), 12, 17 | 27.3h |
| 5 | Infrastructure, CI/CD & Deployment | 13, 15, 16, 19 | 29.9h |
| 6 | Documentation & Integration | 20 | 20.8h |
| **총계** | | **20단계 전체** | **161.2h (약 28일)** |

### Critical Path

```
Step 1 → Step 2 → Step 4 → Step 17 → Step 7(admin) → Step 12 → Step 19 → Step 20
(Gemfile → Auth → User확장 → Pundit → Admin → Seed → Migration → README)
```

---

## 변경 이력 추적

### PRD 변경 흐름
v1 → v2 (피드백 6건) → v3 (공식 문서 재평가 8건) → v3.1 (TSD 정합성) → v3.2 (스케일 참고·README 확충) → **v3.3** (TSD 교차검증: Ruby 3.4+, PostgreSQL 17)

### TSD 변경 흐름
v1.0 (초안) → v1.1 (피드백 4건) → v1.2 (부록 정리) → **v1.3** (교차검증 4건: PostgreSQL 지원기간, Thruster 역할, Ruby 4.0, Gem 버전 최신화)
