#
# a lil script to change the solr pipelines to point to qa instead of prod and to
# send email notifications to jblowe and not the various "real" addresses. 
perl -i -pe 's/prod.42.ist.berkeley.edu port=53/dev-42.ist.berkeley.edu port=51/' solrdatasources/*/*.sh
perl -i -pe 's/=5114/=5113/' solrdatasources/*/*.sh
perl -i -pe 's/=5117/=5107/' solrdatasources/*/*.sh
perl -i -pe 's/=5119/=5110/' solrdatasources/*/*.sh
perl -i -pe 's/cspace.support.lists./jblowe@/' solrdatasources/*/*.sh
perl -i -pe 's/CONTACT=.*/CONTACT="jblowe\@berkeley.edu"/' solrdatasources/*/*.sh
