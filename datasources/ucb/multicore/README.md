#### How to setup and maintain CSpace@UCB Solr cores

This setup structure support multiple cores for the UCB deployments.

The current scheme (October 2019) uses Solr8 and the 'managed-schema' approach.

The files in this directory are used to build the needed POSTs to the Solr schema API
to create the required fields.

Each *.fields.txt file contains the dynamic fields loaded into the Solr; from this list
a set of <copyField> statements is created to generate a corresponding keyword (*_txt) field.
(The _txt version is needed to support keyword searching in the Portals.)

13 cores are currently being maintained for the 5 CSpace@UCB deployments.

To create and maintain these cores, the following scripts and directories are useful:

* legacy - directory containing 'legacy' manually-maintained schema and helpers
* legacy/convert2managedschema.sh -- only needed to convert 'legacy' manually-maintained schema to a list of fields
* *.fields.txt -- list of fields being extracted in the Solr pipelines.
* makecores.sh -- script to create and populate the cores based on *.fields.txt

Some examples of running the scripts, etc. to make this go:

```
# starting and stopping the Solr server (assuming it is installed in ~/solr8)
cd ~/solr8/
bin/solr stop
bin/solr start

# delete a core
~/solr8/bin/solr delete -c cinefiles-xpublic

# delete and recreate all 12 ucb corse
cd ~/PycharmProjects/Tools/datasources/ucb/multicore/
nohup time ./makesolrcores.sh > cores.log 2> /dev/null &
```