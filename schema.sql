-- E-Vumi Seba MVP schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;

create type public.app_role as enum ('super_admin','staff','agent','customer');
create type public.application_status as enum ('NEW','DOCUMENTS_REQUIRED','DOCUMENTS_SUBMITTED','UNDER_REVIEW','PROCESSING','WAITING_FOR_OFFICIAL_PROCESS','ADDITIONAL_INFORMATION_REQUIRED','READY_FOR_DELIVERY','DELIVERED','COMPLETED','REJECTED','CANCELLED','REFUND_PENDING','REFUNDED');
create type public.payment_status as enum ('PENDING','PAID','FAILED','REFUNDED','PARTIAL');
create type public.commission_status as enum ('PENDING','APPROVED','PAYABLE','PAID','REVERSED');

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null,
 mobile text,
 email text,
 avatar_url text,
 created_at timestamptz default now(),
 updated_at timestamptz default now()
);
create table public.user_roles (
 user_id uuid references public.profiles(id) on delete cascade,
 role public.app_role not null,
 primary key(user_id,role)
);
create table public.agents (
 id uuid primary key default gen_random_uuid(),
 user_id uuid unique references public.profiles(id) on delete cascade,
 agent_code text unique not null,
 status text not null default 'pending' check(status in ('pending','active','suspended','rejected')),
 address text, assigned_area text, nid_verified boolean default false,
 commission_plan jsonb default '{}'::jsonb,
 created_at timestamptz default now(), updated_at timestamptz default now()
);
create table public.customers (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references public.profiles(id) on delete set null,
 agent_id uuid references public.agents(id) on delete set null,
 full_name text not null, mobile text not null, email text, address text,
 verification_status text default 'unverified',
 created_at timestamptz default now(), updated_at timestamptz default now()
);
create table public.service_categories (
 id uuid primary key default gen_random_uuid(),
 name_bn text not null, name_en text, description text, active boolean default true,
 created_at timestamptz default now(), updated_at timestamptz default now()
);
create table public.services (
 id uuid primary key default gen_random_uuid(),
 category_id uuid references public.service_categories(id) on delete set null,
 name_bn text not null, name_en text, slug text unique not null, description text,
 official_fee numeric(12,2) default 0 check(official_fee>=0),
 other_cost numeric(12,2) default 0 check(other_cost>=0),
 service_fee numeric(12,2) default 0 check(service_fee>=0),
 commission_type text default 'fixed' check(commission_type in ('fixed','percentage')),
 commission_value numeric(12,2) default 0 check(commission_value>=0),
 estimated_time text, active boolean default true, disclaimer text,
 created_at timestamptz default now(), updated_at timestamptz default now()
);
create table public.service_required_documents (
 id uuid primary key default gen_random_uuid(),
 service_id uuid references public.services(id) on delete cascade,
 name_bn text not null, required boolean default true, instructions text,
 created_at timestamptz default now()
);
create table public.applications (
 id uuid primary key default gen_random_uuid(),
 application_code text unique not null,
 customer_id uuid references public.customers(id) on delete restrict,
 agent_id uuid references public.agents(id) on delete set null,
 service_id uuid references public.services(id) on delete restrict,
 applicant_name text not null, mobile text not null, email text,
 district text, upazila text, mouza text, jl_number text, khatian_number text, dag_number text,
 land_area text, ownership_info text, notes text,
 status public.application_status not null default 'NEW',
 payment_status public.payment_status not null default 'PENDING',
 assigned_staff uuid references public.profiles(id) on delete set null,
 delivery_status text default 'pending',
 created_at timestamptz default now(), updated_at timestamptz default now()
);
create table public.application_status_history (
 id uuid primary key default gen_random_uuid(),
 application_id uuid references public.applications(id) on delete cascade,
 old_status public.application_status,
 new_status public.application_status not null,
 changed_by uuid references public.profiles(id) on delete set null,
 note text, created_at timestamptz default now()
);
create table public.documents (
 id uuid primary key default gen_random_uuid(),
 application_id uuid references public.applications(id) on delete cascade,
 uploaded_by uuid references public.profiles(id) on delete set null,
 document_type text not null, storage_path text not null,
 file_name text not null, mime_type text, size_bytes bigint,
 verification_status text default 'pending' check(verification_status in ('pending','verified','rejected')),
 rejection_reason text, created_at timestamptz default now()
);
create table public.payments (
 id uuid primary key default gen_random_uuid(),
 application_id uuid references public.applications(id) on delete restrict,
 customer_id uuid references public.customers(id) on delete set null,
 agent_id uuid references public.agents(id) on delete set null,
 amount numeric(12,2) not null check(amount>=0),
 official_fee numeric(12,2) default 0,
 other_cost numeric(12,2) default 0,
 service_fee numeric(12,2) default 0,
 method text, transaction_id text, status public.payment_status default 'PENDING',
 paid_at timestamptz, created_at timestamptz default now()
);
create table public.commissions (
 id uuid primary key default gen_random_uuid(),
 application_id uuid references public.applications(id) on delete restrict,
 agent_id uuid references public.agents(id) on delete restrict,
 amount numeric(12,2) not null check(amount>=0),
 status public.commission_status default 'PENDING',
 earned_at timestamptz default now(), payable_at timestamptz, paid_at timestamptz,
 payment_reference text, created_at timestamptz default now()
);
create table public.withdrawal_requests (
 id uuid primary key default gen_random_uuid(),
 agent_id uuid references public.agents(id) on delete restrict,
 amount numeric(12,2) not null check(amount>0),
 method text, account_reference text, status text default 'pending' check(status in ('pending','approved','rejected','paid')),
 admin_note text, created_at timestamptz default now(), updated_at timestamptz default now()
);
create table public.support_tickets (
 id uuid primary key default gen_random_uuid(),
 created_by uuid references public.profiles(id) on delete set null,
 application_id uuid references public.applications(id) on delete set null,
 subject text not null, priority text default 'normal',
 status text default 'OPEN' check(status in ('OPEN','IN_PROGRESS','WAITING_FOR_USER','RESOLVED','CLOSED')),
 assigned_staff uuid references public.profiles(id) on delete set null,
 created_at timestamptz default now(), updated_at timestamptz default now()
);
create table public.support_messages (
 id uuid primary key default gen_random_uuid(),
 ticket_id uuid references public.support_tickets(id) on delete cascade,
 sender_id uuid references public.profiles(id) on delete set null,
 message text not null, attachment_path text, created_at timestamptz default now()
);
create table public.notifications (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references public.profiles(id) on delete cascade,
 title text not null, body text not null, read_at timestamptz, created_at timestamptz default now()
);
create table public.audit_logs (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid references public.profiles(id) on delete set null,
 action text not null, object_type text, object_id uuid, metadata jsonb default '{}'::jsonb,
 created_at timestamptz default now()
);
create table public.settings (key text primary key, value jsonb not null, updated_at timestamptz default now());
create table public.faq (id uuid primary key default gen_random_uuid(), question text not null, answer text not null, active boolean default true, created_at timestamptz default now());
create table public.contact_messages (id uuid primary key default gen_random_uuid(), name text, mobile text, email text, message text not null, created_at timestamptz default now());

