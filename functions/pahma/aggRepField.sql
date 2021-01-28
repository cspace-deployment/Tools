/* aggRepField(coid varchar, tname varchar, sepval varchar)
 *   -- aggregates values of a repeating field
 *   -- requires:
 *      -- coid   = collectionobjects_common.id of the parent Collection Object
 *      -- tname  = table name of the repeating field
 *      -- sepval = separator/delimiter character
 */	

CREATE SCHEMA IF NOT EXISTS utils AUTHORIZATION nuxeo_pahma;

-- DROP FUNCTION utils.aggRepField(coid varchar, tname varchar, sepval varchar);

CREATE OR REPLACE FUNCTION utils.aggRepField(
    coid VARCHAR,
    tname VARCHAR,
    sepval VARCHAR)
RETURNS VARCHAR
AS $$
DECLARE
    aggstr VARCHAr;
BEGIN
    EXECUTE 'SELECT STRING_AGG(CASE WHEN item IS NULL THEN ''%NULLVALUE%'''
        || ' ELSE regexp_replace(item, E''[\\n\\r]+'', ''\n'', ''g'') END, ''' || sepval || ''' ORDER BY pos)'
        || ' FROM ' || tname 
        || ' WHERE id = $1'
        || ' GROUP BY id'
        INTO aggstr
        USING coid;

    RETURN aggstr;
END;
$$
LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION utils.aggRepField(coid varchar, tname varchar, sepval varchar) to reporters_pahma;

-- SELECT proacl FROM pg_proc WHERE proname = 'aggrepfield';

-- SELECT aggRepField('2dbcbf18-4966-4178-9880-e81258568921', 'collectionobjects_nagpra_nagpracategories', '|');

