rsync -v -e "ssh -i ~/.ssh/id_rsa" ~/extracts/cch/*.gz cspace@cynips.bnhm.berkeley.edu:/usr/local/web/ucjeps_web/cspace/
rsync -v -e "ssh -i ~/.ssh/id_rsa" ~/extracts/major_group/*.gz cspace@cynips.bnhm.berkeley.edu:/usr/local/web/ucjeps_web/cspace/
rsync -v -e "ssh -i ~/.ssh/id_rsa" ~/extracts/taxonauth/*.gz cspace@cynips.bnhm.berkeley.edu:/usr/local/web/ucjeps_web/cspace/
rsync -v -e "ssh -i ~/.ssh/id_rsa" ~/extracts/ucjeps-authorities/authorities.tgz cspace@cynips.bnhm.berkeley.edu:/usr/local/web/ucjeps_web/cspace/
rsync -v -e "ssh -i ~/.ssh/id_rsa" /tmp/4solr.ucjeps.public.csv.gz cspace@cynips.bnhm.berkeley.edu:/usr/local/web/ucjeps_web/cspace/
rsync -v -e "ssh -i ~/.ssh/id_rsa" /tmp/4solr.ucjeps.media.csv.gz cspace@cynips.bnhm.berkeley.edu:/usr/local/web/ucjeps_web/cspace/
