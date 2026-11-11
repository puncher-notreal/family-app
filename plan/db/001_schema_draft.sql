-- Family App v0.1 — PostgreSQL architectural schema draft.
-- Do not apply to production until permissions, migration generation,
-- delete policy, indexes and legal requirements have passed review.
-- API must check family and child scope for EVERY operation: FK is not sufficient.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  email_verified_at TIMESTAMPTZ,
  preferred_language TEXT NOT NULL DEFAULT 'ru' CHECK (preferred_language IN ('ru','en')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX users_email_ci_unique ON users (lower(email)) WHERE deleted_at IS NULL;

CREATE TABLE families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT,
  owner_user_id UUID NOT NULL REFERENCES users(id),
  timezone TEXT NOT NULL DEFAULT 'UTC',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  user_id UUID NOT NULL REFERENCES users(id),
  permission_profile TEXT NOT NULL CHECK (permission_profile IN ('owner','co_parent','helper')),
  relation_label TEXT NOT NULL CHECK (relation_label IN ('mother','father','grandmother','grandfather','older_brother','older_sister','guardian','other')),
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at TIMESTAMPTZ,
  UNIQUE (family_id, user_id)
);
CREATE INDEX family_members_user_idx ON family_members(user_id, family_id);

CREATE TABLE adult_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  refresh_token_hash TEXT NOT NULL UNIQUE,
  token_family_id UUID NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX adult_sessions_user_idx ON adult_sessions(user_id, revoked_at);

CREATE TABLE children (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  display_name TEXT NOT NULL,
  age_band TEXT CHECK (age_band IN ('7-9','10-12')),
  preferred_language TEXT NOT NULL DEFAULT 'ru' CHECK (preferred_language IN ('ru','en')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  archived_at TIMESTAMPTZ
);
CREATE INDEX children_family_idx ON children(family_id);

CREATE TABLE family_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  invited_email TEXT NOT NULL,
  token_hash TEXT NOT NULL UNIQUE,
  permission_profile TEXT NOT NULL CHECK (permission_profile IN ('co_parent','helper')),
  relation_label TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  created_by_user_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE child_pair_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id UUID NOT NULL REFERENCES children(id),
  family_id UUID NOT NULL REFERENCES families(id),
  code_hash TEXT NOT NULL,
  challenge_ref TEXT NOT NULL UNIQUE,
  attempts SMALLINT NOT NULL DEFAULT 0 CHECK (attempts BETWEEN 0 AND 5),
  expires_at TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ,
  created_by_user_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX child_pair_codes_live_idx ON child_pair_codes(code_hash, expires_at) WHERE consumed_at IS NULL;
-- Service must reject collisions among currently unexpired codes and expire old pending codes.

CREATE TABLE child_pair_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pair_code_id UUID NOT NULL REFERENCES child_pair_codes(id),
  child_id UUID NOT NULL REFERENCES children(id),
  device_label TEXT,
  device_challenge_hash TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','expired')),
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  approved_by_user_id UUID REFERENCES users(id),
  decided_at TIMESTAMPTZ
);
CREATE INDEX child_pair_requests_child_idx ON child_pair_requests(child_id, status, requested_at DESC);

CREATE TABLE child_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id UUID NOT NULL REFERENCES children(id),
  device_label TEXT,
  refresh_token_hash TEXT NOT NULL UNIQUE,
  token_family_id UUID NOT NULL,
  push_token_ciphertext BYTEA,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ
);
CREATE INDEX child_devices_child_idx ON child_devices(child_id, revoked_at);

CREATE TABLE school_subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  name TEXT NOT NULL,
  color_key TEXT,
  archived_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX school_subjects_child_idx ON school_subjects(child_id);

CREATE TABLE weekly_lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  subject_id UUID NOT NULL REFERENCES school_subjects(id),
  weekday SMALLINT NOT NULL CHECK (weekday BETWEEN 1 AND 7),
  lesson_slot SMALLINT NOT NULL CHECK (lesson_slot BETWEEN 1 AND 12),
  active BOOLEAN NOT NULL DEFAULT true,
  UNIQUE (child_id, weekday, lesson_slot)
);

CREATE TABLE school_lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  subject_id UUID NOT NULL REFERENCES school_subjects(id),
  lesson_date DATE NOT NULL,
  lesson_slot SMALLINT NOT NULL CHECK (lesson_slot BETWEEN 1 AND 12),
  homework TEXT,
  lesson_note TEXT,
  updated_by_user_id UUID REFERENCES users(id),
  updated_by_child_id UUID REFERENCES children(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (child_id, lesson_date, lesson_slot)
);
CREATE INDEX school_lessons_day_idx ON school_lessons(child_id, lesson_date);

