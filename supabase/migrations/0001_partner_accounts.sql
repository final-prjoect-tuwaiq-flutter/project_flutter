-- ============================================================
-- حسابات الشركاء: منظّم فعاليات / مالك منشأة
-- بعد اعتماد الطلب يستطيع الشريك نشر الأماكن مباشرة في events3
-- شغّل هذا الملف في Supabase → SQL Editor
-- ============================================================

create table if not exists public.partner_accounts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null unique references auth.users (id) on delete cascade,
  partner_type  text not null check (partner_type in ('organizer', 'venue_owner')),
  display_name  text not null,
  contact_phone text,
  website       text,
  notes         text,
  status        text not null default 'pending'
                check (status in ('pending', 'approved', 'rejected')),
  review_note   text,          -- سبب الرفض أو ملاحظة الفريق، يظهر للمستخدم
  created_at    timestamptz not null default now(),
  reviewed_at   timestamptz
);

create index if not exists partner_accounts_status_idx
  on public.partner_accounts (status);

alter table public.partner_accounts enable row level security;

-- المستخدم يقرأ طلبه فقط
drop policy if exists "partner reads own row" on public.partner_accounts;
create policy "partner reads own row"
  on public.partner_accounts for select
  using (auth.uid() = user_id);

-- المستخدم ينشئ طلبه الخاص، ويبدأ دائماً بحالة pending
drop policy if exists "partner inserts own row" on public.partner_accounts;
create policy "partner inserts own row"
  on public.partner_accounts for insert
  with check (auth.uid() = user_id and status = 'pending');

-- إعادة إرسال طلب مرفوض. الاعتماد يتم من لوحة Supabase بمفتاح service_role،
-- ولا يستطيع المستخدم ترقية نفسه إلى approved.
drop policy if exists "partner updates own pending row" on public.partner_accounts;
create policy "partner updates own pending row"
  on public.partner_accounts for update
  using (auth.uid() = user_id and status <> 'approved')
  with check (auth.uid() = user_id and status = 'pending');

-- ============================================================
-- دالة مساعدة: هل المستخدم الحالي شريك معتمد؟
-- ============================================================
create or replace function public.is_approved_partner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.partner_accounts
    where user_id = auth.uid()
      and status  = 'approved'
  );
$$;

-- ============================================================
-- النشر المباشر في الدليل
-- ============================================================

-- عمود يربط المكان بناشره (التطبيق يرسله مع كل نشر مباشر)
alter table public.events3
  add column if not exists created_by uuid references auth.users (id);

alter table public.events3 enable row level security;

-- القراءة مفتوحة للجميع كما كانت (التصفح متاح بدون تسجيل دخول)
drop policy if exists "places are public" on public.events3;
create policy "places are public"
  on public.events3 for select
  using (true);

-- الإدراج للشركاء المعتمدين فقط، وباسمهم هم
drop policy if exists "approved partners publish places" on public.events3;
create policy "approved partners publish places"
  on public.events3 for insert
  with check (public.is_approved_partner() and created_by = auth.uid());

-- الشريك يعدّل أماكنه هو فقط
drop policy if exists "partners update own places" on public.events3;
create policy "partners update own places"
  on public.events3 for update
  using (public.is_approved_partner() and created_by = auth.uid())
  with check (created_by = auth.uid());

-- ============================================================
-- الاعتماد (يُنفَّذ من SQL Editor / لوحة التحكم، لا من التطبيق)
--
--   update public.partner_accounts
--   set status = 'approved', reviewed_at = now()
--   where user_id = '<UUID المستخدم>';
--
-- الرفض مع توضيح السبب:
--
--   update public.partner_accounts
--   set status = 'rejected', reviewed_at = now(),
--       review_note = 'نحتاج إثبات ملكية المنشأة'
--   where user_id = '<UUID المستخدم>';
-- ============================================================
