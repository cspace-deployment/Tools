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
CREDS="xxxxx@ucjeps.cspace.berkeley.edu:xxxxx"
SERVER="https://ucjeps.cspace.berkeley.edu"
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
       curl -S -s -u "${CREDS}" -o /tmp/tmp.xml "${SERVER}/cspace-services/$1/items?pgSz=${PAGESIZE}&pgNum=${PAGENUM}&wf_deleted=false"


       if grep -q "<itemsInPage>0</itemsInPage>" /tmp/tmp.xml
       then
            break
       fi

       python $SCRIPTPATH/xmlcombine.py /tmp/new1.xml /tmp/tmp.xml > /tmp/new2.xml
       mv /tmp/new2.xml /tmp/new1.xml

       MAXCURLS=`expr $MAXCURLS - 1`
       PAGENUM=`expr $PAGENUM + 1`
       echo "Page ${PAGENUM}"

    done

   xmllint --format /tmp/new1.xml > $2
   rm /tmp/tmp.xml /tmp/new1.xml
}


extract $1 $2
