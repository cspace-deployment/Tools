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
CORE=locations
HOSTNAME="dba-postgres-prod-42.ist.berkeley.edu port=5307 sslmode=prefer"
USERNAME="reporter_pahma"
DATABASE="pahma_domain_pahma"
CONNECTSTRING="host=$HOSTNAME dbname=$DATABASE"
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
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
grep -P "^object_" m3.sort.csv > header4Solr.csv &
grep -v -P "^object_" m3.sort.csv > m4.csv &
wait
# add a sequential integer as the solr id
perl -i -pe '$i++;print $i . "\t"' m4.csv
perl -i -pe 's/^/id\t/' header4Solr.csv
cat header4Solr.csv m4.csv > m6.csv
rm m3.sort.csv m4.csv
##############################################################################
# count the types and tokens in the final file
##############################################################################
time python evaluate.py m6.csv 4solr.${TENANT}.${CORE}.csv > counts.${CORE}.csv
##############################################################################
# check if we have enough data to be worth refreshing...
##############################################################################
CSVFILE="4solr.${TENANT}.${CORE}.csv"
# this value is an approximate lower bound on the number of rows there should
# be, based on data as of 2019-09-11. It may need to be periodically adjusted.
MINIMUM=3700000
ROWS=`wc -l < ${CSVFILE}`
if (( ${ROWS} < ${MINIMUM} )); then
   echo "Only ${ROWS} rows in ${CSVFILE}; refresh aborted, core left untouched." | mail -s "PROBLEM with ${TENANT}-${CORE} nightly solr refresh" -- cspace-support@lists.berkeley.edu
   exit 1
fi
##############################################################################
# OK, we are good to go! clear out the existing data
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
##############################################################################
# this POSTs the csv to the Solr / update endpoint
# note, among other things, the overriding of the encapsulator with \
##############################################################################
time curl -X POST -s -S "http://localhost:8983/solr/pahma-${CORE}/update/csv?commit=true&header=true&trim=true&separator=%09&encapsulator=\\" -T 4solr.pahma.${CORE}.csv -H 'Content-type:text/plain; charset=utf-8' &
# count blobs
cut -f67 4solr.${TENANT}.${CORE}.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.${CORE}.blobs.csv &
cut -f67 4solr.${TENANT}.${CORE}.csv | perl -pe 's/\r//;s/,/\n/g' | grep -v 'blob_ss' | grep . | wc -l >> counts.${CORE}.blobs.csv &
wait
cp counts.${CORE}.blobs.csv /tmp/${TENANT}.counts.${CORE}.csv
# get rid of intermediate files
rm m6.csv
gzip -f 4solr.${TENANT}.${CORE}.csv
date
