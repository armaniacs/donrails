SET CHARACTER SET UTF8;
START TRANSACTION;

ALTER TABLE don_envs add column akismet_key TEXT;
ALTER TABLE don_envs add column notify_level INTEGER;

COMMIT;
