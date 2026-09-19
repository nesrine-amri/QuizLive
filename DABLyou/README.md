# تبّع و أربح (MVP)

Monorepo:

- `mobile/`: Flutter (RTL) — لغة المستخدم: الدارجة التونسية بالعربي
- `backend/`: NestJS + Prisma + PostgreSQL + Socket.IO (أسئلة لايف simulated)

## Architecture technique (MVP)

### Mobile (Flutter)
- Auth email/password
- اختيار: تلفزة / راديو
- قائمة قنوات/راديوات (mocked من الـ backend)
- Session لايف: Socket.IO يستقبل `question`
- Answer: REST `POST /gameplay/answer` للتحقق وربح 10 نقاط
- Rewards: تبديل 1000 نقطة => coupon 15%

### Backend (NestJS)
- REST API (JWT)
- Socket.IO namespace: `/live`
- DB: PostgreSQL (via Prisma)
- Redis: محضّر (مش mandatory في الـ MVP الحالي)
- Live questions: simulated generator يخلق Question في DB ويبعثها في room متاع `media:{mediaId}`

## Schéma DB (Prisma)
الـ schema موجود في `backend/prisma/schema.prisma` ويغطي:
`User`, `Media`, `Question`, `Answer`, `PointEvent`, `Partner`, `Reward`, `Coupon`, `Campaign`.

## API Endpoints (MVP)

### Auth
- `POST /auth/register`
- `POST /auth/login`

### Profile
- `GET /me`
- `PATCH /me`
- `DELETE /me`

### Media
- `GET /media?type=TV|RADIO`
- `POST /media/select` (JWT)

### Gameplay
- `POST /gameplay/answer` (JWT)

### Rewards / Coupons / History
- `GET /rewards` (JWT)
- `POST /rewards/redeem` (JWT)
- `GET /coupons/mine` (JWT)
- `POST /coupons/:id/use` (JWT)
- `GET /points/history` (JWT)

## WebSocket (Socket.IO)
Namespace: `/live`

Rooms:
- `media:{mediaId}`

Events:
- Client -> Server: `join_media` `{ mediaId }`
- Server -> Client: `question` (LiveQuestionPayload)
- Client -> Server: `dev_generate_question` `{ mediaId }` (dev helper)

## Données mockées (MVP)
Seed موجود في `backend/prisma/seed.ts`:
- Media: قنوات تونسية + راديوات
- Partners: MG, Lloyd
- Rewards: 15% / 1000 points

## Lancement local

### Backend
Prérequis: Node 20+ / 22+, و Postgres (أو Docker Desktop).

1) Configure `backend/.env`
2) Start PostgreSQL (Docker):

```bash
docker compose up -d
```

ملاحظة: لازم Docker Desktop يكون شغّال.

3) Prisma migrate + seed:

```bash
cd backend
npx prisma migrate dev --name init
npm run prisma:seed
```

4) Run API:

```bash
cd backend
npm run start:dev
```

Backend runs on `http://localhost:3000`.

### Mobile (Flutter)
Android emulator يستعمل `10.0.2.2` للوصول للـ backend.

```bash
cd mobile
flutter run
```

إذا تحب تبدّل API URL:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=SOCKET_BASE_URL=http://10.0.2.2:3000
```

## Roadmap تقنية للـ IA (بعد الـ MVP)
- Phase 1: manual/semi-manual question creation (done: simulated generator + real-time pipe)
- Phase 2: Python AI service:
  - ingest stream (TV/Radio)
  - ASR (Whisper / faster-whisper)
  - simple topic detection + guardrails
  - generate JSON question payload
  - send to backend via internal API/queue
- Phase 3: ads popup (TV):
  - ad detection (audio fingerprint / logo / schedule)
  - secret word campaign (Campaign + sponsored Question)
  - short validity window 10-15s + aggregated analytics

