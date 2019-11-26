/*
-- pg_dump unavailable, so the create statements for piction_interface and piction_history are re-engineered from table descriptions of the original tables piction_history and piction_interface
-- 2019/10/10: added object_number column, references collectionobjects_common.objectnumber

-- DATABASE: piction_transit
--   SCHEMA: piction
--    TABLE: piction_interface_cinefiles
*/

CREATE TABLE piction_interface_cinefiles
(
	id bigserial NOT NULL PRIMARY KEY,
	piction_id integer NOT NULL,
	filename text NOT NULL,
	mimetype character varying(100),
	img_size integer,
	img_height integer,
	img_width integer,
	object_number character varying,
	object_csid character varying (100),
	action character varying(20),
	relationship character varying(20) DEFAULT 'ALTERNATE',
	dt_addedtopiction timestamp without time zone,
	dt_uploaded timestamp without time zone,
	bimage bytea,
	dt_processed timestamp without time zone,
	sha1_hash character varying(40),
	website_display_level character varying(30)
);

CREATE INDEX piction_interface_cinefiles_piction_id_idx  ON piction_interface_cinefiles (piction_id);

GRANT ALL ON piction_interface_cinefiles TO piction;
GRANT INSERT, SELECT, UPDATE, DELETE ON piction_interface_cinefiles TO piction_app_role;

GRANT SELECT, UPDATE, USAGE ON piction_interface_cinefiles_id_seq TO piction;
GRANT USAGE ON piction_interface_cinefiles_id_seq TO piction_app_role;

-- DATABASE: piction_transit
--   SCHEMA: piction
--    TABLE: piction_history_cinefiles

CREATE TABLE piction_history_cinefiles
(
	id bigint NOT NULL,
	piction_id integer NOT NULL,
	filename text NOT NULL,
	mimetype character varying(100),
	img_size integer,
	img_height integer,
	img_width integer,
	object_number character varying,
	object_csid character varying (100),
	action character varying(20),
	relationship character varying(20),
	dt_addedtopiction timestamp without time zone,
	dt_uploaded timestamp without time zone,
	bimage bytea,
	dt_processed timestamp without time zone,
	sha1_hash character varying(40),
	website_display_level character varying(30)
);

CREATE INDEX piction_history_cinefiles_object_number_idx ON piction_history_cinefiles (object_number);

GRANT ALL ON piction_history_cinefiles TO piction;

/* alternate method for creating tables
-- create sequence for piction_interface_cinefiles.id identity column

CREATE SEQUENCE piction_interface_cinefiles_id_seq; 

-- copy piction_interface as piction_interface_cinefiles

CREATE TABLE piction_interface_cinefiles (LIKE piction_interface INCLUDING ALL); 
ALTER TABLE piction_interface_cinefiles ALTER id DROP DEFAULT;
ALTER TABLE piction_interface_cinefiles ALTER id SET DEFAULT nextval('piction_interface_cinefiles_id_seq'); 
ALTER SEQUENCE piction_interface_cinefiles_id_seq OWNED BY piction_interface_cinefiles.id;

-- copy piction_history as piction_history_cinefiles

CREATE TABLE piction_history_cinefiles (LIKE piction_history INCLUDING ALL);

-- grant privileges on piction_interface_cinefiles and piction_interface_cinefiles_id_seq

GRANT ALL ON piction_interface_cinefiles TO piction;
GRANT INSERT, SELECT, UPDATE, DELETE ON piction_interface_cinefiles TO piction_app_role;

GRANT SELECT, UPDATE, USAGE ON piction_interface_cinefiles_id_seq TO piction;
GRANT USAGE ON piction_interface_cinefiles_id_seq TO piction_app_role;

GRANT ALL ON piction_history_cinefiles TO piction;
*/
