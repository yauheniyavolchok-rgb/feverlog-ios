-- Supabase's Performance Advisor flags RLS policies that call a function
-- directly (not wrapped in a subquery) in their USING/WITH CHECK clause:
-- Postgres re-evaluates the call once per row scanned rather than caching
-- it as a stable subplan. Wrapping each call in `(select ...)` fixes this
-- without changing access behavior at all — same rules, cheaper to
-- evaluate as row counts grow.

alter policy households_select on households
  using ((select public.is_household_member(id)));

alter policy household_members_select on household_members
  using ((select public.is_household_member(household_id)));

alter policy household_invites_select on household_invites
  using ((select public.is_household_member(household_id)));

alter policy children_select on children
  using ((select public.is_household_member(household_id)));
alter policy children_insert on children
  with check ((select public.is_household_member(household_id)));
alter policy children_update on children
  using ((select public.is_household_member(household_id)))
  with check ((select public.is_household_member(household_id)));

alter policy weight_history_select on weight_history
  using ((select public.is_child_accessible(child_id)));
alter policy weight_history_insert on weight_history
  with check ((select public.is_child_accessible(child_id)));
alter policy weight_history_update on weight_history
  using ((select public.is_child_accessible(child_id)))
  with check ((select public.is_child_accessible(child_id)));

alter policy temperature_logs_select on temperature_logs
  using ((select public.is_child_accessible(child_id)));
alter policy temperature_logs_insert on temperature_logs
  with check ((select public.is_child_accessible(child_id)));
alter policy temperature_logs_update on temperature_logs
  using ((select public.is_child_accessible(child_id)))
  with check ((select public.is_child_accessible(child_id)));

alter policy medication_logs_select on medication_logs
  using ((select public.is_child_accessible(child_id)));
alter policy medication_logs_insert on medication_logs
  with check ((select public.is_child_accessible(child_id)));
alter policy medication_logs_update on medication_logs
  using ((select public.is_child_accessible(child_id)))
  with check ((select public.is_child_accessible(child_id)));

alter policy symptoms_select on symptoms
  using ((select public.is_child_accessible(child_id)));
alter policy symptoms_insert on symptoms
  with check ((select public.is_child_accessible(child_id)));
alter policy symptoms_update on symptoms
  using ((select public.is_child_accessible(child_id)))
  with check ((select public.is_child_accessible(child_id)));

alter policy notes_select on notes
  using ((select public.is_child_accessible(child_id)));
alter policy notes_insert on notes
  with check ((select public.is_child_accessible(child_id)));
alter policy notes_update on notes
  using ((select public.is_child_accessible(child_id)))
  with check ((select public.is_child_accessible(child_id)));

alter policy quick_logs_select on quick_logs
  using ((select public.is_child_accessible(child_id)));
alter policy quick_logs_insert on quick_logs
  with check ((select public.is_child_accessible(child_id)));
alter policy quick_logs_update on quick_logs
  using ((select public.is_child_accessible(child_id)))
  with check ((select public.is_child_accessible(child_id)));
