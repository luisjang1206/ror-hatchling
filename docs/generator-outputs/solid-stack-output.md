# Solid Stack Install 실제 출력 캡처 + 멀티DB 검증

> **실행 일자**: 2026-02-22
> **환경**: Ruby 3.4.8, Rails 8.1.2, PostgreSQL 17.8
> **명령어**: `rails new test_hatchling -d postgresql -c tailwind` (Solid Stack 자동 설치됨)

---

## 핵심 발견 사항

### 1. Rails 8.1은 `rails new`에서 Solid Stack을 자동 설치

Rails 8.1의 `rails new`는 `--skip-solid` 플래그가 없으면 자동으로:
```
rails solid_cache:install solid_queue:install solid_cable:install
```
을 실행한다. 별도로 `generate` 할 필요 없음.

### 2. database.yml은 production에만 멀티DB 자동 설정

`rails new` 생성 시 `config/database.yml`:
- **development**: 단일 DB (멀티DB 없음)
- **test**: 단일 DB (멀티DB 없음)
- **production**: primary + queue + cache + cable (4개, 자동)

**template.rb에서 해야 할 일**: development/test에도 멀티DB 설정을 추가해야 함.

### 3. max_connections (Rails 8.1 변경)

Rails 8.1에서 `pool:` → `max_connections:`로 변경됨.
```yaml
default: &default
  max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

### 4. database.yml 미수정 확인 (R1 리스크 최종 해소)

Solid Stack install 명령은 `config/database.yml`을 수정하지 않음.
production 멀티DB 설정은 `rails new` 자체가 생성.

---

## 생성 파일 목록

### solid_queue:install

| 파일 | 내용 |
|---|---|
| `config/queue.yml` | 워커/디스패처 설정 (default 앵커 + 환경별) |
| `config/recurring.yml` | 주기적 작업 (production에 clear_finished_jobs) |
| `db/queue_schema.rb` | 11개 SolidQueue 테이블 스키마 (6,278 bytes) |
| `bin/jobs` | SolidQueue 워커 실행 스크립트 (chmod 0755) |

**production.rb 수정**:
```ruby
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

### solid_cache:install

| 파일 | 내용 |
|---|---|
| `config/cache.yml` | 캐시 설정 (max_size: 256MB, namespace: Rails.env) |
| `db/cache_schema.rb` | 1개 테이블 스키마 (solid_cache_entries) |

**production.rb 수정**:
```ruby
config.cache_store = :solid_cache_store
```

### solid_cable:install

| 파일 | 내용 |
|---|---|
| `config/cable.yml` | Action Cable 어댑터 설정 (**force:true로 생성**) |
| `db/cable_schema.rb` | 1개 테이블 스키마 (solid_cable_messages) |

**production.rb 수정**: 없음

---

## 설정 파일 내용

### config/queue.yml

```yaml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 3
      processes: <%= ENV.fetch("JOB_CONCURRENCY", 1) %>
      polling_interval: 0.1

development:
  <<: *default

test:
  <<: *default

production:
  <<: *default
```

### config/cache.yml

```yaml
default: &default
  store_options:
    # max_age: <%= 60.days.to_i %>
    max_size: <%= 256.megabytes %>
    namespace: <%= Rails.env %>

development:
  <<: *default

test:
  <<: *default

production:
  database: cache
  <<: *default
```

### config/cable.yml

```yaml
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

### config/recurring.yml

```yaml
production:
  clear_solid_queue_finished_jobs:
    command: "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)"
    schedule: every hour at minute 12
```

---

## 멀티DB 검증 결과

### db:create (4개 DB 생성)

```
Created database 'test_hatchling_development'
Created database 'test_hatchling_development_queue'
Created database 'test_hatchling_development_cache'
Created database 'test_hatchling_development_cable'
Created database 'test_hatchling_test'
Created database 'test_hatchling_test_queue'
Created database 'test_hatchling_test_cache'
Created database 'test_hatchling_test_cable'
```

### db:prepare (schema 로드)

| DB | 테이블 수 | 주요 테이블 |
|---|---|---|
| primary | 3 | pages, schema_migrations, ar_internal_metadata |
| queue | 13 | solid_queue_jobs, solid_queue_processes 등 11개 + 메타 2개 |
| cache | 3 | solid_cache_entries + 메타 2개 |
| cable | 3 | solid_cable_messages + 메타 2개 |

### SolidQueue 테이블 목록 (11개)

```
solid_queue_blocked_executions
solid_queue_claimed_executions
solid_queue_failed_executions
solid_queue_jobs
solid_queue_pauses
solid_queue_processes
solid_queue_ready_executions
solid_queue_recurring_executions
solid_queue_recurring_tasks
solid_queue_scheduled_executions
solid_queue_semaphores
```

---

## template.rb 구현 시 주의사항

1. **development/test 멀티DB 직접 생성 필요**: `rails new`는 production만 자동 설정
2. **database.yml 전체 교체**: `gsub_file` 대신 `create_file force: true`로 전체 덮어쓰기 권장
3. **Solid Stack install은 자동**: `rails new`에서 `--skip-solid` 없으면 자동 실행됨. template에서 별도 generate 불필요
4. **cable.yml은 rails new가 먼저 생성** → solid_cable:install이 force:true로 덮어씀 → 최종 내용은 solid_cable 버전
5. **max_connections vs pool**: Rails 8.1에서 키 이름 변경됨. 이전 조사의 `pool:` 대신 `max_connections:` 사용
