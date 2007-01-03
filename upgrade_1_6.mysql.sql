SET CHARACTER SET UTF8;
START TRANSACTION;

ALTER TABLE pictures RENAME TO don_attachments ;
alter table don_attachments add column format VARCHAR(100);
UPDATE don_attachments SET format = 'picture';

ALTER TABLE don_attachments CHANGE name title TEXT;
ALTER TABLE don_attachments CHANGE comment body TEXT;

ALTER TABLE trackbacks add column spam INTEGER;
ALTER TABLE comments add column spam INTEGER;

COMMIT;
