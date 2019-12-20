/* Concatenates names of artists associated with a collection object
   in the standard 'lastname, first middle' format with artist nationality in parenthesis.
   Accepts id of a collection object.

   Usage:
     select objectnumber, concatArtistNatl(id)
     from collectionobjects_common
     where id = 'a5002073-7f33-4ba2-84e2-10ff9b8d8b8f');

 1994.13.3     | Alvarez, D-L (United States); Black, Joan Jett (United States); Blake, Nayland (United States); Courtney, Erin (United States); Ewert, Mary (United States); Fecteau, Vincent (United States); Gonzales, Mark (United States); Han, Donna (United States); Hengst, Cliff (United States); Horvitz, Philip (United States); Johnson, David E. (United States); Killian, Kevin (United States); Lindell, John (United States); Little, Connell Ray (United States); Mayerson, Keith (United States); Rollman, Michelle (United States); Smith, Wayne (United States); Winters, Jim (United States)
*/

-- DROP FUNCTION utils.concatArtistNatl (id VARCHAR);

 CREATE OR REPLACE FUNCTION utils.concatArtistNatl(id character varying)
  RETURNS character varying
  LANGUAGE plpgsql
  IMMUTABLE STRICT
 AS $function$
 
 DECLARE artistnatlstr VARCHAR;
 
 BEGIN
 
 select array_to_string(
     array_agg(
         case when b.bampfaobjectproductionpersonqualifier is null or b.bampfaobjectproductionpersonqualifier = ''
             then ''
             else utils.getdispl(b.bampfaobjectproductionpersonqualifier) || ' '
         end ||
         utils.getdispl(b.bampfaobjectproductionperson) ||
         case when pcn.item is null or pcn.item = ''
             then ''
             else ' (' || utils.getdispl(pcn.item) || ')'
         end
     order by hb.pos),
     '; ')
 into artistnatlstr
 from collectionobjects_common coc
 left outer join hierarchy hb on (
     coc.id = hb.parentid
     and hb.name = 'collectionobjects_bampfa:bampfaObjectProductionPersonGroupList')
 left outer join bampfaobjectproductionpersongroup b on (hb.id = b.id)
 left outer join persons_common pc on (b.bampfaobjectproductionperson = pc.refname)
 left outer join persons_common_nationalities pcn on (pc.id = pcn.id and pcn.pos = 0)
 where coc.id = $1
 and b.bampfaobjectproductionperson is not null
 and b.bampfaobjectproductionperson != ''
 group by coc.id
 ;
 
 RETURN artistnatlstr;
 
 END;
 
 $function$
;
 
GRANT EXECUTE ON FUNCTION utils.concatArtistNatl (id VARCHAR) TO PUBLIC;

