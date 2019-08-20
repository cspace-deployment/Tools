-- DROP FUNCTION check_uoc_reqbyobjnum (VARCHAR, VARCHAR, VARCHAR)

CREATE OR REPLACE FUNCTION check_uoc_reqbyobjnum (VARCHAR, VARCHAR default null, VARCHAR default null)
RETURNS BOOLEAN
AS
$$

BEGIN

if $2 is null and $3 is null then
        RETURN true;
end if;

if $2 is not null and $3 is not null then
        RETURN EXISTS (
                select 1
                from uoc_common uc
                join hierarchy hug on (uc.id = hug.parentid and hug.name = 'uoc_common:userGroupList')
                join usergroup ug on (hug.id = ug.id)
                join hierarchy huc on (uc.id = huc.id)
                join relations_common rc on (huc.name = rc.subjectcsid and rc.subjectdocumenttype = 'Uoc')
                join hierarchy hcoc on (rc.objectcsid = hcoc.name and rc.objectdocumenttype = 'CollectionObject')
                join collectionobjects_common coc on (hcoc.id = coc.id)
                where uc.id = $1
                and ug.user = $2
                and coc.objectnumber = $3
        );
end if;

if $2 is not null and $3 is not null  then
        RETURN EXISTS (
                select 1
                from uoc_common uc
                join hierarchy hug on (uc.id = hug.parentid and hug.name = 'uoc_common:userGroupList')
                join usergroup ug on (hug.id = ug.id)
                where uc.id = $1
                and ug.user = $2
        );
end if;

if $2 is null and $3 is not null then
        RETURN EXISTS (
                select 1
                from uoc_common uc
                join hierarchy huc on (uc.id = huc.id)
                join relations_common rc on (huc.name = rc.subjectcsid and rc.subjectdocumenttype = 'Uoc')
                join hierarchy hcoc on (rc.objectcsid = hcoc.name and rc.objectdocumenttype = 'CollectionObject')
                join collectionobjects_common coc on (hcoc.id = coc.id)
                where uc.id = $1
                and coc.objectnumber = $3
        );
end if;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE;

GRANT EXECUTE ON FUNCTION check_uoc_reqbyobjnum (varchar, varchar, varchar) TO PUBLIC;

