-- The client always sends `created_by: currentUserID` on every upload,
-- including updates to a record it didn't originally create (the upload
-- payload is a full snapshot, not a diff — see SyncUploadProcessor's
-- header comment). Without this trigger, a household member editing
-- another member's record would silently overwrite the real author,
-- losing that audit information. `created_by` must only ever be set at
-- INSERT time; this trigger pins it to the stored value on every UPDATE
-- regardless of what the client sends, so no client bug (present or
-- future) can clobber it.

create or replace function public.preserve_created_by()
returns trigger
language plpgsql
as $$
begin
  new.created_by := old.created_by;
  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array[
    'children', 'weight_history', 'temperature_logs', 'medication_logs',
    'symptoms', 'notes', 'quick_logs'
  ]
  loop
    execute format('create trigger %I_preserve_created_by before update on %I for each row execute function public.preserve_created_by()', t, t);
  end loop;
end $$;
