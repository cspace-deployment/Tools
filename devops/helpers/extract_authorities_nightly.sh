#!/usr/bin/env bash

~/bin/extract_authorities.sh orgauthorities/225e44ef-7f3d-4660-a4d6 ~/extracts/ucjeps-authorities/nomenclature.xml
~/bin/extract_authorities.sh orgauthorities/751023ec-d953-45f9-a0a8 ~/extracts/ucjeps-authorities/determination.xml
~/bin/extract_authorities.sh orgauthorities/a71f4ab6-221a-4202-bf75 ~/extracts/ucjeps-authorities/institution.xml
~/bin/extract_authorities.sh orgauthorities/dcba2506-20fd-438b-9adc ~/extracts/ucjeps-authorities/typeassertion.xml
# ~/bin/extract_authorities.sh orgauthorities/f53284f1-0462-4326-92e7 ~/extracts/ucjeps-authorities/organizationtest.xml
~/bin/extract_authorities.sh orgauthorities/6d89bda7-867a-4b97-b22f ~/extracts/ucjeps-authorities/organization.xml
~/bin/extract_authorities.sh personauthorities/492326d1-efb1-4d2b-96d9 ~/extracts/ucjeps-authorities/person.xml
# taxonomy is too big, and this data is already being extracted via SQL for the CCH project
# ~/bin/extract_authorities.sh taxonomyauthority/87036424-e55f-4e39-bd12 ~/extracts/ucjeps-authorities/taxonomyauthority.xml
# out with the old, in with the new...
rm -f  ~/extracts/ucjeps-authorities/authorities.tgz
tar -czf  ~/extracts/ucjeps-authorities/authorities.tgz ~/extracts/ucjeps-authorities
