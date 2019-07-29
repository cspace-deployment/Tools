/home/app_solr/solrdatasources/bampfa/solrETL-public.sh           bampfa    >> /home/app_solr/logs/bampfa.solr_extract_public.log  2>&1
/home/app_solr/solrdatasources/bampfa/solrETL-internal.sh         bampfa    >> /home/app_solr/logs/bampfa.solr_extract_internal.log  2>&1
/home/app_solr/solrdatasources/bampfa/bampfa_collectionitems_vw.sh bampfa   >> /home/app_solr/logs/bampfa.solr_extract_BAM.log  2>&1
/home/app_solr/solrdatasources/bampfa/piction_extract.sh          bampfa    >> /home/app_solr/logs/bampfa.solr_extract_Piction.log  2>&1
