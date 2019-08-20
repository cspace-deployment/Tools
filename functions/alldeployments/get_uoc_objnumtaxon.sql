-- DROP FUNCTION get_uoc_objnumtaxon (VARCHAR);

CREATE OR REPLACE FUNCTION get_uoc_objnumtaxon (VARCHAR)
RETURNS VARCHAR
AS
$$

DECLARE objnumtaxstr VARCHAR(9000);

BEGIN

select string_agg(coc.objectnumber || ': ' || getdispl(tig.taxon), '; ' order by coc.objectnumber)
into objnumtaxstr
from uoc_common uc
join hierarchy huc on (uc.id = huc.id)
join relations_common rc on (huc.name = rc.subjectcsid and rc.subjectdocumenttype = 'Uoc')
join hierarchy hcoc on (rc.objectcsid = hcoc.name and rc.objectdocumenttype = 'CollectionObject')
join collectionobjects_common coc on (hcoc.id = coc.id)
join hierarchy htig on (
        coc.id = htig.parentid
        and htig.name = 'collectionobjects_naturalhistory:taxonomicIdentGroupList'
        and htig.pos = 0)
join taxonomicidentgroup tig on (htig.id = tig.id)
where uc.id = $1
and coc.objectnumber is not null
and coc.objectnumber != ''
group by uc.id;

RETURN objnumtaxstr;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION get_uoc_objnumtaxon (VARCHAR) TO PUBLIC;

