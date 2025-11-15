## Finance Manager

Pulls bank notifications from Gmail, extracts structured transactions using OpenAI, and presents them in a clean Rails UI. Built on Rails 8.1 with Solid Queue/Cache/Cable and TailwindCSS.

### Table of contents
- Overview
- Features
- Tech stack
- Architecture
- Prerequisites
- Local setup
- Configuration (env/credentials)
- Google OAuth (Gmail)
- Background jobs (Solid Queue)
- OpenAI extraction
- Running the app
- Testing, linting, and security checks
- Deployment (Docker, Kamal)
- Troubleshooting
- Contributing
- License

---

### Overview
Finance Manager links a user’s Gmail account, ingests relevant bank/notification emails, and extracts transaction data with LLM-based parsing for display and review.

### Features
- Email account linking via Google OAuth (readonly Gmail scope)
- Email ingestion with sender filters
- Transaction extraction via OpenAI (structured JSON)
- Background processing using Solid Queue (SQLite-backed)
- Password-based login and password reset via email
- Health check endpoint at `/up`

### Tech stack
- Rails 8.1 (propshaft, importmap, Turbo, Stimulus)
- Ruby 3.4 (see Dockerfile ARG)
- SQLite (app DB), Solid Cache/Queue/Cable
- TailwindCSS via `tailwindcss-rails`
- Gmail API: `google-apis-gmail_v1`, `googleauth`
- OpenAI via `ruby-openai`
- Deployment: Docker, Kamal

---

### Architecture
- Authentication: email/password (`has_secure_password`) with cookie-based sessions
  - `SessionsController`, `PasswordsController`, `PasswordsMailer`
  - `Authentication` concern handles session restore and access control
- Email/Gmail:
  - OAuth flow (`EmailProviderOauthsController`) for Google accounts
  - Gmail ingestion service `GoogleGmail.ingest_latest`
  - Emails stored in `emails` table, linked to `email_accounts` and `users`
- Transaction extraction:
  - `ExtractTransactionFromEmailJob` calls `TransactionExtractor.extract!`
  - Uses OpenAI to parse snippets into structured data and saves `transactions`
- Background jobs:
  - `DownloadEmailsJob` and `SyncEmailsJob` orchestrate ingest and extraction
  - Solid Queue with SQLite queue database

Data model (simplified)
```
User --< Session
User --< EmailAccount
User --< Email --1 Transaction
EmailAccount --< Email
```

Key routes (see `config/routes.rb`)
- `root` → `transactions#index`
- `resource :session` (`GET /session/new`, `POST /session`, `DELETE /session`)
- `resources :passwords, param: :token` (reset flow)
- `resources :emails, only: [:index, :show], path: "email"`
- `resources :transactions, only: [:index, :show]`
- OAuth (Google): `/oauth/google/start`, `/oauth/google/callback`
- Health: `/up`

---

### Prerequisites
- Ruby 3.4.x (Dockerfile uses `3.4.7`)
- Bundler
- SQLite 3
- Optional for dev: Foreman (auto-installed by `bin/dev`)

No Node/Yarn required (importmap).

---

### Local setup
1) Clone and install gems
```bash
bundle install
```

2) Setup databases (app, cache, queue)
```bash
bin/rails db:setup
bin/rails db:migrate
```

3) Configure credentials or environment variables (see next sections)

4) Create a user (no sign‑up UI)
```bash
bin/rails console
User.create!(email_address: "you@example.com", password: "secret123", password_confirmation: "secret123")
```

5) Start the dev processes
```bash
# Terminal A: web + tailwind watcher
bin/dev
# Terminal B: background jobs
bin/jobs start
```

6) Log in at `http://localhost:3000/session/new` and link Gmail via `http://localhost:3000/oauth/google/start`.

---

### Configuration (env/credentials)
You can configure secrets via Rails credentials or environment variables. Either option works; if both exist, credentials typically take precedence in code that digs credentials first.

Rails credentials (recommended for production)
```bash
bin/rails credentials:edit
```
Minimal structure:
```yaml
google:
  client_id: YOUR_GOOGLE_OAUTH_CLIENT_ID
  client_secret: YOUR_GOOGLE_OAUTH_CLIENT_SECRET
openai:
  api_key: YOUR_OPENAI_API_KEY
```

Environment variables (easy for local)
- `GOOGLE_API_CLIENT_ID`
- `GOOGLE_API_CLIENT_SECRET`
- `OPENAI_API_KEY`

In development, mailer URLs use:
```ruby
# config/environments/development.rb
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```

---

### Google OAuth (Gmail)
The OAuth controller is `EmailProviderOauthsController`. It requests scopes:
- `https://www.googleapis.com/auth/gmail.readonly`
- `openid`, `email`, `profile`

