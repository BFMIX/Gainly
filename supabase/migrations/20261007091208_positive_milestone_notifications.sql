alter table public.notification_preferences
add column positive_milestones boolean not null default false;
