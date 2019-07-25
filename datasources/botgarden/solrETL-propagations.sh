#!/bin/bash -x
date
cd /home/app_solr/solrdatasources/botgarden
##############################################################################
# move the current set of extracts to temp (thereby saving the previous run, just in case)
# note that in the case where there are several nightly scripts, e.g. public and internal,
# like here, the one to run first will "clear out" the previous night's data.
# since we don't know which order these might run in, I'm leaving the mv commands in both
# nb: the jobs in general can't overlap as the have some files in common and would step
# on each other
##############################################################################
# mv 4solr.*.csv.gz /tmp
##############################################################################
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintainance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5313 sslmode=prefer"
USERNAME="reporter_$TENANT"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
export NUMFIELDS=28
##############################################################################
# extract propagations info from CSpace
##############################################################################
time psql  -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f botgardenPropagations.sql -o p1.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' p1.csv > p2.csv 
time perl -ne 'print unless /\(\d+ rows\)/' p2.csv > p3.csv
time perl -ne '$x = $_ ;s/[^\t]//g; if (length eq $ENV{NUMFIELDS}) { print $x;} '     p3.csv > p4.csv &
time perl -ne '$x = $_ ;s/[^\t]//g; unless (length eq $ENV{NUMFIELDS}) { print $x;} ' p3.csv > errors.csv &
wait
# extract displayName from all refNames
perl -pe "s/urn:cspace:.*?.cspace.berkeley.edu:.*?:name(.*?):item:name(.*?)'(.*?)'/\3/g" p4.csv > p5.csv
head -1 p5.csv | perl -pe 's/\r//;s/\t/_s\t/g;s/_s//;s/$/_s/;' > header4Solr.csv
#tail -n +2 p5.csv | perl fixdate.pl > p7.csv
tail -n +2 p5.csv > p6.csv
cat header4Solr.csv p6.csv > 4solr.$TENANT.propagations.csv
##############################################################################
# here are the schema changes needed: copy all the _s and _ss to _txt, and vv.
##############################################################################
rm schemaFragment.xml
perl -pe 's/\t/\n/g' header4Solr.csv| perl -ne 'chomp; next unless /_s/; s/_s$//; print "    <copyField source=\"" .$_."_s\" dest=\"".$_."_txt\"/>\n"' >> schemaFragment.xml
##############################################################################
# here are the solr csv update parameters needed for multivalued fields
##############################################################################
perl -pe 's/\t/\n/g' header4Solr.csv| perl -ne 'chomp; next unless /_ss/; next if /blob/; print "f.$_.split=true&f.$_.separator=%7C&"' > uploadparms.txt
wc -l *.csv
##############################################################################
# count the types and tokens in the final file
##############################################################################
time python3 evaluate.py 4solr.$TENANT.propagations.csv /dev/null > counts.propagations.csv &
curl -S -s "http://localhost:8983/solr/${TENANT}-propagations/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-propagations/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
time curl -X POST -S -s "http://localhost:8983/solr/${TENANT}-propagations/update/csv?commit=true&header=true&trim=true&separator=%09&encapsulator=\\" -T 4solr.$TENANT.propagations.csv -H 'Content-type:text/plain; charset=utf-8' &
# count blobs
cut -f67 4solr.${TENANT}.public.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.public.blobs.csv
cut -f67 4solr.${TENANT}.public.csv | perl -pe 's/\r//;s/,/\n/g' | grep -v 'blob_ss' | grep . | wc -l >> counts.public.blobs.csv
cp counts.public.blobs.csv /tmp/$TENANT.counts.public.csv
# get rid of intermediate files
rm p?.csv header4Solr.csv*
wait
# zip up .csvs, save a bit of space on backups
gzip -f 4solr.$TENANT.propagations.csv
date
