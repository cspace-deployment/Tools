#!/bin/bash -x
#
##############################################################################
# shell script to extract osteology data from database and prep them for load
# into Solr4 using the "csv datahandler"
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
##############################################################################
# extract media info from CSpace
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f osteology.sql -o o1.csv
# cleanup newlines and crlf in data, then switch record separator.
time perl -i -pe 's/[\r\n]/ /g;s/\@\@/\n/g' o1.csv
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
gunzip 4solr.${TENANT}.internal.csv.gz
# compress the osteology data into a single variable
python3 osteology_analyzer.py o1.csv o2.csv
sort o2.csv > o3.csv
# add the internal data
python3 join.py o3.csv 4solr.${TENANT}.internal.csv > o4.csv
# csid_s is both files, let's keep only one in this file
cut -f1,3- o4.csv > o5.csv
grep -P "^id\t" o5.csv > header4Solr.csv
grep -v -P "^id\t" o5.csv > o6.csv
cat header4Solr.csv o6.csv > o7.csv
# hack to fix inventorydate_dt
perl -i -pe 's/([\d\-]+) ([\d:]+)/\1T\2Z/' o7.csv
##############################################################################
# count the types and tokens in the final file
##############################################################################
time python3 evaluate.py o7.csv 4solr.${TENANT}.osteology.csv > counts.osteology.csv
# ok, now let's load this into solr...
# clear out the existing data
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-osteology/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-osteology/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
##############################################################################
# this POSTs the csv to the Solr / update endpoint
# note, among other things, the overriding of the encapsulator with \
##############################################################################
time curl -X POST -S -s "http://localhost:8983/solr/${TENANT}-osteology/update/csv?commit=true&header=true&separator=%09&f.taxon_ss.split=true&f.taxon_ss.separator=%7C&f.objculturedepicted_ss.split=true&f.objculturedepicted_sss.separator=%7C&f.objplacedepicted_ss.split=true&f.objplacedepicted_ss.separator=%7C&f.objpersondepicted_ss.split=true&f.objpersondepicted_ss.separator=%7C&f.status_ss.split=true&f.status_ss.separator=%7C&f.audio_md5_ss.split=true&f.audio_md5_ss.separator=%7C&f.blob_md5_ss.split=true&f.blob_md5_ss.separator=%7C&f.card_md5_ss.split=true&f.card_md5_ss.separator=%7C&f.x3d_md5_ss.split=true&f.x3d_md5_ss.separator=%7C&f.x3d_csid_ss.split=true&f.x3d_csid_ss.separator=%7C&f.video_md5_ss.split=true&f.video_md5_ss.separator=%7C&f.aggregate_ss.split=true&f.aggregate_ss.separator=%2C&f.objpp_ss.split=true&f.objpp_ss.separator=%7C&f.anonymousdonor_ss.split=true&f.anonymousdonor_ss.separator=%7C&f.objaltnum_ss.split=true&f.objaltnum_ss.separator=%7C&f.objfilecode_ss.split=true&f.objfilecode_ss.separator=%7C&f.objdimensions_ss.split=true&f.objdimensions_ss.separator=%7C&f.objmaterials_ss.split=true&f.objmaterials_ss.separator=%7C&f.objinscrtext_ss.split=true&f.objinscrtext_ss.separator=%7C&f.objcollector_ss.split=true&f.objcollector_ss.separator=%7C&f.objaccno_ss.split=true&f.objaccno_ss.separator=%7C&f.objaccdate_ss.split=true&f.objaccdate_ss.separator=%7C&f.objacqdate_ss.split=true&f.objacqdate_ss.separator=%7C&f.objassoccult_ss.split=true&f.objassoccult_ss.separator=%7C&f.objculturetree_ss.split=true&f.objculturetree_ss.separator=%7C&f.objfcptree_ss.split=true&f.objfcptree_ss.separator=%7C&f.grouptitle_ss.split=true&f.grouptitle_ss.separator=%7C&f.objmaker_ss.split=true&f.objmaker_ss.separator=%7C&f.objaccdate_begin_dts.split=true&f.objaccdate_begin_dts.separator=%7C&f.objacqdate_begin_dts.split=true&f.objacqdate_begin_dts.separator=%7C&f.objaccdate_end_dts.split=true&f.objaccdate_end_dts.separator=%7C&f.objacqdate_end_dts.split=true&f.objacqdate_end_dts.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=%7C&f.card_ss.split=true&f.card_ss.separator=%7C&f.imagetype_ss.split=true&f.imagetype_ss.separator=%7C&encapsulator=\\" -T 4solr.${TENANT}.osteology.csv -H 'Content-type:text/plain; charset=utf-8' &
rm o?.csv header4Solr.csv
# count blobs
cut -f78 4solr.${TENANT}.osteology.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.osteology.blobs.csv
cut -f78 4solr.${TENANT}.osteology.csv | perl -pe 's/\r//;s/,/\n/g;s/\|/\n/g;' | grep -v 'blob_ss' | grep . | wc -l >> counts.osteology.blobs.csv &
wait
cp counts.osteology.blobs.csv /tmp/$TENANT.counts.osteology.blobs.csv
cat counts.osteology.blobs.csv
cp counts.osteology.csv /tmp/$TENANT.counts.osteology.csv
gzip -f 4solr.${TENANT}.osteology.csv &
gzip -f 4solr.${TENANT}.internal.csv &
wait
date
