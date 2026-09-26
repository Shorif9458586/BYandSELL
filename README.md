# E-Vumi Seba — MVP

Bangla-first private land-service assistance platform.

## Stack
- Next.js + React + TypeScript
- Tailwind CSS
- Supabase Auth / PostgreSQL / RLS / Private Storage
- Lucide icons

## Run locally
1. Install Node.js 20+.
2. `npm install`
3. Copy `.env.example` to `.env.local`.
4. Create a Supabase project.
5. Run `supabase/schema.sql` in Supabase SQL Editor.
6. Add Supabase URL + anon key to `.env.local`.
7. `npm run dev`

## Important
This starter intentionally does not fake government APIs, payment success, approvals, land records or document issuance. Connect only legally authorized services.

## MVP routes
- `/` public homepage
- `/services` service catalogue
- `/services/namjari` service details
- `/track` application tracking UI
- `/login`, `/register`
- `/dashboard` agent dashboard UI

## Next implementation
Connect Supabase Auth, server-side role checks, application creation server actions, private storage signed URLs, payment gateway, invoice PDF, notifications, staff assignment and audit triggers.

## Security
Never expose `SUPABASE_SERVICE_ROLE_KEY` to the browser. Public tracking must verify Application ID + registered mobile and return only minimal non-sensitive fields.
