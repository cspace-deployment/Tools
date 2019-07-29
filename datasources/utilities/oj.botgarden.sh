/home/app_solr/solrdatasources/botgarden/solrETL-public.sh        botgarden >> /home/app_solr/logs/botgarden.solr_extract_public.log  2>&1
/home/app_solr/solrdatasources/botgarden/solrETL-internal.sh      botgarden >> /home/app_solr/logs/botgarden.solr_extract_internal.log  2>&1
/home/app_solr/solrdatasources/botgarden/solrETL-propagations.sh  botgarden >> /home/app_solr/logs/botgarden.solr_extract_propagations.log  2>&1
