#!/usr/bin/env bash
# mostly untested!
#
# must be executed in the solr home directory
#
# set -e
# set -x

if [ $# -lt 1 ];
then
  echo 1>&2 ""
  echo 1>&2 "Install Solr and configure UCB cores"
  echo 1>&2 ""
  echo 1>&2 "invoke with the location of the Tools directory:"
  echo 1>&2 "$0 fullpathtotoolsdir"
  echo 1>&2 ""
  echo 1>&2 "e.g."
  echo 1>&2 "$0  ~/Tools"
  echo 1>&2 ""
  echo 1>&2 "NB: does NOT install 'custom' cores such as UCBG propagations and PAHMA osteology"
  echo 1>&2 ""
  exit 2
fi

SOLRDIR="solr8/server/solr"
TOOLS="$1/datasources/ucb/multicore"

for t in bampfa botgarden ucjeps pahma cinefiles
do
  for type in public internal media propagations osteology
    do
      if [ -f ${TOOLS}/${t}.${type}.managed-schema ]
      then
        echo "${t}.${type}"
        mkdir -p ${t}/${type}/conf
        touch ${t}/${type}/conf/stopwords.txt
        touch ${t}/${type}/conf/protwords.txt
        touch ${t}/${type}/conf/synonyms.txt
        cp ${TOOLS}/${t}.stopwords.txt ${t}/${type}/conf/stopwords.txt
        cp ${TOOLS}/${t}.synonyms.txt ${t}/${type}/conf/stopwords.txt
        cp ${TOOLS}/${t}.${type}.managed-schema ${t}/${type}/conf/managed-schema
        cp ${TOOLS}/${t}.${type}.solrconfig.xml ${t}/${type}/conf/solrconfig.xml
        echo "name=$t-$type" > ${t}/${type}/core.properties
      else
        echo "${t}.${type}: no schema found"
      fi
    done
done

echo "*** Configured cores for UCB deployments! ****"
echo "You can now start solr. A good way to do this for development purposes is to use"
echo "the script made for the purpose, usually the SOLRHOME directory (${SOLDIR}):"
echo
echo "e.g."
echo "cd ${SOLRDIR}"
echo "bin/solr start"
echo
echo "then review logs/solr.log to for errors"
