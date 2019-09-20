echo "Q&D access log analysis"
echo
echo "Dates:"
echo
cut -f3 -d"-" /var/log/httpd/*.cspace.berkeley.edu_443-access_log | cut -f1 -d ":" | perl -pe 's/ \[//' | sort | uniq -c
echo
echo "HTTP Codes:"
echo
cat /var/log/httpd/*.cspace.berkeley.edu_443-access_log | grep -v webapps | perl -pe 's/^.*? (\d\d\d) .*/\1/' | sort | uniq -c | sort -rn
echo
echo "HTTP Requests:"
echo
grep HTTP /var/log/httpd/*.cspace.berkeley.edu_443-access_log | cut -f6 -d" " | sort | uniq -c | sort -rn | perl -pe 's/"//g'
echo
echo "500s:"
echo
grep " 500 " /var/log/httpd/*.cspace.berkeley.edu_443-access_log | grep -v 'mask' | head -40
echo
