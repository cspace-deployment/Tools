import csv
import sys
import codecs
import psycopg2
import re

from PIL import Image
import configparser
import subprocess
import io

import requests
import urllib
from requests.auth import HTTPBasicAuth
from xml.etree.ElementTree import tostring, fromstring, Element

import time

from os import listdir, environ
from os.path import isfile, join, getsize

check_fields = 'imageOK isImage sizeOK syntaxOK notUpsideDown notFuzzy notDark average OrientationOK'


def checkFormat(img):
    try:
        if img.format in 'TIFF JPEG'.split(' '):
            return True
        else:
            return False
    except:
        return False


def checkFuzzy(img):
    try:
        # not fuzzy...
        return True
    except:
        return False


def checkDark(imagefile):
    try:
        params = f'convert {imagefile} -colorspace Gray -format "%[fx:quantumrange*image.mean]" info:'.split(' ')
        byteOutput = subprocess.check_output(params)
        average = int(float(byteOutput.decode('UTF-8').rstrip().replace('"','')))
        if average < 44000:
            return False, average
        else:
            return True, average
    except:
        return False, 0


def checkOrientation(image_info):
    try:
        if 'imagesize' in image_info:
            imagesize = image_info['imagesize']
            if imagesize[0] < imagesize[1]:
                return True
        return False
    except:
        return False



def checkCompression(img):
    try:
        cell = img.info['compression']
    except:
        return False
    if cell == 'tiff_lzw':
        return True
    elif cell == 'group4':
        return True
    elif cell == 'packbits':
        return True
    elif cell == "IMAG PAC":
        return True
    else:
        # print("Unknown compression format:", cell)
        return False


def checkImage(image_info, img):
    # 12345.p2.300gray
    # (0).p(1).(2)(3)
    parsedName = re.search(r'(\w+)\.(\w+)', image_info['name'])
    if parsedName is None:
        syntaxOK = False
    else:
        syntaxOK = True

    notDark, average_color = checkDark(image_info['fullpathtofile'])

    try:
        resolution = str(image_info['dpi'][0])
    except:
        resolution = ''
    return {'isImage': checkFormat(img),
            'syntaxOK': syntaxOK,
            'sizeOK': True if image_info['filesize'] > 0 else False,
            'OrientationOK': checkOrientation(image_info),
            # 'isCompressed': checkCompression(img),
            'notFuzzy': checkFuzzy(img),
            'notUpsideDown': True,
            'notDark': notDark,
            'average': average_color
    }


def checkSyntax(parsedName, n, value):
    if parsedName is None:
        return False
    else:
        if parsedName.group(n) in value:
            return True
        else:
            return False


def getConfig(form):
    try:
        fileName = form.get('webapp') + '.cfg'
        config = configparser.RawConfigParser()
        filesread = config.read(fileName)
        if filesread == []:
            print('Problem reading config file.')
            sys.exit()
        return config
    except:
        print('Problem reading config file.')
        sys.exit()


def getBlobsFromDB(config, startdate, enddate, binariesrepo):
    dbconn = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()

    query = """
     SELECT cc.id, cc.updatedat, cc.updatedby, b.name, c.data AS md5

     FROM  blobs_common b
      LEFT OUTER JOIN hierarchy h1
         ON (b.repositoryid = h1.parentid AND h1.primarytype = 'content')
      LEFT OUTER JOIN content c
         ON (h1.id = c.id)
      LEFT OUTER JOIN collectionspace_core cc
        ON (cc.id = b.id)

    WHERE cc.updatedat between '%s'  AND '%s'
    """ % (startdate, enddate)

    try:
        objects.execute('set statement_timeout to 600000')
        objects.execute(query)
        records = []
        for r in objects.fetchall():
            tif = {}
            for i, dbfield in enumerate('csid updatedat updatedby name md5'.split(' ')):
                tif[dbfield] = r[i]

            m = re.search(r'(..)(..)', tif['md5'])
            tif['fullpathtofile'] = binariesrepo % (
                # nb: we are assuming here that this app is running with the CSpace variable set...
                m.group(1), m.group(2), tif['md5'])

            records.append(tif)
        return records

    except psycopg2.DatabaseError as e:
        sys.stderr.write('getBlobsFromDB error: %s\n' % e)
        sys.exit()
    except:
        sys.stderr.write("some other getBlobsFromDB error!\n")
        sys.exit()


