#!/usr/bin/env bash
# mostly untested!
#set -e
set -x
if [ $# -lt 1 ];
then
  echo 1>&2 "Make solr8 managed-schema from solr4 schema.xml, based on given managed-schema-template"
  echo 1>&2 ""
  echo 1>&2 "call with one argument, the path to the Tool repo:"
  echo 1>&2 "$0 fullpathtotoolsdir"
  echo 1>&2 ""
  echo 1>&2 "e.g."
  echo 1>&2 "$0  ~/Tools"
  echo 1>&2 ""
  echo 1>&2 "(makes new files in the repo...)"
  echo 1>&2 ""
fi

TOOLS=$1
if [ ! -d $TOOLS ];
then
   echo "Tools directory $TOOLS not found. Please clone from GitHub and provide it as the first argument."
   exit 1
fi
cd ${TOOLS}
for t in bampfa botgarden ucjeps pahma cinefiles
do
  for type in public internal media
    do
      echo "${t}.${type}"
      cp datasources/ucb/multicore/solrconfig.v8.xml datasources/ucb/multicore/${t}.${type}.solrconfig.xml
      cp datasources/ucb/multicore/managed-schema-template temp.xml
      grep '<copyField' datasources/ucb/multicore/${t}.${type}.schema.xml | grep -v '<\!--' | grep -v 'dest="text"/>' > temp.txt
      wc -l temp.txt
      perl -i -pe 's/^ //' temp.txt
      perl -pe 's/COPYFIELDS/`cat temp.txt`/ge' -i temp.xml
      perl -i -pe "s/\"TENANT\"/\"${t}-${type}\"/" temp.xml
      xmllint --format temp.xml > datasources/ucb/multicore/${t}.${type}.managed-schema
    done
done
rm temp.txt temp.xml
