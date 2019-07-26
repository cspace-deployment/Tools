import re
import hashlib
import math
import sys, csv

hashkey_column = 38
fieldCollectionTree_column = 41
objecttype_column = 5
latlong_column = 39
delim = '\t'

def pol2cart(rho, phi):
    x = rho * math.cos(phi)
    y = rho * math.sin(phi)
    return (x, y)

with open(sys.argv[2], 'w') as out:
    writer = csv.writer(out, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
    with open(sys.argv[1], 'r') as original:
        reader = csv.reader(original, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
        for row in reader:
            try:
                # *all* archeology sites worldwide are obscured
                if row[objecttype_column] == "archaeology" and row[latlong_column] != '':
                    # obfuscate lat-long

                    # first, get the actual values...
                    latitude = row[latlong_column].split(",")[0].strip()
                    longitude = row[latlong_column].split(",")[1].strip()

                    # read PAHMA-1408 for details of why this is the way it is
                    # 'hashkey_column' is the constant we will be hashing with
                    # (we want to hash to the same value each run, lest someone try to 'zero in' using multiple
                    # observations of the portal data...)
                    location = re.sub(r'[^\x00-\x7F]+',' ', row[hashkey_column])
                    modulus = 0.2

                    # get md5 hash of secret value, convert to int, normalize this to range of -.05 to .05 degrees
                    lat_offset = int(hashlib.md5(location.encode('utf-8').hexdigest(), 16)
                    lat_offset = (lat_offset + 0.0) / int("9" * len(str(lat_offset)))  # Clamp value to 0 to 1
                    lat_offset = (lat_offset % modulus) / modulus

                    long_offset = int(hashlib.md5(location[::-1].encode('utf-8').hexdigest(), 16)
                    long_offset = (long_offset + 0.0) / int("9" * len(str(long_offset)))  # Clamp value to 0 to 1
                    long_offset = (long_offset % modulus) / modulus

                    # pretend these a polar coordinates and convert them to cartesian coordinates
                    latlongoffset = pol2cart(math.sqrt(lat_offset), long_offset * 2 * math.pi)
                    latlongoffset = [r * 0.05 for r in latlongoffset]

                    latitude = float(latitude) + latlongoffset[0]
                    longitude = float(longitude) + latlongoffset[1]
                    row[latlong_column] = "%s,%s" % (latitude, longitude)
            except:
                print('problem!!!')
                print(row)
                raise
                sys.exit()

            writer.writerow(row)
