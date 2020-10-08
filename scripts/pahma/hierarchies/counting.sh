./runpsql.sh $1 $2 tables.sql reporter > counts/table.$1.counts &
./runpsql.sh $1 $2 groups.sql reporter > counts/group.$1.counts &
wait
grep "|" counts/table.$1.counts | grep -v "count" > counts/table.$1.txt
grep "|" counts/group.$1.counts | grep -v "count" > counts/group.$1.txt
