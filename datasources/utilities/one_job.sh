##################################################################################
#
# "One Job To Rule Them All"
#
##################################################################################
#
# run all solr ETL (and other webapp and API monitoring)
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
##################################################################################
echo 'starting solr refreshes' `date`
/home/app_solr/solrdatasources/bampfa/solrETL-public.sh           bampfa    >> /home/app_solr/logs/bampfa.solr_extract_public.log  2>&1
/home/app_solr/solrdatasources/bampfa/solrETL-internal.sh         bampfa    >> /home/app_solr/logs/bampfa.solr_extract_internal.log  2>&1
/home/app_solr/solrdatasources/bampfa/bampfa_collectionitems_vw.sh bampfa   >> /home/app_solr/logs/bampfa.solr_extract_BAM.log  2>&1
/home/app_solr/solrdatasources/bampfa/piction_extract.sh          bampfa    >> /home/app_solr/logs/bampfa.solr_extract_Piction.log  2>&1

/home/app_solr/solrdatasources/botgarden/solrETL-public.sh        botgarden >> /home/app_solr/logs/botgarden.solr_extract_public.log  2>&1
/home/app_solr/solrdatasources/botgarden/solrETL-internal.sh      botgarden >> /home/app_solr/logs/botgarden.solr_extract_internal.log  2>&1
/home/app_solr/solrdatasources/botgarden/solrETL-propagations.sh  botgarden >> /home/app_solr/logs/botgarden.solr_extract_propagations.log  2>&1

/home/app_solr/solrdatasources/cinefiles/solrETL-public.sh        cinefiles >> /home/app_solr/logs/cinefiles.solr_extract_public.log  2>&1

/home/app_solr/solrdatasources/pahma/solrETL-public.sh            pahma     >> /home/app_solr/logs/pahma.solr_extract_public.log  2>&1
/home/app_solr/solrdatasources/pahma/solrETL-internal.sh          pahma     >> /home/app_solr/logs/pahma.solr_extract_internal.log  2>&1
/home/app_solr/solrdatasources/pahma/solrETL-locations.sh         pahma     >> /home/app_solr/logs/pahma.solr_extract_locations.log  2>&1
/home/app_solr/solrdatasources/pahma/solrETL-osteology.sh         pahma     >> /home/app_solr/logs/pahma.solr_extract_osteology.log  2>&1

/home/app_solr/solrdatasources/ucjeps/solrETL-media.sh            ucjeps    >> /home/app_solr/logs/ucjeps.solr_extract_media.log  2>&1
/home/app_solr/solrdatasources/ucjeps/solrETL-public.sh           ucjeps    >> /home/app_solr/logs/ucjeps.solr_extract_public.log  2>&1
##################################################################################
# optimize all solrcores after refresh
##################################################################################
/home/app_solr/optimize.sh > /home/app_solr/logs/optimize.log
##################################################################################
# monitor solr datastores
##################################################################################
if [[ `/home/app_solr/checkstatus.sh` ]] ; then /home/app_solr/checkstatus.sh -v | mail -s "PROBLEM with solr refresh nightly refresh" -- cspace-support@lists.berkeley.edu ; fi
/home/app_solr/checkstatus.sh -v
echo 'done with solr refreshes' `date`
