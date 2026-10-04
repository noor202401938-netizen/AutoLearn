# AutoLearn 🎓

**AutoLearn** teaches economics the way a good teacher would: short readings that explain the intuition, a supply-and-demand lab you can push around yourself, practice quizzes with worked explanations, assignments marked with feedback, and an AI tutor to ask when you're stuck. Built with Flutter (web/mobile), Node.js/Express + Prisma (MongoDB), Redis and MinIO.

## ✏️ Design: the lecture notebook

The interface is a student's notebook, not a dashboard template:

- **Paper & ink** (light) / **blackboard & chalk** (dark) — graph-paper pages, fountain-pen ink, a red margin rule.
- **Handwriting for annotations** (Caveat), a bookish serif for headings (Fraunces), IBM Plex for reading and Plex Mono for figures. All fonts are bundled — no runtime calls to Google.
- **Economics as the visual language** — the hand-sketched supply & demand diagram is the logo, the empty-state illustration and the interactive lab.
- Notebook components live in `lib/widgets/notebook/` (`GraphPaper`, `NoteCard`, `Highlight`, `MarginNote`, `NoteHeading`, `NoteText`, `SupplyDemandSketch`, `NotebookShell`). Colours come from `ColorScheme` + the `NotebookColors` theme extension in `lib/theme/app_theme.dart` — don't hardcode hex values in screens.

---

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose ≥ 3.8
- Flutter SDK ≥ 3.0.0 (for local development)
- Node.js ≥ 20 (for local backend development)

### Run with Docker Compose (Recommended)

```bash
# 1. Clone the repository
git clone <repo-url>
cd economics-learner-app-main

# 2. Configure environment variables
cp backend/.env.example backend/.env
# Edit backend/.env with your secrets (JWT_SECRET, OPENAI_API_KEY, etc.)
# By default, Docker Compose connects to the included local MongoDB container.
# For production, set DATABASE_URL to your MongoDB Atlas connection string.

# 3. Start all services
docker compose up --build

# 4. Services will be available at:
# Frontend:  http://localhost:8080
# Backend:   http://localhost:3001
# MinIO UI:  http://localhost:9001
```

### Admin Credentials (auto-seeded)
| Field | Value |
|-------|-------|
| Email | `admin@autolearn.com` |
| Password | `admin123` |
| Role | Admin |

> ⚠️ **Change the admin password immediately in production.**

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter App                          │
│  (Android / iOS / Web — Material 3, Dark/Light Theme)   │
└──────────────────────┬──────────────────────────────────┘
                       │ REST API (JWT Bearer)
                       ▼
┌─────────────────────────────────────────────────────────┐
│           Nginx (Reverse Proxy / Load Balancer)         │
│  • Routes traffic & balances load across replicas       │
└──────────────────────┬──────────────────────────────────┘
                       │ (Balances 2 Replicas)
                       ▼
┌─────────────────────────────────────────────────────────┐
│             Node.js / Express Backend (x2 Replicas)      │
│  • Helmet (security headers)                            │
│  • Rate limiting (Distributed via Redis)                │
│  • JWT auth middleware (7-day tokens)                   │
└──────────┬──────────────────────┬────────────────────────┘
           │                      │
           ▼                      ▼
┌──────────────────┐    ┌──────────────────────────┐
│  MongoDB Atlas   │    │  MinIO Object Storage    │
│  or Local Mongo  │    │  (video/media files)     │
│ (via Prisma ORM) │    └──────────────────────────┘
└──────────────────┘    ┌──────────────────────────┐
                        │        Redis 7           │
                        │ (Rate limits / Sessions) │
                        └──────────────────────────┘
