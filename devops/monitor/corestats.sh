#
# snag the nightly field counts files
cp /tmp/*.counts.*.csv /var/www/static/
#
echo "<h2>Contents of Solr Cores</h2>" > corestats.html
echo "<h4>`date`</h4>" >> corestats.html
echo "<h2>Objects in Public Solr Cores</h2>" >> corestats.html
echo '
    <link rel="stylesheet" type="text/css" href="css/reset.css">
    <link rel="stylesheet" type="text/css" href="css/base.css">
    <table><tr><th>Institution</th><th>Number of Objects</th><th>Per-field Counts</th></tr>' >> corestats.html
for t in bampfa botgarden cinefiles pahma ucjeps
do
    echo "processing ${t} ..."
    echo "<a href=\"corestats.html\">Back</a>" > /var/www/static/${t}.counts.public.html
    echo "<h2>${t}: Type and Token Counts for Public Solr Core</h2>" >> /var/www/static/${t}.counts.public.html
    echo "<table class=\"\">" >> /var/www/static/${t}.counts.public.html
    perl -pe "s/\t/<td>/g; print '<tr><td>'" /var/www/static/${t}.counts.public.csv >> /var/www/static/${t}.counts.public.html
    echo "</table>" >> /var/www/static/${t}.counts.public.html
    #count=`curl -S -s "http://localhost:8983/solr/${t}-public/select?q=*%3A*&wt=json&defType=edismax&rows=0" | perl -pe 's/.*numFound..(\d+).*/\1/'`
    count=`curl -S -s "http://localhost:8983/solr/${t}-public/select?q=*%3A*&wt=json&rows=0" | perl -pe 's/.*numFound..(\d+).*/\1/'`
    echo "<tr><td>${t}</td><td>${count}</td><td><a href=\"${t}.counts.public.html\">types and tokens</a></td></tr>" >> corestats.html
    echo "<p/>" >> corestats.html
done
echo "</table>" >> corestats.html
# compute image stats
echo "<h2>Images in Solr Cores</h2>" >> corestats.html
echo "<table><tr><th>Institution<th>Core<th>Objects w Images<th>Images" >> corestats.html
for t in /tmp/*.blobs.csv; do echo $t; cat $t ; done | perl -pe 's#/tmp/#<tr><td>#;s/.counts./<td>/;s/.blobs.csv//;s/^(\d+)/<td>\1/' >> corestats.html
echo "</table>" >> corestats.html
#
cp corestats.html /var/www/static
