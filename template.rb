# frozen_string_literal: true

# =============================================================================
# ROR-Hatchling: Rails 8 Full-Stack Boilerplate Template
# =============================================================================
#
# Usage:
#   rails new my_app -d postgresql -c tailwind -m path/to/template.rb
#
# Prerequisites:
#   - Ruby 3.4.x
#   - Rails 8.1.x
#   - PostgreSQL 17.x (running)
#
# PRD v3.3 / TSD v1.3 기반
# 20 Template Steps (PRD 5.2) → 6 Phases로 구성
#
# =============================================================================

# ---------------------------------------------------------------------------
# Helper Methods
# ---------------------------------------------------------------------------

def say_phase(number, name)
  say "\n#{'=' * 60}", :cyan
  say " Phase #{number}: #{name}", :cyan
  say "#{'=' * 60}\n", :cyan
end

def say_step(number, name)
  say "\n--- Step #{number}: #{name} ---", :yellow
end

def create_component(name, ruby_content, erb_content, stimulus_content = nil)
  # ViewComponent 파일 생성 헬퍼
  # ruby_content  → app/components/{name}_component.rb
  # erb_content   → app/components/{name}_component/{name}_component.html.erb (sidecar)
  # stimulus_content → app/javascript/controllers/{name}_controller.js (optional)
  class_name = name.to_s.camelize

  create_file "app/components/#{name}_component.rb", ruby_content
  create_file "app/components/#{name}_component/#{name}_component.html.erb", erb_content

  if stimulus_content
    create_file "app/javascript/controllers/#{name}_controller.js", stimulus_content
  end

  say_status :component, "#{class_name}Component created", :green
end

def create_locale(path, content)
  # I18n 로케일 파일 생성 헬퍼
  create_file "config/locales/#{path}", content
  say_status :locale, path, :green
end

def create_test(path, content)
  # 테스트 파일 생성 헬퍼
  create_file "test/#{path}", content
  say_status :test, path, :green
end

# ---------------------------------------------------------------------------
# Phase 1: Foundation (Before Bundle)
# ---------------------------------------------------------------------------
# Steps: 1 (Gemfile), 6 (Directories), 11 (Multi-DB), 14 (Procfile.dev)
# Estimated: ~100 lines of actual content
# ---------------------------------------------------------------------------

say_phase 1, "Foundation"

# == Step 1: Gemfile 수정 ====================================================
# rails new -d postgresql -c tailwind 가 이미 포함하는 gems:
#   rails, pg, puma, propshaft, turbo-rails, stimulus-rails, importmap-rails,
#   tailwindcss-rails, solid_queue, solid_cache, solid_cable, thruster, kamal,
#   debug, brakeman, rubocop-rails-omakase, capybara, selenium-webdriver, bcrypt
#
# 추가해야 할 gems (rails new에 포함되지 않는 것):
#   pundit, pagy, lograge, view_component
#
# 버전 핀 교정이 필요한 gems:
#   rails new 기본 생성 Gemfile의 버전이 TSD 핀과 다를 수 있으므로 gsub_file로 교정
# ============================================================================

say_step 1, "Gemfile 수정"

# Ruby 버전 제약 추가 (Ruby 4.0 자동 업그레이드 방지)
# 검증 결과: rails new는 Gemfile에 ruby 지시문 미생성 (.ruby-version만 생성)
# TSD 2.1절: ruby "~> 3.4" 지정으로 4.0 업그레이드 방지
inject_into_file "Gemfile", after: /^source "https:\/\/rubygems\.org"\n/ do
  <<~RUBY

    ruby "~> 3.4"
  RUBY
end

# 불필요 gem 제거 (TSD 미포함)
# jbuilder: API JSON 빌더, 본 보일러플레이트에서 불필요
# image_processing: S3 파일 업로드 미사용 (PRD Out of Scope)
# 주석 라인 + gem 라인 + 후행 빈 줄까지 함께 제거
gsub_file "Gemfile", /# Build JSON APIs.*\n.*gem "jbuilder".*\n\n?/, ""
gsub_file "Gemfile", /# Use Active Storage variants.*\n.*gem "image_processing".*\n\n?/, ""

# 외부 Gems 추가 (TSD 4.2절 — 4개 제한)
# gem 메서드는 Gemfile 맨 아래에 추가하므로, inject_into_file로 group 블록 앞에 배치
inject_into_file "Gemfile", before: /^group :development, :test/ do
  <<~RUBY
    # Authorization & Utilities (TSD 4.2 — external gems, max 4)
    gem "pundit", "~> 2.5"
    gem "pagy", "~> 43.0"
    gem "lograge", "~> 0.14"
    gem "view_component", "~> 4.4"

  RUBY
end

# bcrypt 주석 해제 + TSD 버전 핀 적용 (TSD 4.1절: ~> 3.1)
# 검증 결과: rails new 기본은 `# gem "bcrypt", "~> 3.1.7"` (주석 처리 상태)
gsub_file "Gemfile", /^# gem "bcrypt".*$/, 'gem "bcrypt", "~> 3.1"'

# 기존 Gem 버전 핀 교정 (TSD 4.4절 Gemfile 전체와 일치시킴)
# Core
gsub_file "Gemfile", /gem "rails",\s*"~> 8\.1\.\d+"/, 'gem "rails", "~> 8.1"'
gsub_file "Gemfile", /gem "pg",\s*"~> 1\.1"/, 'gem "pg", "~> 1.5"'
gsub_file "Gemfile", /gem "puma",\s*">= 5\.0"/, 'gem "puma", "~> 6.5"'

# Frontend (버전 미지정 → TSD 버전 추가)
gsub_file "Gemfile", /^gem "propshaft"$/, 'gem "propshaft", "~> 1.1"'
gsub_file "Gemfile", /^gem "importmap-rails"$/, 'gem "importmap-rails", "~> 2.1"'
gsub_file "Gemfile", /^gem "turbo-rails"$/, 'gem "turbo-rails", "~> 2.0"'
gsub_file "Gemfile", /^gem "stimulus-rails"$/, 'gem "stimulus-rails", "~> 1.3"'
gsub_file "Gemfile", /^gem "tailwindcss-rails"$/, 'gem "tailwindcss-rails", "~> 4.2"'

# Infrastructure — Solid Stack (버전 미지정 → TSD 버전 추가)
gsub_file "Gemfile", /^gem "solid_cache"$/, 'gem "solid_cache", "~> 1.0"'
gsub_file "Gemfile", /^gem "solid_queue"$/, 'gem "solid_queue", "~> 1.3"'
gsub_file "Gemfile", /^gem "solid_cable"$/, 'gem "solid_cable", "~> 3.0"'

# Deployment (버전 미지정 → TSD 버전 추가)
gsub_file "Gemfile", /^gem "kamal", require: false$/, 'gem "kamal", "~> 2.10", require: false'
gsub_file "Gemfile", /^gem "thruster", require: false$/, 'gem "thruster", "~> 0.1", require: false'

# Dev/Test gems 버전 핀 교정 (TSD 4.3절)
gsub_file "Gemfile", /gem "debug", platforms:/, 'gem "debug", "~> 1.9", platforms:'
gsub_file "Gemfile", /^  gem "brakeman", require: false$/, '  gem "brakeman", "~> 7.0", require: false'
gsub_file "Gemfile", /^  gem "rubocop-rails-omakase", require: false$/, '  gem "rubocop-rails-omakase", "~> 1.0", require: false'

# Test gems 버전 핀 교정
gsub_file "Gemfile", /^  gem "capybara"$/, '  gem "capybara", "~> 3.40"'
gsub_file "Gemfile", /^  gem "selenium-webdriver"$/, '  gem "selenium-webdriver", "~> 4.27"'

# ============================================================================
# after_bundle 블록
# ============================================================================
# bundle install 완료 후 실행되는 모든 작업
# Phase 1 후반부 + Phase 2~6 전체가 이 블록 안에 위치
# ============================================================================

