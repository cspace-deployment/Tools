for x in `ls legacy/*.schema.xml`; do echo $x ; grep '<copyField' $x | grep -v '\*' | grep -v '<\!--' >  $x.xxx ; done
mv legacy/*.xxx .
for x in `ls *.xxx`; do echo $x ; mv $x ${x/.schema.xml.xxx/}.fields.txt ; done
perl -i -pe 's/    <copyField source="//;s/" dest=.*//' *.fields.txt

rm bampfa.media.fields.txt 
rm botgarden.media.fields.txt 
rm cinefiles.media.fields.txt 
rm pahma.media.fields.txt 
rm cinefiles.internal.fields.txt 