create index applications_customer_idx on public.applications(customer_id);
create index applications_agent_idx on public.applications(agent_id);
create index applications_status_idx on public.applications(status);
create index applications_code_idx on public.applications(application_code);
create index documents_application_idx on public.documents(application_id);
create index payments_application_idx on public.payments(application_id);
create index commissions_agent_idx on public.commissions(agent_id);

-- Helper functions for RLS.
create or replace function public.has_role(target_role public.app_role)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.user_roles ur where ur.user_id=auth.uid() and ur.role=target_role);
$$;
create or replace function public.is_staff_or_admin()
returns boolean language sql stable security definer set search_path=public as $$
 select public.has_role('staff') or public.has_role('super_admin');
$$;

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.agents enable row level security;
alter table public.customers enable row level security;
alter table public.services enable row level security;
alter table public.service_categories enable row level security;
alter table public.service_required_documents enable row level security;
alter table public.applications enable row level security;
alter table public.application_status_history enable row level security;
alter table public.documents enable row level security;
alter table public.payments enable row level security;
alter table public.commissions enable row level security;
alter table public.withdrawal_requests enable row level security;
alter table public.notifications enable row level security;
alter table public.support_tickets enable row level security;
alter table public.support_messages enable row level security;
alter table public.audit_logs enable row level security;