def get_imagetags(im, ret):
    # im = Image.open(fn)
    ret['format'] = im.format
    # The file format of the source file. For images created by the library itself
    # (via a factory function, or by running a method on an existing image), this attribute is set to None.  
    ret['mode'] = im.mode
    # Image mode. This is a string specifying the pixel format used by the image.
    # Typical values are "1", "L", "RGB", or "CMYK." See Concepts for a full list.
    ret['imagesize'] = im.size
    # Image size, in pixels. The size is given as a 2-tuple (width, height).

    info = im.info
    for tag, value in info.items():
        if tag == 'exif': continue
        ret[tag] = value

    checks = checkImage(ret, im)
    for k in checks.keys():
        ret[k] = checks[k]
        # print(ret)
    ret['imageOK'] = True
    for flag in check_fields.split(' '):
        if ret[flag] == False:
            ret['imageOK'] = False


def writeCsv(filename, items, writeheader):
    filehandle = codecs.open(filename, 'w', 'utf-8')
    writer = csv.writer(filehandle, delimiter='\t')
    writer.writerow(writeheader)
    for item in items:
        row = []
        for x in writeheader:
            if x in item.keys():
                cell = str(item[x])
                cell = cell.strip()
                cell = cell.replace('"', '')
                cell = cell.replace('\n', '')
                cell = cell.replace('\r', '')
            else:
                cell = ''
            row.append(cell)
        writer.writerow(row)
    filehandle.close()


def getRecords(rawFile):
    try:
        records = []
        csvfile = csv.reader(open(rawFile, 'r'), delimiter="|")
        for row, values in enumerate(csvfile):
            records.append(values)
        return records, len(values)
    except:
        raise


def getBloblist(blobpath):
    filelist = [f for f in listdir(blobpath) if isfile(join(blobpath, f))]
    records = []
    for f in sorted(filelist):
        tif = {}
        tif['name'] = f
        tif['fullpathtofile'] = join(blobpath, f)
        records.append(tif)
    count = len(records)
    return records, count

def getListOfFiles(blobpath, inputFile):

    with open(inputFile, 'r') as csvfile:
        inputfh = csv.reader(csvfile,  delimiter="|")
        filelist = [cells[0] for cells in inputfh]

    filelist = filelist[1:]
    records = []
    for f in sorted(filelist):
        image_data = {}
        image_data['name'] = f
        image_data['fullpathtofile'] = join(blobpath, f)
        records.append(image_data)
    count = len(records)
    return records, count


