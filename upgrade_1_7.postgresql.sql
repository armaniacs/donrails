SET client_encoding = 'UTF8';
START TRANSACTION;

--
-- Upgrade tables
--

-- Since 2007-05-27
ALTER TABLE don_pings ADD COLUMN send_at TIMESTAMP DEFAULT NULL;
ALTER TABLE don_envs ADD COLUMN ping_async INTEGER DEFAULT 0;

ALTER TABLE don_pings add column status VARCHAR DEFAULT NULL;
ALTER TABLE don_pings add column response_body VARCHAR DEFAULT NULL;

COMMIT;
