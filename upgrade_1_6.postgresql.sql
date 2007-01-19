SET client_encoding = 'UTF8';
START TRANSACTION;

ALTER TABLE pictures RENAME TO don_attachments ;
ALTER TABLE don_attachments ADD COLUMN format VARCHAR;
UPDATE don_attachments SET format = 'picture';

ALTER TABLE don_attachments RENAME COLUMN name TO title;
ALTER TABLE don_attachments RENAME COLUMN comment TO body;
ALTER TABLE don_attachments ALTER COLUMN article_id TYPE INTEGER USING to_number(article_id, '0000000000');

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
       SELECT id,article_id from don_attachments WHERE article_id > 0;
ALTER TABLE don_attachments DROP column article_id;

COMMIT;
