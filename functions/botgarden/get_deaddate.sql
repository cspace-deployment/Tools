/* Gets the latest dead date for a specific:
     1) accession: collectionobjects_common.objectnumber
     2) bed location: getdispl(movments_botgarden.previouslocation)

   Used in the All Accessions Ever (ucbgAccessionsByBedDate.jrxml) report.

   Usage:
     select get_deaddate('98.0890', '3A, Vernal Pool, Californian');
*/

-- drop function get_deaddate (cocid varchar, bedloc varchar);

create or replace function get_deaddate (cocid varchar, bedloc varchar)
returns timestamp
as
$$
declare
        recCount int;
        deadDate  timestamp;

begin

        select into recCount count(distinct(mc.locationdate))
        from movements_common mc
        join movements_botgarden mb on (mc.id = mb.id)
        join hierarchy hmc on (mc.id = hmc.id)
        join relations_common rc on (hmc.name = rc.subjectcsid and rc.objectdocumenttype = 'CollectionObject')
        join hierarchy hcoc on (rc.objectcsid = hcoc.name)
        join collectionobjects_common coc on (hcoc.id = coc.id)
        where coc.objectnumber = $1
        and getdispl(mc.reasonformove) = 'Dead'
        and getdispl(mb.previouslocation) = $2;

        if recCount = 0 then return null;

        elseif recCount = 1 then
                select into deadDate distinct mc.locationdate
                from movements_common mc
                join movements_botgarden mb on (mc.id = mb.id)
                join hierarchy hmc on (mc.id = hmc.id)
                join relations_common rc on (hmc.name = rc.subjectcsid and rc.objectdocumenttype = 'CollectionObject')
                join hierarchy hcoc on (rc.objectcsid = hcoc.name)
                join collectionobjects_common coc on (hcoc.id = coc.id)
                where coc.objectnumber = $1
                and getdispl(mc.reasonformove) = 'Dead'
                and getdispl(mb.previouslocation) = $2;

                return deadDate;

        elseif recCount > 1 then
                select into deadDate max(distinct(mc.locationdate))
                from movements_common mc
                join movements_botgarden mb on (mc.id = mb.id)
                join hierarchy hmc on (mc.id = hmc.id)
                join relations_common rc on (hmc.name = rc.subjectcsid and rc.objectdocumenttype = 'CollectionObject')
                join hierarchy hcoc on (rc.objectcsid = hcoc.name)
                join collectionobjects_common coc on (hcoc.id = coc.id)
                where coc.objectnumber = $1
                and getdispl(mc.reasonformove) = 'Dead'
                and getdispl(mb.previouslocation) = $2;

                return deadDate;
        end if;

        return null;

end;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

grant execute on function get_deaddate(varchar, varchar) to public;

