#!/bin/bash -x
#
##############################################################################
# shell script to extract multiple tabular data files from CSpace,
# "stitch" them together (see join.py)
# prep them for load into Solr4 using the "csv datahandler"
##############################################################################
date
cd /home/app_solr/solrdatasources/pahma
##############################################################################
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintainance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
HOSTNAME="dba-postgres-prod-42.ist.berkeley.edu port=5307 sslmode=prefer"
USERNAME="reporter_pahma"
DATABASE="pahma_domain_pahma"
CONNECTSTRING="host=$HOSTNAME dbname=$DATABASE"
export NUMCOLS=36
##############################################################################
# extract locations, past and present, from CSpace
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f locations1.sql -o m1.csv &
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f locations2.sql -o m2.csv &
wait
# cleanup newlines and crlf in data, then switch record separator.
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m1.csv > m1a.csv &
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m2.csv > m2a.csv &
wait
rm m1.csv m2.csv
##############################################################################
# stitch the two files together
##############################################################################
time sort m1a.csv > m1a.sort.csv &
time sort m2a.csv > m2a.sort.csv &
wait
rm m1a.csv m2a.csv
time join -j 1 -t $'\t' m1a.sort.csv m2a.sort.csv > m3.sort.csv
rm m1a.sort.csv m2a.sort.csv
cut -f1-5,7- m3.sort.csv > m4.csv
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
grep -P "^csid_s\t" m4.csv > header4Solr.csv &
grep -v -P "^csid_s\t" m4.csv > m5.csv &
wait
cat header4Solr.csv m5.csv > m4.csv
rm m5.csv m3.sort.csv
##############################################################################
# count the types and tokens in the final file
##############################################################################
time python evaluate.py m4.csv 4solr.${TENANT}.locations.csv > counts.locations.csv
##############################################################################
# ok, now let's load this into solr...
# clear out the existing data
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-locations/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-locations/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
##############################################################################
# this POSTs the csv to the Solr / update endpoint
# note, among other things, the overriding of the encapsulator with \
##############################################################################
time curl -X POST -s -S 'http://localhost:8983/solr/pahma-locations/update/csv?commit=true&header=true&trim=true&separator=%09&encapsulator=\' -T 4solr.pahma.locations.csv -H 'Content-type:text/plain; charset=utf-8' &
# count blobs
cut -f67 4solr.${TENANT}.locations.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.locations.blobs.csv
cut -f67 4solr.${TENANT}.locations.csv | perl -pe 's/\r//;s/,/\n/g' | grep -v 'blob_ss' | grep . | wc -l >> counts.locations.blobs.csv
cp counts.locations.blobs.csv /tmp/$TENANT.counts.locations.csv
# get rid of intermediate files
rm m4.csv
wait
gzip 4solr.$TENANT.locations.csv
date
