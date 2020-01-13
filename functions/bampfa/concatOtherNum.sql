-- DROP FUNCTION utils.concatOtherNum (id VARCHAR);

-- Concatenates Other Numbers associated with a collection object
-- Accepts csid of a collection object

CREATE OR REPLACE FUNCTION utils.concatOtherNum(id character varying)
 RETURNS character varying
 LANGUAGE plpgsql
 IMMUTABLE STRICT
AS $function$
 
 DECLARE othernumstr VARCHAR(300);
 
 BEGIN
 
 select array_to_string(
     array_agg(
         o.numbervalue ||
         case when o.numbertype is null or o.numbertype = ''
             then ''
             else ' (' || o.numbertype || ')'
         end
     order by ho.pos),
     '; ')
 into othernumstr
 from collectionobjects_common coc
 join hierarchy ho on (
     coc.id = ho.parentid
     and ho.name = 'collectionobjects_common:otherNumberList')
 join othernumber o on (ho.id = o.id)
 where coc.id = $1
 and o.numbervalue is not null
 and o.numbervalue != ''
 group by coc.id;
 
 RETURN othernumstr;
 
 END;
 
$function$
;
 
GRANT EXECUTE ON FUNCTION utils.concatOtherNum (id VARCHAR) TO PUBLIC;

/*
select coc.objectnumber, utils.concatOtherNum(coc.id) othernumber
from collectionobjects_common coc
where coc.id in ( '96d5db9b-443f-419d-8e54-d63a497289ba', 'e4b43c50-b7f3-4545-999d-8646c793b656');

   objectnumber    |                    othernumber                   
-------------------+---------------------------------------------------
 INV.2015.126.1-55 | OBJ0363; OBJ0366; TR.87.1969.1-35; TR.8.1970.1-18
 1983.24.3         | EL15.77.7 (previous)
(2 rows)
*/