The redirect URI is currently hardcoded for development:
```
http://localhost:3000/oauth/google/callback
```
Configure an OAuth Client ID in Google Cloud Console:
1) Enable the Gmail API in your GCP project.
2) Create OAuth 2.0 Client credentials (Web).
3) Add Authorized redirect URI: `http://localhost:3000/oauth/google/callback`
4) Set `GOOGLE_API_CLIENT_ID` and `GOOGLE_API_CLIENT_SECRET` (or use credentials).

Notes
- Offline access is requested, so a `refresh_token` should be provided on first consent.
- If tokens expire or become invalid, the app will clear them and require re-linking.

---

### Background jobs (Solid Queue)
Solid Queue is the Active Job adapter (see `config/application.rb` and `config/environments/*`).

Run workers locally:
```bash
bin/jobs start
```
It loads `config/queue.yml`. You can tune concurrency via:
```bash
JOB_CONCURRENCY=2 bin/jobs start
```

Manual job kickoffs:
```bash
# For all users with linked email accounts
bin/rails runner 'SyncEmailsJob.perform_later(days: 2, max: 200)'

# For a specific user
bin/rails runner 'DownloadEmailsJob.perform_later(User.first.id, days: 2, max: 200)'
```

Job flow
```
SyncEmailsJob → DownloadEmailsJob → GoogleGmail.ingest_latest
                                   → Email records created
                                   → ExtractTransactionFromEmailJob
                                   → TransactionExtractor.extract! → Transaction records
```

---

### OpenAI extraction
`TransactionExtractor` uses `ruby-openai` and the `gpt-4o-mini` model to produce minified JSON (amount, currency, date, merchant, notes, etc.). The extraction operates on the email snippet and updates/creates a `Transaction` attached to the `Email`.

Set:
```bash
export OPENAI_API_KEY=YOUR_KEY
```
Data is sent to OpenAI; consider privacy when using real emails. You may disable extraction or switch models as needed in `app/services/transaction_extractor.rb`.

---

### Running the app
- Start web and CSS watcher: `bin/dev` (serves at `http://localhost:3000`)
- Start background jobs: `bin/jobs start`
- Log in and browse:
  - Sessions: `/session/new`
  - Transactions: `/` and `/transactions/:id`
  - Emails: `/email` and `/email/:id`
  - Link Gmail: `/oauth/google/start`
  - Health: `/up`

Frontend notes
- Importmap + Turbo + Stimulus: see `config/importmap.rb` and `app/javascript/controllers`
- TailwindCSS via `tailwindcss-rails` is watched by `Procfile.dev`

---

### Testing, linting, and security checks
Run the test suite:
```bash
bin/rails test
```
System tests use Capybara/Selenium; install a compatible browser/driver if you add system specs.

Static analysis and security:
```bash
# RuboCop (Rails Omakase)
bin/rubocop

# Brakeman (security)
bin/brakeman

# Bundler Audit (dependencies)
bin/bundler-audit check --update
```

---

### Deployment
Docker (production-oriented image)
```bash
docker build -t finance_manager .
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=<value from config/master.key> \
  -e OPENAI_API_KEY=<...> \
  -e GOOGLE_API_CLIENT_ID=<...> \
  -e GOOGLE_API_CLIENT_SECRET=<...> \
  --name finance_manager finance_manager
```
The image uses Thruster (`bin/thrust`) to launch the Rails server and expects precompiled assets.

Kamal
1) Configure `config/deploy.yml` for your environment/registries/hosts.
2) Deploy:
```bash
bundle exec kamal setup
bundle exec kamal deploy
```

Environment variables/secrets
- Provide `RAILS_MASTER_KEY` in production to unlock credentials
- Or rely on external secret stores and environment variables

---

### Troubleshooting
- Gmail redirect mismatch: Ensure redirect URI is `http://localhost:3000/oauth/google/callback` in GCP.
- Missing refresh token: Revoke and re-consent with prompt; the app requests `access_type=offline`.
- Gmail errors or reauth: The app resets tokens and prompts re-linking if authorization fails.
- No transactions created: Check OpenAI key, model availability, and logs for JSON parse issues.
- Tailwind styles missing in dev: Ensure `bin/dev` is running (watches CSS).
- Jobs not processing: Ensure `bin/jobs start` is running and DB queue tables exist; check `config/queue.yml`.

---

### Contributing
- Create a feature branch, add tests, keep changes focused.
- Run `bin/rails test`, `bin/rubocop`, `bin/brakeman`, and `bin/bundler-audit` before opening a PR.
- Follow Rails conventions and keep code readable and small-scoped.

---

### License
This project’s license is currently unspecified. If you plan to distribute or open-source it, add an appropriate LICENSE file and update this section.

