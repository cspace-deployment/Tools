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
##############################################################################
# extract metadata (dead and alive) info from CSpace
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f botgardenMetadataV1alive.sql -o d1a.csv
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f botgardenMetadataV1dead.sql -o d1b.csv
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1b.csv > d2b.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1a.csv > d2a.csv
cat d2b.csv d2a.csv > d2.csv
time perl -ne 'print unless /\(\d+ rows\)/' d2.csv > d3.csv
##############################################################################
# count the number of columns in each row, solr wants them all to be the same
##############################################################################
time python evaluate.py d3.csv d4.csv > counts.internal.rawdata.csv
##############################################################################
# run the media query
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f media.sql  -o i4.csv
# cleanup newlines and crlf in data, then switch record separator.
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' i4.csv > 4solr.$TENANT.media.csv
rm i4.csv
##############################################################################
# check latlongs
##############################################################################
perl -ne '@y=split /\t/;@x=split ",",$y[17];print if  (abs($x[0])<90 && abs($x[1])<180);' d4.csv > d5.csv
perl -ne '@y=split /\t/;@x=split ",",$y[17];print if !(abs($x[0])<90 && abs($x[1])<180);' d4.csv > errors_in_latlong.csv
##############################################################################
# temporary hack to parse Locality into County/State/Country
##############################################################################
perl fixLocalites.pl d5.csv > metadata.csv
cut -f10 metadata.csv | perl -pe 's/\|/\n/g;' | sort | uniq -c | perl -pe 's/^ *(\d+) /\1\t/' > county.csv
cut -f11 metadata.csv | perl -pe 's/\|/\n/g;' | sort | uniq -c | perl -pe 's/^ *(\d+) /\1\t/' > state.csv
cut -f12 metadata.csv | perl -pe 's/\|/\n/g;' | sort | uniq -c | perl -pe 's/^ *(\d+) /\1\t/' > country.csv
rm d3.csv
##############################################################################
# make a unique sequence number for id
##############################################################################
perl -i -pe '$i++;print $i . "\t"' metadata.csv
python gbif/parseAndInsertGBIFparts.py metadata.csv metadata+parsednames.csv gbif/names.pickle 3
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
grep -P "^1\tid\t" metadata+parsednames.csv | head -1 > header4Solr.csv
perl -i -pe 's/^1\tid/id\tobjcsid_s/' header4Solr.csv
perl -i -pe 's/\r//;s/$/\tblob_ss/' header4Solr.csv
grep -v -P "^1\tid\t" metadata+parsednames.csv > d7.csv
python fixfruits.py d7.csv > d8.csv
##############################################################################
# add the blob csids to the rest of the internal
##############################################################################
time perl mergeObjectsAndMedia.pl 4solr.$TENANT.media.csv d8.csv internal > d9.csv
cat header4Solr.csv d9.csv | perl -pe 's/␥/|/g' > d10.csv
##############################################################################
# compute _i values for _dt values (to support BL date range searching)
##############################################################################
time python computeTimeIntegers.py d10.csv 4solr.$TENANT.internal.csv
# shorten this one long org name...
perl -i -pe 's/International Union for Conservation of Nature and Natural Resources/IUCN/g' 4solr.$TENANT.internal.csv
wc -l *.csv
#
time python evaluate.py 4solr.$TENANT.internal.csv /dev/null > counts.internal.csv &
curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
time curl -X POST -S -s "http://localhost:8983/solr/${TENANT}-internal/update/csv?commit=true&header=true&trim=true&separator=%09&f.fruiting_ss.split=true&f.fruiting_ss.separator=%7C&f.flowering_ss.split=true&f.flowering_ss.separator=%7C&f.fruitingverbatim_ss.split=true&f.fruitingverbatim_ss.separator=%7C&f.floweringverbatim_ss.split=true&f.floweringverbatim_ss.separator=%7C&f.collcounty_ss.split=true&f.collcounty_ss.separator=%7C&f.collstate_ss.split=true&f.collstate_ss.separator=%7C&f.collcountry_ss.split=true&f.collcountry_ss.separator=%7C&f.conservationinfo_ss.split=true&f.conservationinfo_ss.separator=%7C&f.conserveorg_ss.split=true&f.conserveorg_ss.separator=%7C&f.conservecat_ss.split=true&f.conservecat_ss.separator=%7C&f.voucherlist_ss.split=true&f.voucherlist_ss.separator=%7C&f.gardenlocation_ss.split=true&f.gardenlocation_ss.separator=%7C&f.grouptitle_ss.split=true&f.grouptitle_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" -T 4solr.$TENANT.internal.csv -H 'Content-type:text/plain; charset=utf-8' &
# count blobs
cut -f67 4solr.${TENANT}.internal.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.internal.blobs.csv
cut -f67 4solr.${TENANT}.internal.csv | perl -pe 's/\r//;s/,/\n/g;s/\|/\n/g;' | grep -v 'blob_ss' | grep . | wc -l >> counts.internal.blobs.csv
wait
cp counts.internal.blobs.csv /tmp/$TENANT.counts.internal.blobs.csv
cat counts.internal.blobs.csv
cp counts.internal.csv /tmp/$TENANT.counts.internal.csv
# get rid of intermediate files
rm d?.csv d??.csv m?.csv metadata*.csv
# zip up .csvs, save a bit of space on backups
gzip -f 4solr.$TENANT.internal.csv 4solr.$TENANT.media.csv
date
