-- ============================================================
-- بيانات المستخدم: المفضلة وسجل الزيارات
-- الجدولان منشآن مسبقاً ويستعملهما التطبيق بالأعمدة:
--   user_favorites : user_id, place_id
--   user_visited   : id, user_id, place_id, notes, visited_at
-- هذا الملف يضبط سياسات RLS فقط: كل مستخدم يرى ويعدّل صفوفه وحده.
-- بدونها يستطيع أي مستخدم مسجّل قراءة مفضلة غيره أو حذف زياراتهم.
-- شغّله في Supabase → SQL Editor.
-- ============================================================

-- ---------- المفضلة ----------
alter table public.user_favorites enable row level security;

drop policy if exists "favorites are private" on public.user_favorites;
create policy "favorites are private"
  on public.user_favorites for select
  using (auth.uid() = user_id);

drop policy if exists "user inserts own favorite" on public.user_favorites;
create policy "user inserts own favorite"
  on public.user_favorites for insert
  with check (auth.uid() = user_id);

drop policy if exists "user deletes own favorite" on public.user_favorites;
create policy "user deletes own favorite"
  on public.user_favorites for delete
  using (auth.uid() = user_id);

-- صف واحد لكل (مستخدم، مكان): التطبيق يعتمد على رمز التعارض 23505
-- ليتجاهل الإضافة المكرّرة بهدوء.
create unique index if not exists user_favorites_user_place_key
  on public.user_favorites (user_id, place_id);

-- ---------- سجل الزيارات ----------
alter table public.user_visited enable row level security;

drop policy if exists "visits are private" on public.user_visited;
create policy "visits are private"
  on public.user_visited for select
  using (auth.uid() = user_id);

drop policy if exists "user inserts own visit" on public.user_visited;
create policy "user inserts own visit"
  on public.user_visited for insert
  with check (auth.uid() = user_id);

drop policy if exists "user deletes own visit" on public.user_visited;
create policy "user deletes own visit"
  on public.user_visited for delete
  using (auth.uid() = user_id);

create index if not exists user_visited_user_id_idx
  on public.user_visited (user_id);
