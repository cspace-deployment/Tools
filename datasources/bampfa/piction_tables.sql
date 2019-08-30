-- pg_dump unavailable, so the create statements for piction_interface and piction_history are re-engineered from table descriptions

CREATE TABLE piction_interface
(
	id bigserial NOT NULL PRIMARY KEY,
	piction_id integer NOT NULL,
	filename text NOT NULL,
	mimetype character varying(100),
	img_size integer,
	img_height integer,
	img_width integer,
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

-- ALTER TABLE piction_interface OWNER TO piction;

CREATE INDEX idx_pictintf ON piction_interface (piction_id);

CREATE TABLE piction_history (LIKE piction_interface);

-- ALTER TABLE piction_history OWNER TO piction;

/*
                                          Table "piction.piction_interface"
        Column         |            Type             |                           Modifiers                            
-----------------------+-----------------------------+----------------------------------------------------------------
 id                    | bigint                      | not null default nextval('piction_interface_id_seq'::regclass)
 piction_id            | integer                     | not null
 filename              | text                        | not null
 mimetype              | character varying(100)      | 
 img_size              | integer                     | 
 img_height            | integer                     | 
 img_width             | integer                     | 
 object_csid           | character varying(100)      | 
 action                | character varying(20)       | 
 relationship          | character varying(20)       | 
 dt_addedtopiction     | timestamp without time zone | 
 dt_uploaded           | timestamp without time zone | 
 bimage                | bytea                       | 
 dt_processed          | timestamp without time zone | 
 sha1_hash             | character varying(40)       | 
 website_display_level | character varying(30)       | 
Indexes:
    "piction_interface_pkey" PRIMARY KEY, btree (id)
    "idx_pictintf" btree (piction_id)

                 Table "piction.piction_history"
        Column         |            Type             | Modifiers 
-----------------------+-----------------------------+-----------
 id                    | bigint                      | not null
 piction_id            | integer                     | not null
 filename              | text                        | not null
 mimetype              | character varying(100)      | 
 img_size              | integer                     | 
 img_height            | integer                     | 
 img_width             | integer                     | 
 object_csid           | character varying(100)      | 
 action                | character varying(20)       | 
 relationship          | character varying(20)       | 
 dt_addedtopiction     | timestamp without time zone | 
 dt_uploaded           | timestamp without time zone | 
 bimage                | bytea                       | 
 dt_processed          | timestamp without time zone | 
 sha1_hash             | character varying(40)       | 
 website_display_level | character varying(30)       | 
*/
