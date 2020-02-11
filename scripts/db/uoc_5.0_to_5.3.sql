/* Use of Collections V1 to V2 Migration

	This SQL script migrates existing Use of Collections data from V1 to V2 based on the following:
	  1) The appropriate database is specified in executing this script.  This script does not contain commands to connect to the appropriate database.
	  2) New database changes have been made, e.g. new tables created, foreign keys added to hierarchy table.
	  3) The "uuid-ossp" Postgres extension exists in order to execute the uuid_generate_v4() function to generate UUID for new records. To add the extension:
	     -- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
	  4) Once existing data has been migrated, this script does not delete data, nor drop the newly obsolete columns in the database.

	V1 Use of Collections tables:
	
	public.uoc_common ============> Various fields updated to repeatable fields/groups
	public.uoc_common_methodlist => NO MIGRATION NEEDED
	public.usergroup =============> NO MIGRATION NEEDED
	
	V1 uoc_common table description:
	
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
	
	NO CHANGES are required for the following fields in uoc_common:
	
	uoc_common.id
	uoc_common.enddate
	uoc_common.title
	uoc_common.note
	uoc_common.provisos
	uoc_common.result
	uoc_common.referencenumber
	
	The following fields are now repeatable fields, and the data will be stored in new tables:
	
	uoc_common.location ==========> uoc_common_locationlist.item
	uoc_common.authorizationdate => authorizationgroup.authorizationdate
	uoc_common.authorizationnote => authorizationgroup.authorizationnote
	uoc_common.authorizedby ======> authorizationgroup.authorizedby
	uoc_common.startsingledate ===> usedategroup.usedate
	
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
*/

/* Migrate to uoc_common.location to uoc_common_locationlist table:
	
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

	Migrate/add the following from uoc_common to uoc_common_locationlist:

	uoc_common.id ========> uoc_common_locationlist.id
	0 ====================> uoc_common_locationlist.pos
	uoc_common.location ==> uoc_common_locationlist.item

	Since there is only <= 1 value for uoc_common.location, uoc_common_locationlist.pos can be set to 0.

	Only add a new record when there is a value for uoc_common.location.  Do not create empty records in uoc_common_locationlist.
*/

-- Insert new records into uoc_common_locationlist table:

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
AND location != '';

/* Migrate uoc_common authorization data to authorizationgroup table:

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

	Migrate the following from uoc_common to authorizationgroup:

	uuid_generate_v4()::varchar as id ==> authorizationgroup.id
	uoc_common.authorizationdate =======> authorizationgroup.authorizationdate
	uoc_common.authorizationnote =======> authorizationgroup.authorizationnote
	uoc_common.authorizedby ============> authorizationgroup.authorizedby

	Migrate/add the following from uoc_common to hierarchy:

	uuid_generate_v4()::varchar as id ====> hierarchy.id
	uoc_common.id ========================> hierarchy.parentid
	0 ====================================> hierarchy.pos
	'uoc_common:authorizationGroupList' ==> hierarchy.name
	True =================================> hierarchy.isproperty
	'authorizationGroup' =================> hierarchy.primarytype

	Adding new records to the authorizationgroup table requires generating a UUID for the new records, as well as adding new reference records to the hierarchy table.

	Only add a new record when there is a value for uoc_common.authorizationdate or uoc_common.authorizationnote or uoc_common.authorizedby.  Do not create empty records in authorizationgroup.

*/

-- Create temp table to hold data for populating authorizationgroup and hierarchy tables:

CREATE TEMP TABLE authgrouptemp as
SELECT
	id as parentid,
	uuid_generate_v4()::varchar as id,
	authorizationdate, 
	authorizationnote, 
	authorizedby
FROM public.uoc_common
WHERE authorizationdate is not null
OR authorizationnote is not null
OR authorizedby is not null;

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

-- Insert new records into hierarchy table:

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

/* Migrate uoc_common.startsingledate data to usedategroup table:
	
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

	Migrate the following from uoc_common to usedategroup:

	uuid_generate_v4()::varchar as id ==> usedategroup.id
	uoc_common.startsingledate =========> usedategroup.usedate

	Migrate/add the following from uoc_common to hierarchy:

	uuid_generate_v4()::varchar as id ====> hierarchy.id
	uoc_common.id ========================> hierarchy.parentid
	0 ====================================> hierarchy.pos
	'uoc_common:useDateGroupList' ========> hierarchy.name
	True =================================> hierarchy.isproperty
	'useDateGroup' =======================> hierarchy.primarytype

*/

-- Create temp table to hold data for populating usedategroup and hierarchy tables:

CREATE TEMP TABLE usedategrouptemp as
SELECT
	id as parentid,
	uuid_generate_v4()::varchar as id,
	startsingledate
FROM public.uoc_common
WHERE startsingledate IS NOT NULL;

-- Insert new records into usedategroup table:

INSERT INTO public.usedategroup (
	id, 
	usedate)
SELECT 
	id,
	startsingledate
FROM usedategrouptemp;

-- Insert new records into hierarchy table:

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

-- End of V1 to V2 Migration
