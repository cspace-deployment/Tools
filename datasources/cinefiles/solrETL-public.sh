#!/bin/bash -x
date
cd /home/app_solr/solrdatasources/cinefiles
##############################################################################
# move the current set of extracts to temp (thereby saving the previous run, just in case)
# note that in the case where there are several nightly scripts, e.g. public and internal,
# the one to run first will "clear out" the previous night's data.
# NB: at the moment CineFiles has only a public solr core.
##############################################################################
mv 4solr.*.csv.gz /tmp
##############################################################################
# while most of this script is already tenant specific, many of the commands
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
# NB: unlike the other ETL processes, we're still using the default | delimiter here
##############################################################################
time psql -R"@@" -F $'\t' -A -U $USERNAME -d "$CONNECTSTRING"  -f metadata_public.sql -o d1.csv
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1.csv > d4.csv 
time psql -R"@@" -F $'\t' -A -U $USERNAME -d "$CONNECTSTRING" -f media_public.sql -o m1.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m1.csv > media.csv
cp d4.csv metadata.csv
# make the header
head -1 metadata.csv > header4Solr.csv
# add the blob field name to the header (the header already ends with a tab); rewrite objectcsid_s to id (for solr id...)
perl -i -pe 's/\r//;s/\t/_s\t/g;s/id_s/id_ss/g;s/id_ss/id/;s/$/_s\tblob_ss/;s/_ss_s/_ss/;' header4Solr.csv
# add the blobcsids to the rest of the data
time perl mergeObjectsAndMedia.pl media.csv metadata.csv > d6.csv
# we want to use our "special" solr-friendly header.
tail -n +2 d6.csv | grep -v " rows)" > d7.csv
cat header4Solr.csv d7.csv > 4solr.$TENANT.public.csv
wc -l *.csv
##############################################################################
# count the types and tokens in the final file
##############################################################################
time python3 evaluate.py 4solr.$TENANT.public.csv /dev/null > counts.public.csv &
# clear out the existing data
curl -S -s "http://localhost:8983/solr/${TENANT}-public/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-public/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
# note: we skip current location and current crate in loading Solr...
time curl -X POST -S -s "http://localhost:8983/solr/${TENANT}-public/update/csv?commit=true&header=true&trim=true&separator=%09&f.grouptitle_ss.split=true&f.grouptitle_ss.separator=;&f.othernumbers_ss.split=true&f.othernumbers_ss.separator=;&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" -T 4solr.$TENANT.public.csv -H 'Content-type:text/plain; charset=utf-8' &
# get rid of intermediate files
# count blobs
cut -f51 4solr.${TENANT}.public.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.public.blobs.csv
cut -f51 4solr.${TENANT}.public.csv | perl -pe 's/\r//;s/,/\n/g;s/\|/\n/g;' | grep -v 'blob_ss' | grep . | wc -l >> counts.public.blobs.csv &
wait
cp counts.public.blobs.csv /tmp/$TENANT.counts.public.blobs.csv
rm d?.csv m?.csv b?.csv media.csv metadata.csv
cat counts.public.blobs.csv
# zip up .csvs, save a bit of space on backups
gzip -f *.csv
#
date
