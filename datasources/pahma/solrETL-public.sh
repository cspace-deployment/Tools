#!/bin/bash -x
#
##############################################################################
# shell script to extract multiple tabular data files from CSpace,
# "stitch" them together (see join.py)
# prep them for load into solr using the "csv data import handler"
##############################################################################
date
cd /home/app_solr/solrdatasources/pahma
##############################################################################
# move the current set of extracts to temp (thereby saving the previous run, just in case)
# note that in this case there are 4 nightly scripts, public, internal, and locations,
# and osteology. internal depends on data created by public, so this case has to be handled
# specially, and the scripts need to run in order: public > internal > locations
# the public script, which runs first, *can* 'stash' last night's files...
##############################################################################
mv 4solr.*.csv.gz /tmp
##############################################################################
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintainance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
CORE=public
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5307 sslmode=prefer"
USERNAME="reporter_${TENANT}"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
CONTACT="mtblack@berkeley.edu"
# field collection place ("FCP") is used in various calculations, set a
# variable to indicate which column it is in the extract
# (it has to be exported so the perl one-liner below can get the value from
# the environment; the value is used in 2 places below.)
export FCPCOL=39
##############################################################################
# run the "all media query"
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f mediaAllImages.sql -o i4.csv
# cleanup newlines and crlf in data, then switch record separator.
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' i4.csv > 4solr.${TENANT}.allmedia.csv
rm i4.csv
##############################################################################
# start the stitching process: extract the "basic" data (both restricted and unrestricted)
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f basic_restricted.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > basic_restricted.csv
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f basic_all.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > basic_all.csv
##############################################################################
# stitch this together with the results of the rest of the "subqueries"
##############################################################################
cp basic_restricted.csv restricted.csv
cp basic_all.csv internal.csv
# rather than refactor right now, use two sequences of queries for the public core...1 through 20, and 40 through 60.
for i in $(seq 1 1 20; seq 40 1 60)
do
 if [ -e part$i.sql ]; then
     time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f part$i.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > part$i.csv
     time python3 join.py restricted.csv part$i.csv > temp1.csv &
     time python3 join.py internal.csv part$i.csv > temp2.csv &
     wait
     mv temp1.csv restricted.csv
     mv temp2.csv internal.csv
 fi
done
##############################################################################
# these queries are for the internal datastore
##############################################################################
for i in {21..30}
do
 if [ -e part$i.sql ]; then
    time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f part$i.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > part$i.csv
    time python3 join.py internal.csv part$i.csv > temp.csv
    mv temp.csv internal.csv
 fi
