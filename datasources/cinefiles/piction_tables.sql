-- see original tables piction_history and piction_interface
--https://github.com/cspace-deployment/Tools/tree/master/datasources/bampfa
-- copy piction_history as piction_history_cinefiles
CREATE TABLE piction_history_cinefiles (LIKE piction_history INCLUDING ALL);

-- create sequence for piction_interface_cinefiles.id identity column
CREATE SEQUENCE piction_interface_cinefiles_id_seq; 

-- copy piction_interface as piction_interface_cinefiles
CREATE TABLE piction_interface_cinefiles (LIKE piction_interface INCLUDING ALL); 
ALTER TABLE piction_interface_cinefiles ALTER id DROP DEFAULT;
ALTER TABLE piction_interface_cinefiles ALTER id SET DEFAULT nextval('piction_interface_cinefiles_id_seq'); 
ALTER SEQUENCE piction_interface_cinefiles_id_seq OWNED BY piction_interface_cinefiles.id;

/*
            Table "piction.piction_history_cinefiles"
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


                                          Table "piction.piction_interface_cinefiles"
        Column         |            Type             |                                Modifiers                         
        
-----------------------+-----------------------------+------------------------------------------------------------------
--------
 id                    | bigint                      | not null default nextval('piction_interface_cinefiles_id_seq'::re
gclass)
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
    "piction_interface_cinefiles_pkey" PRIMARY KEY, btree (id)
    "piction_interface_cinefiles_piction_id_idx" btree (piction_id)

*/
