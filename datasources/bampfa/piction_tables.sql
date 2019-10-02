/*
-- pg_dump unavailable, so the create statements for piction_interface and piction_history are re-engineered from table descriptions
-- 2019/10/10: added object_number column, references collectionobjects_common.objectnumber

-- DATABASE: piction_transit
--   SCHEMA: piction
--    TABLE: piction_interface
*/

CREATE TABLE piction_interface
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
	relationship character varying(20),
	dt_addedtopiction timestamp without time zone,
	dt_uploaded timestamp without time zone,
	bimage bytea,
	dt_processed timestamp without time zone,
	sha1_hash character varying(40),
	website_display_level character varying(30)
);

CREATE INDEX piction_interface_piction_id_idx ON piction_interface (piction_id);

GRANT ALL ON piction_interface TO piction;
GRANT INSERT, SELECT, UPDATE, DELETE ON piction_interface TO piction_app_role;

GRANT SELECT, UPDATE, USAGE ON piction_interface_id_seq TO piction;
GRANT USAGE ON piction_interface_id_seq TO piction_app_role;

-- DATABASE: piction_transit
--   SCHEMA: piction
--    TABLE: piction_history

CREATE TABLE piction_history
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

CREATE INDEX piction_history_object_number_idx ON piction_history (object_number);
GRANT ALL ON piction_history TO piction;

/* alternate method for creating piction_history table

CREATE TABLE piction_history (LIKE piction_interface);
CREATE INDEX piction_history_object_number_idx ON piction_history (object_number);
GRANT ALL ON piction_history TO piction;

*/

