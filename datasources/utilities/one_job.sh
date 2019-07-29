#!/usr/bin/env bash
##################################################################################
#
# "One Job To Rule Them All"
#
##################################################################################
#
# run all solr ETL
#
# currently runs under app user app_solr on cspace-prod and (optionally) cspace-dev
#
# 1. run the 13 solr4 updates
# 2. monitor solr datastore contents (email contents)
# 3. export and mail BAMPFA and Piction view results museum staff
#
# some notes:
#
# in most cases, the jobs must be order wrt to each other: the 'internal' cores
# often require data generated for the 'public' cores, etc.
#
# in general, the refreshes for a particular tenant must be run sequentially, i.e.
# not in parallel: they may overwrite files or otherwise conflict. there are no
# such conflicts between tenants, except for system resources such as cpu and
# memory.
#
# therefore, this version of one-job.sh runs the refresh for all 5 tenants in
# parallel, and waits for them all to finish.
##################################################################################
echo 'starting solr refresh' `date` >> refresh.log
./oj.bampfa.sh &
./oj.botgarden.sh &
./oj.cinefiles.sh &
./oj.pahma.sh &
./oj.ucjeps.sh &
wait
##################################################################################
# optimize all solrcores after refresh
##################################################################################
/home/app_solr/optimize.sh > /home/app_solr/logs/optimize.log
##################################################################################
# monitor solr datastores
##################################################################################
if [[ `/home/app_solr/checkstatus.sh` ]] ; then /home/app_solr/checkstatus.sh -v | mail -s "PROBLEM with solr refresh nightly refresh" -- jblowe@berkeley.edu ; fi
/home/app_solr/checkstatus.sh -v >> refresh.log
echo 'done with solr refresh' `date` >> refresh.log

