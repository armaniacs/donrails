CREATE TABLE pictures 
(	
id       SERIAL UNIQUE,
name     VARCHAR(100),
path      VARCHAR(100),
size      INTEGER,
content_type   VARCHAR(100),
comment        TEXT,
article_id     INTEGER,
hidden	       INTEGER,
primary key (id)
);

CREATE TABLE comments (
id       SERIAL UNIQUE,
password    VARCHAR(100),

date     TIMESTAMP,
title     TEXT,
author   VARCHAR(100),
url      VARCHAR(100),

ipaddr   VARCHAR(100),
body     TEXT,
hidden	       INTEGER,
primary key (id)
);

CREATE TABLE categories (
id       SERIAL UNIQUE,
name         VARCHAR(100) NOT NULL UNIQUE,
parent_id    INTEGER,
description TEXT,
constraint   fk_category foreign key (parent_id) references categories(id),
primary key (id)
);

-- enrollemnt_id added 2006-9-1(Fri)
CREATE TABLE articles (
id       SERIAL UNIQUE,
title    VARCHAR(100),
body     TEXT,
size     INTEGER,
article_date     TIMESTAMP,
article_mtime    TIMESTAMP,
hnfid    INTEGER,
author_id  INTEGER,
format   VARCHAR(100),
hidden	       INTEGER,
enrollment_id  INTEGER,
primary key (id)
);

CREATE TABLE categories_articles (
category_id       INTEGER NOT NULL,
article_id       INTEGER NOT NULL,
constraint fk_cp_category foreign key (category_id) references categories(id),
constraint fk_cp_article foreign key (article_id) references articles(id),
primary key (category_id, article_id)
);

CREATE TABLE comments_articles (
comment_id       INTEGER NOT NULL,
article_id       INTEGER NOT NULL,
constraint fk_cp_comment foreign key (comment_id) references comments(id),
constraint fk_cp_article foreign key (article_id) references articles(id),
primary key (comment_id, article_id)
);

CREATE TABLE authors (
id     SERIAL UNIQUE,
name   VARCHAR(100) NOT NULL UNIQUE,
nickname   VARCHAR(100),
pass   VARCHAR(100),
summary   TEXT,
writable INTEGER NOT NULL,
primary key (id)
);

-- CREATE TABLE blacklists (
CREATE TABLE banlists (
id     SERIAL UNIQUE,
format   VARCHAR(100),
pattern   VARCHAR(100),
white     INTEGER,
primary key (id)
);

CREATE TABLE plugins (
id     SERIAL UNIQUE,
name   	      VARCHAR(100) NOT NULL UNIQUE,
description   VARCHAR(100) NOT NULL,
manifest      VARCHAR(100) NOT NULL,
activation    BOOLEAN,
primary key (id)
);

CREATE TABLE blogpings (
id          SERIAL UNIQUE,
server_url    VARCHAR(100) NOT NULL UNIQUE,
active	      INTEGER,
primary key (id)
);

CREATE TABLE pings (
id          SERIAL UNIQUE,
article_id  INTEGER,
url         VARCHAR(100) DEFAULT NULL,
created_at  DATETIME DEFAULT NULL,
primary key (id)
);

CREATE TABLE trackbacks (
id          SERIAL UNIQUE,
article_id  INTEGER,
category_id INTEGER,
blog_name   VARCHAR(100) DEFAULT NULL,
title       VARCHAR(100) DEFAULT NULL,
excerpt     TEXT,
url         VARCHAR(100) DEFAULT NULL,
ip          VARCHAR(100) DEFAULT NULL,
created_at  DATETIME DEFAULT NULL,
hidden	       INTEGER,
primary key (id)
);

-- added at 2006-9-1(Fri) 
CREATE TABLE enrollments (
id     SERIAL UNIQUE,
title   VARCHAR(100),
hidden	       INTEGER,
created_at  DATETIME DEFAULT NULL,
updated_at  DATETIME DEFAULT NULL,
primary key (id)
);

