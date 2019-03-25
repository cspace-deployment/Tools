#!/bin/bash -x
date
cd /home/app_solr/solrdatasources/bampfa
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
##############################################################################
# extract metadata and media info from CSpace
##############################################################################
time psql -R"@@" -F $'\t' -A -U $USERNAME -d "$CONNECTSTRING"  -f metadata_internal.sql -o d1.csv
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1.csv > d3.csv
##############################################################################
# count the types and tokens in the final file, check cell counts
##############################################################################
time python evaluate.py d3.csv d4.csv > counts.internal.errors.csv
time psql -R"@@" -F $'\t' -A -U $USERNAME -d "$CONNECTSTRING" -f media_internal.sql -o m1.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m1.csv > media.csv 
time psql -R"@@" -F $'\t' -A -U $USERNAME -d "$CONNECTSTRING" -f blobs.sql -o b1.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' b1.csv > blobs.csv
# Compute the "view status" of each object
time perl addStatus.pl internal 37 38  < d4.csv > metadata.csv
# make the header
head -1 metadata.csv > header4Solr.csv
# add the blob field name to the header (the header already ends with a tab); rewrite objectcsid_s to id (for solr id...)
perl -i -pe 's/\r//;s/\t/_s\t/g;s/objectcsid_s/id/;s/$/_s\tblob_ss/;s/_ss_s/_ss/;' header4Solr.csv
# add the blobcsids to the rest of the data
time perl mergeObjectsAndMedia.pl media.csv metadata.csv > d6.csv
# we want to use our "special" solr-friendly header.
tail -n +2 d6.csv > d7.csv
cat header4Solr.csv d7.csv > d8.csv
##############################################################################
# compute _i values for _dt values (to support BL date range searching)
##############################################################################
time python computeTimeIntegers.py d8.csv 4solr.$TENANT.internal.csv
wc -l *.csv
# clear out the existing data
curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
time curl -X POST -S -s "http://localhost:8983/solr/${TENANT}-internal/update/csv?commit=true&header=true&trim=true&separator=%09&f.grouptitle_ss.split=true&f.grouptitle_ss.separator=;&f.othernumbers_ss.split=true&f.othernumbers_ss.separator=;&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" -T 4solr.$TENANT.internal.csv -H 'Content-type:text/plain; charset=utf-8' &
##############################################################################
# count the types and tokens in the final file, check cell counts
##############################################################################
time python evaluate.py 4solr.$TENANT.internal.csv /dev/null > counts.internal.csv &
# get rid of intermediate files
rm d?.csv m?.csv b?.csv media.csv metadata.csv &
cut -f43 4solr.${TENANT}.internal.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.internal.blobs.csv
cut -f43 4solr.${TENANT}.internal.csv | perl -pe 's/\r//;s/,/\n/g;s/\|/\n/g;' | grep -v 'blob_ss' | grep . | wc -l >> counts.internal.blobs.csv
cp counts.internal.blobs.csv /tmp/$TENANT.counts.internal.blobs.csv
cat counts.internal.blobs.csv
wait
# zip up .csvs, save a bit of space on backups
gzip -f *.csv
date
