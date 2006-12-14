SET client_encoding = 'UTF8';
START TRANSACTION;

ALTER TABLE don_envs add column akismet_key VARCHAR;
ALTER TABLE don_envs add column notify_level INTEGER;

COMMIT;
