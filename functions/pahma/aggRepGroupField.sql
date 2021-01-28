/* utils.aggRepGroupField(coid varchar, tname varchar, cname varchar, sepval varchar)
 *   -- aggregates values of a repeating group of fields
 *   -- requires:
 *      -- coid   = collectionobjects_common.id of the parent Collection Object
 *      -- tname  = table name of the repeating group
 *      -- cname  = column name of the repeating group field
 *      -- sepval = separator/delimiter character
 */	

CREATE SCHEMA IF NOT EXISTS utils AUTHORIZATION nuxeo_pahma;

-- DROP FUNCTION utils.aggRepGroupField(coid varchar, tname varchar, cname varchar, sepval varchar);

CREATE OR REPLACE FUNCTION utils.aggRepGroupField(
    coid VARCHAR,
    tname VARCHAR,
    cname VARCHAR,
    sepval VARCHAR)
RETURNS VARCHAR
AS $$
DECLARE
    ctype VARCHAR;
    cstr VARCHAR;
    aggstr VARCHAR;
BEGIN
    SELECT data_type INTO ctype FROM information_schema.columns WHERE table_name = tname AND column_name = cname;

    IF ctype IN ('text', 'character varying') THEN 
        cstr := cname;
    ELSE
        cstr := cname || '::text';
    END IF;

    EXECUTE 'SELECT STRING_AGG(CASE WHEN n.' || cname || ' IS NULL THEN ''%NULLVALUE%'''
        || ' ELSE regexp_replace(n.' || cstr || ', E''[\\n\\r]+'', ''\n'', ''g'') END, ''' || sepval || ''' ORDER BY h.pos)'
        || ' FROM hierarchy h' 
        || ' JOIN ' || tname || ' n ON (h.id = n.id AND lower(h.primarytype) = $1)' 
        || ' WHERE h.parentid = $2'
        || ' GROUP BY h.parentid'
        INTO aggstr
        USING tname, coid;

    RETURN aggstr;

END;
$$
LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION utils.aggRepGroupField(coid varchar, tname varchar, cname varchar, sepval varchar) to reporters_pahma;

-- SELECT proacl FROM pg_proc WHERE proname = 'aggrepgroupfield';

-- SELECT utils.aggRepGroupField('2dbcbf18-4966-4178-9880-e81258568921', 'referencegroup', 'reference', '|');

-- SELECT utils.aggRepGroupField('2dbcbf18-4966-4178-9880-e81258568921', 'nagprareportfiledgroup', 'nagprareportfiled', '|');

