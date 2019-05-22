set -x 

# run the experimental 'museum-number-to-ark-and-back' script
python3 checknos.py < objnums.csv > possible_arks.csv

# count the results
wc -l possible_arks.csv

# show what the output file looks like
cut -f1-3 possible_arks.csv | expand -15 | head -30

# how many could not be reversed
grep "not reversible" possible_arks.csv | wc -l

# show a few
grep "not reversible" possible_arks.csv | head -10

# check out what got encoded, etc.
perl -ne 'print if /\tx/' possible_arks.csv | expand -30 | head -5
cut -f2 possible_arks.csv | grep -v '%' | expand -30 | head -5
cut -f2 possible_arks.csv | grep '%' | expand -30 | head -5

grep "not reversible" possible_arks.csv | wc -l
perl -ne 'print if /\tx/' possible_arks.csv | wc -l
cut -f2 possible_arks.csv | grep -v '%' | wc -l
cut -f2 possible_arks.csv | grep '%' | wc -l
cut -f2 possible_arks.csv | grep -v '%' | perl -ne 'print if /^[0-9]+$/' | wc -l
cut -f2 possible_arks.csv | grep -v '%' | perl -ne 'print if length($_) != 11' | grep dupe | wc -l
cut -f2 possible_arks.csv | grep -v '%' | perl -ne 'print length($_) . "\n"' | sort | uniq -c
