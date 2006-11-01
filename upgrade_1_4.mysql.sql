SET CHARACTER SET UTF8;
START TRANSACTION;

CREATE TABLE don_envs (
id     SERIAL UNIQUE,
hidden         INTEGER,
image_dump_path   VARCHAR(100),
admin_user   VARCHAR(100),
admin_password VARCHAR(100),
admin_mailadd VARCHAR(100),
rdf_title VARCHAR(100),
rdf_description VARCHAR(100),
rdf_copyright VARCHAR(100),
rdf_managingeditor VARCHAR(100),
rdf_webmaster VARCHAR(100),
baseurl VARCHAR(100),
url_limit INTEGER DEFAULT 5,
default_theme VARCHAR(100),
trackback_enable_time INTEGER,
primary key (id)
);
CREATE TABLE don_rbls (
id     SERIAL UNIQUE,
rbl_type   VARCHAR(100),
hostname   VARCHAR(100),
primary key (id)
);


ALTER TABLE pictures CHANGE name name TEXT, CHANGE path path TEXT;
ALTER TABLE comments CHANGE url url TEXT;
ALTER TABLE articles CHANGE title title TEXT;
ALTER TABLE banlists CHANGE pattern pattern TEXT;
ALTER TABLE plugins CHANGE description description TEXT NOT NULL;
ALTER TABLE blogpings
  CHANGE server_url server_url VARCHAR(255) NOT NULL UNIQUE;
ALTER TABLE pings CHANGE url url TEXT DEFAULT NULL;
ALTER TABLE trackbacks
  CHANGE blog_name blog_name TEXT DEFAULT NULL,
  CHANGE title title TEXT DEFAULT NULL;
ALTER TABLE enrollments CHANGE title title TEXT;
ALTER TABLE don_envs
  CHANGE image_dump_path image_dump_path TEXT,
  CHANGE admin_mailadd admin_mailadd TEXT,
  CHANGE rdf_title rdf_title TEXT,
  CHANGE rdf_description rdf_description TEXT,
  CHANGE rdf_copyright rdf_copyright TEXT,
  CHANGE rdf_managingeditor rdf_managingeditor TEXT,
  CHANGE rdf_webmaster rdf_webmaster TEXT,
  CHANGE baseurl baseurl TEXT;
ALTER TABLE don_rbls CHANGE hostname hostname TEXT;

----

ALTER TABLE pings RENAME TO don_pings;

COMMIT;
