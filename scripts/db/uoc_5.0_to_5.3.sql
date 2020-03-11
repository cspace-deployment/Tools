/* Use of Collections V1 Migration

-- This SQL script migrates existing Use of Collections data from V1 to incorporate new features developed by the UCB CSpace team, based on the following assumptions:

	-- The appropriate database is specified in executing this script.
	   This script does not contain commands to connect to the appropriate database.

	-- New database changes have been made: e.g. new tables created, foreign keys added.

	-- New records should not exist in newly created tables.
	   Since this script may possibly be run repeatedly, it only creates a new record,
	   if the record has not yet been migrated.

	-- The uuid_generate_v4() function is required to generate UUID for new records.
	   Installing the uuid-ossp extension will make all UUID generation functions available.
	   This script creates and uses the uuid_generate_v4() function to generate a version 4 UUID.

           --  To install the uuid-ossp extension:
 		CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

	   -- To create the uuid_generate_v4() function:
		CREATE OR REPLACE FUNCTION public.uuid_generate_v4()
		  RETURNS uuid
		  LANGUAGE c
		  PARALLEL SAFE STRICT
		AS '$libdir/uuid-ossp', $function$uuid_generate_v4$function$;

	-- Once existing data has been migrated, this script does not delete data, nor drop the newly obsolete columns.

-- V1 Use of Collections tables:
	
	public.uoc_common ============> Various fields updated to repeatable fields/groups
	public.uoc_common_methodlist => NO MIGRATION NEEDED
	public.usergroup =============> NO MIGRATION NEEDED
	
-- V1 uoc_common table description:
	
	                            Table "public.uoc_common"
	      Column       |            Type             | Nullable | Migrate To
	-------------------+-----------------------------+----------+-------------
	 id                | character varying(36)       | not null |
	 enddate           | timestamp without time zone |          |
	 location          | character varying           |          | uoc_common_locationlist
	 authorizationdate | timestamp without time zone |          | authorizationgroup
	 title             | character varying           |          |
	 note              | character varying           |          |
	 provisos          | character varying           |          |
	 result            | character varying           |          |
	 referencenumber   | character varying           |          |
	 authorizationnote | character varying           |          | authorizationgroup
	 authorizedby      | character varying           |          | authorizationgroup
	 startsingledate   | timestamp without time zone |          | usedategroup
	Indexes:
	    "uoc_common_pk" PRIMARY KEY, btree (id)
	Foreign-key constraints:
	    "uoc_common_id_hierarchy_fk" FOREIGN KEY (id) REFERENCES hierarchy(id) ON DELETE CASCADE
	
-- NO CHANGES are required for the following uoc_common columns:
	
	uoc_common.id
	uoc_common.enddate
	uoc_common.title
	uoc_common.note
	uoc_common.provisos
	uoc_common.result
	uoc_common.referencenumber
	
-- REPEATABLE FIELDS: The following uoc_common columns are now repeatable fields; migrated as follows:
	
	uoc_common.location ==========> uoc_common_locationlist.item
	uoc_common.authorizationdate => authorizationgroup.authorizationdate
	uoc_common.authorizationnote => authorizationgroup.authorizationnote
	uoc_common.authorizedby ======> authorizationgroup.authorizedby
	uoc_common.startsingledate ===> usedategroup.usedate

*/
	

/* 1) Migrate uoc_common.location data to uoc_common_locationlist table:

-- NEW uoc_common_locationlist table description:
	
	   Table "public.uoc_common_locationlist"
	 Column |         Type          | Modifiers 
	--------+-----------------------+-----------
	 id     | character varying(36) | not null
	 pos    | integer               | 
	 item   | character varying     | 
	Indexes:
	    "uoc_common_locationlist_id_idx" btree (id)
	Foreign-key constraints:
	    "uoc_common_locationlist_id_hierarchy_fk" FOREIGN KEY (id) REFERENCES hierarchy(id) ON DELETE CASCADE

-- Since there is only <= 1 value for uoc_common.location, uoc_common_locationlist.pos can be set to 0.
-- Only add a new record when there is a value for uoc_common.location, and if the record does not yet exist.
-- Do not create empty records in uoc_common_locationlist.

	uoc_common.id ========> uoc_common_locationlist.id
	0 ====================> uoc_common_locationlist.pos
	uoc_common.location ==> uoc_common_locationlist.item

-- Insert a new record into uoc_common_locationlist table.
-- Only add a new record when there is a value for location.
-- Do not create empty records in uoc_common_locationlist.
-- Only add the record if it does NOT already exist:

INSERT INTO public.uoc_common_locationlist (
	id, 
	pos, 
	item)
SELECT
	id,
	0,
	location
FROM public.uoc_common
WHERE location IS NOT NULL
AND location != ''
ON CONFLICT DO NOTHING;

*/


