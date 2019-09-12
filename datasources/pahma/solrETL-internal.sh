#!/bin/bash -x
#
##############################################################################
# this script loads the solr core for the "internal" portal.
#
# the input file is created by the script that creates the input file for
# the public core, so all this script has to do is unzip it and POST it to
# to the Solr update endpoint...
#
# Features of the 'internal' metadata, so far:
#
# un-obfuscated latlongs
# all images, "in the clear", including catalog cards
# museum location info
#
##############################################################################
date
cd /home/app_solr/solrdatasources/pahma
##############################################################################
# note that there are 4 nightly scripts, public, internal, and locations,
# and osteology.
# the scripts need to run in order: public > internal > locations | osteology.
# internal (this script) depends on data created by public
# so in this case, the internal script cannot 'stash' any files...they
# have already been stashed by the public script, and this script needs one
# of them.
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintenance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
CORE=internal
##############################################################################
# gunzip the csv file for the internal store, prepared by the solrETL-public.sh
##############################################################################
gunzip -f 4solr.${TENANT}.${CORE}.csv.gz
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
# this POSTs the csv to the Solr / update endpoint
# note, among other things, the overriding of the encapsulator with \
##############################################################################
time curl -X POST -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update/csv?commit=true&header=true&separator=%09&f.taxon_ss.split=true&f.taxon_ss.separator=%7C&f.objculturedepicted_ss.split=true&f.objculturedepicted_sss.separator=%7C&f.objplacedepicted_ss.split=true&f.objplacedepicted_ss.separator=%7C&f.objpersondepicted_ss.split=true&f.objpersondepicted_ss.separator=%7C&f.status_ss.split=true&f.status_ss.separator=%7C&f.audio_md5_ss.split=true&f.audio_md5_ss.separator=%7C&f.blob_md5_ss.split=true&f.blob_md5_ss.separator=%7C&f.card_md5_ss.split=true&f.card_md5_ss.separator=%7C&f.d3_md5_ss.split=true&f.d3_md5_ss.separator=%7C&f.d3_csid_ss.split=true&f.d3_csid_ss.separator=%7C&f.video_md5_ss.split=true&f.video_md5_ss.separator=%7C&f.materials_ss.split=true&f.materials_ss.separator=%7C&f.materialstree_ss.split=true&f.materialstree_ss.separator=%7C&f.culturedepicted_ss.split=true&f.culturedepicted_ss.separator=%7C&f.placedepicted_ss.split=true&f.placedepicted_ss.separator=%7C&f.taxa_ss.split=true&f.taxa_ss.separator=%7C&f.culturedepictedtree_ss.split=true&f.culturedepictedtree_ss.separator=%7C&f.placedepictedtree_ss.split=true&f.placedepictedtree_ss.separator=%7C&f.taxatree_ss.split=true&f.taxatree_ss.separator=%7C&f.persondepicted_ss.split=true&f.persondepicted_ss.separator=%7C&f.video_csid_ss.split=true&f.video_csid_ss.separator=%7C&f.video_mimetype_ss.split=true&f.video_mimetype_ss.separator=%7C&f.audio_csid_ss.split=true&f.audio_csid_ss.separator=%7C&f.media_available_ss.split=true&f.media_available_ss.separator=%7C&f.audio_mimetype_ss.split=true&f.audio_mimetype_ss.separator=%7C&f.mimetypes_ss.split=true&f.mimetypes_ss.separator=%7C&f.restrictions_ss.split=true&f.restrictions_ss.separator=%7C&f.objpp_ss.split=true&f.objpp_ss.separator=%7C&f.anonymousdonor_ss.split=true&f.anonymousdonor_ss.separator=%7C&f.objaltnum_ss.split=true&f.objaltnum_ss.separator=%7C&f.objfilecode_ss.split=true&f.objfilecode_ss.separator=%7C&f.objdimensions_ss.split=true&f.objdimensions_ss.separator=%7C&f.objmaterials_ss.split=true&f.objmaterials_ss.separator=%7C&f.objinscrtext_ss.split=true&f.objinscrtext_ss.separator=%7C&f.objcollector_ss.split=true&f.objcollector_ss.separator=%7C&f.objaccno_ss.split=true&f.objaccno_ss.separator=%7C&f.objaccdate_ss.split=true&f.objaccdate_ss.separator=%7C&f.objacqdate_ss.split=true&f.objacqdate_ss.separator=%7C&f.objassoccult_ss.split=true&f.objassoccult_ss.separator=%7C&f.objculturetree_ss.split=true&f.objculturetree_ss.separator=%7C&f.objfcptree_ss.split=true&f.objfcptree_ss.separator=%7C&f.grouptitle_ss.split=true&f.grouptitle_ss.separator=%7C&f.objmaker_ss.split=true&f.objmaker_ss.separator=%7C&donor_ss.separator=%7C&donor_ss.split=true&exhibitionnumber_ss.separator=%7C&exhibitionnumber_ss.split=true&exhibitiontitle_ss.separator=%7C&exhibitiontitle_ss.split=true&f.objaccdate_begin_dts.split=true&f.objaccdate_begin_dts.separator=%7C&f.objacqdate_begin_dts.split=true&f.objacqdate_begin_dts.separator=%7C&f.objaccdate_end_dts.split=true&f.objaccdate_end_dts.separator=%7C&f.objacqdate_end_dts.split=true&f.objacqdate_end_dts.separator=%7C&f.objaccdate_begin_is.split=true&f.objaccdate_begin_is.separator=%7C&f.objacqdate_begin_is.split=true&f.objacqdate_begin_is.separator=%7C&f.objaccdate_end_is.split=true&f.objaccdate_end_is.separator=%7C&f.objacqdate_end_is.split=true&f.objacqdate_end_is.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=%7C&f.card_ss.split=true&f.card_ss.separator=%7C&f.imagetype_ss.split=true&f.imagetype_ss.separator=%7C&encapsulator=\\" -T 4solr.${TENANT}.${CORE}.csv -H 'Content-type:text/plain; charset=utf-8' &
##############################################################################
# wrap things up: make a gzipped version of what was loaded
##############################################################################
# count blobs
cut -f59 4solr.${TENANT}.${CORE}.csv | grep -v 'blob_ss' |perl -pe 's/\r//' |  grep . | wc -l > counts.${CORE}.blobs.csv
cut -f59 4solr.${TENANT}.${CORE}.csv | perl -pe 's/\r//;s/,/\n/g;s/\|/\n/g;' | grep -v 'blob_ss' | grep . | wc -l >> counts.${CORE}.blobs.csv
wait
cp counts.${CORE}.blobs.csv /tmp/${TENANT}.counts.${CORE}.blobs.csv
cat counts.${CORE}.blobs.csv
gzip -f 4solr.*.csv
date