def doChecks(args):
    if len(args) < 1:
        sys.exit('Usage: %s [db|dir|rest|file] ...' % args[0])

    if args[1] == 'db' or args[1] == 'rest':
        if len(args) < 6:
            sys.exit('Usage: %s %s config-file startdate enddate reportname' % (args[0], args[1]))

        startdate = args[3]
        enddate = args[4]
        outputFile = args[5]

        try:
            # form = {'webapp': '/var/www/cgi-bin/' + args[2]}
            form = {'webapp': args[2]}
            config = getConfig(form)
            hostname = config.get('connect', 'hostname')
            username = config.get('connect', 'username')
            password = config.get('connect', 'password')
        except:
            print("could not get configuration from %s.cfg. Does it exist?" % args[2])
            sys.exit()

        if args[1] == 'db':
            try:
                connect_str = config.get('connect', 'connect_string')
            except:
                print("%s.cfg does not contain a parameter called 'connect_string'" % args[2])
                sys.exit()
            try:
                binariesrepo = config.get('connect', 'binariesrepo')
            except:
                print("%s.cfg does not contain a parameter called 'binariesrepo'" % args[2])
                sys.exit()


            records = getBlobsFromDB(config, startdate, enddate, binariesrepo)


        if args[1] == 'rest':

            try:
                start_date_timestamp = startdate.strip() + "T00:00:00"
                end_date_timestamp = enddate.strip() + "T23:59:59"
                search_terms = 'collectionspace_core:updatedAt >= TIMESTAMP "%s" AND collectionspace_core:updatedAt <= TIMESTAMP "%s"'
                search_terms = search_terms % (start_date_timestamp, end_date_timestamp)
                search_terms = urllib.parse.quote_plus(search_terms)
                url = 'https://%s/cspace-services/blobs?as=%s&%s' % (hostname, search_terms, 'pgSz=%s&wf_deleted=false&pgNum=%s' % (7000,1))
                response = requests.get(url, auth=HTTPBasicAuth(username, password))
                xml = response.content
                if response.status_code != 200:
                    print("HTTP %s" % response.status_code)
            except:
                raise
                messages.append("cspace REST API get items failed...")


            try:
                cspaceXML = fromstring(xml)
                totalItems = int(cspaceXML.find('.//totalItems').text)
                items = cspaceXML.findall('.//list-item')
                records = []
                for i in items:
                    outputrow = {}
                    for tag in 'csid name updatedAt'.split(' '):
                        element = i.find('.//%s' % tag)
                        element = '' if element is None else element.text
                        outputrow[tag] = element
                    records.append(outputrow)
            except:
                error_message = 'XML list extract failed.'


    elif args[1] == 'dir':

        if len(args) < 4:
            sys.exit('Usage: %s dir directory reportname' % args[0])

        blobpath = args[2]
        records, count = getBloblist(blobpath)
        print('MEDIA: %s files found in directory %s' % (count, args[2]))
        outputFile = args[3]

    elif args[1] == 'file':

        if len(args) < 5:
            sys.exit('Usage: %s file directory inputfile reportname' % args[0])

        blobpath = args[2]
        inputFile = args[3]
        outputFile = args[4]
        records, count = getListOfFiles(blobpath, inputFile)
        print('MEDIA: %s files found in file %s' % (count, args[3]))

    else:
        print('datasource must be "db", "rest", "file" or "dir"')
        sys.exit()

    columns = ('name ' + check_fields + ' imagesize filesize updatedAt updatedby format mode compression dpi csid fullpathtofile').split(' ')
    outputfh = csv.writer(open(outputFile, 'w'), delimiter="\t")
    outputfh.writerow(columns)

    for i, image_info in enumerate(records):

        elapsedtimetotal = time.time()
        row = []
        if args[1] == 'rest':
            # https://ucjeps.cspace.berkeley.edu/cspace-services/blobs/9ca4cb04-6d66-45e7-a2c9/derivatives/Medium/content
            url = 'https://%s/cspace-services/blobs/%s/derivatives/Medium/content' % (hostname, image_info['csid'])
            response = requests.get(url, auth=HTTPBasicAuth(username, password))
            image = io.BytesIO(response.content)
            image_info['filesize'] = len(response.content)
            image = Image.open(image)
            filename = image_info['name']
            tempfile = '/tmp/imagefile'
            fh = open(tempfile, 'wb')
            fh.write(response.content)
            fh.close()
            image_info['fullpathtofile'] = tempfile

        else:
            try:
                # print("checking file", i, tif['fullpathtofile'])
                image_info['filesize'] = getsize(image_info['fullpathtofile'])
                image = Image.open(image_info['fullpathtofile'])
            except:
                print("failed to open image file", i, image_info['fullpathtofile'])

        try:
            get_imagetags(image, image_info)
        except:
            print("failed on blob", i)
            for key in check_fields.split(' '):
                image_info[key] = False
            raise

        for v1, v2 in enumerate(columns):
            try:
                row.append(image_info[v2])
            except:
                row.append('')

        try:
            outputfh.writerow(row)
        except:
            print("failed to write data for file %s, %8.2f" % (image_info['name'], (time.time() - elapsedtimetotal)))


def do_query(index, search_term, record_type, pgSz, credentials):
    querystring = {index: search_term, 'wf_deleted': 'false', 'pgSz': pgSz}
    querystring = urllib.parse.urlencode(querystring)
    url = '%s/cspace-services/%s?%s' % (credentials.server, record_type, querystring)
    response = requests.get(url, auth=HTTPBasicAuth(credentials.username, credentials.password))
    # response.raise_for_status()

    response.encoding = 'utf-8'
    return response


if __name__ == "__main__":
    #
    doChecks(sys.argv)
