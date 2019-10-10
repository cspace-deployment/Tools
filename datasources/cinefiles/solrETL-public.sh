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
CORE=public
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5313 sslmode=prefer"
USERNAME="reporter_${TENANT}"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
CONTACT="jblowe@berkeley.edu"
##############################################################################
# extract metadata and media info from CSpace
##############################################################################
# NB: unlike the other ETL processes, we're still using the default | delimiter here
##############################################################################
time psql -R"@@" -F $'\t' -A -U $USERNAME -d "$CONNECTSTRING"  -c "select * from cinefiles_denorm.doclist_view"  -o d1a.csv
time psql -R"@@" -F $'\t' -A -U $USERNAME -d "$CONNECTSTRING"  -c "select * from cinefiles_denorm.filmlist_view" -o d1b.csv
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1a.csv > docs.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1b.csv > films.csv
rm d1?.csv
time psql -R"@@" -F $'\t' -A -U $USERNAME -d "$CONNECTSTRING" -f media_${CORE}.sql -o m1.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m1.csv > media.csv

# make the header
head -1 docs.csv > header4Solr.csv
# add the blob field name to the header (the header already ends with a tab); rewrite objectcsid_s to id (for solr id...)
perl -i -pe 's/\r//;s/^/d/;s/\t/_s\t/g;s/ddoc_id_s/id/;s/$/_s\tblob_ss/;s/_ss_s/_ss/;' header4Solr.csv
# add the blobcsids to the rest of the data
time perl mergeObjectsAndMedia.pl media.csv docs.csv > d6.csv
# we want to use our "special" solr-friendly header.
tail -n +2 d6.csv | grep -v " rows)" > d7.csv
cat header4Solr.csv d7.csv > docs.csv

# make the header
head -1 films.csv > header4Solr.csv
# add the blob field name to the header (the header already ends with a tab); rewrite objectcsid_s to id (for solr id...)
# nb: yes it is a happy accident that 'updatedat', a date-type field, is the last field. be careful if that every changes!
perl -i -pe 's/\r//;s/^/f/;s/\t/_s\t/g;s/ffilm_id_s/id/;s/$/_s/;s/_ss_s/_ss/;' header4Solr.csv
# we want to use our "special" solr-friendly header.
tail -n +2 films.csv | grep -v " rows)" > d7.csv
cat header4Solr.csv d7.csv > films.csv

wc -l *.csv
##############################################################################
# check if we have enough data to be worth refreshing...
##############################################################################
for f in docs.csv films.csv; do
  time python evaluate.py $f /dev/null > counts.$f &
  CSVFILE=${f}
  # this value is an approximate lower bound on the number of rows there should
  # be, based on data as of 2019-09-11. It may need to be periodically adjusted.
  MINIMUM=10000
  ROWS=`wc -l < ${CSVFILE}`
  if (( ${ROWS} < ${MINIMUM} )); then
     echo "Only ${ROWS} rows in ${CSVFILE}; refresh aborted, core left untouched." | mail -s "PROBLEM with ${TENANT}-${CORE} nightly solr refresh" -- ${CONTACT}
     exit 1
  fi
done;
##############################################################################
# OK, we are good to go! clear out the existing data
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
# note: we skip current location and current crate in loading Solr...
time curl -X POST -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update/csv?commit=true&header=true&trim=true&separator=%09&f.grouptitle_ss.split=true&f.grouptitle_ss.separator=;&f.othernumbers_ss.split=true&f.othernumbers_ss.separator=;&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" -T docs.csv -H 'Content-type:text/plain; charset=utf-8' &
time curl -X POST -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update/csv?commit=true&header=true&trim=true&separator=%09&f.grouptitle_ss.split=true&f.grouptitle_ss.separator=;&f.othernumbers_ss.split=true&f.othernumbers_ss.separator=;&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" -T films.csv -H 'Content-type:text/plain; charset=utf-8' &
# get rid of intermediate files
# count blobs
cut -f51 docs.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.${CORE}.blobs.csv
cut -f51 docs.csv | perl -pe 's/\r//;s/,/\n/g;s/\|/\n/g;' | grep -v 'blob_ss' | grep . | wc -l >> counts.${CORE}.blobs.csv &
wait
cp counts.${CORE}.blobs.csv /tmp/${TENANT}.counts.${CORE}.blobs.csv
rm d?.csv m?.csv b?.csv media.csv docs.csv
cat counts.${CORE}.blobs.csv
# zip up .csvs, save a bit of space on backups
gzip -f *.csv
#
date
