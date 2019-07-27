import sys, csv

# these represent the "non-bone" fields, which should be added as is.
# the "bone" fields are aggregated into one multi-valued field, aggregate_ss
skip_columns = ["id",
                "csid_s",
                "objectnumber_s",
                "inventoryid_s",
                "inventoryanalyst_s",
                "inventorydate_dt",
                "inventoryiscomplete_b",
                "osteoageestimateverbatim_s",
                "osteoageestimateupper_f",
                "osteoageestimatelower_f",
                "sexdetermination_s",
                "osteoageestimatenote_s",
                "sexdeterminationnote_s",
                "notes_postcranialpathology_s",
                "notes_cranialpathology_s",
                "notes_dentalpathology_s",
                "notes_nhtaphonomicalterations_s",
                "notes_curatorialsuffixing_s",
                "notes_onelementinventory_s",
                "notes_culturalmodifications_s"]


def process_header(line1):
    outputheader =[]
    for k, cell in enumerate(line1):
        if line1[k] in skip_columns:
            outputheader.append(cell)
    outputheader.append('aggregate_ss')
    return outputheader


with open(sys.argv[2], "w") as out:
    writer = csv.writer(out, delimiter="\t", escapechar='\\')
    with open(sys.argv[1], "r") as original:
        reader = csv.reader(original, delimiter="\t")
        for i, row in enumerate(reader):
            bunch = []
            outputrow = []
            if i == 0:
                writer.writerow(process_header(row))
                header = row
                continue
            try:
                for j, cell in enumerate(row):
                    if header[j] in skip_columns:
                        outputrow.append(cell)
                    else:
                        if cell != '' and cell != '0':
                            bunch.append(header[j][:-2] + '=' + cell)
            except:
                raise
                print('problem!!!')
                print(row)
                sys.exit()
            outputrow.append(','.join(bunch))
            writer.writerow(outputrow)