CREATE TABLE school_grades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  lesson_id UUID REFERENCES school_lessons(id),
  subject_id UUID NOT NULL REFERENCES school_subjects(id),
  score SMALLINT NOT NULL CHECK (score BETWEEN 1 AND 5),
  note TEXT,
  scored_at TIMESTAMPTZ NOT NULL,
  created_by_user_id UUID REFERENCES users(id),
  created_by_child_id UUID REFERENCES children(id),
  last_edited_by_user_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT grades_exactly_one_creator CHECK ((created_by_user_id IS NULL) <> (created_by_child_id IS NULL))
);
CREATE INDEX school_grades_child_date_idx ON school_grades(child_id, scored_at, subject_id) WHERE deleted_at IS NULL;

CREATE TABLE teacher_remarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  lesson_id UUID REFERENCES school_lessons(id),
  remark_date DATE NOT NULL,
  body TEXT NOT NULL,
  created_by_user_id UUID REFERENCES users(id),
  created_by_child_id UUID REFERENCES children(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT remarks_exactly_one_creator CHECK ((created_by_user_id IS NULL) <> (created_by_child_id IS NULL))
);

CREATE TABLE diary_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  grade_id UUID REFERENCES school_grades(id),
  actor_user_id UUID REFERENCES users(id),
  action TEXT NOT NULL CHECK (action IN ('grade_created','grade_updated','grade_deleted','lesson_updated','remark_updated')),
  before_json JSONB,
  after_json JSONB,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX diary_audit_child_idx ON diary_audit(child_id, occurred_at DESC);

CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  created_by_member_id UUID NOT NULL REFERENCES family_members(id),
  title TEXT NOT NULL,
  description TEXT,
  points INTEGER NOT NULL DEFAULT 0 CHECK (points BETWEEN 0 AND 100000),
  recurrence_type TEXT NOT NULL CHECK (recurrence_type IN ('once','daily','weekly')),
  weekdays SMALLINT[],
  start_date DATE NOT NULL,
  end_date DATE,
  due_time TIME,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT tasks_date_valid CHECK (end_date IS NULL OR end_date >= start_date)
);
CREATE INDEX tasks_child_idx ON tasks(child_id, active);

CREATE TABLE task_occurrences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  task_id UUID NOT NULL REFERENCES tasks(id),
  scheduled_date DATE NOT NULL,
  due_at TIMESTAMPTZ,
  points_snapshot INTEGER NOT NULL DEFAULT 0 CHECK (points_snapshot BETWEEN 0 AND 100000),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','submitted','completed','cancelled')),
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (task_id, scheduled_date)
);
CREATE INDEX task_occurrences_child_idx ON task_occurrences(child_id, scheduled_date, status);

CREATE TABLE task_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  occurrence_id UUID NOT NULL REFERENCES task_occurrences(id),
  description TEXT NOT NULL CHECK (length(btrim(description)) > 0),
  review_status TEXT NOT NULL DEFAULT 'pending' CHECK (review_status IN ('pending','approved','changes_requested')),
  review_feedback TEXT,
  reviewed_by_user_id UUID REFERENCES users(id),
  reviewed_at TIMESTAMPTZ,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX task_submissions_occ_idx ON task_submissions(occurrence_id, submitted_at DESC);

