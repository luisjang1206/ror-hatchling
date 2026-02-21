# Rails 8.1 Authentication Generator 실제 출력 캡처

> **실행 일자**: 2026-02-22
> **환경**: Ruby 3.4.8, Rails 8.1.2, PostgreSQL 17.8
> **명령어**: `bin/rails generate authentication`

---

## 생성 파일 목록 (총 19개)

### 생성된 파일

```
Models:
  app/models/user.rb
  app/models/session.rb
  app/models/current.rb

Controllers:
  app/controllers/sessions_controller.rb
  app/controllers/passwords_controller.rb
  app/controllers/concerns/authentication.rb

Channels:
  app/channels/application_cable/connection.rb

Mailers:
  app/mailers/passwords_mailer.rb

Views:
  app/views/sessions/new.html.erb
  app/views/passwords/new.html.erb
  app/views/passwords/edit.html.erb
  app/views/passwords_mailer/reset.html.erb
  app/views/passwords_mailer/reset.text.erb

Migrations:
  db/migrate/XXXXXX_create_users.rb
  db/migrate/XXXXXX_create_sessions.rb

Tests:
  test/fixtures/users.yml
  test/models/user_test.rb
  test/controllers/sessions_controller_test.rb
  test/controllers/passwords_controller_test.rb
  test/mailers/previews/passwords_mailer_preview.rb
  test/test_helpers/session_test_helper.rb

Modified:
  Gemfile (bcrypt uncomment)
  app/controllers/application_controller.rb (include Authentication)
  config/routes.rb (resource :session, resources :passwords)
  test/test_helper.rb (include SessionTestHelper)
```

---

## 이론 조사 대비 실제 차이점

| 항목 | 이론 조사 | 실제 출력 | 영향 |
|---|---|---|---|
| Session 토큰 | `has_secure_token` + `token` 컬럼 | `session.id` + `cookies.signed[:session_id]` | Session 모델에 token 컬럼 없음 |
| 쿠키 키 | `cookies.signed[:session_token]` | `cookies.signed[:session_id]` | inject 타겟 변경 불필요 |
| Passwords rate_limit | `to: 3, within: 1.hour` (추정) | `to: 10, within: 3.minutes` | Sessions와 동일 값 |
| Passwords rate_limit 유무 | 불확실 | **포함됨** | 별도 추가 불필요 |
| Password reset 메서드 | `find_by_token_for(:password_reset, token)` | `find_by_password_reset_token!(params[:token])` | Rails 8.1 내장 토큰 사용 |
| Channels | 미언급 | `application_cable/connection.rb` 생성 | 추가 파일 1개 |
| Test helpers | 미언급 | `session_test_helper.rb` + `test_helper.rb` 수정 | 테스트 설정 자동화 |

---

## 핵심 파일 내용

### app/models/user.rb

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
```

### app/models/session.rb

```ruby
class Session < ApplicationRecord
  belongs_to :user
end
```

### app/models/current.rb

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
```

### app/controllers/sessions_controller.rb

```ruby
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
```

### app/controllers/passwords_controller.rb

```ruby
class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "Password reset instructions sent (if user with that email address exists)."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Password has been reset."
    else
      redirect_to edit_password_path(params[:token]), alert: "Passwords did not match."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end
end
```

### app/controllers/concerns/authentication.rb

```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
```

### config/routes.rb (auth 부분)

```ruby
Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # ...
end
```

### db/migrate/XXXXXX_create_users.rb

```ruby
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
```

### db/migrate/XXXXXX_create_sessions.rb

```ruby
class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
```

---

## inject_into_file 타겟 문자열 (확정)

### 1. User 모델 — role enum + validation 주입

**파일**: `app/models/user.rb`
**타겟**: `"  has_secure_password\n"`
**방향**: `:after`
**주입 내용 예시**:
```ruby
inject_into_file "app/models/user.rb",
  after: "  has_secure_password\n" do
  <<~RUBY
    has_many :sessions, dependent: :destroy

    enum :role, { user: 0, admin: 1, super_admin: 2 }, default: :user

    validates :email_address, presence: true, uniqueness: true
    validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }
  RUBY
end
```

**주의**: `has_many :sessions`는 이미 생성되므로 중복 방지 필요. 실제로는:
```ruby
inject_into_file "app/models/user.rb",
  after: "  has_many :sessions, dependent: :destroy\n" do
  <<~RUBY

    enum :role, { user: 0, admin: 1, super_admin: 2 }, default: :user

    validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }
  RUBY
end
```

### 2. Routes — 회원가입 라우트 추가

**파일**: `config/routes.rb`
**타겟**: `"  resource :session\n"`
**방향**: `:after`
**주입 내용**:
```ruby
inject_into_file "config/routes.rb",
  after: "  resource :session\n" do
  "  resource :registration, only: %i[new create]\n"
end
```

### 3. User migration — role 컬럼 추가

**파일**: `db/migrate/*_create_users.rb`
**타겟**: `"      t.string :password_digest, null: false\n"`
**방향**: `:after`
**주입 내용**:
```ruby
# 파일명이 동적이므로 Dir.glob 사용
Dir.glob("db/migrate/*_create_users.rb").each do |file|
  inject_into_file file,
    after: "      t.string :password_digest, null: false\n" do
    "      t.integer :role, default: 0, null: false\n"
  end
end
```

### 4. ApplicationController 수정 (이미 Authentication include됨)

**파일**: `app/controllers/application_controller.rb`
**상태**: Generator가 이미 `include Authentication` 추가함
**추가 필요**: 에러 핸들링
```ruby
inject_into_file "app/controllers/application_controller.rb",
  after: "  include Authentication\n" do
  <<~RUBY

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from Pundit::NotAuthorizedError, with: :forbidden

    private

    def not_found
      render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
    end

    def forbidden
      render file: Rails.public_path.join("403.html"), status: :forbidden, layout: false
    end
  RUBY
end
```

---

## Rate Limiting 요약

| Controller | rate_limit | to | within | only |
|---|---|---|---|---|
| SessionsController | **포함됨** (자동) | 10 | 3.minutes | :create |
| PasswordsController | **포함됨** (자동) | 10 | 3.minutes | :create |
| RegistrationsController | **미포함** (별도 생성) | template.rb에서 추가 필요 | — | — |

**결론**: RegistrationsController만 rate_limit 수동 추가 필요.
