SET CHARACTER SET UTF8;
START TRANSACTION;

-- added 2007-05-27
ALTER TABLE don_pings add column send_at DATETIME DEFAULT NULL;
ALTER TABLE don_envs add column ping_async INTEGER DEFAULT 0;

-- added 2007-06
ALTER TABLE don_pings add column status VARCHAR(100) DEFAULT NULL;
ALTER TABLE don_pings add column response_body TEXT DEFAULT NULL;

COMMIT;

