SET CHARACTER SET UTF8;
START TRANSACTION;

ALTER TABLE pictures RENAME TO don_attachments ;
ALTER TABLE don_attachments ADD COLUMN format VARCHAR(100);
UPDATE don_attachments SET format = 'picture';

ALTER TABLE don_attachments CHANGE name title TEXT;
ALTER TABLE don_attachments CHANGE comment body TEXT;

ALTER TABLE trackbacks add column spam INTEGER;
ALTER TABLE comments add column spam INTEGER;

CREATE TABLE don_attachments_articles (
don_attachment_id	INTEGER NOT NULL,
article_id	INTEGER NOT NULL,
constraint fk_cp_don_attachment foreign key (don_attachment_id) 
	   references don_attachments(id),
constraint fk_cp_article foreign key (article_id) 
	   references articles(id),
primary key (don_attachment_id, article_id)
);

INSERT INTO don_attachments_articles (don_attachment_id, article_id)
       SELECT id,article_id from don_attachments;
ALTER TABLE don_attachments DROP column article_id;

--
-- correct default value
--
ALTER TABLE don_envs ALTER COLUMN notify_level SET DEFAULT 1;

COMMIT;