/* 2) Migrate uoc_common authorization data to authorizationgroup table:

-- NEW authorizationgroup table description:

	               Table "public.authorizationgroup"
	       Column        |            Type             | Modifiers 
	---------------------+-----------------------------+-----------
	 id                  | character varying(36)       | not null
	 authorizationnote   | character varying           | 
	 authorizedby        | character varying           | 
	 authorizationdate   | timestamp without time zone | 
	 authorizationstatus | character varying           | 
	Indexes:
	    "authorizationgroup_pk" PRIMARY KEY, btree (id)
	Foreign-key constraints:
	    "authorizationgroup_id_hierarchy_fk" FOREIGN KEY (id) REFERENCES hierarchy(id) ON DELETE CASCADE

-- Migrate/add from uoc_common to hierarchy.
-- The foreign key on the authorizationgroup table requires first adding new records to hierarchy.
-- Use the uuid_generate_v4() function to generate a new type 4 UUID for the new record.

	uuid_generate_v4()::varchar as id ====> hierarchy.id
	uoc_common.id ========================> hierarchy.parentid
	0 ====================================> hierarchy.pos
	'uoc_common:authorizationGroupList' ==> hierarchy.name
	True =================================> hierarchy.isproperty
	'authorizationGroup' =================> hierarchy.primarytype

-- Migrate from uoc_common to authorizationgroup:
-- Only add a new record when there is a value for authorizationdate, authorizationnote, or authorizedby.
-- Do not create empty records in authorizationgroup.

	hierarchy.id ==> authorizationgroup.id
	uoc_common.authorizationdate =======> authorizationgroup.authorizationdate
	uoc_common.authorizationnote =======> authorizationgroup.authorizationnote
	uoc_common.authorizedby ============> authorizationgroup.authorizedby

*/

-- Create function uuid_generate_v4() for generating UUID:

CREATE OR REPLACE FUNCTION public.uuid_generate_v4()
 RETURNS uuid
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v4$function$

-- Create temp table to hold data for populating authorizationgroup and hierarchy tables:

CREATE TEMP TABLE authgrouptemp AS
SELECT 
	uuid_generate_v4()::varchar AS id,
	x.parentid,
	x.authorizationdate, 
	x.authorizationnote, 
	x.authorizedby
FROM (
	SELECT
		uc.id AS parentid,
		uc.authorizationdate, 
		uc.authorizationnote, 
		uc.authorizedby
	FROM public.uoc_common uc
	WHERE uc.authorizationdate IS NOT NULL
	OR uc.authorizationnote IS NOT NULL
	OR uc.authorizedby IS NOT NULL
	UNION ALL
	SELECT
		h.parentid,
		ag.authorizationdate, 
		ag.authorizationnote, 
		ag.authorizedby
	FROM public.authorizationgroup ag
	JOIN public.hierarchy h ON (ag.id = h.id)
	) x
GROUP BY x.parentid, x.authorizationdate, x.authorizationnote, x.authorizedby
HAVING count(*) = 1;

-- Insert new records into hierarchy table first, due to foreign key on authorizationgroup table:

INSERT INTO public.hierarchy (
	id, 
	parentid, 
	pos, 
	name, 
	isproperty, 
	primarytype)
SELECT
	id,
	parentid,
	0,
	'uoc_common:authorizationGroupList',
	True,
	'authorizationGroup'
FROM authgrouptemp;	

-- Insert new records into authorizationgroup table:

INSERT INTO public.authorizationgroup (
	id, 
	authorizationdate, 
	authorizationnote, 
	authorizedby)
SELECT 
	id,
	authorizationdate, 
	authorizationnote, 
	authorizedby
FROM authgrouptemp;


/* 3) Migrate uoc_common.startsingledate data to usedategroup table:
	
-- NEW usedategroup table description:

	                    Table "public.usedategroup"
	         Column          |            Type             | Modifiers 
	-------------------------+-----------------------------+-----------
	 id                      | character varying(36)       | not null
	 usedate                 | timestamp without time zone | 
	 usedatenumberofvisitors | bigint                      | 
	 usedatevisitornote      | character varying           | 
	 usedatehoursspent       | double precision            | 
	 usedatetimenote         | character varying           | 
	Indexes:
	    "usedategroup_pk" PRIMARY KEY, btree (id)
	Foreign-key constraints:
	    "usedategroup_id_hierarchy_fk" FOREIGN KEY (id) REFERENCES hierarchy(id) ON DELETE CASCADE

-- Migrate/add from uoc_common to hierarchy.
-- The foreign key on the usedategroup table requires first adding new records to hierarchy.
-- Use the uuid_generate_v4() function to generate a new type 4 UUID for the new record.

	uuid_generate_v4()::varchar as id ====> hierarchy.id
	uoc_common.id ========================> hierarchy.parentid
	0 ====================================> hierarchy.pos
	'uoc_common:useDateGroupList' ========> hierarchy.name
	True =================================> hierarchy.isproperty
	'useDateGroup' =======================> hierarchy.primarytype

-- Migrate from uoc_common to usedategroup.
-- Only add a new record when there is a value for startsingledate.
-- Do not create empty records in usedategroup.

	hierarchy.id ==> usedategroup.id
	uoc_common.startsingledate =========> usedategroup.usedate

*/

-- Create temp table to hold data for populating usedategroup and hierarchy tables:

CREATE TEMP TABLE usedategrouptemp AS
SELECT
        uuid_generate_v4()::varchar AS id,
        x.parentid,
        x.usedate
FROM (
        SELECT
                uc.id AS parentid,
                uc.startsingledate AS usedate
        FROM public.uoc_common uc
        WHERE startsingledate IS NOT NULL;
        UNION ALL
        SELECT
                h.parentid,
                udg.usedate
        FROM public.usedategroup udg
        JOIN public.hierarchy h ON (udg.id = h.id)
        ) x
GROUP BY x.parentid, x.usedate
HAVING count(*) = 1;

-- Insert new records into hierarchy table first, due to foreign key on usedategroup table to hierarchy.id:

INSERT INTO public.hierarchy (
	id, 
	parentid, 
	pos, 
	name, 
	isproperty, 
	primarytype)
SELECT
	id,
	parentid,
	0,
	'uoc_common:useDateGroupList',
	True,
	'useDateGroup'
FROM usedategrouptemp;

-- Insert new records into usedategroup table:

INSERT INTO public.usedategroup (
	id, 
	usedate)
SELECT 
	id,
	startsingledate
FROM usedategrouptemp;

-- END OF MIGRATION
