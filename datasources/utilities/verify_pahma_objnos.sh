
python tS.py pahma-public http://localhost:8983 'objmusno_txt:"%s"' < $1 > objmusno_txt.txt &
python tS.py pahma-public http://localhost:8983 'objmusno_s:"%s"' < $1 > objmusno_s.txt &
perl -pe 'tr/A-Z/a-z/' $1 | python tS.py pahma-public http://localhost:8983 'objmusno_s:"%s"' > objmusno_s_vs_lower.txt &
perl -pe 'tr/A-Z/a-z/' $1 | python tS.py pahma-public http://localhost:8983 'objmusno_s_lower:"%s"' > objmusno_s_lower.txt &

wait

for x in s_lower s_vs_lower s txt
do
    echo
    echo "objmusno_${x}.txt"
    cut -f2 objmusno_${x}.txt | sort -n | uniq -c | head -20
done