after_bundle do

  # == Step 11: database.yml 멀티DB 설정 ======================================
  # Rails 8.1 rails new는 production만 멀티DB 자동 설정.
  # development/test에도 멀티DB를 추가해야 함 (PRD 2.5절).
  # 검증 결과: pool: → max_connections: 키 변경 (Rails 8.1)
  # 검증 결과: Solid Stack install은 database.yml 미수정 (R1 리스크 해소)
  #
  # 구조: 3환경(dev/test/prod) x 4DB(primary/queue/cache/cable) = 12 논리 DB
  # YAML 앵커: &primary_dev, &primary_test, &primary_prod
  # ERB 참고: create_file 블록은 ERB 미처리. <%= %> 가 파일에 그대로 출력되며,
  #   Rails가 database.yml 로드 시 ERB 파싱하여 ENV 값을 평가함.
  #   따라서 <%%= %> (double %) 아닌 <%= %> (single %) 사용이 올바름.
  # ==========================================================================

  say_step 11, "database.yml 멀티DB 설정"

  create_file "config/database.yml", force: true do
    <<~YAML
      # PostgreSQL Multi-DB Configuration (PRD 2.5)
      # Single PostgreSQL server with 4 logical databases: primary, queue, cache, cable
      # https://guides.rubyonrails.org/active_record_multiple_databases.html
      #
      # Migration directories:
      #   primary -> db/migrate/
      #   queue   -> db/queue_migrate/
      #   cache   -> db/cache_migrate/
      #   cable   -> db/cable_migrate/

      default: &default
        adapter: postgresql
        encoding: unicode
        host: <%= ENV.fetch("DB_HOST", "localhost") %>
        username: <%= ENV.fetch("DB_USER", "postgres") %>
        password: <%= ENV.fetch("DB_PASSWORD", "password") %>
        port: <%= ENV.fetch("DB_PORT", 5432) %>
        # For details on connection pooling, see Rails configuration guide
        # https://guides.rubyonrails.org/configuring.html#database-pooling
        max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

      development:
        primary: &primary_dev
          <<: *default
          database: #{app_name}_development
        queue:
          <<: *primary_dev
          database: #{app_name}_development_queue
          migrations_paths: db/queue_migrate
        cache:
          <<: *primary_dev
          database: #{app_name}_development_cache
          migrations_paths: db/cache_migrate
        cable:
          <<: *primary_dev
          database: #{app_name}_development_cable
          migrations_paths: db/cable_migrate

      test:
        primary: &primary_test
          <<: *default
          database: #{app_name}_test
        queue:
          <<: *primary_test
          database: #{app_name}_test_queue
          migrations_paths: db/queue_migrate
        cache:
          <<: *primary_test
          database: #{app_name}_test_cache
          migrations_paths: db/cache_migrate
        cable:
          <<: *primary_test
          database: #{app_name}_test_cable
          migrations_paths: db/cable_migrate

      production:
        primary: &primary_prod
          <<: *default
          database: #{app_name}_production
          host: <%= ENV.fetch("DB_HOST", "localhost") %>
          username: <%= ENV.fetch("DB_USER", "#{app_name}") %>
          password: <%= ENV["DB_PASSWORD"] %>
        queue:
          <<: *primary_prod
          database: #{app_name}_production_queue
          migrations_paths: db/queue_migrate
        cache:
          <<: *primary_prod
          database: #{app_name}_production_cache
          migrations_paths: db/cache_migrate
        cable:
          <<: *primary_prod
          database: #{app_name}_production_cable
          migrations_paths: db/cable_migrate
    YAML
  end

  # == Step 6: 디렉토리 구조 생성 =============================================
  # create_file은 부모 디렉토리 자동 생성
  # ==========================================================================

  say_step 6, "디렉토리 구조 생성"

  %w[
    app/services/.keep
    app/policies/.keep
    app/components/.keep
    db/seeds/.keep
    db/cache_migrate/.keep
    db/queue_migrate/.keep
    db/cable_migrate/.keep
  ].each { |path| create_file path }

  # NOTE: rails new는 Solid Stack 자동 설치 시 db/*_schema.rb만 생성하고
  # db/*_migrate/ 디렉토리는 생성하지 않음. database.yml의 migrations_paths가
  # 참조하는 디렉토리이므로 .keep 파일로 확보 필요.

  # == Step 14: Procfile.dev 수정 =============================================
  # rails new -c tailwind 기본 생성: web + css (2프로세스)
  # 추가: jobs (SolidQueue 워커) → 3프로세스
  # NOTE: bin/jobs는 solid_queue:install이 자동 생성 (Rails 8.1 rails new 시)
  # ==========================================================================

  say_step 14, "Procfile.dev 수정"

  # rails new -c tailwind 기본 Procfile.dev: web + css
  # append_to_file로 기존 내용 보존 + jobs만 추가 (최소 변경 원칙)
  append_to_file "Procfile.dev", "jobs: bin/jobs\n"

  # == Step 1 (계속): 환경 설정 파일 ==========================================

  say_step "1b", "환경 설정 파일"

  create_file ".env.example" do
    <<~ENV
      # Database
      DB_USER=postgres
      DB_PASSWORD=

      # Rails
      RAILS_MAX_THREADS=5

      # Admin seed (Phase 4에서 사용)
      ADMIN_EMAIL=admin@example.com
      ADMIN_PASSWORD=changeme123
    ENV
  end

  # .gitignore에 .env 추가 (rails new가 이미 생성한 .gitignore에 추가)
  append_to_file ".gitignore", "\n# Environment variables\n.env\n.env.local\n"

  # -------------------------------------------------------------------------
  # Phase 2: Authentication & User Model
  # -------------------------------------------------------------------------
  # Steps: 2 (auth generator), 3 (registration), 4 (User extension), 18 (rate_limit)
  # Estimated: ~300 lines of actual content
  # -------------------------------------------------------------------------

  say_phase 2, "Authentication & User Model"

  # == Step 2: Authentication Generator 실행 ==================================
  # 생성 파일 19개: User, Session, Current 모델, SessionsController,
  # PasswordsController, Authentication concern, Mailer, Views, Migrations 등
  # 검증 결과: docs/generator-outputs/authentication-output.md 참조
  # ==========================================================================

  say_step 2, "Authentication Generator 실행"

  generate "authentication"

  # == Step 4: User 모델 확장 ==================================================
  # inject 타겟 (실행 검증 확정):
  #   User model: after "  has_many :sessions, dependent: :destroy\n"
  #   User migration: after "      t.string :password_digest, null: false\n"
  # ==========================================================================

  say_step 4, "User 모델 확장"

  # role enum + password validation 주입
  # 타겟: "  has_many :sessions, dependent: :destroy\n" 직후
  inject_into_file "app/models/user.rb",
    after: "  has_many :sessions, dependent: :destroy\n" do
    <<~'RUBY'

      enum :role, { user: 0, admin: 1, super_admin: 2 }, default: :user

      validates :email_address, uniqueness: true
      validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }

      generates_token_for :email_confirmation, expires_in: 24.hours do
        email_address
      end

      generates_token_for :magic_link, expires_in: 5.minutes do
        updated_at.to_f
      end
    RUBY
  end

  # role 컬럼을 User migration에 추가
  # 타겟: "      t.string :password_digest, null: false\n" 직후
  Dir.glob("db/migrate/*_create_users.rb").each do |migration_file|
    inject_into_file migration_file,
      after: "      t.string :password_digest, null: false\n" do
      "      t.integer :role, default: 0, null: false\n"
    end
  end

  # == Step 3: 회원가입 플로우 구현 ============================================
  # Auth generator는 Registration 미포함 → 별도 구현 필요
  # ==========================================================================

  say_step 3, "회원가입 컨트롤러/뷰/라우트"

  # Registration 라우트 추가
  # 타겟: "  resource :session\n" 직후
  inject_into_file "config/routes.rb",
    after: "  resource :session\n" do
    "  resource :registration, only: %i[new create]\n"
  end

  # root 라우트 추가
  route 'root "pages#home"'

  create_file "app/controllers/pages_controller.rb", <<~'RUBY'
    # frozen_string_literal: true

    class PagesController < ApplicationController
      allow_unauthenticated_access
    end
  RUBY

  create_file "app/views/pages/home.html.erb", <<~'ERB'
    <% content_for(:title) { t("defaults.app_name") } %>

    <div class="mx-auto max-w-2xl py-16 text-center">
      <h1 class="text-4xl font-bold text-gray-900"><%= t("defaults.app_name") %></h1>
      <p class="mt-4 text-lg text-gray-600"><%= t("defaults.welcome") %></p>
    </div>
  ERB

  create_file "app/controllers/registrations_controller.rb" do
    <<~'RUBY'
      class RegistrationsController < ApplicationController
        allow_unauthenticated_access only: %i[new create]
        rate_limit to: 5, within: 1.hour, only: :create,
          with: -> { redirect_to new_registration_url, alert: t("rate_limit.exceeded") }

        def new
          @user = User.new
        end

        def create
          @user = User.new(registration_params)
          if @user.save
            start_new_session_for @user
            redirect_to root_path, notice: t("registrations.create.success")
          else
            render :new, status: :unprocessable_entity
          end
        end

        private

        def registration_params
          params.require(:user).permit(:email_address, :password, :password_confirmation)
        end
      end
    RUBY
  end

  create_file "app/views/registrations/new.html.erb" do
    <<~'ERB'
      <div class="flex min-h-full flex-col justify-center px-6 py-12 lg:px-8">
        <div class="sm:mx-auto sm:w-full sm:max-w-sm">
          <h2 class="text-center text-2xl/9 font-bold tracking-tight text-gray-900">
            <%= t("registrations.new.title") %>
          </h2>
        </div>

        <div class="mt-10 sm:mx-auto sm:w-full sm:max-w-sm">
          <% if @user.errors.any? %>
            <div id="error-messages" class="mb-6 rounded-lg bg-red-50 p-4 text-sm text-red-800" role="alert">
              <ul class="list-disc space-y-1 pl-5">
                <% @user.errors.full_messages.each do |message| %>
                  <li><%= message %></li>
                <% end %>
              </ul>
            </div>
          <% end %>

          <%= form_with model: @user, url: registration_path, class: "space-y-6" do |form| %>
            <div>
              <%= form.label :email_address, class: "block text-sm/6 font-medium text-gray-900" %>
              <div class="mt-2">
                <%= form.email_field :email_address, required: true, autofocus: true, autocomplete: "email",
                  class: "block w-full rounded-md border-0 px-3 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm/6" %>
              </div>
            </div>

            <div>
              <%= form.label :password, class: "block text-sm/6 font-medium text-gray-900" %>
              <div class="mt-2">
                <%= form.password_field :password, required: true, autocomplete: "new-password",
                  class: "block w-full rounded-md border-0 px-3 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm/6" %>
              </div>
            </div>

            <div>
              <%= form.label :password_confirmation, class: "block text-sm/6 font-medium text-gray-900" %>
              <div class="mt-2">
                <%= form.password_field :password_confirmation, required: true, autocomplete: "new-password",
                  class: "block w-full rounded-md border-0 px-3 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm/6" %>
              </div>
            </div>

            <%= form.submit t("registrations.new.submit"),
              class: "flex w-full justify-center rounded-md bg-indigo-600 px-3 py-1.5 text-sm/6 font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600" %>
          <% end %>

          <p class="mt-10 text-center text-sm/6 text-gray-500">
            <%= t("registrations.new.login_prompt") %>
            <%= link_to t("registrations.new.login_link"), new_session_path, class: "font-semibold text-indigo-600 hover:text-indigo-500" %>
          </p>
        </div>
      </div>
    ERB
  end

  # == Step 18: rate_limit 설정 ================================================
  # 검증 결과: SessionsController, PasswordsController는 이미 rate_limit 포함
  #   (to: 10, within: 3.minutes, only: :create)
  # RegistrationsController만 수동 추가 필요
  # ==========================================================================

  say_step 18, "rate_limit 설정 + I18n 적용"

  # SessionsController — rate_limit alert를 I18n으로 교체
  gsub_file "app/controllers/sessions_controller.rb",
    'alert: "Try again later."',
    'alert: t("rate_limit.exceeded")'

  # SessionsController — 로그인 실패 메시지를 I18n으로 교체
  gsub_file "app/controllers/sessions_controller.rb",
    'alert: "Try another email address or password."',
    'alert: t("sessions.create.invalid")'

  # PasswordsController — rate_limit 값 변경 (10/3min → 3/1hr, ROADMAP spec) + I18n
  gsub_file "app/controllers/passwords_controller.rb",
    'rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Try again later." }',
    'rate_limit to: 3, within: 1.hour, only: :create, with: -> { redirect_to new_password_path, alert: t("rate_limit.exceeded") }'

  # PasswordsController — 비밀번호 재설정 안내 메시지 I18n
  gsub_file "app/controllers/passwords_controller.rb",
    'notice: "Password reset instructions sent (if user with that email address exists)."',
    'notice: t("passwords.create.sent")'

  # PasswordsController — 비밀번호 재설정 성공 메시지 I18n
  gsub_file "app/controllers/passwords_controller.rb",
    'notice: "Password has been reset."',
    'notice: t("passwords.update.success")'

  # PasswordsController — 비밀번호 불일치 메시지 I18n
  gsub_file "app/controllers/passwords_controller.rb",
    'alert: "Passwords did not match."',
    'alert: t("passwords.update.mismatch")'

  # PasswordsController — 토큰 만료/무효 메시지 I18n
  gsub_file "app/controllers/passwords_controller.rb",
    'alert: "Password reset link is invalid or has expired."',
    'alert: t("passwords.invalid_token")'

  # -------------------------------------------------------------------------
  # Phase 3: UI Components, Error Handling & I18n
  # -------------------------------------------------------------------------
  # Steps: 5 (ViewComponent), 7-error (에러/헬스), 8 (Stimulus), 9 (I18n), 10 (에러 페이지)
  # Estimated: ~800 lines of actual content
  # -------------------------------------------------------------------------

  say_phase 3, "UI Components, Error Handling & I18n"

  # == Step 5: ViewComponent 설치 및 10종 컴포넌트 =============================
  # ViewComponent 전역 설정 → ApplicationComponent → 10종 컴포넌트
  # ==========================================================================

  say_step 5, "ViewComponent 설치 및 10종 컴포넌트"

  # ViewComponent 전역 설정
  environment do
    <<~'RUBY'
      # ViewComponent configuration
      config.view_component.generate.sidecar = true
      config.view_component.generate.stimulus_controller = true
    RUBY
  end

  # ApplicationComponent 베이스 클래스 (YAGNI: 최소한의 공통 기능만)
  create_file "app/components/application_component.rb", <<~'RUBY'
    class ApplicationComponent < ViewComponent::Base
      private

      def safe_classes(*args)
        args.compact.join(" ")
      end
    end
  RUBY

  # 10종 ViewComponent 생성 (PRD 2.3.2절)
  # 모든 Tailwind 클래스는 정적 상수(VARIANTS hash)로 정의 — 문자열 보간 금지
  # Stimulus 컨트롤러는 Step 8에서 별도 생성, 여기서는 ERB data-* 속성만 참조

  # --- 1. ButtonComponent ---
  create_component :button, <<~'RUBY', <<~'ERB'
    # frozen_string_literal: true

    class ButtonComponent < ApplicationComponent
      VARIANTS = {
        primary: "inline-flex items-center justify-center rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:opacity-50 disabled:cursor-not-allowed",
        secondary: "inline-flex items-center justify-center rounded-md bg-white px-4 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed",
        danger: "inline-flex items-center justify-center rounded-md bg-red-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600 disabled:opacity-50 disabled:cursor-not-allowed"
      }.freeze

      def initialize(variant: :primary, tag: :button, href: nil, disabled: false, type: "button", **options)
        @variant = variant
        @tag = tag
        @href = href
        @disabled = disabled
        @type = type
        @options = options
      end

      private

      def css_classes
        safe_classes(VARIANTS[@variant], @options[:class])
      end
    end
  RUBY
    <% if @tag == :a %>
      <%= link_to @href, class: css_classes, **@options.except(:class) do %>
        <%= content %>
      <% end %>
    <% else %>
      <button type="<%= @type %>" class="<%= css_classes %>" <%= "disabled" if @disabled %> <%= tag.attributes(@options.except(:class)) %>>
        <%= content %>
      </button>
    <% end %>
  ERB

  # --- 2. CardComponent ---
  create_component :card, <<~'RUBY', <<~'ERB'
    # frozen_string_literal: true

    class CardComponent < ApplicationComponent
      VARIANTS = {
        default: "rounded-lg bg-white shadow p-6",
        bordered: "rounded-lg bg-white border border-gray-200 p-6"
      }.freeze

      renders_one :title
      renders_one :body
      renders_one :footer

      def initialize(variant: :default)
        @variant = variant
      end

      private

      def css_classes
        VARIANTS[@variant]
      end
    end
  RUBY
    <div class="<%= css_classes %>">
      <% if title? %>
        <div class="mb-4 text-lg font-semibold text-gray-900">
          <%= title %>
        </div>
      <% end %>

      <% if body? %>
        <div class="text-gray-700">
          <%= body %>
        </div>
      <% end %>

      <% if footer? %>
        <div class="mt-4 border-t border-gray-100 pt-4">
          <%= footer %>
        </div>
      <% end %>
    </div>
  ERB

  # --- 3. BadgeComponent ---
  create_component :badge, <<~'RUBY', <<~'ERB'
    # frozen_string_literal: true

    class BadgeComponent < ApplicationComponent
      VARIANTS = {
        success: "inline-flex items-center rounded-full bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20",
        warning: "inline-flex items-center rounded-full bg-yellow-50 px-2 py-1 text-xs font-medium text-yellow-800 ring-1 ring-inset ring-yellow-600/20",
        error: "inline-flex items-center rounded-full bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/20",
        info: "inline-flex items-center rounded-full bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-600/20"
      }.freeze

      def initialize(variant: :info, label:)
        @variant = variant
        @label = label
      end

      private

      def css_classes
        VARIANTS[@variant]
      end
    end
  RUBY
    <span class="<%= css_classes %>"><%= @label %></span>
  ERB

  # --- 4. FlashComponent ---
  create_component :flash, <<~'RUBY', <<~'ERB'
    # frozen_string_literal: true

    class FlashComponent < ApplicationComponent
      VARIANTS = {
        notice: "border-l-4 border-green-400 bg-green-50 p-4 text-green-800",
        alert: "border-l-4 border-yellow-400 bg-yellow-50 p-4 text-yellow-800",
        error: "border-l-4 border-red-400 bg-red-50 p-4 text-red-800"
      }.freeze

      # notice/alert는 Rails 표준, error는 추가
      VARIANT_MAPPING = {
        "notice" => :notice,
        "alert" => :alert,
        "error" => :error
      }.freeze

      def initialize(flash:)
        @flash = flash
      end

      def render?
        @flash.any?
      end

      private

      def variant_for(type)
        VARIANT_MAPPING[type.to_s] || :notice
      end

      def css_classes_for(type)
        VARIANTS[variant_for(type)]
      end
    end
  RUBY
    <div class="space-y-2">
      <% @flash.each do |type, message| %>
        <div class="<%= css_classes_for(type) %> flex items-center justify-between rounded-md"
             data-controller="flash"
             data-flash-duration-value="5000"
             data-flash-hidden-class="hidden">
          <p class="text-sm font-medium"><%= message %></p>
          <button type="button" data-action="click->flash#dismiss" class="ml-4 inline-flex shrink-0 rounded-md p-1.5 hover:bg-black/5 focus:outline-none">
            <span class="sr-only"><%= t("defaults.buttons.close") %></span>
            <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
            </svg>
          </button>
        </div>
      <% end %>
    </div>
  ERB

  # --- 5. ModalComponent ---
  create_component :modal, <<~'RUBY', <<~'ERB'
    # frozen_string_literal: true

    class ModalComponent < ApplicationComponent
      renders_one :trigger
      renders_one :body
    end
  RUBY
    <div data-controller="modal">
      <% if trigger? %>
        <div data-action="click->modal#open">
          <%= trigger %>
        </div>
      <% end %>

      <%# dialogTarget이 backdrop 겸 scroll container 역할 %>
      <%# closeOnBackdrop: event.target === dialogTarget일 때만 닫힘 (패널 내부 클릭은 무시) %>
      <div data-modal-target="dialog"
           data-action="click->modal#closeOnBackdrop"
           class="hidden fixed inset-0 z-50 flex min-h-full items-center justify-center overflow-y-auto bg-gray-500/75 p-4"
           aria-modal="true"
           role="dialog">
        <div class="relative w-full max-w-lg rounded-lg bg-white p-6 shadow-xl">
          <%# Close button %>
          <div class="absolute right-4 top-4">
            <button type="button" data-action="click->modal#close" class="rounded-md text-gray-400 hover:text-gray-500 focus:outline-none">
              <span class="sr-only"><%= t("defaults.buttons.close") %></span>
              <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
              </svg>
            </button>
          </div>

          <% if body? %>
            <%= body %>
          <% end %>
        </div>
      </div>
    </div>
  ERB

  # --- 6. DropdownComponent ---
  create_component :dropdown, <<~'RUBY', <<~'ERB'
    # frozen_string_literal: true

    class DropdownComponent < ApplicationComponent
      renders_one :trigger
      renders_many :items
    end
  RUBY
    <div data-controller="dropdown" data-dropdown-hidden-class="hidden" class="relative inline-block text-left">
      <% if trigger? %>
        <div data-action="click->dropdown#toggle">
          <%= trigger %>
        </div>
      <% end %>

      <div data-dropdown-target="menu"
           class="hidden absolute right-0 z-10 mt-2 w-48 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black/5 focus:outline-none"
           role="menu"
           aria-orientation="vertical">
        <div class="py-1" role="none">
          <% items.each do |item| %>
            <%= item %>
          <% end %>
        </div>
      </div>
    </div>
  ERB

  # --- 7. FormFieldComponent ---
  create_component :form_field, <<~'RUBY', <<~'ERB'
    # frozen_string_literal: true

    class FormFieldComponent < ApplicationComponent
      INPUT_CLASSES = "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
      INPUT_ERROR_CLASSES = "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-red-500 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-red-600 sm:text-sm sm:leading-6"
      LABEL_CLASSES = "block text-sm font-medium leading-6 text-gray-900"
      ERROR_CLASSES = "mt-1 text-sm text-red-600"

      def initialize(form:, field_name:, type: :text, label: nil, error_messages: nil, required: false, options: nil, **input_options)
        @form = form
        @field_name = field_name
        @type = type
        @label = label
        @error_messages = error_messages
        @required = required
        @options = options
        @input_options = input_options
      end

      private

      def has_errors?
        @error_messages.present?
      end

      def input_css_classes
        has_errors? ? INPUT_ERROR_CLASSES : INPUT_CLASSES
      end
    end
  RUBY
    <div>
      <% if @label %>
        <%= @form.label @field_name, @label, class: FormFieldComponent::LABEL_CLASSES %>
      <% end %>

      <div class="mt-1">
        <% case @type %>
        <% when :select %>
          <%= @form.select @field_name, @options, {}, class: input_css_classes, **@input_options %>
        <% when :textarea %>
          <%= @form.text_area @field_name, class: input_css_classes, **@input_options %>
        <% when :password %>
          <%= @form.password_field @field_name, class: input_css_classes, required: @required, **@input_options %>
        <% when :email %>
          <%= @form.email_field @field_name, class: input_css_classes, required: @required, **@input_options %>
        <% else %>
          <%= @form.text_field @field_name, class: input_css_classes, required: @required, **@input_options %>
        <% end %>
      </div>

      <% if has_errors? %>
        <% Array(@error_messages).each do |message| %>
          <p class="<%= FormFieldComponent::ERROR_CLASSES %>"><%= message %></p>
        <% end %>
      <% end %>
    </div>
  ERB

  # --- 8. EmptyStateComponent ---
  create_component :empty_state, <<~'RUBY', <<~'ERB'
    # frozen_string_literal: true

    class EmptyStateComponent < ApplicationComponent
      renders_one :icon
      renders_one :action

      def initialize(message:)
        @message = message
      end
    end
  RUBY
    <div class="py-12 text-center">
      <% if icon? %>
        <div class="mx-auto mb-4 text-gray-400">
          <%= icon %>
        </div>
      <% end %>

      <p class="text-sm text-gray-500"><%= @message %></p>

      <% if action? %>
        <div class="mt-6">
          <%= action %>
        </div>
      <% end %>
    </div>
  ERB

  # --- 9. PaginationComponent ---
  # Pagy 43.x: @pagy.series_nav로 raw HTML 출력 (<%== %> 사용)
  # Pagy::Method은 ApplicationController에 include (Phase 4 설정, Pagy::Frontend 제거됨)
  create_component :pagination, <<~'RUBY', <<~'ERB'
    # frozen_string_literal: true

    class PaginationComponent < ApplicationComponent
      def initialize(pagy:)
        @pagy = pagy
      end

      def render?
        @pagy.pages > 1
      end
    end
  RUBY
    <nav aria-label="Pagination" class="flex items-center justify-center py-4">
      <%== @pagy.series_nav %>
    </nav>
  ERB

  # --- 10. NavbarComponent ---
  create_component :navbar, <<~'RUBY', <<~'ERB'
    # frozen_string_literal: true

    class NavbarComponent < ApplicationComponent
      def initialize(user: nil)
        @user = user
      end

      private

      def signed_in?
        @user.present?
      end
    end
  RUBY
    <nav class="bg-white shadow" data-controller="navbar" data-navbar-hidden-class="hidden">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="flex h-16 justify-between">
          <%# Logo / Home link %>
          <div class="flex shrink-0 items-center">
            <%= link_to t("defaults.navigation.home"), root_path, class: "text-lg font-bold text-gray-900" %>
          </div>

          <%# Desktop navigation %>
          <div class="hidden sm:ml-6 sm:flex sm:items-center sm:space-x-4">
            <% if signed_in? %>
              <%= link_to t("defaults.navigation.dashboard"), root_path, class: "rounded-md px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 hover:text-gray-900" %>
              <%= button_to t("defaults.navigation.logout"), session_path, method: :delete, class: "rounded-md px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 hover:text-gray-900" %>
            <% else %>
              <%= link_to t("defaults.navigation.login"), new_session_path, class: "rounded-md px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 hover:text-gray-900" %>
              <%= link_to t("defaults.navigation.signup"), new_registration_path, class: "rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500" %>
            <% end %>
          </div>

          <%# Mobile hamburger button %>
          <div class="flex items-center sm:hidden">
            <button type="button"
                    data-action="click->navbar#toggle"
                    class="inline-flex items-center justify-center rounded-md p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-500 focus:outline-none"
                    aria-expanded="false">
              <span class="sr-only">Open main menu</span>
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"/>
              </svg>
            </button>
          </div>
        </div>
      </div>

      <%# Mobile menu %>
      <div data-navbar-target="menu" class="hidden sm:hidden">
        <div class="space-y-1 px-2 pb-3 pt-2">
          <% if signed_in? %>
            <%= link_to t("defaults.navigation.dashboard"), root_path, class: "block rounded-md px-3 py-2 text-base font-medium text-gray-700 hover:bg-gray-100 hover:text-gray-900" %>
            <%= button_to t("defaults.navigation.logout"), session_path, method: :delete, class: "block w-full rounded-md px-3 py-2 text-left text-base font-medium text-gray-700 hover:bg-gray-100 hover:text-gray-900" %>
          <% else %>
            <%= link_to t("defaults.navigation.login"), new_session_path, class: "block rounded-md px-3 py-2 text-base font-medium text-gray-700 hover:bg-gray-100 hover:text-gray-900" %>
            <%= link_to t("defaults.navigation.signup"), new_registration_path, class: "block rounded-md px-3 py-2 text-base font-medium text-indigo-600 hover:bg-gray-100" %>
          <% end %>
        </div>
      </div>
    </nav>
  ERB

  # == Step 8: Stimulus 컨트롤러 4종 ==========================================
  # flash, modal, dropdown, navbar
  # Import Maps 핀은 stimulus-rails가 자동 관리 (controllers/ 자동 로딩)
  # ==========================================================================

  say_step 8, "Stimulus 컨트롤러 4종"

  # flash_controller.js — auto-dismiss + manual dismiss
  create_file "app/javascript/controllers/flash_controller.js", <<~'JS'
    import { Controller } from "@hotwired/stimulus"

    export default class extends Controller {
      static values = { duration: { type: Number, default: 5000 } }
      static classes = ["hidden"]

      connect() {
        this.dismissTimer = setTimeout(() => this.dismiss(), this.durationValue)
      }

      disconnect() {
        if (this.dismissTimer) {
          clearTimeout(this.dismissTimer)
        }
      }

      dismiss() {
        if (this.dismissTimer) {
          clearTimeout(this.dismissTimer)
        }
        this.element.classList.add(this.hiddenClass)
        setTimeout(() => this.element.remove(), 300)
      }
    }
  JS

  # modal_controller.js — open/close + ESC key + backdrop click
  create_file "app/javascript/controllers/modal_controller.js", <<~'JS'
    import { Controller } from "@hotwired/stimulus"

    export default class extends Controller {
      static targets = ["dialog"]

      connect() {
        this.boundKeydown = (event) => {
          if (event.key === "Escape") this.close()
        }
        document.addEventListener("keydown", this.boundKeydown)
      }

      disconnect() {
        document.removeEventListener("keydown", this.boundKeydown)
        document.body.style.overflow = ""
      }

      open() {
        this.dialogTarget.classList.remove("hidden")
        document.body.style.overflow = "hidden"
      }

      close() {
        this.dialogTarget.classList.add("hidden")
        document.body.style.overflow = ""
      }

      closeOnBackdrop(event) {
        if (event.target === this.dialogTarget) {
          this.close()
        }
      }
    }
  JS

  # dropdown_controller.js — toggle + outside click close
  create_file "app/javascript/controllers/dropdown_controller.js", <<~'JS'
    import { Controller } from "@hotwired/stimulus"

    export default class extends Controller {
      static targets = ["menu"]
      static classes = ["hidden"]

      connect() {
        this.boundClickOutside = (event) => {
          if (!this.element.contains(event.target)) {
            this.hide()
          }
        }
        document.addEventListener("click", this.boundClickOutside)
      }

      disconnect() {
        document.removeEventListener("click", this.boundClickOutside)
      }

      toggle() {
        this.menuTarget.classList.toggle(this.hiddenClass)
      }

      hide() {
        this.menuTarget.classList.add(this.hiddenClass)
      }
    }
  JS

  # navbar_controller.js — mobile menu toggle
  create_file "app/javascript/controllers/navbar_controller.js", <<~'JS'
    import { Controller } from "@hotwired/stimulus"

    export default class extends Controller {
      static targets = ["menu"]
      static classes = ["hidden"]

      toggle() {
        this.menuTarget.classList.toggle(this.hiddenClass)
      }
    }
  JS

  # == Step 7 (에러/헬스): ApplicationController + HealthController ============
  # ApplicationController: RecordNotFound(404) + Pundit::NotAuthorizedError(403)
  # HealthController: GET /health readiness check
  # 500 에러는 rescue 금지 (Rails 미들웨어 위임)
  # ==========================================================================

  say_step 7, "에러 핸들링 + HealthController"

  # ApplicationController에 에러 핸들링 주입
  # 타겟 (실행 검증 확정): "  include Authentication\n" 직후
  inject_into_file "app/controllers/application_controller.rb",
    after: "  include Authentication\n" do
    <<~'RUBY'

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from Pundit::NotAuthorizedError, with: :forbidden

      private

      # Pundit은 current_user를 기대하지만 Rails 8 auth는 Current.user 패턴 사용
      def pundit_user
        Current.user
      end

      def not_found
        respond_to do |format|
          format.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
          format.json { render json: { error: "Not found" }, status: :not_found }
        end
      end

      def forbidden
        respond_to do |format|
          format.html { render file: Rails.public_path.join("403.html"), status: :forbidden, layout: false }
          format.json { render json: { error: "Forbidden" }, status: :forbidden }
        end
      end
    RUBY
  end

  create_file "app/controllers/health_controller.rb", <<~'RUBY'
    class HealthController < ApplicationController
      allow_unauthenticated_access

      def show
        ActiveRecord::Base.connection.execute("SELECT 1")
        render json: { status: "ok" }, status: :ok
      rescue StandardError => e
        render json: { status: "error", message: e.message }, status: :service_unavailable
      end
    end
  RUBY

  # Health route 추가
  route 'get "/health", to: "health#show"'

  # == Step 9: I18n 로케일 파일 ================================================
  # config.i18n.default_locale = :ko
  # 로케일 파일: defaults/ (공통 UI) + models/ (모델/속성)
  # ==========================================================================

  say_step 9, "I18n 로케일 파일"

  # I18n 설정 initializer
  create_file "config/initializers/locale.rb", <<~'RUBY'
    Rails.application.configure do
      config.i18n.default_locale = :ko
      config.i18n.available_locales = [ :ko, :en ]
      config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]
    end
  RUBY

  # 루트 로케일 파일 (rails new 기본 파일 교체)
  create_file "config/locales/ko.yml", force: true do
    <<~YAML
      ko:
        registrations:
          new:
            title: "회원가입"
            submit: "가입하기"
            login_prompt: "이미 계정이 있으신가요?"
            login_link: "로그인"
          create:
            success: "회원가입이 완료되었습니다."
        sessions:
          create:
            invalid: "이메일 또는 비밀번호가 올바르지 않습니다."
        passwords:
          create:
            sent: "비밀번호 재설정 안내가 발송되었습니다."
          update:
            success: "비밀번호가 변경되었습니다."
            mismatch: "비밀번호가 일치하지 않습니다."
          invalid_token: "비밀번호 재설정 링크가 유효하지 않거나 만료되었습니다."
        rate_limit:
          exceeded: "요청이 너무 많습니다. 잠시 후 다시 시도해주세요."
    YAML
  end

  create_file "config/locales/en.yml", force: true do
    <<~YAML
      en:
        registrations:
          new:
            title: "Sign Up"
            submit: "Create Account"
            login_prompt: "Already have an account?"
            login_link: "Log in"
          create:
            success: "Account created successfully."
        sessions:
          create:
            invalid: "Invalid email address or password."
        passwords:
          create:
            sent: "Password reset instructions sent (if account exists)."
          update:
            success: "Password has been reset."
            mismatch: "Passwords did not match."
          invalid_token: "Password reset link is invalid or has expired."
        rate_limit:
          exceeded: "Too many requests. Please try again later."
    YAML
  end

  # defaults/ 서브디렉토리 로케일 (공통 UI 텍스트)
  create_locale "defaults/ko.yml", <<~YAML
    ko:
      time:
        formats:
          default: "%Y년 %m월 %d일 %H:%M"
          short: "%m/%d %H:%M"
          long: "%Y년 %m월 %d일 %A %H:%M"
      date:
        formats:
          default: "%Y-%m-%d"
          short: "%m/%d"
          long: "%Y년 %m월 %d일"
      defaults:
        app_name: "#{app_name.titleize}"
        welcome: "Rails 8 풀스택 보일러플레이트로 시작하세요."
        buttons:
          submit: "제출"
          save: "저장"
          cancel: "취소"
          delete: "삭제"
          edit: "수정"
          back: "뒤로"
          confirm: "확인"
          close: "닫기"
        flash:
          success: "성공적으로 처리되었습니다."
          error: "오류가 발생했습니다."
          alert: "알림"
          notice: "안내"
        navigation:
          home: "홈"
          dashboard: "대시보드"
          settings: "설정"
          login: "로그인"
          logout: "로그아웃"
          signup: "회원가입"
        pagination:
          previous: "이전"
          next: "다음"
        errors:
          not_found: "요청하신 페이지를 찾을 수 없습니다."
          unauthorized: "로그인이 필요합니다."
          forbidden: "접근 권한이 없습니다."
  YAML

  create_locale "defaults/en.yml", <<~YAML
    en:
      defaults:
        app_name: "#{app_name.titleize}"
        welcome: "Get started with your Rails 8 full-stack boilerplate."
        buttons:
          submit: "Submit"
          save: "Save"
          cancel: "Cancel"
          delete: "Delete"
          edit: "Edit"
          back: "Back"
          confirm: "Confirm"
          close: "Close"
        flash:
          success: "Completed successfully."
          error: "An error occurred."
          alert: "Alert"
          notice: "Notice"
        navigation:
          home: "Home"
          dashboard: "Dashboard"
          settings: "Settings"
          login: "Log in"
          logout: "Log out"
          signup: "Sign up"
        pagination:
          previous: "Previous"
          next: "Next"
        errors:
          not_found: "The page you requested could not be found."
          unauthorized: "You need to sign in first."
          forbidden: "You are not authorized to access this page."
  YAML

  # models/ 서브디렉토리 로케일 (ActiveRecord 모델/속성)
  create_locale "models/ko.yml", <<~YAML
    ko:
      activerecord:
        models:
          user: "사용자"
        attributes:
          user:
            email_address: "이메일"
            password: "비밀번호"
            password_confirmation: "비밀번호 확인"
            role: "역할"
        errors:
          models:
            user:
              attributes:
                email_address:
                  blank: "이메일을 입력해주세요."
                  taken: "이미 사용 중인 이메일입니다."
                  invalid: "유효한 이메일을 입력해주세요."
                password:
                  too_short: "비밀번호는 최소 %{count}자 이상이어야 합니다."
                password_confirmation:
                  confirmation: "비밀번호가 일치하지 않습니다."
  YAML

  create_locale "models/en.yml", <<~YAML
    en:
      activerecord:
        models:
          user: "User"
        attributes:
          user:
            email_address: "Email"
            password: "Password"
            password_confirmation: "Password confirmation"
            role: "Role"
        errors:
          models:
            user:
              attributes:
                email_address:
                  blank: "can't be blank."
                  taken: "has already been taken."
                  invalid: "is not a valid email."
                password:
                  too_short: "is too short (minimum is %{count} characters)."
                password_confirmation:
                  confirmation: "doesn't match password."
  YAML

  # == Step 10: 커스텀 에러 페이지 =============================================
  # public/404.html, public/422.html, public/500.html
  # Tailwind CDN 또는 인라인 CSS (public/ 파일은 에셋 파이프라인 미사용)
  # ==========================================================================

  say_step 10, "커스텀 에러 페이지"

  error_page_style = <<~'STYLE'
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: system-ui, -apple-system, sans-serif; background-color: #f9fafb; color: #111; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 1rem; text-align: center; }
    .container { max-width: 28rem; }
    .code { font-size: 6rem; font-weight: 800; line-height: 1; margin-bottom: 1rem; }
    .message { font-size: 1.125rem; color: #4b5563; margin-bottom: 2rem; }
    .link { display: inline-block; padding: 0.75rem 1.5rem; background-color: #000; color: #fff; text-decoration: none; border-radius: 0.375rem; font-size: 0.875rem; font-weight: 500; }
    .link:hover { background-color: #333; }
  STYLE

  create_file "public/404.html", force: true do
    <<~HTML
      <!DOCTYPE html>
      <html lang="ko">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>404 - 페이지를 찾을 수 없습니다</title>
        <style>#{error_page_style}</style>
      </head>
      <body>
        <div class="container">
          <div class="code">404</div>
          <p class="message">찾으시는 페이지가 없습니다.</p>
          <a href="/" class="link">홈으로 돌아가기</a>
        </div>
      </body>
      </html>
    HTML
  end

  create_file "public/422.html", force: true do
    <<~HTML
      <!DOCTYPE html>
      <html lang="ko">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>422 - 처리할 수 없는 요청</title>
        <style>#{error_page_style}</style>
      </head>
      <body>
        <div class="container">
          <div class="code">422</div>
          <p class="message">요청을 처리할 수 없습니다.</p>
          <a href="/" class="link">홈으로 돌아가기</a>
        </div>
      </body>
      </html>
    HTML
  end

  create_file "public/500.html", force: true do
    <<~HTML
      <!DOCTYPE html>
      <html lang="ko">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>500 - 서버 오류</title>
        <style>#{error_page_style}</style>
      </head>
      <body>
        <div class="container">
          <div class="code">500</div>
          <p class="message">서버 오류가 발생했습니다.</p>
          <a href="/" class="link">홈으로 돌아가기</a>
        </div>
      </body>
      </html>
    HTML
  end

  create_file "public/403.html" do
    <<~HTML
      <!DOCTYPE html>
      <html lang="ko">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>403 - 접근 권한 없음</title>
        <style>#{error_page_style}</style>
      </head>
      <body>
        <div class="container">
          <div class="code">403</div>
          <p class="message">접근 권한이 없습니다.</p>
          <a href="/" class="link">홈으로 돌아가기</a>
        </div>
      </body>
      </html>
    HTML
  end

  # == Step 5 (계속): 레이아웃 업데이트 ========================================

  say_step "5b", "레이아웃 업데이트 및 Tailwind @source"

  # application.html.erb에 NavbarComponent + FlashComponent 렌더링 추가
  inject_into_file "app/views/layouts/application.html.erb",
    after: "<body>\n" do
    <<~'ERB'
        <%= render(NavbarComponent.new(user: Current.user)) %>
        <%= render(FlashComponent.new(flash: flash)) if flash.any? %>
    ERB
  end

  # Tailwind CSS v4 @source 디렉티브 추가
  # ViewComponent 파일의 Tailwind 클래스 스캐닝 명시적 보장
  # Tailwind v4는 자동 스캐닝하지만, @source로 확실히 포함시킴
  # 경로: app/assets/tailwind/application.css → ../../components = app/components
  inject_into_file "app/assets/tailwind/application.css",
    before: '@import "tailwindcss"' do
    <<~'CSS'
      @source "../../components";
    CSS
  end

  # -------------------------------------------------------------------------
  # Phase 4: Authorization, Admin & Seed Data
  # -------------------------------------------------------------------------
  # Steps: 7-admin (Admin namespace), 12 (Seed), 17 (Pundit/Pagy/Lograge)
  # Estimated: ~400 lines of actual content
  # -------------------------------------------------------------------------

  say_phase 4, "Authorization, Admin & Seed Data"

  # == Step 17: Pundit, Pagy, Lograge 초기 설정 ================================

  say_step 17, "Pundit, Pagy, Lograge 초기 설정"

  # Pundit 설치 — ApplicationPolicy 자동 생성 (app/policies/application_policy.rb)
  generate "pundit:install"

  # ApplicationController에 Pundit::Authorization include
  # Phase 3에서 동일 앵커로 rescue_from 주입 완료 → Phase 4 inject는 앞에 위치 (의도된 순서)
  inject_into_file "app/controllers/application_controller.rb",
    after: "  include Authentication\n" do
    "  include Pundit::Authorization\n"
  end

  # UserPolicy — PRD 2.2 인가 정책 기반
  # Role enum: { user: 0, admin: 1, super_admin: 2 } (Phase 2에서 정의)
  create_file "app/policies/user_policy.rb", <<~'RUBY'
    # frozen_string_literal: true

    class UserPolicy < ApplicationPolicy
      # 사용자 목록: 관리자만 접근
      def index?
        user.admin? || user.super_admin?
      end

      # 사용자 상세: 자기 자신 + 관리자
      def show?
        user == record || user.admin? || user.super_admin?
      end

      # 사용자 수정: 자기 자신 + 슈퍼관리자
      def update?
        user == record || user.super_admin?
      end

      # 역할 변경: 슈퍼관리자만
      def change_role?
        user.super_admin?
      end

      class Scope < ApplicationPolicy::Scope
        def resolve
          if user.admin? || user.super_admin?
            scope.all
          else
            scope.where(id: user.id)
          end
        end
      end
    end
  RUBY

  # Pagy 43+ 이니셜라이저 — Pagy.options API 사용 (Pagy::DEFAULT 아님)
  create_file "config/initializers/pagy.rb", <<~'RUBY'
    # frozen_string_literal: true

    # Pagy 43+ configuration
    # API 변경: Pagy::DEFAULT → Pagy.options, :items → :limit, :size → :slots (Integer)
    Pagy.options[:limit] = 25
    Pagy.options[:slots] = 7
    Pagy.options[:page_key] = "page"

    # 런타임 설정 변경 방지
    Pagy.options.freeze
  RUBY

  # ApplicationController에 Pagy::Method include (Pagy 43+ API: Backend → Method)
  inject_into_file "app/controllers/application_controller.rb",
    after: "  include Pundit::Authorization\n" do
    "  include Pagy::Method\n"
  end

  # Lograge 0.14 — 구조화된 JSON 로그 출력 (PRD 2.9)
  # ROADMAP 4-4 결정: production 환경만 활성화 + ENV 플래그
  create_file "config/initializers/lograge.rb", <<~'RUBY'
    # frozen_string_literal: true

    Rails.application.configure do
      # production 환경 기본 활성화, 다른 환경은 ENV 플래그로 활성화 가능
      config.lograge.enabled = Rails.env.production? || ENV["LOGRAGE_ENABLED"].present?

      # JSON 포맷 — 구조화된 로그 분석에 적합
      config.lograge.formatter = Lograge::Formatters::Json.new

      # 요청별 커스텀 페이로드: 사용자 ID, 요청 ID, 클라이언트 IP
      config.lograge.custom_payload do |controller|
        {
          user_id: Current.user&.id,
          request_id: controller.request.request_id,
          remote_ip: controller.request.remote_ip
        }
      end

      # Health check 엔드포인트 로그 제외 (노이즈 감소)
      # /up (liveness)은 Rails::HealthController이므로 별도 제외 불필요
      config.lograge.ignore_actions = [ "HealthController#show" ]
    end
  RUBY

  # == Step 7 (Admin): Admin 네임스페이스 ======================================

  say_step "7-admin", "Admin 네임스페이스"

  # Admin::BaseController — before_action으로 관리자 역할 체크 (PRD 2.4)
  # Pundit::NotAuthorizedError → ApplicationController rescue_from → 403
  create_file "app/controllers/admin/base_controller.rb", <<~'RUBY'
    # frozen_string_literal: true

    module Admin
      class BaseController < ApplicationController
        before_action :require_admin
        layout "admin"

        private

        # admin? 또는 super_admin? 역할만 접근 허용
        # Current.user nil → safe navigation → false → 403
        def require_admin
          raise Pundit::NotAuthorizedError unless Current.user&.admin? || Current.user&.super_admin?
        end
      end
    end
  RUBY

  # Admin 레이아웃 — 사이드바 네비게이션 + FlashComponent 재활용 (Tailwind v4)
  create_file "app/views/layouts/admin.html.erb", <<~'ERB'
    <!DOCTYPE html>
    <html lang="ko">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title><%= content_for(:title) || t("admin.title") %> | Admin</title>
      <%= csrf_meta_tags %>
      <%= csp_meta_tag %>
      <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
      <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
      <%= javascript_importmap_tags %>
    </head>
    <body class="bg-gray-100 min-h-screen">
      <div class="flex min-h-screen">
        <%# 사이드바 %>
        <aside class="w-64 bg-gray-800 text-white flex-shrink-0">
          <div class="p-6">
            <h1 class="text-xl font-bold"><%= t("admin.sidebar.title") %></h1>
          </div>
          <nav class="mt-2">
            <%= link_to t("admin.sidebar.dashboard"), admin_root_path,
                class: "block px-6 py-3 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors" %>
            <%= link_to t("admin.sidebar.users"), admin_users_path,
                class: "block px-6 py-3 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors" %>
          </nav>
          <div class="mt-auto p-6 border-t border-gray-700">
            <%= link_to t("admin.sidebar.back_to_site"), root_path,
                class: "text-sm text-gray-400 hover:text-white" %>
          </div>
        </aside>

        <%# 메인 콘텐츠 %>
        <main class="flex-1 p-8">
          <%= render(FlashComponent.new(flash: flash)) if flash.any? %>
          <%= yield %>
        </main>
      </div>
    </body>
    </html>
  ERB

  # Admin 라우트 — /admin/* 네임스페이스
  route <<~'RUBY'
    namespace :admin do
      root "dashboard#show"
      resources :users, only: [ :index, :show ]
    end
  RUBY

  # Admin::DashboardController — 통계 대시보드 (사용자 수, 최근 가입)
  create_file "app/controllers/admin/dashboard_controller.rb", <<~'RUBY'
    # frozen_string_literal: true

    module Admin
      class DashboardController < BaseController
        def show
          @user_count = User.count
          @recent_users = User.order(created_at: :desc).limit(5)
        end
      end
    end
  RUBY

  # Admin::UsersController — 사용자 목록 (Pagy + policy_scope) + 상세
  create_file "app/controllers/admin/users_controller.rb", <<~'RUBY'
    # frozen_string_literal: true

    module Admin
      class UsersController < BaseController
        def index
          @pagy, @users = pagy(policy_scope(User))
        end

        def show
          @user = User.find(params[:id])
          authorize @user
        end
      end
    end
  RUBY

  # Admin 대시보드 뷰 — 통계 카드 (CardComponent 재활용)
  create_file "app/views/admin/dashboard/show.html.erb", <<~'ERB'
    <% content_for(:title) { t("admin.dashboard.title") } %>

    <h1 class="text-2xl font-bold text-gray-900 mb-8"><%= t("admin.dashboard.title") %></h1>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
      <%= render(CardComponent.new) do |card| %>
        <% card.with_title { t("admin.dashboard.total_users") } %>
        <% card.with_body do %>
          <p class="text-3xl font-bold text-blue-600"><%= @user_count %></p>
        <% end %>
      <% end %>
    </div>

    <h2 class="text-xl font-semibold text-gray-900 mb-4"><%= t("admin.dashboard.recent_users") %></h2>

    <div class="bg-white shadow rounded-lg overflow-hidden">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"><%= t("admin.users.email") %></th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"><%= t("admin.users.role") %></th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"><%= t("admin.users.created_at") %></th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <% @recent_users.each do |user| %>
            <tr>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                <%= link_to user.email_address, admin_user_path(user), class: "text-blue-600 hover:underline" %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <%= render(BadgeComponent.new(label: user.role.humanize, variant: user.super_admin? ? :error : user.admin? ? :warning : :info)) %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= l(user.created_at, format: :short) %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
  ERB

  # Admin 사용자 목록 뷰 — 테이블 + PaginationComponent
  create_file "app/views/admin/users/index.html.erb", <<~'ERB'
    <% content_for(:title) { t("admin.users.title") } %>

    <h1 class="text-2xl font-bold text-gray-900 mb-8"><%= t("admin.users.title") %></h1>

    <div class="bg-white shadow rounded-lg overflow-hidden">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"><%= t("admin.users.email") %></th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"><%= t("admin.users.role") %></th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"><%= t("admin.users.created_at") %></th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <% @users.each do |user| %>
            <tr>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                <%= link_to user.email_address, admin_user_path(user), class: "text-blue-600 hover:underline" %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <%= render(BadgeComponent.new(label: user.role.humanize, variant: user.super_admin? ? :error : user.admin? ? :warning : :info)) %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= l(user.created_at, format: :short) %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>

    <%= render(PaginationComponent.new(pagy: @pagy)) %>
  ERB

  # Admin 사용자 상세 뷰 — BadgeComponent로 역할 표시
  create_file "app/views/admin/users/show.html.erb", <<~'ERB'
    <% content_for(:title) { @user.email_address } %>

    <div class="mb-6">
      <%= link_to t("admin.users.back_to_list"), admin_users_path, class: "text-blue-600 hover:underline text-sm" %>
    </div>

    <div class="bg-white shadow rounded-lg p-6">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-gray-900"><%= @user.email_address %></h1>
        <%= render(BadgeComponent.new(label: @user.role.humanize, variant: @user.super_admin? ? :error : @user.admin? ? :warning : :info)) %>
      </div>

      <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <dt class="text-sm font-medium text-gray-500"><%= t("admin.users.email") %></dt>
          <dd class="mt-1 text-sm text-gray-900"><%= @user.email_address %></dd>
        </div>
        <div>
          <dt class="text-sm font-medium text-gray-500"><%= t("admin.users.role") %></dt>
          <dd class="mt-1 text-sm text-gray-900"><%= @user.role.humanize %></dd>
        </div>
        <div>
          <dt class="text-sm font-medium text-gray-500"><%= t("admin.users.created_at") %></dt>
          <dd class="mt-1 text-sm text-gray-900"><%= l(@user.created_at, format: :long) %></dd>
        </div>
        <div>
          <dt class="text-sm font-medium text-gray-500"><%= t("admin.users.updated_at") %></dt>
          <dd class="mt-1 text-sm text-gray-900"><%= l(@user.updated_at, format: :long) %></dd>
        </div>
      </dl>
    </div>
  ERB

  # == Step 12: 시드 데이터 ====================================================

  say_step 12, "시드 데이터"

  # seeds.rb 진입점 — db/seeds/ 하위 파일을 알파벳 순 로드 (PRD 2.10)
  # admin_user.rb(a) → sample_data.rb(s) 순서로 실행
  create_file "db/seeds.rb", force: true do
    <<~'RUBY'
      # frozen_string_literal: true

      # db/seeds/ 디렉토리 하위 파일을 알파벳 순서대로 로드
      Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| load f }
    RUBY
  end

  # 관리자 시드 — 환경변수로 비밀번호 주입 (보안)
  # Rails 8 auth generator: email_address 칼럼 사용 (email 아님)
  create_file "db/seeds/admin_user.rb", <<~'RUBY'
    # frozen_string_literal: true

    admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
    admin_password = ENV.fetch("ADMIN_PASSWORD", "password123")

    User.find_or_create_by!(email_address: admin_email) do |user|
      user.password = admin_password
      user.password_confirmation = admin_password
      user.role = :super_admin
    end

    puts "Admin user seeded: #{admin_email}"
  RUBY

  # 개발용 샘플 데이터 — development 환경에서만 실행
  create_file "db/seeds/sample_data.rb", <<~'RUBY'
    # frozen_string_literal: true

    return unless Rails.env.development?

    10.times do |i|
      User.find_or_create_by!(email_address: "user#{i + 1}@example.com") do |user|
        user.password = "password123"
        user.password_confirmation = "password123"
        user.role = :user
      end
    end

    puts "Sample data seeded: #{User.count} users total"
  RUBY

  # -------------------------------------------------------------------------
  # Phase 5: Infrastructure, CI/CD & Deployment
  # -------------------------------------------------------------------------
  # Steps: 13 (Docker), 15 (CI), 16 (Kamal), 19 (Migration)
  # Estimated: ~300 lines of actual content
  #
  # NOTE: Solid Stack은 Rails 8.1 rails new에서 자동 설치됨.
  # solid_queue:install, solid_cache:install, solid_cable:install 별도 실행 불필요.
  # 단, development/test 환경 설정은 추가 필요:
  #   - config/environments/development.rb에 queue_adapter, cache_store 설정
  #   - cable.yml은 solid_cable:install이 force:true로 덮어씀 (R7 리스크)
  #     → 커스텀 cable.yml 설정은 install 이후에 적용해야 함
  # -------------------------------------------------------------------------

  say_phase 5, "Infrastructure, CI/CD & Deployment"

  # == Solid Stack 환경 설정 (Step 19 준비) ====================================
  # production.rb는 solid_queue:install, solid_cache:install이 자동 수정
  # development.rb에 멀티DB connects_to 설정 추가 (없을 경우)
  # cable.yml 재생성: solid_cable:install이 force:true로 생성한 것을 최종 형태로 교체
  #   - development도 solid_cable 사용 (멀티DB 일관성)
  # ==========================================================================

  say_step "19-prep", "Solid Stack 환경 설정"

  # cable.yml — 전 환경에서 solid_cable 사용 (멀티DB cable DB 활용)
  # solid_cable:install이 force:true로 생성하므로 최종 형태로 재교체 (R7 리스크 해결)
  create_file "config/cable.yml", force: true do
    <<~'YAML'
      # Action Cable Configuration
      # SolidCable: DB-backed adapter (no Redis required)
      # Database: cable DB (config/database.yml → cable section)

      development:
        adapter: solid_cable
        connects_to:
          database:
            writing: cable
        polling_interval: 0.1.seconds

      test:
        adapter: test

      production:
        adapter: solid_cable
        connects_to:
          database:
            writing: cable
        polling_interval: 0.1.seconds
        message_retention: 1.day
    YAML
  end

  # Development: SolidQueue + SolidCache 멀티DB 연결 설정
  # Rails 8.1 rails new가 이미 추가했을 수 있으므로 조건부 주입
  dev_env_content = File.read("config/environments/development.rb")

  unless dev_env_content.include?("solid_queue")
    inject_into_file "config/environments/development.rb",
      after: "Rails.application.configure do\n" do
      <<~'RUBY'
        # Solid Stack: Background jobs via SolidQueue (multi-DB)
        config.active_job.queue_adapter = :solid_queue
        config.solid_queue.connects_to = { database: { writing: :queue } }

      RUBY
    end
  end

  unless dev_env_content.include?("solid_cache_store")
    inject_into_file "config/environments/development.rb",
      after: "Rails.application.configure do\n" do
      <<~'RUBY'
        # Solid Stack: SolidCache store (toggle: bin/rails dev:cache)
        config.cache_store = :solid_cache_store

      RUBY
    end
  end

  # == 환경별 설정 보강 ========================================================
  # CSP initializer — PRD 3.7 보안 요구사항
  # .gitignore, .dockerignore 정리
  # ==========================================================================

  say_step "5-env", "환경별 설정 정리 (CSP, .gitignore)"

  create_file "config/initializers/content_security_policy.rb", force: true do
    <<~'RUBY'
      # Content Security Policy (CSP) — PRD 3.7
      # https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
      #
      # Tailwind CSS v4 + Import Maps + Turbo/Stimulus 호환 설정
      # 프로덕션 배포 전 report_only → enforce 전환 권장

      Rails.application.configure do
        config.content_security_policy do |policy|
          policy.default_src :self
          policy.font_src    :self, "https://fonts.gstatic.com"
          policy.img_src     :self, :data, :https
          policy.object_src  :none
          policy.script_src  :self, :unsafe_inline
          policy.style_src   :self, :unsafe_inline
          policy.connect_src :self
        end

        # Report violations without blocking (switch to false for enforcement)
        config.content_security_policy_report_only = true
      end
    RUBY
  end

  # .gitignore에 .kamal/secrets 추가
  gitignore_content = File.read(".gitignore")
  unless gitignore_content.include?(".kamal/secrets")
    append_to_file ".gitignore", <<~'GITIGNORE'

      # Kamal secrets (DO NOT COMMIT)
      .kamal/secrets
      .kamal/secrets-*
    GITIGNORE
  end

  # .dockerignore — .kamal/secrets 추가
  if File.exist?(".dockerignore") && !File.read(".dockerignore").include?(".kamal/secrets")
    append_to_file ".dockerignore", <<~'IGNORE'

      # Kamal secrets
      .kamal/secrets
      .kamal/secrets-*
    IGNORE
  end

  # == Step 13: Docker 파일 ====================================================
  # Dockerfile: Rails 8 기본 멀티스테이지 빌드 (rails new가 이미 생성) — 수정 불필요
  # docker-compose.yml: PostgreSQL 17 DB-only 서비스 (rails new 미생성, 새로 생성)
  # ==========================================================================

  say_step 13, "Docker 파일"

  # docker-compose.yml — PRD 3.4: DB만 Docker, 앱은 로컬 실행 (bin/dev)
  create_file "docker-compose.yml", force: true do
    <<~YAML
      # Docker Compose — Local Development (DB Only)
      # Usage: docker-compose up db
      # PRD 3.4: PostgreSQL만 Docker, Rails 앱은 bin/dev로 로컬 실행

      services:
        db:
          image: postgres:17
          container_name: #{app_name}_db
          restart: unless-stopped
          environment:
            POSTGRES_USER: postgres
            POSTGRES_PASSWORD: password
          ports:
            - "5432:5432"
          volumes:
            - postgres_data:/var/lib/postgresql/data
          healthcheck:
            test: ["CMD-SHELL", "pg_isready -U postgres"]
            interval: 10s
            timeout: 5s
            retries: 5

      volumes:
        postgres_data:
    YAML
  end

  # == Step 15: GitHub Actions CI ==============================================
  # PRD 3.5 — 7단계 파이프라인
  # PostgreSQL 17 서비스 컨테이너, 멀티DB 4개, headless Chrome
  # ==========================================================================

  say_step 15, "GitHub Actions CI"

  create_file ".github/workflows/ci.yml" do
    <<~'YAML'
      name: CI

      on:
        push:
          branches: [main]
        pull_request:

      jobs:
        test:
          runs-on: ubuntu-latest

          env:
            RAILS_ENV: test
            PGHOST: localhost
            PGUSER: postgres
            PGPASSWORD: postgres

          services:
            postgres:
              image: postgres:17
              env:
                POSTGRES_PASSWORD: postgres
              options: >-
                --health-cmd pg_isready
                --health-interval 10s
                --health-timeout 5s
                --health-retries 5
              ports:
                - 5432:5432

          steps:
            # Step 1: Ruby setup + dependencies (bundler-cache auto-caches gems)
            - uses: actions/checkout@v4

            - uses: ruby/setup-ruby@v1
              with:
                ruby-version: '3.4'
                bundler-cache: true

            - name: Install system dependencies
              run: sudo apt-get update && sudo apt-get install -y libpq-dev

            # Step 2: Precompile assets (Tailwind CSS v4 + Propshaft)
            - name: Precompile assets
              run: bin/rails assets:precompile

            # Step 3: DB setup (creates 4 logical databases: primary, queue, cache, cable)
            - name: Setup databases
              run: bin/rails db:prepare

            # Step 4: RuboCop lint
            - name: RuboCop
              run: bundle exec rubocop

            # Step 5: Brakeman security scan
            - name: Brakeman
              run: bundle exec brakeman --no-pager

            # Step 6: Unit & Integration tests (Minitest)
            - name: Run tests
              run: bin/rails test

            # Step 7: System tests (Capybara + headless Chrome)
            - name: Run system tests
              run: bin/rails test:system
              env:
                CHROME_NO_SANDBOX: "true"
    YAML
  end

  # == Step 16: Kamal 2 배포 설정 ==============================================
  # deploy.yml + .kamal/secrets + .kamal/hooks/pre-deploy
  # 프록시 아키텍처: kamal-proxy → Thruster → Puma
  # SSL, error_pages_path는 주석으로 포함 (PRD 4.1)
  # ==========================================================================

  say_step 16, "Kamal 2 배포 설정"

  # deploy.yml — Kamal 2.10 배포 설정 (PRD 4.1, TSD 5.1)
  create_file "config/deploy.yml", force: true do
    <<~YAML
      # Kamal 2 Deployment Configuration
      # Docs: https://kamal-deploy.org/docs/configuration/overview/
      #
      # Proxy architecture: kamal-proxy → Thruster → Puma
      #   kamal-proxy: SSL termination, HTTP/2, zero-downtime routing (host level)
      #   Thruster:    gzip compression, asset caching, X-Sendfile (container level)
      #   Puma:        Ruby app server (multi-worker, multi-thread)
      #
      # Setup:
      #   1. Edit server IPs, registry, and domain below
      #   2. Configure .kamal/secrets with real credentials
      #   3. Run: kamal setup

      service: #{app_name}
      image: #{app_name}

      servers:
        web:
          hosts:
            - YOUR_SERVER_IP
        job:
          hosts:
            - YOUR_SERVER_IP
          cmd: bundle exec jobs

      registry:
        server: ghcr.io
        username:
          - KAMAL_REGISTRY_USERNAME
        password:
          - KAMAL_REGISTRY_PASSWORD

      env:
        clear:
          RAILS_ENV: production
          RAILS_LOG_TO_STDOUT: "true"
        secret:
          - RAILS_MASTER_KEY
          - DATABASE_URL

      proxy:
        host: YOUR_DOMAIN
        app_port: 3000
        healthcheck:
          path: /up
          interval: 3
          timeout: 3
        # SSL: Uncomment for automatic Let's Encrypt (single server)
        # ssl: true
        # ssl_redirect: true

      # Error pages: kamal-proxy serves these directly from public/
      # Uncomment after verifying custom error pages exist
      # error_pages_path: public

      # Asset bridging for zero-downtime deploys
      asset_path: /app/public/assets

      # Deployment behavior
      primary_role: web
      readiness_delay: 7
      deploy_timeout: 60
      drain_timeout: 30

      # SSH configuration
      ssh:
        user: deploy
        # keys:
        #   - ~/.ssh/id_rsa

      # Logging
      logging:
        driver: json-file
        options:
          max-size: 100m
          max-file: "3"
    YAML
  end

  # .kamal/secrets — 환경변수 주입 (PRD 4.1)
  create_file ".kamal/secrets", force: true do
    <<~'SECRETS'
      # Kamal Secrets — DO NOT COMMIT THIS FILE
      # Copy from .kamal/secrets.example and fill in real values
      #
      # Format: KEY=value (dotenv format)
      # Supports: variable substitution ($VAR), command substitution ($(cmd))

      KAMAL_REGISTRY_USERNAME=$KAMAL_REGISTRY_USERNAME
      KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD
      RAILS_MASTER_KEY=$(cat config/master.key)
      DATABASE_URL=$DATABASE_URL
    SECRETS
  end

  # .kamal/secrets.example — 커밋 가능한 템플릿
  create_file ".kamal/secrets.example" do
    <<~'SECRETS'
      # Kamal Secrets Template
      # Copy to .kamal/secrets and fill in real values
      # See: https://kamal-deploy.org/docs/configuration/environment-variables/

      KAMAL_REGISTRY_USERNAME=your_registry_username
      KAMAL_REGISTRY_PASSWORD=your_registry_password
      RAILS_MASTER_KEY=your_master_key
      DATABASE_URL=postgresql://user:pass@host:5432/dbname
    SECRETS
  end

  # .kamal/hooks/pre-deploy — 배포 전 검증 (PRD 4.1)
  create_file ".kamal/hooks/pre-deploy" do
    <<~'BASH'
      #!/bin/bash
      set -e

      echo "Running pre-deploy checks..."

      # Verify no uncommitted changes
      if [ -n "$(git status --porcelain)" ]; then
        echo "ERROR: Uncommitted changes detected. Commit or stash before deploying."
        exit 1
      fi

      echo "Pre-deploy checks passed."
    BASH
  end

  chmod ".kamal/hooks/pre-deploy", 0755

  # == Step 19: 초기 마이그레이션 실행 =========================================
  # rails db:prepare가 4개 DB 모두 처리 (Phase 0 검증 완료)
  # DB 미기동 시 안내 메시지 표시
  # ==========================================================================

  say_step 19, "초기 마이그레이션 실행"

  say "  Creating databases and running migrations (4 DBs: primary, queue, cache, cable)...", :cyan
  say "  NOTE: PostgreSQL must be running. Start with: docker-compose up db", :yellow
  rails_command "db:prepare", abort_on_failure: false
  say ""
  say "  If db:prepare failed, run manually after starting PostgreSQL:", :yellow
  say "    docker-compose up -d db && bin/rails db:prepare", :yellow

  # -------------------------------------------------------------------------
  # Phase 6: Documentation & Integration
  # -------------------------------------------------------------------------
  # Steps: 20 (README)
  # Estimated: ~200 lines of actual content
  # -------------------------------------------------------------------------

  say_phase 6, "Documentation & Integration"

  # == Step 20: README.md 생성 =================================================
  # PRD 5.3 정의 항목:
  #   - 프로젝트 소개 / 기술 스택
  #   - 로컬 개발 환경 셋업 가이드
  #   - ViewComponent 사용법 / 예시
  #   - 테스트 실행 방법
  #   - Kamal 2 배포 가이드
  #   - 디렉토리 구조 설명
  #   - 선택적 기능 활성화 가이드
  #   - 스케일 전환 가이드 (Postgres-only → Redis)
  #   - 프론트엔드 확장 가이드 (Import Maps → jsbundling)
  #   - Kamal 배포 체크리스트
  # ==========================================================================

  say_step 20, "README.md 생성"

  create_file "README.md", force: true do
    readme_content = <<~'MARKDOWN'
      # APP_NAME_PLACEHOLDER — Rails 8 Production Boilerplate

      A production-ready Rails 8 application template delivered as a single `template.rb` file. Run one command to scaffold a complete, opinionated full-stack application with authentication, authorization, UI components, background jobs, and a deployment pipeline — all without Node.js.

      ```bash
      rails new my_app -d postgresql -c tailwind -m path/to/template.rb
      ```

      ---

      ## Table of Contents

      - [A. Project Introduction & Technology Stack](#a-project-introduction--technology-stack)
      - [B. Local Development Setup](#b-local-development-setup)
      - [C. UI Components (ViewComponent)](#c-ui-components-viewcomponent)
      - [D. Testing](#d-testing)
      - [E. Deployment (Kamal 2)](#e-deployment-kamal-2)
      - [F. Directory Structure](#f-directory-structure)
      - [G. Optional Features Guide](#g-optional-features-guide)
      - [H. Scaling Guide](#h-scaling-guide)
      - [I. Frontend Expansion Guide](#i-frontend-expansion-guide)
      - [J. Kamal Deployment Checklist](#j-kamal-deployment-checklist)

      ---

      ## A. Project Introduction & Technology Stack

      APP_NAME_PLACEHOLDER applies a "Built-in First" philosophy: every architectural choice maximizes Rails 8 native capabilities. Only 4 external gems are added beyond Rails defaults (pundit, pagy, lograge, view_component). There is no Node.js, no webpack, and no build step.

      ### Technology Stack

      | Layer | Choice | Version |
      |---|---|---|
      | Ruby | MRI | ~> 3.4 |
      | Rails | Full-stack | ~> 8.1 |
      | Database | PostgreSQL | 17.x |
      | Frontend | Hotwire (Turbo + Stimulus) | turbo-rails ~> 2.0, stimulus-rails ~> 1.3 |
      | CSS | Tailwind CSS v4 | tailwindcss-rails ~> 4.2 |
      | Asset Pipeline | Propshaft + Import Maps | propshaft ~> 1.1, importmap-rails ~> 2.1 |
      | Background Jobs | SolidQueue | ~> 1.3 |
      | Caching | SolidCache | ~> 1.0 |
      | WebSocket | SolidCable | ~> 3.0 |
      | Auth | Rails 8 built-in + custom sign-up | bcrypt ~> 3.1 |
      | Authorization | Pundit | ~> 2.5 |
      | Pagination | Pagy | ~> 43.0 |
      | Logging | Lograge | ~> 0.14 |
      | UI Components | ViewComponent | ~> 4.4 |
      | Deployment | Kamal 2 | ~> 2.10 |
      | Web Server | Puma behind Thruster | puma ~> 6.5, thruster ~> 0.1 |

      ### Key Architecture Principles

      **Zero-Build JavaScript.** Tailwind CSS v4 uses a standalone Rust-based CLI (no Node.js required). Import Maps serve ES modules directly from the browser. Propshaft replaces Sprockets for straightforward asset serving.

      **Solid Stack (no Redis).** Background jobs (SolidQueue), caching (SolidCache), and WebSocket (SolidCable) are all database-backed, running on the same PostgreSQL server as the application. No separate infrastructure is required.

      **Proxy Architecture.**

      ```
      [Internet] → [kamal-proxy] → [Thruster] → [Puma]
                     SSL/HTTP2       gzip           Rails app
                     routing         asset caching
                     error pages     X-Sendfile
      ```

      ---

      ## B. Local Development Setup

      ### Prerequisites

      - Ruby 3.4 or later (managed via rbenv, asdf, or mise)
      - Docker (for PostgreSQL 17 only — the Rails app runs natively)
      - Bundler 2.x

      ### Three-Step Setup

      ```bash
      # Step 1: Start PostgreSQL 17 via Docker (DB only)
      docker-compose up db -d

      # Step 2: Install dependencies, create databases, run migrations, seed data
      bin/setup

      # Step 3: Start the development server
      bin/dev
      ```

      `bin/dev` uses Foreman to run three processes in parallel via `Procfile.dev`:

      | Process | Command | Description |
      |---|---|---|
      | `web` | `rails server -p 3000` | Rails application server |
      | `css` | Tailwind watcher | Rebuilds CSS on file changes |
      | `jobs` | SolidQueue worker | Processes background jobs |

      > **Note (Hybrid Docker):** Only PostgreSQL runs inside Docker. The Rails app itself runs natively on your machine via `bin/dev`. This avoids Docker networking overhead and makes debugging straightforward.

      ### Multi-Database Setup

      The template configures four logical databases on a single PostgreSQL server. Each maps to a separate Rails database connection role:

      | Database name | Purpose | Rails connection |
      |---|---|---|
      | `app_primary` | Application data | `primary` (default) |
      | `app_cache` | SolidCache storage | `cache` |
      | `app_queue` | SolidQueue job storage | `queue` |
      | `app_cable` | SolidCable pub/sub | `cable` |

      Each database has its own migration directory (`db/migrate/`, `db/cache_migrate/`, `db/queue_migrate/`, `db/cable_migrate/`) and is managed independently via Rails multi-DB conventions.

      ---

      ## C. UI Components (ViewComponent)

      Ten pre-built ViewComponents are included under `app/components/`. All components inherit from `ApplicationComponent < ViewComponent::Base` and use Tailwind CSS utility classes directly — no external UI library dependency.

      ### 1. ButtonComponent

      Renders a `<button>` or `<a>` tag with three visual variants.

      **Variants:** `primary` (indigo), `secondary` (white/ring), `danger` (red)

      ```erb
      <%= render ButtonComponent.new(variant: :primary) do %>
        Save Changes
      <% end %>

      <%= render ButtonComponent.new(variant: :danger, tag: :a, href: delete_path) do %>
        Delete
      <% end %>
      ```

      ### 2. CardComponent

      A container component with optional `title`, `body`, and `footer` slots.

      **Variants:** `default` (white with shadow), `bordered` (white with border)

      ```erb
      <%= render CardComponent.new(variant: :bordered) do |c| %>
        <% c.with_title { "Card Title" } %>
        <% c.with_body  { "Card content goes here." } %>
      <% end %>
      ```

      ### 3. BadgeComponent

      A compact inline label for status indicators. Requires a `label:` argument.

      **Variants:** `info` (blue), `success` (green), `warning` (yellow), `error` (red)

      ```erb
      <%= render BadgeComponent.new(variant: :success, label: "Active") %>
      <%= render BadgeComponent.new(variant: :warning, label: "Pending") %>
      ```

      ### 4. FlashComponent

      Renders all Rails flash messages (notice, alert, error) with auto-dismiss via the `flash` Stimulus controller. Skips rendering when the flash hash is empty.

      ```erb
      <%# In application layout — pass the flash hash directly %>
      <%= render FlashComponent.new(flash: flash) %>
      ```

      ### 5. ModalComponent

      A dialog overlay managed by the `modal` Stimulus controller. Supports a `trigger` slot (the element that opens the modal) and a `body` slot (modal content). Closes on backdrop click.

      ```erb
      <%= render ModalComponent.new do |m| %>
        <% m.with_trigger { render ButtonComponent.new { "Open Modal" } } %>
        <% m.with_body    { "Modal content here." } %>
      <% end %>
      ```

      ### 6. DropdownComponent

      A relative-positioned dropdown menu managed by the `dropdown` Stimulus controller. Accepts a `trigger` slot and multiple `items` slots.

      ```erb
      <%= render DropdownComponent.new do |d| %>
        <% d.with_trigger { "Menu" } %>
        <% d.with_items   { link_to "Profile", profile_path, role: "menuitem" } %>
        <% d.with_items   { link_to "Sign out", session_path, data: { turbo_method: :delete }, role: "menuitem" } %>
      <% end %>
      ```

      ### 7. FormFieldComponent

      Wraps a `form_with` field with a label, styled input, and inline validation error messages. Applies error ring styles automatically when `error_messages` are present.

      **Input types:** `:text` (default), `:email`, `:password`, `:select`, `:textarea`

      ```erb
      <%= form_with model: @user do |f| %>
        <%= render FormFieldComponent.new(
              form: f, field_name: :email, type: :email,
              label: "Email address",
              error_messages: @user.errors[:email],
              required: true) %>
      <% end %>
      ```

      ### 8. EmptyStateComponent

      A centered empty-state display with an optional `icon` slot and `action` slot (for a CTA button).

      ```erb
      <%= render EmptyStateComponent.new(message: "No records found.") do |e| %>
        <% e.with_action { render ButtonComponent.new { "Create your first record" } } %>
      <% end %>
      ```

      ### 9. PaginationComponent

      Renders a Pagy navigation bar. Skips rendering automatically when there is only one page (`pagy.pages <= 1`).

      ```erb
      <%# Controller: @pagy, @records = pagy(Record.all) %>
      <%= render PaginationComponent.new(pagy: @pagy) %>
      ```

      ### 10. NavbarComponent

      A responsive navigation bar with desktop links and a mobile hamburger menu, managed by the `navbar` Stimulus controller. Conditionally renders authenticated vs. unauthenticated links based on the `user:` argument.

      ```erb
      <%# In application layout %>
      <%= render NavbarComponent.new(user: Current.user) %>
      ```

      ---

      ## D. Testing

      The template configures Minitest (Rails default) with Capybara and headless Chrome for system tests.

      ### Running Tests

      ```bash
      # All unit and integration tests
      bin/rails test

      # System tests (Capybara + headless Chrome)
      bin/rails test:system

      # Single test file
      bin/rails test test/models/user_test.rb

      # Single test by line number
      bin/rails test test/models/user_test.rb:42
      ```

      ### Test Organization

      | Directory | Contents |
      |---|---|
      | `test/models/` | Model unit tests |
      | `test/policies/` | Pundit policy tests |
      | `test/components/` | ViewComponent unit tests |
      | `test/integration/` | Controller and request integration tests |
      | `test/system/` | End-to-end browser tests (Capybara) |

      ### Code Quality

      ```bash
      # Lint with rubocop-rails-omakase style guide
      bundle exec rubocop

      # Static security analysis
      bundle exec brakeman
      ```

      > **Note:** System tests require Google Chrome installed locally. The Selenium WebDriver (`~> 4.27`) manages the headless Chrome session.

      ---

      ## E. Deployment (Kamal 2)

      ### Proxy Architecture

      ```
      [Internet] → [kamal-proxy] → [Thruster] → [Puma]
                     SSL/HTTP2       gzip           Rails app
                     routing         asset caching
                     error pages     X-Sendfile
      ```

      **kamal-proxy** handles SSL termination, HTTP/2, and zero-downtime routing at the host level. **Thruster** runs inside the container and handles gzip compression, asset caching, and `X-Sendfile`. **Puma** serves the Rails application.

      ### Configuration Files

      | File | Purpose |
      |---|---|
      | `config/deploy.yml` | Main Kamal deployment configuration |
      | `.kamal/secrets` | Runtime secrets (not committed to git) |
      | `.kamal/secrets.example` | Template for secrets — commit this |
      | `.kamal/hooks/pre-deploy` | Pre-deployment checks (clean git state) |

      ### Deployment Commands

      ```bash
      # First-time server setup (provisions server, pulls image, starts containers)
      kamal setup

      # Deploy a new release
      kamal deploy

      # Stream application logs
      kamal app logs

      # Open a Rails console on the remote server
      kamal app exec --interactive --reuse "bin/rails console"

      # Roll back to the previous release
      kamal rollback
      ```

      ### Key deploy.yml Settings

      The generated `config/deploy.yml` includes two server roles:

      - **web** — Rails application (served via Thruster + Puma on port 3000)
      - **job** — SolidQueue worker (`bundle exec jobs`)

      Both roles can point to the same server IP for single-server deployments.

      ```yaml
      proxy:
        host: YOUR_DOMAIN
        app_port: 3000
        healthcheck:
          path: /up
          interval: 3
          timeout: 3
        # SSL: Uncomment for automatic Let's Encrypt (single server)
        # ssl: true
        # ssl_redirect: true
      ```

      ### Health Checks

      | Endpoint | Type | Description |
      |---|---|---|
      | `/up` | Liveness | Rails built-in; returns 200 when the app process is running |
      | `/health` | Readiness | Custom endpoint; performs a database connectivity check |

      > **SSL Note:** Automatic Let's Encrypt SSL is supported by kamal-proxy but is commented out in the generated config. Uncomment `ssl: true` and `ssl_redirect: true` in `config/deploy.yml` after confirming your domain's DNS resolves to the server IP.

      ---

      ## F. Directory Structure

      ```
      my_app/
      ├── app/
      │   ├── components/              # ViewComponent (10 components)
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
      │   │   ├── admin/               # Admin namespace (Pundit role checks)
      │   │   ├── application_controller.rb
      │   │   ├── registrations_controller.rb   # Custom sign-up
      │   │   ├── sessions_controller.rb        # Rails 8 auth generator
      │   │   └── passwords_controller.rb       # Rails 8 auth generator
      │   ├── javascript/
      │   │   └── controllers/         # Stimulus controllers
      │   │       ├── flash_controller.js
      │   │       ├── modal_controller.js
      │   │       ├── dropdown_controller.js
      │   │       └── navbar_controller.js
      │   ├── models/
      │   │   ├── current.rb
      │   │   └── user.rb              # Role enum, password validation
      │   ├── policies/                # Pundit authorization policies
      │   │   ├── application_policy.rb
      │   │   └── admin/
      │   └── views/
      │       ├── layouts/
      │       └── components/          # ViewComponent ERB templates
      ├── config/
      │   ├── database.yml             # Multi-DB (primary/cache/queue/cable)
      │   ├── deploy.yml               # Kamal 2 deployment configuration
      │   ├── initializers/
      │   │   ├── pagy.rb
      │   │   ├── pundit.rb
      │   │   └── lograge.rb
      │   └── locales/
      │       ├── defaults/            # General UI translations (ko.yml, en.yml)
      │       └── models/              # Model attribute translations
      ├── db/
      │   ├── migrate/                 # Primary database migrations
      │   ├── cache_migrate/           # SolidCache schema migrations
      │   ├── queue_migrate/           # SolidQueue schema migrations
      │   ├── cable_migrate/           # SolidCable schema migrations
      │   └── seeds/
      │       ├── admin_user.rb
      │       └── sample_data.rb
      ├── test/
      │   ├── components/              # ViewComponent tests
      │   ├── integration/
      │   ├── models/
      │   ├── policies/                # Pundit policy tests
      │   └── system/                  # Capybara end-to-end tests
      ├── .kamal/
      │   ├── secrets                  # Runtime credentials (gitignored)
      │   ├── secrets.example          # Template (committed)
      │   └── hooks/
      │       └── pre-deploy           # Git clean-state check
      ├── Procfile.dev                 # Foreman: web + css + jobs
      └── docker-compose.yml           # PostgreSQL 17 only
      ```

      ---

      ## G. Optional Features Guide

      ### G.1 Active Record Encryption

      Rails 7.1+ includes built-in transparent encryption for model attributes. Use it to encrypt sensitive fields (e.g., tokens, PII) at rest in the database.

      **Step 1: Generate encryption keys.**

      ```bash
      bin/rails db:encryption:init
      ```

      This outputs three keys. Copy the entire block.

      **Step 2: Add the keys to Rails credentials.**

      ```bash
      bin/rails credentials:edit
      ```

      Paste the generated output under the `active_record_encryption:` key:

      ```yaml
      active_record_encryption:
        primary_key: <generated>
        deterministic_key: <generated>
        key_derivation_salt: <generated>
      ```

      **Step 3: Declare encrypted attributes in the model.**

      ```ruby
      class User < ApplicationRecord
        encrypts :phone_number
        encrypts :api_token, deterministic: true  # deterministic = searchable
      end
      ```

      > **Note:** Keys are environment-specific. Production keys must be set separately — either via `RAILS_MASTER_KEY` pointing to `config/credentials/production.yml.enc`, or by injecting `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` and related environment variables directly.

      ---

      ### G.2 Rate Limit Store Customization

      The boilerplate uses Rails 8's built-in `rate_limit` method. The store it uses is determined by `config.cache_store`.

      **Default (production and test):** SolidCache — database-backed via the `cache` PostgreSQL database.

      ```ruby
      # config/environments/production.rb
      config.cache_store = :solid_cache_store
      ```

      **Development override — memory store (no DB required):**

      Add to `config/environments/development.rb`:

      ```ruby
      config.cache_store = :memory_store
      ```

      **Switching to Redis:**

      1. Add `gem "redis"` to the Gemfile and run `bundle install`.
      2. Update `config/environments/production.rb`:

      ```ruby
      config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL") }
      ```

      The `rate_limit` calls in `SessionsController`, `PasswordsController`, and `RegistrationsController` will automatically use the new store — no changes to controller code are needed.

      ---

      ### G.3 Password Policy Strengthening

      The default policy enforces a minimum of 8 characters, applied in `app/models/user.rb`:

      ```ruby
      validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }
      ```

      To require greater complexity, add a `format:` validation alongside the length check:

      ```ruby
      COMPLEXITY_REGEX = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[[:^alnum:]])/

      validates :password,
        length: { minimum: 12 },
        format: {
          with: COMPLEXITY_REGEX,
          message: :complexity
        },
        if: -> { new_record? || password.present? }
      ```

      Add the corresponding I18n key to `config/locales/models/`:

      ```yaml
      # config/locales/models/user.ko.yml
      ko:
        errors:
          models:
            user:
              attributes:
                password:
                  complexity: "은(는) 대문자, 소문자, 숫자, 특수문자를 각각 하나 이상 포함해야 합니다."
      ```

      ---

      ## H. Scaling Guide

      Start with the Solid Stack. Monitor. Migrate one component at a time when you hit a specific, observed bottleneck — not preemptively.

      ### H.1 When to Consider Redis

      | Component | Signal to migrate |
      |---|---|
      | **SolidQueue** | Job volume causes noticeable DB I/O contention, or you need sub-second job pickup latency |
      | **SolidCache** | Cache read volume measurably impacts primary DB query performance |
      | **SolidCable** | Real-time connection count grows beyond what long-polling handles efficiently |

      For most applications serving under a few thousand concurrent users, the Solid Stack on a well-resourced PostgreSQL server is sufficient.

      ---

      ### H.2 Solid Cable → Redis Adapter

      1. Add `gem "redis"` to the Gemfile and run `bundle install`.

      2. Update `config/cable.yml`:

      ```yaml
      production:
        adapter: redis
        url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
        channel_prefix: <%= Rails.application.name.underscore %>_production
      ```

      3. Optionally remove the `cable` database entry from `config/database.yml` and the `db/cable_migrate/` directory.

      4. Deploy and verify WebSocket connections in the browser developer tools Network tab (look for `101 Switching Protocols`).

      ---

      ### H.3 Solid Queue → Sidekiq or GoodJob

      **Option A: Sidekiq (requires Redis)**

      1. Add `gem "sidekiq"` to the Gemfile and run `bundle install`.
      2. Set the queue adapter in `config/application.rb`:

      ```ruby
      config.active_job.queue_adapter = :sidekiq
      ```

      3. Remove the `queue` database from `config/database.yml` and its migration directory `db/queue_migrate/`.
      4. Remove the `jobs:` process from `Procfile.dev` and replace with `bundle exec sidekiq`.
      5. Add a Sidekiq process to `config/deploy.yml` under `servers:`.

      **Option B: GoodJob (stays PostgreSQL-backed)**

      1. Add `gem "good_job"` to the Gemfile and run `bundle install`.
      2. Set the queue adapter:

      ```ruby
      config.active_job.queue_adapter = :good_job
      ```

      3. Follow the same cleanup steps for the `queue` database. GoodJob stores its data in the primary database by default.

      > **Note:** Sidekiq requires Redis. GoodJob remains PostgreSQL-backed, making it a lower-complexity migration from SolidQueue.

      ---

      ### H.4 Solid Cache → Redis Cache Store

      1. Add `gem "redis"` to the Gemfile and run `bundle install`.

      2. Update `config/environments/production.rb`:

      ```ruby
      config.cache_store = :redis_cache_store, {
        url: ENV.fetch("REDIS_URL"),
        expires_in: 1.day
      }
      ```

      3. Optionally remove the `cache` database from `config/database.yml` and the `db/cache_migrate/` directory.

      4. The `rate_limit` calls in all three auth controllers will automatically use the Redis store — no controller changes are required.

      ---

      ## I. Frontend Expansion Guide

      ### I.1 When to Migrate from Import Maps

      The zero-build Import Maps setup covers the vast majority of use cases. Consider migrating when you encounter one or more of these specific triggers:

      - You need TypeScript with compile-time type checking.
      - An NPM package you require does not ship an ESM-compatible build.
      - You are bundling large libraries (e.g., Chart.js, Three.js, D3) where tree-shaking provides a meaningful size reduction.
      - Your team requires a CSS preprocessor (Sass, PostCSS plugins) beyond what Tailwind v4 provides.

      If none of these apply, stay with Import Maps.

      ---

      ### I.2 Import Maps → jsbundling-rails (esbuild) Migration

      1. Add `gem "jsbundling-rails"` to the Gemfile and run `bundle install`.
      2. Run the esbuild installer:

      ```bash
      bin/rails javascript:install:esbuild
      ```

      3. Remove `gem "importmap-rails"` from the Gemfile and run `bundle install`.
      4. Delete `config/importmap.rb`.
      5. Review `app/assets/config/manifest.js` — add `//= link_tree ../../javascript .js` if the installer did not update it.
      6. Node.js is now required on all development machines and CI. Install it via your version manager (`mise`, `nvm`, or `asdf`).

      ---

      ### I.3 Procfile.dev Changes

      **Before (Import Maps, zero-build):**

      ```
      web: bin/rails server -p 3000
      css: bin/rails tailwindcss:watch
      jobs: bundle exec jobs
      ```

      **After (esbuild):**

      ```
      web: bin/rails server -p 3000
      css: bin/rails tailwindcss:watch
      js: yarn build --watch
      jobs: bundle exec jobs
      ```

      ---

      ### I.4 CI Workflow Changes

      After migrating to esbuild, update `.github/workflows/ci.yml` to add Node.js setup before the test steps:

      ```yaml
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version-file: .node-version
          cache: yarn

      - name: Install JavaScript dependencies
        run: yarn install --frozen-lockfile

      - name: Build JavaScript assets
        run: yarn build
      ```

      Insert these steps before the `Precompile assets` step (if present) and before running `bin/rails test`.

      ---

      ## J. Kamal Deployment Checklist

      ### J.1 SSL Configuration (Let's Encrypt)

      SSL via Let's Encrypt is supported by kamal-proxy but is commented out in the generated `config/deploy.yml`. Complete this checklist before enabling it.

      - [ ] Domain DNS A record points to the server IP
      - [ ] Ports 80 and 443 are open on the server (Let's Encrypt HTTP-01 challenge requires port 80)
      - [ ] `proxy.host` in `config/deploy.yml` is set to your domain (not an IP address)
      - [ ] Uncomment and configure the SSL block:

      ```yaml
      proxy:
        host: yourdomain.com
        app_port: 3000
        ssl: true
        ssl_redirect: true
        forward_headers: true
        healthcheck:
          path: /up
          interval: 3
          timeout: 3
      ```

      ---

      ### J.2 forward_headers Warning

      When `ssl: true` is set, kamal-proxy terminates SSL and forwards plain HTTP to Thruster and Puma. This means Rails receives unencrypted requests and cannot detect HTTPS on its own.

      **`forward_headers: true` must be explicitly set** when SSL is enabled. Without it:

      - `request.ssl?` returns `false` inside Rails
      - `config.force_ssl` does not redirect correctly
      - Secure cookie flags may not be set
      - CSRF token verification can fail on form submissions

      With `forward_headers: true`, kamal-proxy passes `X-Forwarded-For` and `X-Forwarded-Proto: https` to the app. Rails reads `X-Forwarded-Proto` via its default middleware (`ActionDispatch::RemoteIp`, `ActionDispatch::SSL`) to correctly identify the request as HTTPS.

      ---

      ### J.3 Health Check Verification

      - [ ] `/up` returns HTTP 200 (Rails built-in liveness — checks the process is alive)
      - [ ] `/health` returns HTTP 200 (custom readiness — verifies database connectivity)
      - [ ] In SSL environment, both endpoints respond correctly over HTTPS
      - [ ] Kamal proxy health check configuration is present in `config/deploy.yml`:

      ```yaml
      proxy:
        healthcheck:
          path: /up
          interval: 3
          timeout: 3
      ```

      - [ ] `app_port` in `config/deploy.yml` matches the Puma port (default: `3000`)
      - [ ] After `kamal setup`, verify with:

      ```bash
      curl -I https://yourdomain.com/up
      curl -I https://yourdomain.com/health
      ```

      Both should return `HTTP/2 200`. A `503` on `/health` indicates a database connectivity problem; check `DATABASE_URL` in `.kamal/secrets`.
    MARKDOWN
    readme_content.gsub("APP_NAME_PLACEHOLDER", app_name.titleize)
  end

  # -------------------------------------------------------------------------
  # Test Files (전 Phase 누적)
  # -------------------------------------------------------------------------
  # Phase 2: User model test, Registrations controller test
  # Phase 3: 10 component tests, Health controller test
  # Phase 4: Policy tests, Admin controller tests
  # Estimated: ~400 lines of actual content
  # -------------------------------------------------------------------------

  # Phase 2: Fixtures + User 모델 테스트
  create_file "test/fixtures/users.yml", force: true do
    <<~'YAML'
      regular:
        email_address: user@example.com
        password_digest: <%= BCrypt::Password.create('password123') %>
        role: 0

      admin:
        email_address: admin@example.com
        password_digest: <%= BCrypt::Password.create('password123') %>
        role: 1

      super_admin:
        email_address: superadmin@example.com
        password_digest: <%= BCrypt::Password.create('password123') %>
        role: 2
    YAML
  end

  create_test "models/user_test.rb", <<~'RUBY'
    require "test_helper"

    class UserTest < ActiveSupport::TestCase
      # -- Role enum --
      test "default role is user" do
        user = User.new(email_address: "new@example.com", password: "password123", password_confirmation: "password123")
        assert user.user?
      end

      test "admin role" do
        assert users(:admin).admin?
      end

      test "super_admin role" do
        assert users(:super_admin).super_admin?
      end

      # -- Password validation --
      test "password minimum 8 characters rejects short" do
        user = User.new(email_address: "short@example.com", password: "short12", password_confirmation: "short12")
        assert_not user.valid?
        assert user.errors[:password].any?, "Expected password errors but got none"
      end

      test "password valid at 8 characters" do
        user = User.new(email_address: "valid@example.com", password: "12345678", password_confirmation: "12345678")
        assert user.valid?
      end

      # -- Email normalization --
      test "email normalization strips and downcases" do
        user = User.create!(email_address: "  TEST@Example.COM  ", password: "password123", password_confirmation: "password123")
        assert_equal "test@example.com", user.email_address
      end

      # -- generates_token_for :email_confirmation --
      test "generates email_confirmation token and resolves" do
        user = users(:regular)
        token = user.generate_token_for(:email_confirmation)
        assert_not_nil token
        found = User.find_by_token_for(:email_confirmation, token)
        assert_equal user, found
      end

      # -- generates_token_for :magic_link --
      test "generates magic_link token and resolves" do
        user = users(:regular)
        token = user.generate_token_for(:magic_link)
        assert_not_nil token
        found = User.find_by_token_for(:magic_link, token)
        assert_equal user, found
      end

      test "magic_link token invalidated after update" do
        user = users(:regular)
        token = user.generate_token_for(:magic_link)
        user.touch
        found = User.find_by_token_for(:magic_link, token)
        assert_nil found
      end
    end
  RUBY

  # Phase 2: Controller 통합 테스트
  create_test "controllers/registrations_controller_test.rb", <<~'RUBY'
    require "test_helper"

    class RegistrationsControllerTest < ActionDispatch::IntegrationTest
      test "get new renders registration form" do
        get new_registration_url
        assert_response :success
      end

      test "create with valid params creates user and redirects" do
        assert_difference("User.count", 1) do
          post registration_url, params: {
            user: { email_address: "newuser@example.com", password: "password123", password_confirmation: "password123" }
          }
        end
        assert_redirected_to root_url
      end

      test "create with short password renders form with errors" do
        assert_no_difference("User.count") do
          post registration_url, params: {
            user: { email_address: "short@example.com", password: "short", password_confirmation: "short" }
          }
        end
        assert_response :unprocessable_entity
      end

      test "create with duplicate email renders form with errors" do
        assert_no_difference("User.count") do
          post registration_url, params: {
            user: { email_address: users(:regular).email_address, password: "password123", password_confirmation: "password123" }
          }
        end
        assert_response :unprocessable_entity
      end
    end
  RUBY

  create_file "test/controllers/sessions_controller_test.rb", force: true do
    <<~'RUBY'
      require "test_helper"

      class SessionsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:regular)
        end

        test "get new renders login form" do
          get new_session_url
          assert_response :success
        end

        test "create with valid credentials logs in and redirects" do
          post session_url, params: { email_address: @user.email_address, password: "password123" }
          assert_redirected_to root_url
        end

        test "create with invalid credentials redirects with alert" do
          post session_url, params: { email_address: @user.email_address, password: "wrongpassword" }
          assert_redirected_to new_session_url
        end

        test "destroy logs out and redirects" do
          post session_url, params: { email_address: @user.email_address, password: "password123" }

          delete session_url
          assert_redirected_to new_session_url
        end
      end
    RUBY
  end

  # PasswordsController 테스트 — Rails 8 생성기 테스트를 한국어 I18n + 비밀번호 정책에 맞게 덮어쓰기
  create_file "test/controllers/passwords_controller_test.rb", force: true do
    <<~'RUBY'
      require "test_helper"

      class PasswordsControllerTest < ActionDispatch::IntegrationTest
        setup { @user = User.take }

        test "new" do
          get new_password_path
          assert_response :success
        end

        test "create" do
          post passwords_path, params: { email_address: @user.email_address }
          assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
          assert_redirected_to new_session_path
        end

        test "create for an unknown user redirects but sends no mail" do
          post passwords_path, params: { email_address: "missing-user@example.com" }
          assert_enqueued_emails 0
          assert_redirected_to new_session_path
        end

        test "edit" do
          get edit_password_path(@user.password_reset_token)
          assert_response :success
        end

        test "edit with invalid password reset token" do
          get edit_password_path("invalid token")
          assert_redirected_to new_password_path
        end

        test "update" do
          assert_changes -> { @user.reload.password_digest } do
            put password_path(@user.password_reset_token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
            assert_redirected_to new_session_path
          end
        end

        test "update with non matching passwords" do
          token = @user.password_reset_token
          assert_no_changes -> { @user.reload.password_digest } do
            put password_path(token), params: { password: "newpassword123", password_confirmation: "mismatch123" }
            assert_redirected_to edit_password_path(token)
          end
        end
      end
    RUBY
  end

  # Phase 3: ViewComponent 테스트 10종 + HealthController 테스트

  create_test "components/button_component_test.rb", <<~'RUBY'
    require "test_helper"

    class ButtonComponentTest < ViewComponent::TestCase
      test "renders primary button by default" do
        render_inline(ButtonComponent.new) { "Click me" }
        assert_selector("button[type='button']", text: "Click me")
        assert_selector("button.bg-indigo-600")
      end

      test "renders secondary variant" do
        render_inline(ButtonComponent.new(variant: :secondary)) { "Cancel" }
        assert_selector("button.ring-1")
        assert_no_selector("button.bg-indigo-600")
      end

      test "renders danger variant" do
        render_inline(ButtonComponent.new(variant: :danger)) { "Delete" }
        assert_selector("button.bg-red-600")
      end

      test "renders as link when tag is :a" do
        render_inline(ButtonComponent.new(tag: :a, href: "/path")) { "Link" }
        assert_selector("a[href='/path']", text: "Link")
        assert_no_selector("button")
      end

      test "renders disabled button" do
        render_inline(ButtonComponent.new(disabled: true)) { "Disabled" }
        assert_selector("button[disabled]")
      end
    end
  RUBY

  create_test "components/card_component_test.rb", <<~'RUBY'
    require "test_helper"

    class CardComponentTest < ViewComponent::TestCase
      test "renders default card with shadow" do
        render_inline(CardComponent.new) do |card|
          card.with_body { "Content" }
        end
        assert_selector("div.shadow", text: "Content")
      end

      test "renders bordered variant" do
        render_inline(CardComponent.new(variant: :bordered)) do |card|
          card.with_body { "Content" }
        end
        assert_selector("div.border")
      end

      test "renders title slot" do
        render_inline(CardComponent.new) do |card|
          card.with_title { "Title" }
          card.with_body { "Body" }
        end
        assert_selector("div.font-semibold", text: "Title")
      end

      test "renders footer slot" do
        render_inline(CardComponent.new) do |card|
          card.with_body { "Body" }
          card.with_footer { "Footer" }
        end
        assert_selector("div.border-t", text: "Footer")
      end
    end
  RUBY

  create_test "components/badge_component_test.rb", <<~'RUBY'
    require "test_helper"

    class BadgeComponentTest < ViewComponent::TestCase
      test "renders info badge by default" do
        render_inline(BadgeComponent.new(label: "New"))
        assert_selector("span.bg-blue-50", text: "New")
      end

      test "renders success badge" do
        render_inline(BadgeComponent.new(variant: :success, label: "Active"))
        assert_selector("span.bg-green-50", text: "Active")
      end

      test "renders warning badge" do
        render_inline(BadgeComponent.new(variant: :warning, label: "Pending"))
        assert_selector("span.bg-yellow-50", text: "Pending")
      end

      test "renders error badge" do
        render_inline(BadgeComponent.new(variant: :error, label: "Failed"))
        assert_selector("span.bg-red-50", text: "Failed")
      end
    end
  RUBY

  create_test "components/flash_component_test.rb", <<~'RUBY'
    require "test_helper"

    class FlashComponentTest < ViewComponent::TestCase
      test "renders notice flash message" do
        render_inline(FlashComponent.new(flash: { notice: "Success!" }))
        assert_selector("[data-controller='flash']")
        assert_text("Success!")
        assert_selector(".border-green-400")
      end

      test "renders alert flash message" do
        render_inline(FlashComponent.new(flash: { alert: "Warning!" }))
        assert_selector(".border-yellow-400")
        assert_text("Warning!")
      end

      test "renders error flash message" do
        render_inline(FlashComponent.new(flash: { error: "Error!" }))
        assert_selector(".border-red-400")
        assert_text("Error!")
      end

      test "does not render when flash is empty" do
        render_inline(FlashComponent.new(flash: {}))
        assert_no_selector("[data-controller='flash']")
      end

      test "renders dismiss button" do
        render_inline(FlashComponent.new(flash: { notice: "Test" }))
        assert_selector("button[data-action='click->flash#dismiss']")
      end
    end
  RUBY

  create_test "components/modal_component_test.rb", <<~'RUBY'
    require "test_helper"

    class ModalComponentTest < ViewComponent::TestCase
      test "renders modal with trigger and body" do
        render_inline(ModalComponent.new) do |modal|
          modal.with_trigger { "Open" }
          modal.with_body { "Modal content" }
        end
        assert_selector("[data-controller='modal']")
        assert_selector("[data-action='click->modal#open']", text: "Open")
        assert_selector("[data-modal-target='dialog']")
        assert_text("Modal content")
      end

      test "renders close button" do
        render_inline(ModalComponent.new) do |modal|
          modal.with_body { "Content" }
        end
        assert_selector("button[data-action='click->modal#close']")
      end

      test "dialog has backdrop click handler" do
        render_inline(ModalComponent.new) do |modal|
          modal.with_body { "Content" }
        end
        assert_selector("[data-action='click->modal#closeOnBackdrop']")
      end
    end
  RUBY

  create_test "components/dropdown_component_test.rb", <<~'RUBY'
    require "test_helper"

    class DropdownComponentTest < ViewComponent::TestCase
      test "renders dropdown with trigger and items" do
        render_inline(DropdownComponent.new) do |dropdown|
          dropdown.with_trigger { "Menu" }
          dropdown.with_item { "Item 1" }
          dropdown.with_item { "Item 2" }
        end
        assert_selector("[data-controller='dropdown']")
        assert_selector("[data-action='click->dropdown#toggle']", text: "Menu")
        assert_selector("[data-dropdown-target='menu']")
        assert_text("Item 1")
        assert_text("Item 2")
      end

      test "menu has role=menu attribute" do
        render_inline(DropdownComponent.new) do |dropdown|
          dropdown.with_trigger { "Menu" }
        end
        assert_selector("[role='menu']")
      end
    end
  RUBY

  create_test "components/form_field_component_test.rb", <<~'RUBY'
    require "test_helper"

    class FormFieldComponentTest < ViewComponent::TestCase
      setup do
        @user = User.new
      end

      test "renders text field with label" do
        with_rendered_component do
          assert_selector("label", text: "Name")
          assert_selector("input[type='text']")
        end
      end

      test "renders error messages" do
        with_rendered_component(error_messages: [ "can't be blank" ]) do
          assert_selector("p.text-red-600", text: "can't be blank")
        end
      end

      private

      def with_rendered_component(error_messages: nil, &block)
        vc_test_controller.view_context.form_with(model: @user, url: "/test") do |form|
          render_inline(FormFieldComponent.new(
            form: form,
            field_name: :email_address,
            label: "Name",
            error_messages: error_messages
          ))
        end
        yield
      end
    end
  RUBY

  create_test "components/empty_state_component_test.rb", <<~'RUBY'
    require "test_helper"

    class EmptyStateComponentTest < ViewComponent::TestCase
      test "renders message" do
        render_inline(EmptyStateComponent.new(message: "No items found"))
        assert_text("No items found")
        assert_selector("div.text-center")
      end

      test "renders icon slot" do
        render_inline(EmptyStateComponent.new(message: "Empty")) do |empty|
          empty.with_icon { "<svg>icon</svg>".html_safe }
        end
        assert_selector("svg")
      end

      test "renders action slot" do
        render_inline(EmptyStateComponent.new(message: "Empty")) do |empty|
          empty.with_action { "Add new" }
        end
        assert_text("Add new")
      end
    end
  RUBY

  create_test "components/pagination_component_test.rb", <<~'RUBY'
    require "test_helper"

    class PaginationComponentTest < ViewComponent::TestCase
      test "renders pagination when multiple pages" do
        mock_request = Struct.new(:params, :base_url, :path, :query_string)
                             .new({}, "http://test.com", "/test", "")
        pagy = Pagy::Offset.new(count: 100, page: 1, limit: 10, request: mock_request)
        render_inline(PaginationComponent.new(pagy: pagy))
        assert_selector("nav[aria-label='Pagination']")
      end

      test "does not render when single page" do
        pagy = Pagy::Offset.new(count: 5, page: 1, limit: 10)
        render_inline(PaginationComponent.new(pagy: pagy))
        assert_no_selector("nav")
      end
    end
  RUBY

  create_test "components/navbar_component_test.rb", <<~'RUBY'
    require "test_helper"

    class NavbarComponentTest < ViewComponent::TestCase
      test "renders navbar with login links when no user" do
        render_inline(NavbarComponent.new(user: nil))
        assert_selector("nav[data-controller='navbar']")
        assert_selector("a", text: I18n.t("defaults.navigation.login"))
        assert_selector("a", text: I18n.t("defaults.navigation.signup"))
      end

      test "renders navbar with logout when user present" do
        user = users(:regular)
        render_inline(NavbarComponent.new(user: user))
        assert_text(I18n.t("defaults.navigation.logout"))
        assert_text(I18n.t("defaults.navigation.dashboard"))
      end

      test "renders mobile hamburger button" do
        render_inline(NavbarComponent.new)
        assert_selector("button[data-action='click->navbar#toggle']")
        assert_selector("[data-navbar-target='menu']")
      end
    end
  RUBY

  # Phase 3: HealthController 통합 테스트
  create_test "controllers/health_controller_test.rb", <<~'RUBY'
    require "test_helper"

    class HealthControllerTest < ActionDispatch::IntegrationTest
      test "GET /health returns ok when database is connected" do
        get "/health"
        assert_response :success
        json = JSON.parse(response.body)
        assert_equal "ok", json["status"]
      end
    end
  RUBY

  # Phase 3: I18n 키 정합성 테스트
  create_test "i18n/locale_keys_test.rb", <<~'RUBY'
    require "test_helper"

    class LocaleKeysTest < ActiveSupport::TestCase
      # 앱 전용 키만 비교 (Rails 표준 i18n 키: date, time, number, errors 등은 제외)
      APP_SCOPES = %w[defaults registrations sessions passwords rate_limit admin].freeze

      test "ko and en locales have matching app keys" do
        ko_keys = app_keys(:ko)
        en_keys = app_keys(:en)

        missing_in_en = ko_keys - en_keys
        missing_in_ko = en_keys - ko_keys

        assert missing_in_en.empty?, "Keys in ko but missing in en: #{missing_in_en.join(', ')}"
        assert missing_in_ko.empty?, "Keys in en but missing in ko: #{missing_in_ko.join(', ')}"
      end

      test "defaults.buttons keys exist in ko" do
        assert_not_nil I18n.t("defaults.buttons.submit", locale: :ko, raise: true)
        assert_not_nil I18n.t("defaults.buttons.save", locale: :ko, raise: true)
        assert_not_nil I18n.t("defaults.buttons.cancel", locale: :ko, raise: true)
      end

      test "defaults.navigation keys exist in ko" do
        assert_not_nil I18n.t("defaults.navigation.home", locale: :ko, raise: true)
        assert_not_nil I18n.t("defaults.navigation.login", locale: :ko, raise: true)
        assert_not_nil I18n.t("defaults.navigation.logout", locale: :ko, raise: true)
      end

      private

      def app_keys(locale)
        translations = I18n.backend.translations[locale] || {}
        APP_SCOPES.flat_map do |scope|
          flatten_keys(translations[scope.to_sym] || {}, scope)
        end
      end

      def flatten_keys(hash, prefix = "")
        hash.each_with_object([]) do |(key, value), keys|
          full_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
          if value.is_a?(Hash)
            keys.concat(flatten_keys(value, full_key))
          else
            keys << full_key
          end
        end
      end
    end
  RUBY

  # Phase 4: Policy 단위 테스트 + Admin 컨트롤러 통합 테스트

  create_test "policies/application_policy_test.rb", <<~'RUBY'
    require "test_helper"

    class ApplicationPolicyTest < ActiveSupport::TestCase
      setup do
        @user = users(:regular)
        @record = users(:admin)
      end

      test "default policy denies index" do
        assert_not ApplicationPolicy.new(@user, @record).index?
      end

      test "default policy denies show" do
        assert_not ApplicationPolicy.new(@user, @record).show?
      end

      test "default policy denies create" do
        assert_not ApplicationPolicy.new(@user, @record).create?
      end

      test "default policy denies update" do
        assert_not ApplicationPolicy.new(@user, @record).update?
      end

      test "default policy denies destroy" do
        assert_not ApplicationPolicy.new(@user, @record).destroy?
      end
    end
  RUBY

  create_test "policies/user_policy_test.rb", <<~'RUBY'
    require "test_helper"

    class UserPolicyTest < ActiveSupport::TestCase
      setup do
        @regular = users(:regular)
        @admin = users(:admin)
        @super_admin = users(:super_admin)
      end

      # -- index? --
      test "admin can index users" do
        assert UserPolicy.new(@admin, User).index?
      end

      test "super_admin can index users" do
        assert UserPolicy.new(@super_admin, User).index?
      end

      test "regular user cannot index users" do
        assert_not UserPolicy.new(@regular, User).index?
      end

      # -- show? --
      test "user can show self" do
        assert UserPolicy.new(@regular, @regular).show?
      end

      test "user cannot show other user" do
        assert_not UserPolicy.new(@regular, @admin).show?
      end

      test "admin can show any user" do
        assert UserPolicy.new(@admin, @regular).show?
      end

      # -- update? --
      test "user can update self" do
        assert UserPolicy.new(@regular, @regular).update?
      end

      test "user cannot update other user" do
        assert_not UserPolicy.new(@regular, @admin).update?
      end

      test "admin cannot update other user" do
        assert_not UserPolicy.new(@admin, @regular).update?
      end

      test "super_admin can update any user" do
        assert UserPolicy.new(@super_admin, @regular).update?
      end

      # -- change_role? --
      test "only super_admin can change role" do
        assert UserPolicy.new(@super_admin, @regular).change_role?
      end

      test "admin cannot change role" do
        assert_not UserPolicy.new(@admin, @regular).change_role?
      end

      test "regular user cannot change role" do
        assert_not UserPolicy.new(@regular, @regular).change_role?
      end

      # -- Scope --
      test "scope for admin returns all users" do
        scope = UserPolicy::Scope.new(@admin, User).resolve
        assert_equal User.count, scope.count
      end

      test "scope for regular user returns only self" do
        scope = UserPolicy::Scope.new(@regular, User).resolve
        assert_equal 1, scope.count
        assert_includes scope, @regular
      end
    end
  RUBY

  create_test "controllers/admin/dashboard_controller_test.rb", <<~'RUBY'
    require "test_helper"

    class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = users(:admin)
        @regular = users(:regular)
      end

      test "admin can access dashboard" do
        post session_url, params: { email_address: @admin.email_address, password: "password123" }
        get admin_root_url
        assert_response :success
      end

      test "regular user gets forbidden" do
        post session_url, params: { email_address: @regular.email_address, password: "password123" }
        get admin_root_url
        assert_response :forbidden
      end

      test "unauthenticated user gets redirected" do
        get admin_root_url
        assert_redirected_to new_session_url
      end
    end
  RUBY

  create_test "controllers/admin/users_controller_test.rb", <<~'RUBY'
    require "test_helper"

    class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = users(:admin)
        @regular = users(:regular)
      end

      test "admin can list users" do
        post session_url, params: { email_address: @admin.email_address, password: "password123" }
        get admin_users_url
        assert_response :success
      end

      test "admin can show user" do
        post session_url, params: { email_address: @admin.email_address, password: "password123" }
        get admin_user_url(@regular)
        assert_response :success
      end

      test "regular user gets forbidden on index" do
        post session_url, params: { email_address: @regular.email_address, password: "password123" }
        get admin_users_url
        assert_response :forbidden
      end

      test "regular user gets forbidden on show" do
        post session_url, params: { email_address: @regular.email_address, password: "password123" }
        get admin_user_url(@admin)
        assert_response :forbidden
      end

      test "unauthenticated user gets redirected" do
        get admin_users_url
        assert_redirected_to new_session_url
      end
    end
  RUBY

  # Phase 4: Admin I18n 로케일 (한국어/영어)
  create_locale "defaults/admin.ko.yml", <<~YAML
    ko:
      admin:
        title: "관리자"
        sidebar:
          title: "관리자 패널"
          dashboard: "대시보드"
          users: "사용자 관리"
          back_to_site: "사이트로 돌아가기"
        dashboard:
          title: "대시보드"
          total_users: "전체 사용자"
          recent_users: "최근 가입 사용자"
        users:
          title: "사용자 관리"
          email: "이메일"
          role: "역할"
          created_at: "가입일"
          updated_at: "수정일"
          back_to_list: "목록으로 돌아가기"
  YAML

  create_locale "defaults/admin.en.yml", <<~YAML
    en:
      admin:
        title: "Admin"
        sidebar:
          title: "Admin Panel"
          dashboard: "Dashboard"
          users: "User Management"
          back_to_site: "Back to Site"
        dashboard:
          title: "Dashboard"
          total_users: "Total Users"
          recent_users: "Recent Users"
        users:
          title: "User Management"
          email: "Email"
          role: "Role"
          created_at: "Joined"
          updated_at: "Updated"
          back_to_list: "Back to List"
  YAML

  # -------------------------------------------------------------------------
  # Final Summary
  # -------------------------------------------------------------------------

  say "\n#{'=' * 60}", :green
  say " ROR-Hatchling setup complete!", :green
  say " Next steps:", :green
  say "   1. cd #{app_name}", :green
  say "   2. bin/dev  (starts web + css + jobs)", :green
  say "   3. Visit http://localhost:3000", :green
  say "#{'=' * 60}\n", :green

end # after_bundle
