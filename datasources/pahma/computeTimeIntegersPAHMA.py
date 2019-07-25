import sys, csv
from datetime import datetime
from fix_fields import fix_materials, fix_name, fix_proper_name, fix_culture

delim = '\t'

object_name_column = 10
object_materials_column = 17
name_columns = [27, 29, 43]
culture_columns = [36, 37]
#    27	objcollector_ss
#    29	anonymousdonor_ss
#    43	objmaker_ss


current_year = datetime.today().strftime("%Y")


def get_date_rows(row):
    date_rows = []
    int_year_names = []
    for i, r in enumerate(row):
        if "_dt" in r:
            row.append(r.replace('_dt', '_i'))
            int_year_name = r.replace('_dts', '_i').replace('_dt', '_i')
            int_year_names.append(int_year_name)
            date_rows.append(i)
    return date_rows, int_year_names


def get_year(date_value):
    return date_value[0:4]


def compare_years(years, int_year_names, musno):
    new_years = []
    for year in int_year_names:
        candidate_replacement_year = years[year.replace('begin', 'end')]
        if years[year] < '1695' and candidate_replacement_year != '' and candidate_replacement_year <= current_year:
            print('replaced %s (%s) with %s (%s) for %s' % (
            years[year], year, candidate_replacement_year, year.replace('begin', 'end'), musno))
            years[year] = candidate_replacement_year
        # make sure it's after 1695 no matter what happened above
        if years[year] < '1695':
            years[year] = ''
        new_years.append(years[year])
    return new_years


with open(sys.argv[2], 'w') as f2:
    file_with_integer_times = csv.writer(f2, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
    with open(sys.argv[1], 'r') as f1:
        reader = csv.reader(f1, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
        try:
            for i, row in enumerate(reader):
                if i == 0:
                    date_rows, int_year_names = get_date_rows(row)
                else:
                    row[object_materials_column] = fix_materials(row[object_materials_column])
                    row[object_name_column] = fix_name(row[object_name_column])
                    for n in culture_columns:
                        row[n] = fix_culture(row[n])

                    # "proper name reversal": save this for eventualities
                    # for n in name_columns:
                    #    row[n] = fix_proper_name(row[n])

                    years = {}
                    for j, d in enumerate(date_rows):
                        years[int_year_names[j]] = get_year(row[d])
                    new_years = compare_years(years, int_year_names, row[3])
                    row += new_years
                file_with_integer_times.writerow(row)
        except:
            # really someday we should do something better than just die here...
            raise
            print('couldnt')
            exit()
