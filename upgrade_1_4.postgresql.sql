SET client_encoding = 'UTF8';
START TRANSACTION;

CREATE TABLE don_envs (
id          SERIAL PRIMARY KEY,
hidden         INTEGER,
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

CREATE TABLE don_rbls (
id     SERIAL UNIQUE,
rbl_type   VARCHAR,
hostname   VARCHAR
);

----
ALTER TABLE pings RENAME TO don_pings;

COMMIT;
