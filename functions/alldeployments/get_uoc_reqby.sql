-- DROP FUNCTION get_uoc_reqby (VARCHAR);

CREATE OR REPLACE FUNCTION get_uoc_reqby (VARCHAR)
RETURNS VARCHAR
AS
$$

DECLARE reqstr VARCHAR(4000);

BEGIN

select string_agg(
        getdispl(ug.usertype) || ': ' ||
        getdispl(ug.user), '<br>' order by hug.pos)
into reqstr
from uoc_common uc
join hierarchy hug on (
        uc.id = hug.parentid
        and hug.name = 'uoc_common:userGroupList')
join usergroup ug on (hug.id = ug.id)
where uc.id = $1
group by uc.id;

RETURN reqstr;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION get_uoc_reqby (VARCHAR) TO PUBLIC;