create policy "profile self/admin" on public.profiles for select using (id=auth.uid() or public.has_role('super_admin') or public.has_role('staff'));
create policy "profile self update" on public.profiles for update using (id=auth.uid());
create policy "roles self/admin" on public.user_roles for select using (user_id=auth.uid() or public.has_role('super_admin'));
create policy "public active services" on public.services for select using (active=true or public.is_staff_or_admin());
create policy "public active categories" on public.service_categories for select using (active=true or public.is_staff_or_admin());
create policy "required docs visible" on public.service_required_documents for select using (exists(select 1 from public.services s where s.id=service_id and s.active=true) or public.is_staff_or_admin());
create policy "admin agents" on public.agents for all using (public.has_role('super_admin') or user_id=auth.uid());
create policy "customer own data" on public.customers for select using (user_id=auth.uid() or public.is_staff_or_admin() or exists(select 1 from public.agents a where a.id=agent_id and a.user_id=auth.uid()));
create policy "customer insert" on public.customers for insert with check (user_id=auth.uid() or public.has_role('agent') or public.is_staff_or_admin());
create policy "app authorized read" on public.applications for select using (
 public.is_staff_or_admin()
 or exists(select 1 from public.customers c where c.id=customer_id and c.user_id=auth.uid())
 or exists(select 1 from public.agents a where a.id=agent_id and a.user_id=auth.uid())
);
create policy "app authorized insert" on public.applications for insert with check (
 public.is_staff_or_admin() or exists(select 1 from public.agents a where a.id=agent_id and a.user_id=auth.uid())
);
create policy "app staff/admin update" on public.applications for update using (public.is_staff_or_admin() or exists(select 1 from public.agents a where a.id=agent_id and a.user_id=auth.uid()));
create policy "status history authorized" on public.application_status_history for select using (public.is_staff_or_admin() or exists(select 1 from public.applications x join public.agents a on a.id=x.agent_id where x.id=application_id and a.user_id=auth.uid()) or exists(select 1 from public.applications x join public.customers c on c.id=x.customer_id where x.id=application_id and c.user_id=auth.uid()));
create policy "documents authorized" on public.documents for select using (public.is_staff_or_admin() or uploaded_by=auth.uid() or exists(select 1 from public.applications x join public.customers c on c.id=x.customer_id where x.id=application_id and c.user_id=auth.uid()) or exists(select 1 from public.applications x join public.agents a on a.id=x.agent_id where x.id=application_id and a.user_id=auth.uid()));
create policy "documents upload authorized" on public.documents for insert with check (public.is_staff_or_admin() or uploaded_by=auth.uid());
create policy "payments authorized" on public.payments for select using (public.is_staff_or_admin() or customer_id in(select id from public.customers where user_id=auth.uid()) or agent_id in(select id from public.agents where user_id=auth.uid()));
create policy "commissions agent read" on public.commissions for select using (public.has_role('super_admin') or agent_id in(select id from public.agents where user_id=auth.uid()));
create policy "withdrawal agent read/write" on public.withdrawal_requests for all using (public.has_role('super_admin') or agent_id in(select id from public.agents where user_id=auth.uid()));
create policy "notifications own" on public.notifications for select using (user_id=auth.uid());
create policy "tickets authorized" on public.support_tickets for all using (created_by=auth.uid() or public.is_staff_or_admin());
create policy "messages authorized" on public.support_messages for all using (sender_id=auth.uid() or public.is_staff_or_admin());
create policy "audit admin only" on public.audit_logs for select using (public.has_role('super_admin'));

-- Private storage bucket.
insert into storage.buckets (id,name,public) values ('private-documents','private-documents',false) on conflict (id) do nothing;
create policy "private docs read" on storage.objects for select using (
 bucket_id='private-documents' and (public.is_staff_or_admin() or owner_id::uuid=auth.uid())
);
create policy "private docs upload" on storage.objects for insert with check (
 bucket_id='private-documents' and auth.uid() is not null
);

-- Demo categories/services.
insert into public.service_categories(name_bn,name_en) values
('Land Record Services','Land Record Services'),('Mutation / Namjari','Mutation / Namjari'),('Land Tax / Khajna','Land Tax / Khajna'),('Deed / Document Assistance','Deed / Document Assistance')
on conflict do nothing;
