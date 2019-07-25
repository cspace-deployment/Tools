#!/bin/bash -x
date
cd /home/app_solr/solrdatasources/ucjeps
##############################################################################
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintainance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5310 sslmode=prefer"
USERNAME="reporter_$TENANT"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
##############################################################################
# save last night results to tmp just in case
##############################################################################
mv 4solr.${TENANT}.media.csv /tmp
##############################################################################
# get media
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f ucjepsNewMedia.sql -o newmedia.csv
time perl -i -pe 's/[\r\n]/ /g;s/\@\@/\n/g' newmedia.csv
perl -ne 's/\\/x/g; next if / rows/; print $_' newmedia.csv > 4solr.${TENANT}.media.csv
##############################################################################
# clear out the existing data
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-media/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-media/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
##############################################################################
# load the csv file into Solr using the csv DIH
##############################################################################
time curl -X POST -S -s "http://localhost:8983/solr/${TENANT}-media/update/csv?commit=true&header=true&trim=true&separator=%09&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" -T 4solr.$TENANT.media.csv -H 'Content-type:text/plain; charset=utf-8' &
##############################################################################
# count the types and tokens in the sql output
##############################################################################
time python3 evaluate.py 4solr.${TENANT}.media.csv /dev/null > counts.media.csv
# get rid of intermediate files
rm newmedia.csv
# count blobs
cut -f8 4solr.${TENANT}.public.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.public.blobs.csv
cut -f8 4solr.${TENANT}.public.csv | perl -pe 's/\r//;s/,/\n/g' | grep -v 'blob_ss' | grep . | wc -l >> counts.public.blobs.csv
cp counts.public.blobs.csv /tmp/$TENANT.counts.public.csv
# zip up .csvs, save a bit of space on backups
gzip -f 4solr.${TENANT}.media.csv
wait
date
