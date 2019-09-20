#!/bin/bash -x
date
cd /home/app_solr/solrdatasources/ucjeps
##############################################################################
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintainance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
CORE=media
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5310 sslmode=prefer"
USERNAME="reporter_${TENANT}"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
##############################################################################
# save last night results to tmp just in case
##############################################################################
mv 4solr.${TENANT}.${CORE}.csv.gz /tmp
##############################################################################
# get media
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f ucjepsNewMedia.sql -o newmedia.csv
time perl -i -pe 's/[\r\n]/ /g;s/\@\@/\n/g' newmedia.csv
perl -ne 's/\\/x/g; next if / rows/; print $_' newmedia.csv > 4solr.${TENANT}.${CORE}.csv
##############################################################################
# check if we have enough data to be worth refreshing...
##############################################################################
CSVFILE="4solr.${TENANT}.${CORE}.csv"
# this value is an approximate lower bound on the number of rows there should
# be, based on data as of 2019-09-11. It may need to be periodically adjusted.
MINIMUM=19000
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
# load the csv file into Solr using the csv DIH
##############################################################################
time curl -X POST -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update/csv?commit=true&header=true&trim=true&separator=%09&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" -T 4solr.${TENANT}.${CORE}.csv -H 'Content-type:text/plain; charset=utf-8' &
##############################################################################
# count the types and tokens in the sql output
##############################################################################
time python3 evaluate.py 4solr.${TENANT}.${CORE}.csv /dev/null > counts.${CORE}.csv
# get rid of intermediate files
rm newmedia.csv
# count blobs
cut -f8 4solr.${TENANT}.${CORE}.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.${CORE}.blobs.csv
cut -f8 4solr.${TENANT}.${CORE}.csv | perl -pe 's/\r//;s/,/\n/g' | grep -v 'blob_ss' | grep . | wc -l >> counts.${CORE}.blobs.csv
cp counts.${CORE}.blobs.csv /tmp/${TENANT}.counts.${CORE}.csv
# zip up .csvs, save a bit of space on backups
gzip -f 4solr.${TENANT}.${CORE}.csv
wait
date
