#
# extract the current set of cURL commands that will refresh
# the Solr cores from the extracted .csv files.
#
# (3 curls for each core: delete, commit, POST fresh data) 
#
cd
rm -f ~/allcurls.sh
for t in bampfa botgarden cinefiles pahma ucjeps
do
    for d in public internal propagations locations media osteology
    do
       if [[ -e logs/${t}.solr_extract_${d}.log ]]
       then
          echo "# ${t}-${d}" >> ~/allcurls.sh
          grep curl logs/${t}.solr_extract_${d}.log | cut -c3- | tail -3 >> ~/allcurls.sh
       fi
    done
done
chmod +x ~/allcurls.sh
