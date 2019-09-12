#!/bin/bash -x
date
cd /home/app_solr/solrdatasources/ucjeps
##############################################################################
# move the current set of extracts to temp (thereby saving the previous run, just in case)
# note that in the case where there are several nightly scripts, e.g. public and internal,
# like here, the one to run first will "clear out" the previous night's data.
# since we don't know which order these might run in, I'm leaving the mv commands in both
# nb: the jobs in general can't overlap as the have some files in common and would step
# on each other
##############################################################################
mv 4solr.*.csv.gz /tmp
##############################################################################
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintainance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
core=public
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5310 sslmode=prefer"
USERNAME="reporter_${TENANT}"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
CONTACT="ucjeps-it@berkeley.edu"
##############################################################################
# extract and massage the metadata from CSpace
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f ucjepsMetadata.sql -o d1.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1.csv | perl -ne 'next if / rows/; print $_' > d3.csv
##############################################################################
# count the types and tokens in the sql output, check cell counts
##############################################################################
time python3 evaluate.py d3.csv metadata.csv > counts.${CORE}.rawdata.csv
##############################################################################
# get media
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f ucjepsMedia.sql -o media.csv
time perl -i -pe 's/[\r\n]/ /g;s/\@\@/\n/g' media.csv 
##############################################################################
# make a unique sequence number for id
##############################################################################
perl -i -pe '$i++;print $i . "\t"' metadata.csv
##############################################################################
# add the blobcsids to mix
##############################################################################
time perl mergeObjectsAndMedia.pl media.csv metadata.csv > d6.csv
##############################################################################
# make sure dates are in ISO-8601 format. Solr accepts nothing else!
##############################################################################
tail -n +2 d6.csv | perl fixdate.pl > d7.csv
##############################################################################
# check latlongs
##############################################################################
perl -ne '@x=split /\t/;print if abs($x[22])<90 && abs($x[23])<180;' d7.csv > d8.csv
perl -ne '@x=split /\t/;print if !(abs($x[22])<90 && abs($x[23])<180);' d7.csv > counts.errors_in_latlong.csv
##############################################################################
# snag UCBG accession number and stuff it in the right field
##############################################################################
perl -i -ne '@x=split /\t/;$x[49]="";($x[48]=~/U.?C.? Botanical Ga?r?de?n.*(\d\d+\.\d+)|(\d+\.\d+).*U.?C.? Botanical Ga?r?de?n/)&&($x[49]="$1$2");print join "\t",@x;' d8.csv
##############################################################################
# parse collector names
##############################################################################
perl -i -ne '@x=split /\t/;$_=$x[8];unless (/Paccard/ || (!/ [^ ]+ [^ ]+ [^ ]+/ && ! /,.*,/ && ! / (and|with|\&) /)) {s/,? (and|with|\&) /|/g;s/, /|/g;s/,? ?\[(in company|with) ?(.*?)\]/|\2/;s/\|Jr/, Jr/g;s/\|?et al\.?//;s/\|\|/|/g;};s/ \& /|/ if /Paccard/;$x[8]=$_;print join "\t",@x;' d8.csv
##############################################################################
# recover & use our "special" solr-friendly header, which got buried
# and name the first column 'id'; add the blob field name to the header.
##############################################################################
head -1 metadata.csv | perl -i -pe 's/\r//;s/^1\t/id\t/;s/$/\tblob_ss/;s/\r//g'> header4Solr.csv
grep -v csid_s d8.csv > d9.csv
cat header4Solr.csv d9.csv | perl -pe 's/␥/|/g' > 4solr.${TENANT}.${CORE}.csv
# clean up some stray quotes. Really this should get fixed properly someday!
perl -i -pe 's/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;s/\"\"/"/g' 4solr.${TENANT}.${CORE}.csv
##############################################################################
# mark duplicate accession numbers
##############################################################################
cut -f3 4solr.${TENANT}.${CORE}.csv | sort | uniq -c | sort -rn |perl -ne 'print unless / 1 / ' > counts.duplicates.csv
cut -c9- counts.duplicates.csv | perl -ne 'chomp; print "s/\\t$_\\t/\\t$_ (duplicate)\\t/;\n"' > fix_dups.sh
perl -i -p fix_dups.sh 4solr.${TENANT}.${CORE}.csv
##############################################################################
# check if we have enough data to be worth refreshing...
##############################################################################
CSVFILE="4solr.${TENANT}.${CORE}.csv"
# this value is an approximate lower bound on the number of rows there should
# be, based on data as of 2019-09-11. It may need to be periodically adjusted.
MINIMUM=750000
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
time curl -X POST -S -s 'http://localhost:8983/solr/ucjeps-${CORE}/update/csv?commit=true&header=true&trim=true&separator=%09&f.comments_ss.split=true&f.comments_ss.separator=%7C&f.collector_ss.split=true&f.collector_ss.separator=%7C&f.previousdeterminations_ss.split=true&f.previousdeterminations_ss.separator=%7C&f.otherlocalities_ss.split=true&f.otherlocalities_ss.separator=%7C&f.associatedtaxa_ss.split=true&f.associatedtaxa_ss.separator=%7C&f.typeassertions_ss.split=true&f.typeassertions_ss.separator=%7C&f.alllocalities_ss.split=true&f.alllocalities_ss.separator=%7C&f.othernumber_ss.split=true&f.othernumber_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&f.card_ss.split=true&f.card_ss.separator=,&encapsulator=\' -T 4solr.${TENANT}.${CORE}.csv -H 'Content-type:text/plain; charset=utf-8' &
##############################################################################
# while that's running, clean up, generate some stats, mail reports
##############################################################################
time python3 evaluate.py 4solr.${TENANT}.${CORE}.csv /dev/null > counts.${CORE}.final.csv
cp counts.${CORE}.final.csv /tmp/${TENANT}.counts.${CORE}.csv
wc -l *.csv
# send the errors off to be dealt with
tar -czf counts.tgz counts.*.csv
./make_error_report.sh | mail -A counts.tgz -s "UCJEPS Solr Refresh Counts and Errors `date`" ${CONTACT}
# get rid of intermediate files
rm d?.csv m?.csv metadata.csv media.csv
# count blobs
cut -f67 4solr.${TENANT}.${CORE}.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.${CORE}.blobs.csv
cut -f67 4solr.${TENANT}.${CORE}.csv | perl -pe 's/\r//;s/,/\n/g;s/\|/\n/g;' | grep -v 'blob_ss' | grep . | wc -l >> counts.${CORE}.blobs.csv
cp counts.${CORE}.blobs.csv /tmp/${TENANT}.counts.${CORE}.blobs.csv
cat counts.${CORE}.blobs.csv
# zip up .csvs, save a bit of space on backups
gzip -f *.csv
wait
# hack to zap latlong errors and load the records anyway.
./zapCoords.sh
date
