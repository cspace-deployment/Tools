#!/usr/bin/env bash

# make cURLs to get pages of <list-item> elements and merge them into one XML file
# (a way to get all the records in a cspace procedure / authority / etc)
#
# NB: v5.0 has a max result size of 2500

# invoke as:
# ./extract.sh <cspace-object> <xmloutputfile>
#
# e.g.
#
# ./extract_authority.sh orgauthorities/dcba2506-20fd-438b-9adc typeassertion.xml

# Absolute path this script is in. /home/user/bin
SCRIPTPATH=`dirname $0`

# set these to appropriate cspace login and password
eval `grep CREDS  /var/www/ucjeps/config/authextract.cfg`
eval `grep SERVER /var/www/ucjeps/config/authextract.cfg`
# number of records get get
PAGESIZE=1000
# maximum number of cURLs to issue
MAXCURLS=1000
# ergo, maximum number of records that can be retrieved with these settings is
# MAXCURLS * PAGESIZE = 1,000,000


function extract()
{
   cat <<HERE > /tmp/new1.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<list-wrapper>
</list-wrapper>
HERE

   PAGENUM=0
   while [ $MAXCURLS -gt 0 ]; do

       if ! curl -S -s -u "${CREDS}" -o /tmp/tmp.xml "${SERVER}/cspace-services/$1/items?pgSz=${PAGESIZE}&pgNum=${PAGENUM}&wf_deleted=false"
       then
           echo ERROR: cURL failed.
           echo "curl -S -s -u \"CREDS\" -o /tmp/tmp.xml \"${SERVER}/cspace-services/$1/items?pgSz=${PAGESIZE}&pgNum=${PAGENUM}&wf_deleted=false\""
           cat /tmp/tmp.xml
           echo
           exit 1
        fi

       if ! grep -q "<itemsInPage>" /tmp/tmp.xml
       then
           echo ERROR: unexpected XML returned.
           echo "curl -S -s -u \"CREDS\" -o /tmp/tmp.xml \"${SERVER}/cspace-services/$1/items?pgSz=${PAGESIZE}&pgNum=${PAGENUM}&wf_deleted=false\""
           cat /tmp/tmp.xml
           echo
           exit 1
       fi

       if grep -q "<itemsInPage>0</itemsInPage>" /tmp/tmp.xml
       then
            break
       fi

       python $SCRIPTPATH/xmlcombine.py /tmp/new1.xml /tmp/tmp.xml > /tmp/new2.xml
       mv /tmp/new2.xml /tmp/new1.xml

       MAXCURLS=`expr $MAXCURLS - 1`
       PAGENUM=`expr $PAGENUM + 1`
       printf '%s ' "${PAGENUM}"

    done
    echo
    echo done with $1

   xmllint --format /tmp/new1.xml > $2
   rm /tmp/tmp.xml /tmp/new1.xml
   echo created $2
}


extract $1 $2
