import requests
import yaml
import xml.etree.ElementTree as ET
import os, sys, csv, codecs, logging

logging.basicConfig(
    format='%(asctime)s %(levelname)-8s %(message)s',
    level=logging.INFO,
    datefmt='%Y-%m-%d %H:%M:%S')

if len(sys.argv) != 5:
    print("")
    print("finds all the PAHMA 'Kroeber' locations and updates them with the new Location name ('MA1')")
    print("also outputs selected elements as a .csv file, along with the XML")
    print("")
    print("usage: python %s <record_type> <config.cfg> <outputfile.csv> <outputxmlfileprefix> " % sys.argv[0])
    print("")
    print("e.g:   nohup time python %s locationauthorities/d65c614a-e70e-441b-8855 extract.cfg storagelocations3.csv locations &" % sys.argv[0])
    print("")
    exit(1)

RECORD = sys.argv[1]
CONFIG_FILE = sys.argv[2]
CSV_FILE = sys.argv[3]
PREFIX = sys.argv[4]
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

cspaceCSV = csv.writer(codecs.open(CSV_FILE, 'w', "utf-8"), delimiter='\t')

while True:
    try:
        # alas, authorities are fetched differently than procedures
        get_items = '/items' if 'authorit' in RECORD else ''

        # retrieve the 1st page of records each time, until we get a page with no items...
        logging.info(f'retrieving page {PAGES_RETRIEVED}')
        url = f'{SERVER}/cspace-services/{RECORD}{get_items}?kw=kroeber&pgSz={PAGESIZE}&pgNum={PAGES_RETRIEVED}'
        # url = 'https://pahma.cspace.berkeley.edu/cspace-services/blobs?kw=x3d&pgNum=0&pgSz=200&wf_deleted=false'
        r = requests.get(url, auth=credentials)
        if r.status_code != 200:
            logging.info(f'status code for List GET is {r.status_code}, not 200. Cannot continue. url is {url}')
            break
        try:
            cspaceXML = ET.fromstring(r.text)
        except:
            logging.info(f'could not parse response for {url}')
            logging.info('check credentials? etc?')
            logging.info(r.text)
            raise
        # if we get no items, we are done
        itemsInPage = int(cspaceXML.find('.//itemsInPage').text)
        logging.info(f'page {PAGES_RETRIEVED} retrieved, {itemsInPage} items')
        if itemsInPage == 0:
            logging.info(f'nothing left to do, leaving infinite loop')
            break
        items = cspaceXML.findall('.//list-item')

        number_updated = 0
        for i in items:
            uri = i.find('.//uri').text

            termDisplayName = i.find('.//termDisplayName').text

            if termDisplayName == 'Kroeber, Gallery': continue
            # don't redo anything we might have done already
            if 'Kroeber' not in termDisplayName or 'MA1' in termDisplayName:
                continue

            url = f'{SERVER}/cspace-services{uri}'
            r = requests.get(url, auth=credentials)
            if r.status_code != 200:
                logging.info(f'status code for Object GET is {r.status_code}, not 200. skipping url is {url}')
                break
            try:
                cspaceObject = ET.fromstring(r.text)
            except:
                logging.info(f'could not parse response for {url}')
                logging.info('uri is {uri}')
                continue
            uri = cspaceObject.find('.//uri').text
            uri4file = uri.replace('/items', '')

            locTermGroupList = cspaceObject.find('.//locTermGroupList')
            termDisplayName = locTermGroupList.find('.//termDisplayName').text
            demotedlocTermGroup = locTermGroupList.find('.//locTermGroup')
            if termDisplayName == 'Kroeber, Gallery': continue
            # don't redo anything we might have done already
            if not 'Kroeber' in termDisplayName or 'MA1' in termDisplayName:
                continue
            revisedtermDisplayName = termDisplayName.replace('Kroeber', 'MA1')
            # make the current 1st term become: Kroeber, 09, 03, 10 [USE "MA1, 09, 03, 10"]
            demotedDisplayName = f'{termDisplayName} [USE "{revisedtermDisplayName}"]'
            newlocTermGroup = ET.Element('locTermGroup')
            for (tag, content) in [('termType', 'descriptor'), ('termStatus', 'accepted'),
                                   ('termPrefForLang', 'true'),
                                   ('termLanguage',"urn:cspace:pahma.cspace.berkeley.edu:vocabularies:name(languages):item:name(eng)'English'"),
                                   ('termDisplayName', revisedtermDisplayName),
                                   ('termName', revisedtermDisplayName)]:
                newelement = ET.Element(tag)
                newelement.text = content
                newlocTermGroup.append(newelement)

            for (tag, content) in [('termType', 'descriptor'), ('termStatus', 'accepted'),
                                   ('termPrefForLang', 'false'),
                                   ('termLanguage',"urn:cspace:pahma.cspace.berkeley.edu:vocabularies:name(languages):item:name(eng)'English'"),
                                   ('termDisplayName', demotedDisplayName),
                                   ('termName', demotedDisplayName)]:
                demotedElement = demotedlocTermGroup.find(f'.//{tag}')
                demotedElement.text = content

            locTermGroupList.insert(0, newlocTermGroup)
            '''
            <locTermGroup>
                <termType>descriptor</termType>
                <termStatus>accepted</termStatus>
                <termDisplayName>MA1, 09, 01, 01</termDisplayName>
            </locTermGroup>
            '''
            xml_string = ET.tostring(cspaceObject).decode('utf-8')
            url = f'{SERVER}/cspace-services{uri}'
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
                    field = i.find(f'.//{f}').text
                except:
                    field = ''
                Row.append(field)
            cspaceCSV.writerow(Row)
            number_updated += 1

        logging.info(f'update {number_updated} of {itemsInPage}')
        if number_updated == 0:
            PAGES_RETRIEVED += 1
            logging.info(f'no updates seen on this page, going on to next page {PAGES_RETRIEVED}')
    except:
        logging.info(f'error retrieving or parsing or updating the XML for {url}')
        raise
