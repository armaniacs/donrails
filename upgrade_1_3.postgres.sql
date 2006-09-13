SET client_encoding = 'UTF8';
START TRANSACTION;

CREATE TABLE enrollments (
id          SERIAL UNIQUE,
title       VARCHAR,
hidden      INTEGER,
created_at  TIMESTAMP DEFAULT NULL,
updated_at  TIMESTAMP DEFAULT NULL,
primary key (id)
);

-- articlesテーブルのidとtitleをenrollmentsにコピーする。
INSERT INTO enrollments (id, title, hidden, created_at) 
  SELECT id,title,hidden,article_date from articles;

-- articlesテーブルにenrollment_idを設定する。
 ALTER table articles add column enrollment_id INTEGER; 
 UPDATE articles SET enrollment_id = q.id FROM (SELECT id FROM articles) AS q WHERE articles.id = q.id;

---- pictures,pings,trackbacksテーブルのarticle_idをenrollment_idに変更
-- ALTER TABLE pictures CHANGE article_id enrollment_id INTEGER;
-- ALTER TABLE pings CHANGE article_id enrollment_id INTEGER;
-- ALTER TABLE trackbacks CHANGE article_id enrollment_id INTEGER;

-- -- comments_articlesテーブルをやめて、commentsテーブルのenrollment_idに代入
--  ALTER TABLE comments add column enrollment_id INTEGER;
--  REPLACE INTO comments (id, password, date, title, author, url, ipaddr, body, hidden, enrollment_id) SELECT comments.id,comments.password,comments.date,comments.title,comments.author,comments.url,comments.ipaddr,comments.body,comments.hidden,comments_articles.article_id from comments_articles,comments where comments_articles.comment_id = comments.id;
--  drop table comments_articles;

-- comments_articlesテーブルをやめて、commentsテーブルのarticle_idに代入
 ALTER TABLE comments add column article_id INTEGER;
 UPDATE comments SET article_id = c.article_id FROM (SELECT comments_articles.article_id, comments.id FROM comments_articles, comments WHERE comments_articles.comment_id = comments.id) AS c WHERE comments.id = c.id;
 drop table comments_articles;

----

COMMIT;