done
##############################################################################
# recover the headers and put them back at the top of the file
##############################################################################
time grep -P "^id\t"  restricted.csv > header4Solr.csv &
time grep -v -P "^id\t" restricted.csv > d8.csv &
wait
cat header4Solr.csv d8.csv | perl -pe 's/␥/|/g' > restricted.csv
#
time grep -P "^id\t"  internal.csv > header4Solr.csv &
time grep -v -P "^id\t" internal.csv > d8.csv &
wait
cat header4Solr.csv d8.csv | perl -pe 's/␥/|/g' > internal.csv
##############################################################################
# internal.csv and restricted.csv contain the basic metadata for the internal
# and public portals respectively. We keep these around for debugging.
# no other accesses to the database are made after this point
#
# the script from here on uses only three files: these two and
# 4solr.${TENANT}.allmedia.csv, so if you wanted to re-run the next chunks of
# the ETL, you can use these files for that purpose.
##############################################################################
# check to see that each row has the right number of columns (solr will barf)
##############################################################################
time perl -pe 's/\r//g;s/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;s/\"\"/"/g' restricted.csv > d6a.csv &
time perl -pe 's/\r//g;s/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;s/\"\"/"/g' internal.csv > d6b.csv &
wait
time python3 evaluate.py d6a.csv temp.${CORE}.csv > counts.${CORE}.rawdata.csv &
time python3 evaluate.py d6b.csv temp.internal.csv > counts.internal.rawdata.csv &
wait
##############################################################################
# check latlongs for ${CORE} datastore
##############################################################################
perl -ne '@y=split /\t/;$x=$y[$ENV{"FCPCOL"}];print if     $x =~ /^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$/ || $x =~ /_p/ || $x eq "" ;' temp.${CORE}.csv >d6a.csv &
perl -ne '@y=split /\t/;$x=$y[$ENV{"FCPCOL"}];print unless $x =~ /^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$/ || $x =~ /_p/ || $x eq "" ;' temp.${CORE}.csv > counts.latlong_errors.csv &
##############################################################################
# check latlongs for internal datastore
##############################################################################
perl -ne '@y=split /\t/;$x=$y[$ENV{"FCPCOL"}];print if     $x =~ /^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$/ || $x =~ /_p/ || $x eq "" ;' temp.internal.csv > d6b.csv &
# nb: we don"t have to save the errors in this datastore, they will be the same as the restricted one.
wait
mv d6a.csv temp.${CORE}.csv
mv d6b.csv temp.internal.csv
##############################################################################
# add the blob and card csids and other flags to the rest of the metadata
# nb: has dependencies on the media file order; less so on the metadata.
##############################################################################
time python3 mergeObjectsAndMediaPAHMA.py 4solr.${TENANT}.allmedia.csv temp.${CORE}.csv public d6a.csv &
time python3 mergeObjectsAndMediaPAHMA.py 4solr.${TENANT}.allmedia.csv temp.internal.csv internal d6b.csv &
wait
mv d6a.csv temp.${CORE}.csv
mv d6b.csv temp.internal.csv
##############################################################################
#  compute a boolean: hascoords = yes/no
##############################################################################
time perl setCoords.pl ${FCPCOL} < temp.${CORE}.csv   > d6a.csv &
time perl setCoords.pl ${FCPCOL} < temp.internal.csv > d6b.csv &
wait
##############################################################################
#  Obfuscate the lat-longs of sensitive sites for public portal
#  nb: this script has dependencies on 4 columns in the input file.
#      if you change them or other order, you'll need to modify this script.
##############################################################################
time python3 obfuscateUSArchaeologySites.py d6a.csv d7.csv
##############################################################################
# clean up some outstanding sins perpetuated by obfuscateUSArchaeologySites.py
##############################################################################
time perl -i -pe 's/\r//g;s/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;s/\"\"/"/g' d7.csv
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
time grep -P "^id\t" d7.csv > header4Solr.csv &
time grep -v -P "^id\t" d7.csv > d8.csv &
wait
cat header4Solr.csv d8.csv | perl -pe 's/␥/|/g' > d9.csv
##############################################################################
# compute _i values for _dt values (to support BL date range searching
##############################################################################
time python3 computeTimeIntegersPAHMA.py d9.csv 4solr.${TENANT}.${CORE}.csv > counts.date_hacks.csv
#
time grep -P "^id\t" d6b.csv > header4Solr.csv &
time grep -v -P "^id\t" d6b.csv > d8.csv &
wait
cat header4Solr.csv d8.csv | perl -pe 's/␥/|/g' > d9.csv
##############################################################################
# compute _i values for _dt values (to support BL date range searching
##############################################################################
time python3 computeTimeIntegersPAHMA.py d9.csv 4solr.${TENANT}.internal.csv
wc -l *.csv
##############################################################################
# check if we have enough data to be worth refreshing...
##############################################################################
CSVFILE="4solr.${TENANT}.${CORE}.csv"
# this value is an approximate lower bound on the number of rows there should
# be, based on data as of 2019-09-11. It may need to be periodically adjusted.
MINIMUM=740000
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
time curl -X POST -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update/csv?commit=true&header=true&separator=%09&f.status_ss.split=true&f.taxon_ss.split=true&f.taxon_ss.separator=%7C&f.objculturedepicted_ss.split=true&f.objculturedepicted_ss.separator=%7C&f.objplacedepicted_ss.split=true&f.objplacedepicted_ss.separator=%7C&f.objpersondepicted_ss.split=true&f.objpersondepicted_ss.separator=%7C&f.status_ss.separator=%7C&f.audio_md5_ss.split=true&f.audio_md5_ss.separator=%7C&f.blob_md5_ss.split=true&f.blob_md5_ss.separator=%7C&f.card_md5_ss.split=true&f.card_md5_ss.separator=%7C&f.d3_md5_ss.split=true&f.d3_md5_ss.separator=%7C&f.d3_csid_ss.split=true&f.d3_csid_ss.separator=%7C&f.video_md5_ss.split=true&f.video_md5_ss.separator=%7C&f.materials_ss.split=true&f.materials_ss.separator=%7C&f.materialstree_ss.split=true&f.materialstree_ss.separator=%7C&f.culturedepicted_ss.split=true&f.culturedepicted_ss.separator=%7C&f.placedepicted_ss.split=true&f.placedepicted_ss.separator=%7C&f.taxa_ss.split=true&f.taxa_ss.separator=%7C&f.culturedepictedtree_ss.split=true&f.culturedepictedtree_ss.separator=%7C&f.placedepictedtree_ss.split=true&f.placedepictedtree_ss.separator=%7C&f.taxatree_ss.split=true&f.taxatree_ss.separator=%7C&f.persondepicted_ss.split=true&f.persondepicted_ss.separator=%7C&f.video_csid_ss.split=true&f.video_csid_ss.separator=%7C&f.video_mimetype_ss.split=true&f.video_mimetype_ss.separator=%7C&f.audio_csid_ss.split=true&f.audio_csid_ss.separator=%7C&f.media_available_ss.split=true&f.media_available_ss.separator=%7C&f.audio_mimetype_ss.split=true&f.audio_mimetype_ss.separator=%7C&f.mimetypes_ss.split=true&f.mimetypes_ss.separator=%7C&f.restrictions_ss.split=true&f.restrictions_ss.separator=%7C&f.objpp_ss.split=true&f.objpp_ss.separator=%7C&f.anonymousdonor_ss.split=true&f.anonymousdonor_ss.separator=%7C&f.objaltnum_ss.split=true&f.objaltnum_ss.separator=%7C&f.objfilecode_ss.split=true&f.objfilecode_ss.separator=%7C&f.objdimensions_ss.split=true&f.objdimensions_ss.separator=%7C&f.objmaterials_ss.split=true&f.objmaterials_ss.separator=%7C&f.objinscrtext_ss.split=true&f.objinscrtext_ss.separator=%7C&f.objcollector_ss.split=true&f.objcollector_ss.separator=%7C&f.objaccno_ss.split=true&f.objaccno_ss.separator=%7C&f.objaccdate_ss.split=true&f.objaccdate_ss.separator=%7C&f.objacqdate_ss.split=true&f.objacqdate_ss.separator=%7C&f.objassoccult_ss.split=true&f.objassoccult_ss.separator=%7C&f.objculturetree_ss.split=true&f.objculturetree_ss.separator=%7C&f.objfcptree_ss.split=true&f.objfcptree_ss.separator=%7C&f.grouptitle_ss.split=true&f.grouptitle_ss.separator=%7C&f.objmaker_ss.split=true&f.objmaker_ss.separator=%7C&f.objaccdate_begin_dts.split=true&f.objaccdate_begin_dts.separator=%7C&f.objacqdate_begin_dts.split=true&f.objacqdate_begin_dts.separator=%7C&f.objaccdate_end_dts.split=true&f.objaccdate_end_dts.separator=%7C&f.objacqdate_end_dts.split=true&f.objacqdate_end_dts.separator=%7C&f.objaccdate_begin_is.split=true&f.objaccdate_begin_is.separator=%7C&f.objacqdate_begin_is.split=true&f.objacqdate_begin_is.separator=%7C&f.objaccdate_end_is.split=true&f.objaccdate_end_is.separator=%7C&f.objacqdate_end_is.split=true&f.objacqdate_end_is.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=%7C&f.card_ss.split=true&f.card_ss.separator=%7C&f.imagetype_ss.split=true&f.imagetype_ss.separator=%7C&encapsulator=\\" -T 4solr.${TENANT}.${CORE}.csv -H 'Content-type:text/plain; charset=utf-8'
##############################################################################
# while that's running, clean up, generate some stats, mail reports
##############################################################################
time python3 evaluate.py 4solr.${TENANT}.${CORE}.csv /dev/null > counts.${CORE}.final.csv &
time python3 evaluate.py 4solr.${TENANT}.internal.csv /dev/null > counts.internal.final.csv &
wait
cp counts.${CORE}.final.csv /tmp/${TENANT}.counts.${CORE}.csv
cp counts.internal.final.csv /tmp/${TENANT}.counts.internal.csv
# send the errors off to be dealt with
tar -czf counts.tgz counts*.csv
./make_error_report.sh | mail -A counts.tgz -s "PAHMA Solr Counts and Refresh Errors `date`" ${CONTACT}
# count blobs
cut -f51 4solr.${TENANT}.${CORE}.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.${CORE}.blobs.csv
cut -f51 4solr.${TENANT}.${CORE}.csv | perl -pe 's/\r//;s/,/\n/g;s/\|/\n/g;' | grep -v 'blob_ss' | grep . | wc -l >> counts.${CORE}.blobs.csv
cp counts.${CORE}.blobs.csv /tmp/${TENANT}.counts.${CORE}.blobs.csv
cat counts.${CORE}.blobs.csv
# get rid of intermediate files
rm d?.csv d6?.csv m?.csv part*.csv temp.*.csv basic*.csv errors*.csv header4Solr.csv
# zip up .csvs, save a bit of space on backups
gzip -f *.csv &
date
