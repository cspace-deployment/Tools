--DROP FUNCTION get_uoc_authby (VARCHAR, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION get_uoc_authby (VARCHAR, VARCHAR default '%', VARCHAR default '%')
RETURNS VARCHAR
AS
$$

DECLARE authstr VARCHAR(4000);

BEGIN

select string_agg(
        to_char(ag.authorizationdate, 'yyyy-mm-dd') || ': <b>' ||
        getdispl(ag.authorizationstatus) || '</b>: ' ||
        getdispl(ag.authorizedby), '<br>' order by ag.authorizationdate)
into authstr
from uoc_common uc
join hierarchy hag on (
        uc.id = hag.parentid
        and hag.name = 'uoc_common:authorizationGroupList')
join authorizationgroup ag on (hag.id = ag.id)
where uc.id = $1
and ag.authorizedby like $2
and ag.authorizationstatus like $3
group by uc.id;

RETURN authstr;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION get_uoc_authby (VARCHAR, VARCHAR, VARCHAR) TO PUBLIC;

