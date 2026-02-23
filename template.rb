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
    RUBY
  end

  # TODO: Phase 2 구현 시 — generates_token_for 추가
  # inject_into_file "app/models/user.rb",
  #   after: "  validates :password, length: { minimum: 8 }...\n" do
  #   <<~'RUBY'
  #
  #     generates_token_for :email_confirmation, expires_in: 24.hours do
  #       email
  #     end
  #   RUBY
  # end

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

  # TODO: Phase 2 구현 시 — RegistrationsController 생성
  # create_file "app/controllers/registrations_controller.rb" do
  #   <<~'RUBY'
  #     class RegistrationsController < ApplicationController
  #       allow_unauthenticated_access
  #       rate_limit to: 5, within: 1.hour, only: :create,
  #         with: -> { redirect_to new_registration_url, alert: t("rate_limit.exceeded") }
  #
  #       def new
  #         @user = User.new
  #       end
  #
  #       def create
  #         @user = User.new(registration_params)
  #         if @user.save
  #           start_new_session_for @user
  #           redirect_to root_path, notice: t("registrations.created")
  #         else
  #           render :new, status: :unprocessable_entity
  #         end
  #       end
  #
  #       private
  #
  #       def registration_params
  #         params.require(:user).permit(:email_address, :password, :password_confirmation)
  #       end
  #     end
  #   RUBY
  # end

  # TODO: Phase 2 구현 시 — Registration view 생성
  # create_file "app/views/registrations/new.html.erb" do ... end

  # == Step 18: rate_limit 설정 ================================================
  # 검증 결과: SessionsController, PasswordsController는 이미 rate_limit 포함
  #   (to: 10, within: 3.minutes, only: :create)
  # RegistrationsController만 수동 추가 필요
  # ==========================================================================

  say_step 18, "rate_limit 설정"

  # NOTE: SessionsController — rate_limit 이미 포함 (auth generator 자동 생성)
  # NOTE: PasswordsController — rate_limit 이미 포함 (auth generator 자동 생성)
  # RegistrationsController — Phase 2 구현 시 create_file에서 직접 포함 (위 TODO 참조)

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

  # ApplicationComponent 베이스 클래스
  # TODO: Phase 3 구현 시 — 아래 주석 해제 및 실제 내용 작성
  # create_file "app/components/application_component.rb" do
  #   <<~'RUBY'
  #     class ApplicationComponent < ViewComponent::Base
  #     end
  #   RUBY
  # end

  # 10종 ViewComponent 생성 (Phase 3 구현 시 create_component 헬퍼 사용)
  # TODO: Phase 3 구현 시 — 각 컴포넌트의 ruby_content, erb_content 작성
  #
  # Components list (PRD 2.6절):
  #   1. ButtonComponent    — primary/secondary/danger variant
  #   2. CardComponent      — default/bordered variant, title/body slots
  #   3. BadgeComponent     — success/warning/error/info variant
  #   4. FlashComponent     — notice/alert/error, Stimulus auto-dismiss
  #   5. ModalComponent     — open/close/ESC, Stimulus toggle
  #   6. DropdownComponent  — toggle/outside-click, Stimulus
  #   7. FormFieldComponent — label+input+error wrapper
  #   8. EmptyStateComponent — icon+message+action
  #   9. PaginationComponent — Pagy integration
  #  10. NavbarComponent    — responsive, mobile toggle, Stimulus

  # == Step 8: Stimulus 컨트롤러 4종 ==========================================
  # flash, modal, dropdown, navbar
  # Import Maps 핀은 stimulus-rails가 자동 관리 (controllers/ 자동 로딩)
  # ==========================================================================

  say_step 8, "Stimulus 컨트롤러 4종"

  # TODO: Phase 3 구현 시 — 4개 Stimulus 컨트롤러 JS 파일 작성
  # create_file "app/javascript/controllers/flash_controller.js" do ... end
  # create_file "app/javascript/controllers/modal_controller.js" do ... end
  # create_file "app/javascript/controllers/dropdown_controller.js" do ... end
  # create_file "app/javascript/controllers/navbar_controller.js" do ... end

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

  # TODO: Phase 3 구현 시 — HealthController 생성
  # create_file "app/controllers/health_controller.rb" do
  #   <<~'RUBY'
  #     class HealthController < ApplicationController
  #       allow_unauthenticated_access
  #
  #       def show
  #         ActiveRecord::Base.connection.execute("SELECT 1")
  #         render json: { status: "ok" }, status: :ok
  #       rescue StandardError => e
  #         render json: { status: "error", message: e.message }, status: :service_unavailable
  #       end
  #     end
  #   RUBY
  # end

  # Health route 추가
  # TODO: Phase 3 구현 시 — route 메서드로 추가
  # route 'get "/health", to: "health#show"'

  # == Step 9: I18n 로케일 파일 ================================================
  # config.i18n.default_locale = :ko
  # 로케일 파일: defaults/ (공통 UI) + models/ (모델/속성)
  # ==========================================================================

  say_step 9, "I18n 로케일 파일"

  # I18n 설정 initializer
  # TODO: Phase 3 구현 시 — locale.rb initializer 생성
  # create_file "config/initializers/locale.rb" do
  #   <<~'RUBY'
  #     Rails.application.configure do
  #       config.i18n.default_locale = :ko
  #       config.i18n.available_locales = [:ko, :en]
  #       config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]
  #     end
  #   RUBY
  # end

  # TODO: Phase 3 구현 시 — 6개 로케일 파일 생성 (create_locale 헬퍼 사용)
  # create_locale "defaults/ko.yml", <<~YAML ... YAML
  # create_locale "defaults/en.yml", <<~YAML ... YAML
  # create_locale "models/ko.yml", <<~YAML ... YAML
  # create_locale "models/en.yml", <<~YAML ... YAML
  # 기존 ko.yml, en.yml은 gsub_file 또는 create_file force:true로 교체

  # == Step 10: 커스텀 에러 페이지 =============================================
  # public/404.html, public/422.html, public/500.html
  # Tailwind CDN 또는 인라인 CSS (public/ 파일은 에셋 파이프라인 미사용)
  # ==========================================================================

  say_step 10, "커스텀 에러 페이지"

  # TODO: Phase 3 구현 시 — 3개 에러 페이지 + 403.html 생성
  # create_file "public/404.html", force: true do ... end
  # create_file "public/422.html", force: true do ... end
  # create_file "public/500.html", force: true do ... end
  # create_file "public/403.html" do ... end

  # == Step 5 (계속): 레이아웃 업데이트 ========================================

  # TODO: Phase 3 구현 시 — application.html.erb에 FlashComponent, NavbarComponent 렌더링 추가
  # inject_into_file "app/views/layouts/application.html.erb",
  #   after: "<body>\n" do
  #   <<~ERB
  #     <%= render(NavbarComponent.new(user: Current.user)) %>
  #     <%= render(FlashComponent.new(flash: flash)) if flash.any? %>
  #   ERB
  # end

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

  # TODO: Phase 2 구현 시 — User 모델 테스트
  # create_test "models/user_test.rb" do ... end
  # create_test "controllers/registrations_controller_test.rb" do ... end

  # TODO: Phase 3 구현 시 — ViewComponent 테스트 10개
  # %w[button card badge flash modal dropdown form_field empty_state pagination navbar].each do |name|
  #   create_test "components/#{name}_component_test.rb" do ... end
  # end
  # create_test "controllers/health_controller_test.rb" do ... end

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
