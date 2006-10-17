CREATE TABLE pictures 
(	
id       INTEGER PRIMARY KEY,
name     VARCHAR,
path      VARCHAR,
size      INTEGER,
content_type   VARCHAR,
comment        VARCHAR,
hidden	       INTEGER,
article_id     INTEGER
);

CREATE TABLE comments (
id       INTEGER PRIMARY KEY,
password    VARCHAR,

date     TIMESTAMP,
title     VARCHAR,
author   VARCHAR,
url      VARCHAR,

ipaddr   VARCHAR,
hidden	       INTEGER,
body     VARCHAR,
article_id       INTEGER
);

CREATE TABLE categories (
id       INTEGER PRIMARY KEY,
name         VARCHAR NOT NULL UNIQUE,
parent_id    INTEGER,
description VARCHAR,
constraint   fk_category foreign key (parent_id) references categories(id)
);

CREATE TABLE articles (
id       INTEGER PRIMARY KEY,
enrollment_id    INTEGER,
title    VARCHAR,
body     VARCHAR,
size     INTEGER,
article_date     TIMESTAMP,
article_mtime    TIMESTAMP,
hnfid    INTEGER,
author_id  INTEGER,
hidden	       INTEGER,
format   VARCHAR
);

CREATE TABLE categories_articles (
category_id       INTEGER NOT NULL,
article_id       INTEGER NOT NULL,
constraint fk_cp_category foreign key (category_id) references categories(id),
constraint fk_cp_article foreign key (article_id) references articles(id),
primary key (category_id, article_id)
);

CREATE TABLE authors (
id     INTEGER PRIMARY KEY,
name   VARCHAR NOT NULL UNIQUE,
nickname   VARCHAR,
pass   VARCHAR,
summary   VARCHAR,
writable INTEGER NOT NULL
);

-- CREATE TABLE blacklists (
CREATE TABLE banlists (
id     INTEGER PRIMARY KEY,
format   VARCHAR,
pattern   VARCHAR,
white	  INTEGER
);

CREATE TABLE plugins (
id     INTEGER PRIMARY KEY,
name   	      VARCHAR NOT NULL UNIQUE,
description   VARCHAR NOT NULL,
manifest      VARCHAR NOT NULL,
activation    BOOLEAN
);

CREATE TABLE blogpings (
id          INTEGER PRIMARY KEY NOT NULL,
server_url    VARCHAR NOT NULL UNIQUE,
active	      INTEGER
);

CREATE TABLE pings (
id          INTEGER PRIMARY KEY NOT NULL,
article_id  INTEGER,
url         VARCHAR DEFAULT NULL,
created_at  DATETIME DEFAULT NULL
);

CREATE TABLE trackbacks (
id          INTEGER PRIMARY KEY NOT NULL,
article_id  INTEGER,
category_id INTEGER,
blog_name   VARCHAR DEFAULT NULL,
title       VARCHAR DEFAULT NULL,
excerpt     VARCHAR DEFAULT NULL,
url         VARCHAR DEFAULT NULL,
ip          VARCHAR DEFAULT NULL,
hidden	       INTEGER,
created_at  DATETIME DEFAULT NULL
);

CREATE TABLE enrollments (
id         INTEGER PRIMARY KEY NOT NULL,
title      VARCHAR,
hidden     INTEGER,
created_at TIMESTAMP DEFAULT NULL,
updated_at TIMESTAMP DEFAULT NULL
);

-- added at 2006-10-14
CREATE TABLE don_envs (
id         INTEGER PRIMARY KEY NOT NULL,
hidden	       INTEGER,
image_dump_path   VARCHAR,
admin_user   VARCHAR,
admin_password VARCHAR,
admin_mailadd VARCHAR,
rdf_title VARCHAR,
rdf_description VARCHAR,
rdf_copyright VARCHAR,
rdf_managingeditor VARCHAR,
rdf_webmaster VARCHAR,
baseurl VARCHAR,
url_limit INTEGER DEFAULT 5,
default_theme VARCHAR,
trackback_enable_time INTEGER
);

-- added at 2006-10-14
CREATE TABLE don_rbls (
id     SERIAL UNIQUE,
rbl_type   VARCHAR,
hostname   VARCHAR
);
