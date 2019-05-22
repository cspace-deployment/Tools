TENANT=$1
grep blobs ${TENANT}.django.log | grep -v "image error" | cut -f9 | perl -pe 's/content.*/content/;s#derivatives/.*/content#derivatives/Thumbnail/content#' | sort | uniq -c | sort -rn | head -200 | tail -100 | perl -pe 's/^ *(\d+) /\1\t/' | grep -v image1blobcsid > ${TENANT}.blobs.txt
TOTAL=`grep blobs ${TENANT}.django.log | grep -v "image error" | wc -l`
cat << EOM > ${TENANT}.blobs.html
<html>
<style>
div {
  float: left;
  padding: 3px;
  width: 80px;
  height: 120px;
}
</style>
<h3>"Top Blobs" (most frequently retrieved images) for $TENANT</h3>
<h5>total number of images served: $TOTAL</h5>
EOM
cat ${TENANT}.blobs.txt | perl -ne 'chomp; ($n,$i)=split/\t/;print "<div><a href=\"https://webapps.cspace.berkeley.edu/TTT/imageserver/$i\"><img style=\"max-width: 80px;\" src=\"https://webapps.cspace.berkeley.edu/TTT/imageserver/$i\"></a><br/>$n</div>\n"' | perl -pe "s/TTT/"$TENANT"/g" >> ${TENANT}.blobs.html
mv ${TENANT}.blobs.html /var/www/static
