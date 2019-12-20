/* Gets the latest action date for a specific:
     1) accession: collectionobjects_common.objectnumber
     2) action: movements_common.reasonformove
     3) bed location: getdispl(movments_common.currentlocation)

   Used in the All Accessions Ever (ucbgAccessionsByBedDate.jrxml) report.

   Usage:
     select get_actiondate('98.0890', 'Planted Out', '3A, Vernal Pool, Californian');
*/

-- drop function get_actiondate (cocid varchar, action varchar, bedloc varchar);

create or replace function get_actiondate (cocid varchar, action varchar, bedloc varchar)
returns timestamp
as
$$
declare
        recCount int;
        actionDate  timestamp;

begin

        select into recCount count(distinct(mc.locationdate))
        from movements_common mc
        join hierarchy hmc on (mc.id = hmc.id)
        join relations_common rc on (hmc.name = rc.subjectcsid and rc.objectdocumenttype = 'CollectionObject')
        join hierarchy hcoc on (rc.objectcsid = hcoc.name)
        join collectionobjects_common coc on (hcoc.id = coc.id)
        where coc.objectnumber = $1
        and getdispl(mc.reasonformove) = $2
        and getdispl(mc.currentlocation) = $3;

        if recCount = 0 then return null;

        elseif recCount = 1 then
                select into actionDate distinct mc.locationdate
                from movements_common mc
                join hierarchy hmc on (mc.id = hmc.id)
                join relations_common rc on (hmc.name = rc.subjectcsid and rc.objectdocumenttype = 'CollectionObject')
                join hierarchy hcoc on (rc.objectcsid = hcoc.name)
                join collectionobjects_common coc on (hcoc.id = coc.id)
                where coc.objectnumber = $1
                and getdispl(mc.reasonformove) = $2
                and getdispl(mc.currentlocation) = $3;

                return actionDate;

        elseif recCount > 1 then
                select into actionDate max(distinct(mc.locationdate))
                from movements_common mc
                join hierarchy hmc on (mc.id = hmc.id)
                join relations_common rc on (hmc.name = rc.subjectcsid and rc.objectdocumenttype = 'CollectionObject')
                join hierarchy hcoc on (rc.objectcsid = hcoc.name)
                join collectionobjects_common coc on (hcoc.id = coc.id)
                where coc.objectnumber = $1
                and getdispl(mc.reasonformove) = $2
                and getdispl(mc.currentlocation) = $3;

                return actionDate;
        end if;

        return null;

end;
$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

grant execute on function get_actiondate(varchar, varchar, varchar) to public;