```

---

## 📋 API Endpoints

❌ public · ✅ signed in · 🔒 admin. All paths are under `/api`.

| Area | Endpoints |
|------|-----------|
| Auth | ❌ `POST /auth/signup`, `POST /auth/login`, `POST /auth/password-reset`, `POST /auth/password-reset/confirm` · ✅ `GET /auth/me`, `POST /auth/change-password` · 🔒 `GET /auth/users`, `PATCH /auth/users/:uid/toggle-status` |
| Users | ✅ `GET /users/:uid` (self) · 🔒 `PUT /users/:uid/role`, `DELETE /users/:uid` |
| Courses | ❌ `GET /courses`, `GET /courses/:id` · ✅ `POST /courses/:id/enroll` (free courses), `POST /courses/:id/rate` (enrolled, one rating each) · 🔒 `POST/PUT/DELETE /courses[/:id]` — `syllabus` in the body creates/updates/deletes chapters and lessons |
| Learning | ✅ `GET /quizzes/lesson/:lessonId` (no answers until submitted), `POST /user/quizzes/:quizId/submit` (graded on the server), `GET /assignments/lesson/:lessonId`, `GET /user/assignments`, `POST /user/assignments/:id/submit` (AI feedback), `GET/POST /user/certificates` (issued only when earned), `GET /user/courses/:id/progress` · 🔒 `POST /quizzes`, `POST /assignments` |
| Study tools | ✅ `GET/POST/DELETE /user/bookmarks`, `GET /learning-paths`, forum: `GET/POST /forum/threads`, `GET/DELETE /forum/threads/:id`, `POST /forum/threads/:id/{replies,upvote,accept}`, `POST /forum/replies/:id/upvote` · 🔒 `POST/PUT/DELETE /learning-paths` |
| AI tutor | ✅ `POST /chat/session`, `GET /chat/sessions`, `GET /chat/:id/history`, `POST /chat/:id/message`, `DELETE /chat/:id`, `POST /ai/quiz`, `POST /ai/summary`, `POST /ai/chat` — all AI runs server-side; the app holds no AI key |
| Profile & progress | ✅ `GET/PUT /user/profile`, `GET /user/stats`, `POST /user/progress`, `GET /user/progress/:lessonId`, `GET /user/enrollments`, notifications (`GET`, `unread-count`, `read-all`, `:id/read`) · 🔒 broadcast + history |
| Payments | ✅ `POST /payments/checkout` (Stripe Checkout; price from the database) · Stripe → `POST /payments/webhook` (signature required) · 🔒 `GET /payments`, `POST /payments/:id/refund`, `GET /finance/stats`, `GET /admin/analytics` |

### Environment you'll want to set
`JWT_SECRET`, `DATABASE_URL` (Prisma needs a MongoDB **replica set** — the compose file runs a single-node one), `OPENAI_API_KEY` (tutor, quiz generation, assignment feedback; disabled without it), `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` (paid courses), `APP_URL` + `SMTP_URL` (password-reset emails; without SMTP the link is logged in development). See `backend/.env.example`.

---

## 📊 Capacity & Performance Specifications

### How Many Users Can AutoLearn Handle?

| Deployment | Concurrent Users | Total Registered | Notes |
|------------|-----------------|------------------|-------|
| **Current Docker Compose Setup** | ~2,000 | ~500,000 | Horizontally scaled locally |
| **Cloud-native (ECS/GKE + RDS + CDN)** | ~10,000+ | Unlimited | With auto-scaling |

**Recently Solved Scaling Bottlenecks:**
- ✅ Added **PgBouncer** connection pooler in front of PostgreSQL.
- ✅ Added a **Redis** layer for distributed rate limiting state.
- ✅ Added **Nginx** reverse proxy for load balancing.
- ✅ Enabled **horizontal backend scaling** (2 replicas running simultaneously).

---

## 🔒 Security Features

- **JWT Authentication** — 7-day expiry tokens stored in `flutter_secure_storage`
- **Password Hashing** — bcrypt with cost factor 12
- **Rate Limiting** — 200 req/15min globally, 20 req/15min on auth endpoints
- **Security Headers** — Helmet.js (CSP, HSTS, X-Frame-Options, etc.)
- **Role-Based Access Control** — Student vs Admin enforced at controller level
- **Account Status Check** — Disabled accounts are rejected on login
- **Input Validation** — Required field checks on all mutation endpoints
- **Cascade Deletes** — Database referential integrity via Prisma relations
- **Secure Storage** — JWT tokens stored in OS keychain via `flutter_secure_storage`

---

## 🧰 Technical Specifications

### Backend
| Property | Value |
|----------|-------|
| Runtime | Node.js 20 LTS |
| Framework | Express 5.x |
| ORM | Prisma 5.x |
| Database | PostgreSQL 15 |
| Auth | JWT (jwt-simple), bcrypt 12 rounds |
| File Storage | MinIO (S3-compatible) |
| AI | OpenAI GPT-3.5 Turbo |
| Payments | Stripe |
| TypeScript | Strict mode |
| Container | Docker (Alpine-based) |

### Frontend (Flutter)
| Property | Value |
|----------|-------|
| SDK | Flutter ≥ 3.0.0 / Dart ≥ 3.0.0 |
| Design System | Material 3 |
| Theming | Full dark/light + high-contrast support |
| HTTP | `package:http` with bearer token auth |
| Auth Storage | `flutter_secure_storage` |
| Video | `youtube_player_flutter` + `video_player` |
| PDF | `pdf` + `printing` packages |
| Payments | `flutter_stripe` |
| Config | `flutter_dotenv` |

### Infrastructure (Docker)
| Service | Image | RAM Limit | Notes |
|---------|-------|-----------|-------|
| Nginx | nginx:alpine | 256 MB | Load Balancer |
| PostgreSQL | postgres:15-alpine | 512 MB | Primary Database |
| PgBouncer | edoburu/pgbouncer | 256 MB | Connection Pooler |
| Redis | redis:7-alpine | 256 MB | Distributed Cache |
| MinIO | minio/minio | 256 MB | File Storage |
| Backend | node:20-alpine (custom) | 1 GB (x2) | 2 Replicas |
| Frontend | nginx:alpine (custom) | 256 MB | Web UI |

---

## 📈 Non-Functional Requirements

### Performance
- API response time (P95): **< 200ms** for read operations under normal load
- Database query time (P95): **< 50ms** with proper indexes
- App startup time: **< 3 seconds** on mid-range device

### Availability
- Target uptime: **99.9%** (8.7 hours downtime/year)
- All Docker services configured with `restart: unless-stopped`
- Health checks on all services

### Scalability
- Backend is **stateless** — can horizontally scale behind a load balancer
- Database supports **connection pooling** via PgBouncer
- File storage (MinIO) can be replaced with **AWS S3** with no code changes

### Reliability
- Enrollment uses `upsert` to prevent duplicate entries
- JWT tokens include `exp` claim for automatic expiry
- Database cascades properly delete related records
- Error boundaries at both UI and API layers

### Security
- OWASP Top 10 mitigations: rate limiting, input validation, auth checks, secure headers
- Environment variables for all secrets — no hardcoded credentials
- `.env` excluded from Git via `.gitignore`

### Maintainability
- Layered architecture: UI → Business Logic → Repository → API Client → Backend
- TypeScript strict mode on backend
- Prisma schema as single source of truth for database structure

---

## 🛠️ Local Development

### Backend Only
```bash
cd backend
cp .env.example .env   # Configure your .env
npm install
npx prisma db push     # Create tables
npm run seed           # Create admin user
npm run dev            # Start development server
```

### Flutter App Only
```bash
flutter pub get
# Edit .env with: API_BASE_URL=http://localhost:3001/api
flutter run
```

---

## 📁 Project Structure

```
autolearn/
├── lib/                          # Flutter app
│   ├── backend/
│   │   └── api_client.dart       # HTTP client with JWT auth
│   ├── business_logic/           # Domain logic layer
│   ├── model/                    # Data models
│   ├── repository/               # API data access layer
│   ├── screens/
│   │   ├── admin/                # Admin dashboard screens
│   │   └── student/              # Student-facing screens
│   ├── theme.dart                # App-wide Material 3 theme
│   └── main.dart                 # App entry point
├── backend/
│   ├── src/
│   │   ├── controllers/          # Request handlers
│   │   ├── middleware/           # Auth & security middleware
│   │   └── routes/               # Express route definitions
│   ├── prisma/
│   │   ├── schema.prisma         # Database schema
│   │   └── seed.ts               # Admin user seeding
│   ├── .env                      # Backend environment (gitignored)
│   └── Dockerfile
├── docker-compose.yml            # Full stack orchestration
└── .env                          # Flutter environment (gitignored)
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.