import sys, csv

delim = '\t'

def get_date_rows(row):
    date_rows = []
    for i,r in enumerate(row):
        if "_dt" in r:
            row.append(r.replace('_dt', '_i'))
            date_rows.append(i)
    return date_rows


def get_year(date_value):
    return date_value[0:4]


with open(sys.argv[2], 'w') as f2:
    file_with_integer_times = csv.writer(f2, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255), escapechar='\\')
    with open(sys.argv[1], 'r') as f1:
        reader = csv.reader(f1, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
        try:
            for i,row in enumerate(reader):
                if i == 0:
                    date_rows = get_date_rows(row)
                else:
                    for d in date_rows:
                        row.append(get_year(row[d]))
                file_with_integer_times.writerow(row)
        except:
            # really someday we should do something better than just die here...
            raise
            print('couldnt')
            exit()
        
        