CREATE TABLE media_assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  owner_child_id UUID REFERENCES children(id),
  uploaded_by_user_id UUID REFERENCES users(id),
  uploaded_by_child_id UUID REFERENCES children(id),
  purpose TEXT NOT NULL CHECK (purpose IN ('task_evidence','wish_image','shop_image')),
  s3_object_key TEXT NOT NULL UNIQUE,
  mime_type TEXT NOT NULL,
  size_bytes BIGINT NOT NULL CHECK (size_bytes > 0),
  state TEXT NOT NULL DEFAULT 'pending' CHECK (state IN ('pending','ready','rejected','deleted')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE submission_media (
  submission_id UUID NOT NULL REFERENCES task_submissions(id),
  media_id UUID NOT NULL REFERENCES media_assets(id),
  PRIMARY KEY(submission_id, media_id)
);

CREATE TABLE point_wallets (
  child_id UUID PRIMARY KEY REFERENCES children(id),
  family_id UUID NOT NULL REFERENCES families(id),
  balance BIGINT NOT NULL DEFAULT 0 CHECK (balance >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE shop_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  title TEXT NOT NULL,
  description TEXT,
  price_points INTEGER NOT NULL CHECK (price_points > 0),
  image_asset_id UUID REFERENCES media_assets(id),
  active BOOLEAN NOT NULL DEFAULT true,
  created_by_user_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  shop_item_id UUID NOT NULL REFERENCES shop_items(id),
  price_points_snapshot INTEGER NOT NULL CHECK (price_points_snapshot > 0),
  item_title_snapshot TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'requested' CHECK (status IN ('requested','approved','fulfilled','declined','cancelled')),
  reviewed_by_user_id UUID REFERENCES users(id),
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  fulfilled_at TIMESTAMPTZ
);
CREATE INDEX redemptions_child_idx ON redemptions(child_id, requested_at DESC);

CREATE TABLE point_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  amount INTEGER NOT NULL CHECK (amount <> 0),
  reason TEXT NOT NULL CHECK (reason IN ('task_approved','shop_reserved','shop_refunded','manual_adjustment')),
  task_occurrence_id UUID REFERENCES task_occurrences(id),
  redemption_id UUID REFERENCES redemptions(id),
  idempotency_key TEXT NOT NULL UNIQUE,
  actor_user_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX point_ledger_child_idx ON point_ledger(child_id, created_at DESC);

CREATE TABLE wishes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  title TEXT NOT NULL,
  description TEXT,
  product_url TEXT,
  image_asset_id UUID REFERENCES media_assets(id),
  fulfilled_at TIMESTAMPTZ,
  fulfilled_by_user_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX wishes_child_idx ON wishes(child_id, created_at DESC);

CREATE TABLE mood_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  local_date DATE NOT NULL,
  score SMALLINT NOT NULL CHECK (score BETWEEN 1 AND 10),
  emoji_key TEXT NOT NULL,
  comment_ciphertext BYTEA,
  comment_nonce BYTEA,
  comment_key_version SMALLINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (child_id, local_date),
  CONSTRAINT mood_cipher_pair CHECK ((comment_ciphertext IS NULL) = (comment_nonce IS NULL))
);
CREATE INDEX mood_child_date_idx ON mood_entries(child_id, local_date DESC);

CREATE TABLE achievement_defs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  title TEXT NOT NULL,
  description TEXT,
  icon_key TEXT NOT NULL DEFAULT 'default_award',
  award_type TEXT NOT NULL DEFAULT 'manual' CHECK (award_type IN ('manual','automatic')),
  rule_json JSONB,
  active BOOLEAN NOT NULL DEFAULT true,
  created_by_user_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE child_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  child_id UUID NOT NULL REFERENCES children(id),
  achievement_def_id UUID NOT NULL REFERENCES achievement_defs(id),
  awarded_by_user_id UUID REFERENCES users(id),
  awarded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX child_achievements_child_idx ON child_achievements(child_id, awarded_at DESC);

CREATE TABLE user_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  platform TEXT NOT NULL CHECK (platform IN ('ios','android')),
  push_token_ciphertext BYTEA,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  recipient_user_id UUID REFERENCES users(id),
  recipient_child_id UUID REFERENCES children(id),
  event_type TEXT NOT NULL,
  payload_minimal JSONB NOT NULL DEFAULT '{}'::jsonb,
  dedupe_key TEXT NOT NULL UNIQUE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT notification_one_recipient CHECK ((recipient_user_id IS NULL) <> (recipient_child_id IS NULL))
);
CREATE INDEX notifications_adult_idx ON notifications(recipient_user_id, created_at DESC);
CREATE INDEX notifications_child_idx ON notifications(recipient_child_id, created_at DESC);

CREATE TABLE notification_outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL UNIQUE REFERENCES notifications(id),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','sent','failed')),
  run_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  attempts SMALLINT NOT NULL DEFAULT 0,
  last_error_code TEXT,
  delivered_at TIMESTAMPTZ
);
CREATE INDEX notification_outbox_due_idx ON notification_outbox(status, run_at);

CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  talk_reminder_enabled BOOLEAN NOT NULL DEFAULT true,
  talk_reminder_local_time TIME NOT NULL DEFAULT '20:30',
  push_enabled BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE child_preferences (
  child_id UUID PRIMARY KEY REFERENCES children(id),
  mood_reminder_enabled BOOLEAN NOT NULL DEFAULT true,
  mood_reminder_local_time TIME NOT NULL DEFAULT '20:00',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE consent_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID REFERENCES families(id),
  user_id UUID NOT NULL REFERENCES users(id),
  child_id UUID REFERENCES children(id),
  consent_type TEXT NOT NULL,
  document_version TEXT NOT NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at TIMESTAMPTZ
);

CREATE TABLE deletion_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requested_by_user_id UUID NOT NULL REFERENCES users(id),
  family_id UUID REFERENCES families(id),
  child_id UUID REFERENCES children(id),
  scope TEXT NOT NULL CHECK (scope IN ('user','child','family')),
  status TEXT NOT NULL DEFAULT 'requested' CHECK (status IN ('requested','verifying','approved','processing','complete','rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID REFERENCES families(id),
  actor_user_id UUID REFERENCES users(id),
  actor_child_id UUID REFERENCES children(id),
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id UUID,
  metadata_safe JSONB NOT NULL DEFAULT '{}'::jsonb,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX audit_events_family_idx ON audit_events(family_id, occurred_at DESC);
COMMIT;
