/* utils.aggRepDateField(coid varchar, tname varchar, cname varchar, sepval varchar)
 *   -- aggregates values of a repeating date field
 *   -- requires:
 *      -- coid   = collectionobjects_common.id of the parent Collection Object
 *      -- tname  = table name of the repeating group
 *      -- cname  = column name of the date field in structuredDateGroup
 *      -- sepval = separator/delimiter character
 */	

CREATE SCHEMA IF NOT EXISTS utils AUTHORIZATION nuxeo_pahma;

-- DROP FUNCTION utils.aggRepDateField(coid varchar, tname varchar, cname varchar, sep varchar);

CREATE OR REPLACE FUNCTION utils.aggRepDateField(
    coid VARCHAR,
    tname VARCHAR,
    cname VARCHAR,
    sepval VARCHAR)
RETURNS VARCHAR
AS $$
DECLARE
    ctype VARCHAR;
    cstr VARCHAR := cname::text;
    aggstr VARCHAR;
BEGIN

    EXECUTE 'SELECT STRING_AGG(CASE WHEN s.' || cname || ' IS NULL THEN ''%NULLVALUE%'''
        || ' ELSE s.' || cstr || ' END, ''' || sepval || ''' ORDER BY h.pos)'
        || ' FROM hierarchy h' 
        || ' JOIN ' || tname || ' n ON (h.id = n.id)'
        || ' JOIN hierarchy hn on (n.id = hn.parentid AND hn.primarytype = ''structuredDateGroup'')' 
        || ' JOIN structureddategroup s ON (hn.id = s.id)'
        || ' WHERE h.parentid = $2'
        || ' GROUP BY h.parentid'
        INTO aggstr
        USING tname, coid;

    RETURN aggstr;

END;
$$
LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION utils.aggRepDateField(coid varchar, tname varchar, cname varchar, sepval varchar) to reporters_pahma;

-- SELECT proacl FROM pg_proc WHERE proname = 'aggrepdatefield';

-- SELECT utils.aggRepDateField('2dbcbf18-4966-4178-9880-e81258568921', 'nagprareportfiledgroup', 'datedisplaydate', '|');

