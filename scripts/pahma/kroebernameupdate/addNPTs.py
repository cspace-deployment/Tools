import requests
import yaml
import xml.etree.ElementTree as ET
import os, sys, csv, codecs, logging

logging.basicConfig(
    format='%(asctime)s %(levelname)-8s %(message)s',
    level=logging.INFO,
    datefmt='%Y-%m-%d %H:%M:%S')

if len(sys.argv) != 6:
    print("")
    print("adds NPTs to existing locations")
    print("also outputs selected elements as a .csv file, along with the XML")
    print("")
    print("usage: python %s <record_type> <config.cfg> <inputfile.csv> <outputfile.csv> <outputxmlfileprefix> " % sys.argv[0])
    print("")
    print("e.g:   nohup time python %s locationauthorities/d65c614a-e70e-441b-8855 extract.cfg kroeberupdate.tab storagelocations3.csv locations &" % sys.argv[0])
    print("")
    exit(1)

RECORD = sys.argv[1]
CONFIG_FILE = sys.argv[2]
INPUT_FILE = sys.argv[3]
CSV_FILE = sys.argv[4]
PREFIX = sys.argv[5]
PAGESIZE = 100
PAGES_RETRIEVED = 0

try:
    uri = RECORD
    if uri[0] == '/':
        uri = uri[1:]
        RECORD = f'{uri}/items'
    record_type = uri.split('/')[0]
except:
    logging.info(f'could not extract record type from "{RECORD}"')
    raise

lists_of_fields = {
    'collectionobjects': 'uri csid objectName objectNumber title updatedAt'.split(' '),
    'vocabularies': 'uri displayName csid refName shortIdentifier updatedAt'.split(' '),
    'groups': 'uri title refName csid updatedAt'.split(' '),
    'acquisitions': 'uri acquisitionReferenceNumber refName csid updatedAt'.split(' '),
    'movements': 'uri currentLocation refName csid updatedAt'.split(' '),
    'media': 'uri title identificationNumber refName csid updatedAt'.split(' '),
    'orgauthorities': 'uri termDisplayName refName csid updatedAt'.split(' '),
    'personauthorities': 'uri termDisplayName refName csid updatedAt'.split(' '),
    'locationauthorities': 'uri termDisplayName refName csid updatedAt'.split(' '),
    'conceptauthorities': 'uri termDisplayName refName csid updatedAt'.split(' '),
    'valuationcontrols': 'uri valuationcontrolRefNumber valueType refName csid updatedAt'.split(' '),
    'exhibitions': 'uri exhibitionNumber title valueType refName csid updatedAt'.split(' '),
}

fields_to_extract = lists_of_fields[record_type]

with open(CONFIG_FILE, 'r') as stream:
    try:
        config = yaml.safe_load(stream)
        SERVER = config['SERVER']
        CREDS = config['CREDS']
        credentials = tuple(CREDS.split(':'))
    except yaml.YAMLError as exc:
        logging.info(exc)

try:
    os.makedirs(RECORD)
except OSError as e:
    pass

inputCSV = csv.reader(codecs.open(INPUT_FILE, 'r', "utf-8"), delimiter='\t')

cspaceCSV = csv.writer(codecs.open(CSV_FILE, 'w', "utf-8"), delimiter='\t')


for row, values in enumerate(inputCSV):
    try:
        location, NPT, location_CSID = values
        url = f'{SERVER}/cspace-services/{RECORD}/items/{location_CSID}'
        r = requests.get(url, auth=credentials)
        if r.status_code != 200:
            logging.info(f'status code for Object GET is {r.status_code}, not 200. skipping url is {url}')
            break
        try:
            cspaceObject = ET.fromstring(r.text)
        except:
            logging.info(f'could not parse response for {url}')
            continue
        uri = cspaceObject.find('.//uri').text
        uri4file = uri.replace('/items', '')

        locTermGroupList = cspaceObject.find('.//locTermGroupList')

        termDisplayNames = [x.text for x in locTermGroupList.findall('.//termDisplayName')]

        if NPT in termDisplayNames:
            logging.info(f'{NPT} already appears in {location_CSID}. Skipping!')
            continue

        termDisplayName = locTermGroupList.find('.//termDisplayName').text
        newlocTermGroup = ET.Element('locTermGroup')
        for (tag, content) in [('termType', 'descriptor'), ('termStatus', 'accepted'),
                               ('termPrefForLang', 'true'),
                               ('termLanguage',"urn:cspace:pahma.cspace.berkeley.edu:vocabularies:name(languages):item:name(eng)'English'"),
                               ('termDisplayName', NPT),
                               ('termName', NPT)]:
            newelement = ET.Element(tag)
            newelement.text = content
            newlocTermGroup.append(newelement)

        locTermGroupList.append(newlocTermGroup)
        xml_string = ET.tostring(cspaceObject).decode('utf-8')
        url = f'{SERVER}/cspace-services{uri}?impTimeout=900'
        headers = {'Content-Type': 'application/xml'}
        r = requests.put(url, data=xml_string, headers=headers, auth=credentials)
        if r.status_code != 200:
            logging.info(f'status code for PUT is {r.status_code}, not 200. skipping. url is {url}')
            continue
        xml = open(f'.{uri4file}.xml', 'w')
        xml.write(xml_string)
        xml.close()

        Row = []
        for f in fields_to_extract:
            try:
                field = cspaceObject.find(f'.//{f}').text
            except:
                field = ''
            Row.append(field)
        cspaceCSV.writerow(Row)
    except:
        logging.info(f'error retrieving or parsing or updating the XML for {url}')
        raise
