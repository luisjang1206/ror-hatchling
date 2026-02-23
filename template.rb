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
  # Pagy::Backend은 ApplicationController, Pagy::Frontend은 ApplicationHelper (Phase 4 설정)
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
      config.i18n.available_locales = [:ko, :en]
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
      defaults:
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

  # Pundit 설치
  # TODO: Phase 4 구현 시 — generate 실행 및 ApplicationController에 include 추가
  # generate "pundit:install"
  # inject_into_file "app/controllers/application_controller.rb",
  #   after: "  include Authentication\n" do
  #   "  include Pundit::Authorization\n"
  # end

  # TODO: Phase 4 구현 시 — UserPolicy 생성
  # create_file "app/policies/user_policy.rb" do ... end

  # TODO: Phase 4 구현 시 — Pagy initializer
  # create_file "config/initializers/pagy.rb" do
  #   <<~'RUBY'
  #     Pagy::DEFAULT[:limit] = 25
  #   RUBY
  # end
  # ApplicationController에 include Pagy::Backend
  # ApplicationHelper에 include Pagy::Frontend

  # TODO: Phase 4 구현 시 — Lograge initializer
  # create_file "config/initializers/lograge.rb" do
  #   <<~'RUBY'
  #     Rails.application.configure do
  #       config.lograge.enabled = true
  #       config.lograge.formatter = Lograge::Formatters::Json.new
  #       config.lograge.custom_payload do |controller|
  #         {
  #           user_id: controller.try(:current_user)&.id,
  #           request_id: controller.request.request_id
  #         }
  #       end
  #     end
  #   RUBY
  # end

  # == Step 7 (Admin): Admin 네임스페이스 ======================================

  say_step "7-admin", "Admin 네임스페이스"

  # TODO: Phase 4 구현 시 — Admin::BaseController, Dashboard, Users
  # create_file "app/controllers/admin/base_controller.rb" do ... end
  # create_file "app/controllers/admin/dashboard_controller.rb" do ... end
  # create_file "app/controllers/admin/users_controller.rb" do ... end
  # create_file "app/views/layouts/admin.html.erb" do ... end
  # create_file "app/views/admin/dashboard/show.html.erb" do ... end
  # create_file "app/views/admin/users/index.html.erb" do ... end
  # create_file "app/views/admin/users/show.html.erb" do ... end

  # Admin 라우트
  # TODO: Phase 4 구현 시 — admin namespace 추가
  # route <<~'RUBY'
  #   namespace :admin do
  #     root "dashboard#show"
  #     resources :users, only: [:index, :show]
  #   end
  # RUBY

  # == Step 12: 시드 데이터 ====================================================

  say_step 12, "시드 데이터"

  # TODO: Phase 4 구현 시 — seeds.rb 진입점 + 하위 파일
  # create_file "db/seeds.rb", force: true do
  #   <<~'RUBY'
  #     Dir[Rails.root.join("db/seeds/*.rb")].each { |f| load f }
  #   RUBY
  # end
  # create_file "db/seeds/admin_user.rb" do ... end
  # create_file "db/seeds/sample_data.rb" do ... end

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
  # development.rb는 수동 추가 필요

  say_step "19-prep", "Solid Stack 환경 설정"

  # TODO: Phase 5 구현 시 — development.rb에 Solid Stack 설정 추가
  # environment "development" do
  #   <<~'RUBY'
  #     config.active_job.queue_adapter = :solid_queue
  #     config.solid_queue.connects_to = { database: { writing: :queue } }
  #     config.cache_store = :solid_cache_store
  #   RUBY
  # end

  # == Step 13: Docker 파일 ====================================================
  # Dockerfile: Rails 8 기본 멀티스테이지 빌드 (rails new가 이미 생성)
  # docker-compose.yml: PostgreSQL 17 DB-only 서비스
  # ==========================================================================

  say_step 13, "Docker 파일"

  # TODO: Phase 5 구현 시 — docker-compose.yml 교체 (DB-only)
  # create_file "docker-compose.yml", force: true do
  #   <<~YAML
  #     services:
  #       db:
  #         image: postgres:17
  #         environment:
  #           POSTGRES_USER: postgres
  #           POSTGRES_PASSWORD: password
  #         ports:
  #           - "5432:5432"
  #         volumes:
  #           - postgres_data:/var/lib/postgresql/data
  #     volumes:
  #       postgres_data:
  #   YAML
  # end

  # TODO: Phase 5 구현 시 — Dockerfile 검토 및 필요 시 수정

  # == Step 15: GitHub Actions CI ==============================================
  # 7단계 파이프라인: Ruby설정 → 캐싱 → DB → RuboCop → Brakeman → Test → System Test
  # ==========================================================================

  say_step 15, "GitHub Actions CI"

  # TODO: Phase 5 구현 시 — .github/workflows/ci.yml 생성
  # create_file ".github/workflows/ci.yml" do
  #   <<~YAML
  #     name: CI
  #     on:
  #       push:
  #         branches: [main]
  #       pull_request:
  #     jobs:
  #       test:
  #         runs-on: ubuntu-latest
  #         services:
  #           postgres:
  #             image: postgres:17
  #             env:
  #               POSTGRES_PASSWORD: postgres
  #             ports:
  #               - 5432:5432
  #             options: >-
  #               --health-cmd pg_isready
  #               --health-interval 10s
  #               --health-timeout 5s
  #               --health-retries 5
  #         steps:
  #           # 1. Checkout + Ruby setup
  #           # 2. Asset caching
  #           # 3. DB setup (multi-DB)
  #           # 4. RuboCop
  #           # 5. Brakeman
  #           # 6. Minitest
  #           # 7. System tests
  #   YAML
  # end

  # == Step 16: Kamal 2 배포 설정 ==============================================
  # deploy.yml + .kamal/secrets + hooks
  # 프록시 아키텍처: kamal-proxy → Thruster → Puma
  # ==========================================================================

  say_step 16, "Kamal 2 배포 설정"

  # TODO: Phase 5 구현 시 — deploy.yml 교체
  # create_file "config/deploy.yml", force: true do ... end

  # TODO: Phase 5 구현 시 — .kamal/secrets 생성
  # create_file ".kamal/secrets" do
  #   <<~SECRETS
  #     KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD
  #     RAILS_MASTER_KEY=$(cat config/master.key)
  #     DB_PASSWORD=$DB_PASSWORD
  #   SECRETS
  # end

  # TODO: Phase 5 구현 시 — hooks
  # create_file ".kamal/hooks/pre-deploy" do ... end

  # .gitignore에 .kamal/secrets 추가
  # append_to_file ".gitignore", "\n.kamal/secrets\n"

  # == Step 19: 초기 마이그레이션 실행 =========================================
  # rails db:prepare가 4개 DB 모두 처리 (검증 완료)
  # ==========================================================================

  say_step 19, "초기 마이그레이션 실행"

  rails_command "db:prepare", abort_on_failure: true

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

  # TODO: Phase 6 구현 시 — README.md 전체 작성
  # create_file "README.md", force: true do
  #   <<~'MARKDOWN'
  #     # #{app_name.titleize}
  #     ...
  #   MARKDOWN
  # end

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
        assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
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
        with_rendered_component(error_messages: ["can't be blank"]) do
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
        pagy = Pagy.new(count: 100, page: 1, limit: 10)
        render_inline(PaginationComponent.new(pagy: pagy))
        assert_selector("nav[aria-label='Pagination']")
      end

      test "does not render when single page" do
        pagy = Pagy.new(count: 5, page: 1, limit: 10)
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
      test "ko and en locales have matching top-level keys" do
        ko_keys = flatten_keys(I18n.backend.translations[:ko] || {})
        en_keys = flatten_keys(I18n.backend.translations[:en] || {})

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

  # TODO: Phase 4 구현 시 — Policy + Admin 테스트
  # create_test "policies/application_policy_test.rb" do ... end
  # create_test "policies/user_policy_test.rb" do ... end
  # create_test "controllers/admin/dashboard_controller_test.rb" do ... end
  # create_test "controllers/admin/users_controller_test.rb" do ... end

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
