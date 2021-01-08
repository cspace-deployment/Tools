#!/bin/bash
LOGS=/var/log/apache2/webapps*/*/*ssl-access.log
echo "Q&D access log analysis"
echo
echo "500s:"
echo
grep " 500 " $LOGS | grep -v -i bot | grep -v imageserver | perl -pe 's/^.*?://;s/\" \".*/"/' |\
 sort -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n | tac | head -50
echo
echo "Dates:"
echo
cut -f3 -d"-" $LOGS | cut -f1 -d ":" | perl -pe 's/ \[//' | sort -t ' ' -k 1.8,1.11n -k 1.4,1.6M -k 1.1,1.2n | uniq -c | tac | perl -pe 's/^ *(\d+) /\1\t/' > webapps.log.counts.csv
head -100 webapps.log.counts.csv
echo
echo "HTTP Codes:"
echo
cat $LOGS | grep -v webapps | perl -pe 's/^.*? (\d\d\d) .*/\1/' | sort | uniq -c | sort -rn | head -100
echo
echo "HTTP Requests:"
echo
grep HTTP $LOGS | cut -f6 -d" " | sort | uniq -c | sort -rn | perl -pe 's/"//g' | head -100
echo