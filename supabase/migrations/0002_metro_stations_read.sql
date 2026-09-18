-- ============================================================
-- محطات المترو: قراءة عامة
-- الجدول منشأ مسبقاً بالأعمدة:
--   station_code, station_name, line_name, lat, lng
-- هذا الملف يضبط الصلاحيات فقط حتى يقرأه التطبيق (التصفح متاح للزوار).
-- ============================================================

alter table public.metro_stations enable row level security;

drop policy if exists "metro stations are public" on public.metro_stations;
create policy "metro stations are public"
  on public.metro_stations for select
  using (true);

-- التطبيق يحمّل كل المحطات مرة واحدة ويحسب المسافات محلياً،
-- فلا حاجة لفهرس جغرافي ما دام العدد بالعشرات.
