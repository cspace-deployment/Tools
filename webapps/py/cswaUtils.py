#!/usr/bin/env /usr/bin/python

import os
import sys
import copy

# for log
import csv
import codecs
import ConfigParser

import time, datetime
import httplib, urllib2
import cgi
#import cgitb; cgitb.enable()  # for troubleshooting
import re

MAXLOCATIONS = 1000

try:
    import xml.etree.ElementTree as etree
    #print("running with ElementTree")
except ImportError:
    try:
        from lxml import etree
        #print("running with lxml.etree")
    except ImportError:
        try:
            # normal cElementTree install
            import cElementTree as etree
            #print("running with cElementTree")
        except ImportError:
            try:
                # normal ElementTree install
                import elementtree.ElementTree as etree
                #print("running with ElementTree")
            except ImportError:
                print("Failed to import ElementTree from any known place")

# the only other module: isolate postgres calls and connection
import cswaDB as cswaDB
import getPlaces
import getTaxname
import getAuthorityTree
import cswaConceptutils as concept
import cswaCollectionUtils as cswaCollectionUtils

## {{{ http://code.activestate.com/recipes/81547/ (r1)
def cgiFieldStorageToDict(fieldStorage):
    """Get a plain dictionary, rather than the '.value' system used by the cgi module."""
    params = {}
    for key in fieldStorage.keys():
        params[key] = fieldStorage[key].value
    return params


def getConfig(form):
    try:
        fileName = form.get('webapp') + '.cfg'
        config = ConfigParser.RawConfigParser()
        config.read(fileName)
        # test to see if it seems like it is really a config file
        updateType = config.get('info', 'updatetype')
        return config
    except:
        return False


def getProhibitedLocations(appconfig):
    #fileName = appconfig.get('files','prohibitedLocations.csv')
    fileName = 'prohibitedLocations.csv'
    locList = []
    try:
        with open(fileName, 'rb') as csvfile:
            csvreader = csv.reader(csvfile, delimiter="\t")
            for row in csvreader:
                locList.append(row[0])
    except:
        print 'FAIL'
        raise

    return locList


def serverCheck(form, config):
    result = "<tr><td>start server check</td><td>" + time.strftime("%b %d %Y %H:%M:%S", time.localtime()) + "</td></tr>"

    elapsedtime = time.time()
    # do an sql search...
    result += "<tr><td>SQL check</td><td>" + cswaDB.testDB(config) + "</td></tr>"
    elapsedtime = time.time() - elapsedtime
    result += "<tr><td>SQL time</td><td>" + ('%8.2f' % elapsedtime) + " seconds</td></tr>"

    # if we are configured for barcodes, try that...
    try:
        config.get('files', 'cmdrfileprefix') + config.get('files', 'cmdrauditfile')
        try:
            elapsedtime = time.time()
            result += "<tr><td>barcode audit file</td><td>" + config.get('files', 'cmdrauditfile') + "</td></tr>"
            result += "<tr><td>trying...</td><td> to write empty test files to commanderWatch directory</td></tr>"
            result += "<tr><td>location labels</td><td>" + writeCommanderFile('test', 'kroeberBCP', 'locationLabels',
                                                                              'locations', [], config) + "</td></tr>"
            result += "<tr><td>object labels</td><td>" + writeCommanderFile('test', 'kroeberBCP', 'objectLabels',
                                                                            'objects', [], config) + "</td></tr>"
            elapsedtime = time.time() - elapsedtime
            result += "<tr><td>barcode check time</td><td>" + ('%8.2f' % elapsedtime) + " seconds</td></tr>"
        except:
            result += "<tr><td>barcode funtionality check</td><td>FAILED.</td></tr>"
    except:
        result += "<tr><td>barcode funtionality check</td><td>skipped, not configured.</td></tr>"

    elapsedtime = time.time()
    # rest check...
    elapsedtime = time.time() - elapsedtime
    result += "<tr><td>REST check</td><td>Not ready yet.</td></tr>"
    #result += "<tr><td>REST check</td><td>" + ('%8.2f' % elapsedtime) + " seconds</td></tr>"

    result += "<tr><td>end server check</td><td>" + time.strftime("%b %d %Y %H:%M:%S", time.localtime()) + "</td></tr>"
    result += '''<tr><td colspan="2"><hr/></td></tr>'''

    return '''<table width="100%"><tbody><tr><td><h3>Server Status Check</h3></td></tr>''' + result + '''</tbody></table>'''


def handleTimeout(source, form):
    print '<h3><span style="color:red;">Time limit exceeded! The problem has been logged and will be examined. Feel free to try again though!</span></h3>'
    sys.stderr.write('TIMEOUT::' + source + '::location::' + str(form.get("lo.location1")) + '::')


def validateParameters(form, config):
    valid = True

    if form.get('handlerRefName') == 'None':
        print '<h3>Please select a handler before searching</h3>'
        valid = False

    #if not str(form.get('num2ret')).isdigit():
    #    print '<h3><i>number to retrieve</i> must be a number, please!</h3>'
    #    valid = False

    if form.get('reason') == 'None':
        print '<h3>Please select a reason before searching</h3>'
        valid = False

    if config.get('info', 'updatetype') == 'barcodeprint':
        if form.get('printer') == 'None':
            print '<h3>Please select a printer before trying to print labels</h3>'
            valid = False

    prohibitedLocations = getProhibitedLocations(config)
    if form.get("lo.location1"):
        loc = form.get("lo.location1")
        if loc in prohibitedLocations:
            print '<h3>Location "%s" is unavailable to this webapp. Please contact registration staff for details.</h3>' % form.get(
                "lo.location1")
            valid = False

    if form.get("lo.location2"):
        loc = form.get("lo.location2")
        if loc in prohibitedLocations:
            print '<h3>Location "%s" is unavailable to this webapp. Please contact registration staff for details.</h3>' % form.get(
                "lo.location2")
            valid = False

    return valid


def search(form, config):
    mapping = {'lo.location1': 'l1', 'lo.location2': 'l2', 'ob.objectnumber': 'ob', 'cp.place': 'pl',
               'co.concept': 'co'}
    for m in mapping.keys():
        if form.get(m) == None:
            pass
        else:
            print '%s : %s %s\n' % (m, mapping[m], form.get(m))


def doComplexSearch(form, config, displaytype):
    #if not validateParameters(form,config): return
    listAuthorities('taxon', 'TaxonTenant35', form.get("ta.taxon"), config, form, displaytype)
    listAuthorities('locations', 'Locationitem', form.get("lo.location1"), config, form, displaytype)
    listAuthorities('places', 'Placeitem', form.get("px.place"), config, form, displaytype)
    #listAuthorities('taxon',     'TaxonTenant35',  form.get("ob.objectnumber"),config, form, displaytype)
    #listAuthorities('concepts',  'TaxonTenant35',  form.get("cx.concept"),     config, form, displaytype)

    getTableFooter(config, displaytype)


def listAuthorities(authority, primarytype, authItem, config, form, displaytype):
    if authItem == None or authItem == '': return
    rows = getAuthorityTree.getAuthority(authority, primarytype, authItem, config.get('connect', 'connect_string'))

    listSearchResults(authority, config, displaytype, form, rows)

    return rows


def doLocationSearch(form, config, displaytype):
    if not validateParameters(form, config): return
    updateType = config.get('info', 'updatetype')

    try:
        #If barcode print, assume empty end location is start location
        if updateType == "barcodeprint":
            if form.get("lo.location2"):
                rows = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location2"), 500, config)
            else:
                rows = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location1"), 500, config)
        else:
            rows = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location2"), MAXLOCATIONS, config)
    except:
        raise
        handleTimeout('search', form)

    listSearchResults('locations', config, displaytype, form, rows)

    if len(rows) != 0: getTableFooter(config, displaytype)


def doObjectSearch(form, config, displaytype):
    if not validateParameters(form, config): return

    updateType = config.get('info', 'updatetype')
    updateactionlabel = config.get('info', 'updateactionlabel')

    if updateType == 'moveobject':
        crate = verifyLocation(form.get("lo.crate"), form, config)
        toLocation = verifyLocation(form.get("lo.location1"), form, config)

        if str(form.get("lo.crate")) != '' and crate == '':
            print '<span style="color:red;">Crate is not valid! Sorry!</span><br/>'
        if toLocation == '':
            print '<span style="color:red;">Destination is not valid! Sorry!</span><br/>'
        if (str(form.get("lo.crate")) != '' and crate == '') or toLocation == '':
            return

        toRefname = cswaDB.getrefname('locations_common', toLocation, config)
        toCrate = cswaDB.getrefname('locations_common', crate, config)

    try:
        rows = cswaDB.getobjlist('range', form.get("ob.objno1"), form.get("ob.objno2"), 500, config)
    except:
        raise
        handleTimeout('search', form)

    if len(rows) == 0:
        print '<span style="color:red;">No objects in this range! Sorry!</span>'
    else:
        totalobjects = 0
        if updateType == 'objinfo':
            print infoHeaders(form.get('fieldset'))
        else:
            print getHeader(updateType)
        for r in rows:
            totalobjects += 1
            print formatRow({'rowtype': updateType, 'data': r}, form, config)

        print """<tr><td align="center" colspan="99"><hr><td></tr>"""
        print """<tr><td align="center" colspan="3">"""
        msg = "Caution: clicking on the button at left will update <b>ALL %s objects</b> shown on this page!" % totalobjects
        print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td><td  colspan="3">%s</td></tr>''' % msg

        print "\n</table><hr/>"
        if updateType == 'moveobject':
            print '<input type="hidden" name="toRefname" value="%s">' % toRefname
            print '<input type="hidden" name="toCrate" value="%s">' % toCrate
            print '<input type="hidden" name="toLocAndCrate" value="%s: %s">' % (toLocation, crate)

            #if len(rows) != 0: getTableFooter(config,displaytype)


def doSingleObjectSearch(form, config, displaytype=''):
    if not validateParameters(form, config): return

    updateType = config.get('info', 'updatetype')
    updateactionlabel = config.get('info', 'updateactionlabel')

    if updateType == 'barcodeprint':
        try:
            obj = cswaDB.getobjinfo(form.get('ob.objectnumber'), config)
        except:
            raise
            handleTimeout('search', form)
            #obj = [-1, -1, '(null)', '(null)', '(null)']
        print """
    <table width="100%"><tr>
    <th>Object</th>
    <th>Count</th>
    <th>Object Name</th>
    <th>Culture</th>
    <th>Collection Place</th>
    <th>Ethnographic File Code</th>
    </tr>"""
        print '''<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>''' % tuple(obj)

        print """<tr><td align="center" colspan="6"><hr><td></tr>"""
        print """<tr><td align="center" colspan="6">"""
        print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td></tr>'''


def listSearchResults(authority, config, displaytype, form, rows):
    updateType = config.get('info', 'updatetype')

    if not rows: rows = []
    rows.sort()
    rowcount = len(rows)

    label = authority
    if label[-1] == 's' and rowcount == 1: label = label[:-1]

    if displaytype == 'silent':
        print """<table width="100%">"""
    elif displaytype == 'select':
        print """<div style="float:left; width: 300px;">%s %s in this range</th>""" % (rowcount, label)
    else:
        print """
    <table width="100%%">
    <tr>
      <th>%s %s in this range</th>
    </tr>""" % (rowcount, label)

    if rowcount == 0:
        print "</table>"
        return

    if displaytype == 'select':
        print """<li><input type="checkbox" name="select-%s" id="select-%s" checked/> select all</li>""" % (
            authority, authority)

    if displaytype == 'list' or displaytype == 'select':
        rowtype = 'location'
        if displaytype == 'select': rowtype = 'select'
        for r in rows:
            print formatRow({'boxtype': authority, 'rowtype': rowtype, 'data': r}, form, config)

    elif displaytype == 'nolist':
        label = authority
        if label[-1] == 's': label = label[:-1]
        if rowcount == 1:
            print '<tr><td class="authority">%s</td></tr>' % (rows[0][0])
        else:
            print '<tr><th>first %s</th><td class="authority">%s</td></tr>' % (label, rows[0][0])
            print '<tr><th>last %s</th><td class="authority">%s</td></tr>' % (label, rows[-1][0])

    if displaytype == 'select':
        print "\n</div>"
    else:
        print "</table>"
        #print """<input type="hidden" name="count" value="%s">""" % rowcount


def getTableFooter(config, displaytype):
    updateType = config.get('info', 'updatetype')

    print """<table width="100%"><tr><td align="center" colspan="2"><hr></tr>"""
    if displaytype == 'list':
        print """<tr><td align="center">"""
        button = 'Enumerate Objects'
        print """<input type="submit" class="save" value="%s" name="action"></td>""" % button
        if updateType == "packinglist":
            print """<td><input type="submit" class="save" value="%s" name="action"></td>""" % 'Download as CSV'
        else:
            print "<td></td>"
        print "</tr>"
    else:
        print """<tr><td align="center">"""
        button = config.get('info', 'updateactionlabel')
        print """<input type="submit" class="save" value="%s" name="action"></td>""" % button
        if updateType == "packinglist":
            print """<td><input type="submit" class="save" value="%s" name="action"></td>""" % 'Download as CSV'
        if updateType == "barcodeprint":
            print """<td><input type="submit" class="save" value="%s" name="action"></td>""" % 'Create Labels for Locations Only'
        else:
            print "<td></td>"
        print "</tr>"
    print "</table>"


def getHeader(updateType):
    if updateType == 'inventory':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Found</th>
      <th style="width:60px; text-align:center;">Not Found</th>
      <th>Notes</th>
    </tr>"""
    elif updateType == 'movecrate':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Move</th>
      <th style="width:60px; text-align:center;">Not Found</th>
      <th>Notes</th>
    </tr>"""
    elif updateType == 'packinglist':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Count</th>
      <th>Field Collection Place</th>
      <th>Cultural Group</th>
      <th>Ethnographic File Code</th>
      <th>P?</th>
    </tr>"""
    elif updateType == 'packinglistbyculture':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Count</th>
      <th width="150px;">Location</th>
      <th>Field Collection Place</th>
      <th>P?</th>
    </tr>"""
    elif updateType == 'moveobject':
        return """
    <table><tr>
      <th>Move?</th>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Count</th>
      <th>Location</th>
    </tr>"""
    elif updateType == 'bedlist':
        return """
    <table class="tablesorter" id="sortTable%s"><thead>
    <tr>
      <th>Accession</th>
      <th>Family</th>
      <th>Taxonomic Name</th>
    </tr></thead><tbody>"""
    elif updateType == 'bedlistxxx' or updateType == 'advsearchxxx':
        return """
    <table class="tablesorter" id="sortTable%s"><thead>
    <tr>
      <th data-sort="float">Accession Number</th>
      <th data-sort="string">Family</th>
      <th data-sort="string">Taxonomic Name</th>
    </tr></thead><tbody>"""
    elif updateType == 'bedlistnone':
        return """
    <table class="tablesorter" id="sortTable"><thead><tr>
      <th>Accession</th>
      <th>Family</th>
      <th>Taxonomic Name</th>
      <th>Garden Location</th>
    </tr></thead><tbody>"""
    elif updateType == 'locreport' or updateType == 'holdings' or updateType == 'advsearch':
        return """
    <table class="tablesorter" id="sortTable"><thead><tr>
      <th data-sort="float">Accession</th>
      <th data-sort="string">Taxonomic Name</th>
      <th data-sort="string">Family</th>
      <th data-sort="string">Garden Location</th>
      <th data-sort="string">Locality</th>
      <th data-sort="string">Rare</th>
      <th data-sort="string">Dead</th>
    </tr></thead><tbody>"""
    elif updateType == 'keyinfoResult' or updateType == 'objinfoResult':
        return """
    <table width="100%" border="1">
    <tr>
      <th>Museum #</th>
      <th>CSID</th>
      <th>Status</th>
    </tr>"""
    elif updateType == 'inventoryResult':
        return """
    <table width="100%" border="1">
    <tr>
      <th>Museum #</th>
      <th>Updated Inventory Status</th>
      <th>Note</th>
      <th>Update status</th>
    </tr>"""
    elif updateType == 'barcodeprint':
        return """
    <table width="100%"><tr>
      <th>Location</th>
      <th>Objects found</th>
      <th>Barcode Filename</th>
      <th>Notes</th>
    </tr>"""
    elif updateType == 'barcodeprintlocations':
        return """
    <table width="100%"><tr>
      <th>Locations listed</th>
      <th>Barcode Filename</th>
    </tr>"""


def doEnumerateObjects(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    if not validateParameters(form, config): return

    try:
        locationList = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location2"), MAXLOCATIONS,
                                         config)
    except:
        raise
        handleTimeout(updateType, form)
        locationList = []

    rowcount = len(locationList)

    if rowcount == 0:
        print '<h2>No locations in this range!</h2>'
        return

    if updateType == 'keyinfo' or updateType == 'objinfo':
        print infoHeaders(form.get('fieldset'))
    else:
        print getHeader(updateType)
    totalobjects = 0
    totallocations = 0
    for l in locationList:

        try:
            objects = cswaDB.getlocations(l[0], '', 1, config, updateType)
        except:
            handleTimeout(updateType + ' getting objects', form)
            return

        rowcount = len(objects)
        locations = {}
        if rowcount == 0:
            locationheader = formatRow({'rowtype': 'subheader', 'data': l}, form, config)
            locations[locationheader] = ['<tr><td colspan="3">No objects found at this location.</td></tr>']
        for r in objects:
            locationheader = formatRow({'rowtype': 'subheader', 'data': r}, form, config)
            if locations.has_key(locationheader):
                pass
            else:
                locations[locationheader] = []
                totallocations += 1

            totalobjects += 1
            locations[locationheader].append(formatRow({'rowtype': updateType, 'data': r}, form, config))

        locs = locations.keys()
        locs.sort()
        for header in locs:
            print header
            print '\n'.join(locations[header])

    if totalobjects == 0:
        pass
    else:
        print """<tr><td align="center" colspan="99"><hr><td></tr>"""
        print """<tr><td align="center" colspan="3">"""
        if updateType == 'keyinfo' or updateType == 'objinfo':
            msg = "Caution: clicking on the button at left will revise the above fields for <b>ALL %s objects</b> shown in these %s locations!" % (
                totalobjects, totallocations)
        else:
            msg = "Caution: clicking on the button at left will change the " + updateType + " of <b>ALL %s objects</b> shown in these %s locations!" % (
                totalobjects, totallocations)
        print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td><td  colspan="4">%s</td></tr>''' % msg

    print "\n</table><hr/>"


def verifyLocation(loc, form, config):
    location = cswaDB.getloclist('set', loc, '', 1, config)
    if loc == location[0][0]:
        return loc
    else:
        return ''


def doCheckMove(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    if not validateParameters(form, config): return

    crate = verifyLocation(form.get("lo.crate"), form, config)
    fromLocation = verifyLocation(form.get("lo.location1"), form, config)
    toLocation = verifyLocation(form.get("lo.location2"), form, config)

    toRefname = cswaDB.getrefname('locations_common', toLocation, config)

    #sys.stderr.write('%-13s:: %-18s:: %s\n' % (updateType, 'toRefName', toRefname))

    # DEBUG
    #print '<table cellpadding="8px" border="1">'
    #print '<tr><td>%s</td><td>%s</td></tr>' % ('From',fromLocation)
    #print '<tr><td>%s</td><td>%s</td></tr>' % ('Crate',crate)
    #print '<tr><td>%s</td><td>%s</td></tr>' % ('To',toLocation)
    #print '</table>'

    if crate == '':
        print '<span style="color:red;">Crate is not valid! Sorry!</span><br/>'
    if fromLocation == '':
        print '<span style="color:red;">From location is not valid! Sorry!</span><br/>'
    if toLocation == '':
        print '<span style="color:red;">To location is not valid! Sorry!</span><br/>'
    if crate == '' or fromLocation == '' or toLocation == '':
        return

    try:
        objects = cswaDB.getlocations(form.get("lo.location1"), '', 1, config, 'inventory')
    except:
        handleTimeout(updateType + ' getting objects', form)
        return

    locations = {}
    if len(objects) == 0:
        print '<span style="color:red;">No objects found at this location! Sorry!</span>'
        return

    totalobjects = 0
    totallocations = 0

    #sys.stderr.write('%-13s:: %-18s:: %s\n' % (updateType, 'objects', len(objects)))
    for r in objects:
        #sys.stderr.write('%-13s:: %-18s:: %s\n' % (updateType, crate, r[15]))
        if r[15] != crate: # skip if this is not the crate we want
            continue
        locationheader = formatRow({'rowtype': 'subheader', 'data': r}, form, config)
        if locations.has_key(locationheader):
            pass
        else:
            locations[locationheader] = []
            totallocations += 1

        totalobjects += 1
        locations[locationheader].append(formatRow({'rowtype': 'inventory', 'data': r}, form, config))

    locs = locations.keys()
    locs.sort()

    if len(locs) == 0:
        print '<span style="color:red;">Did not find this crate at this location! Sorry!</span>'
        return

    print getHeader(updateType)
    for header in locs:
        print header
        print '\n'.join(locations[header])

    print """<tr><td align="center" colspan="6"><hr><td></tr>"""
    print """<tr><td align="center" colspan="3">"""
    msg = "Caution: clicking on the button at left will move <b>ALL %s objects</b> shown in this crate!" % totalobjects
    print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td><td  colspan="3">%s</td></tr>''' % msg

    print "\n</table><hr/>"
    print '<input type="hidden" name="toRefname" value="%s">' % toRefname
    print '<input type="hidden" name="toLocAndCrate" value="%s: %s">' % (toLocation, crate)


def doUpdateKeyinfo(form, config):
    #print form
    CSIDs = []
    fieldset = form.get('fieldset')
    for i in form:
        if 'csid.' in i:
            CSIDs.append(form.get(i))

    refNames2find = {}
    for row, csid in enumerate(CSIDs):

        index = csid # for now, the index is the csid
        if fieldset == 'namedesc':
            pass
        elif fieldset == 'registration':
            if not refNames2find.has_key(form.get('ant.' + index)):
                refNames2find[form.get('ant.' + index)] = cswaDB.getrefname('pahmaaltnumgroup_type', form.get('ant.' + index), config)
            if not refNames2find.has_key(form.get('pc.' + index)):
                refNames2find[form.get('pc.' + index)] = cswaDB.getrefname('collectionobjects_common_fieldcollectors', form.get('pc.' + index), config)
            if not refNames2find.has_key(form.get('pd.' + index)):
                refNames2find[form.get('pd.' + index)] = cswaDB.getrefname('acquisitions_common_owners', form.get('pd.' + index), config)
        elif fieldset == 'keyinfo':
            if not refNames2find.has_key(form.get('cp.' + index)):
                refNames2find[form.get('cp.' + index)] = cswaDB.getrefname('places_common', form.get('cp.' + index), config)
            if not refNames2find.has_key(form.get('cg.' + index)):
                refNames2find[form.get('cg.' + index)] = cswaDB.getrefname('concepts_common', form.get('cg.' + index), config)
            if not refNames2find.has_key(form.get('fc.' + index)):
                refNames2find[form.get('fc.' + index)] = cswaDB.getrefname('concepts_common', form.get('fc.' + index), config)
        else:
            pass
            #error! fieldset not set!

    print getHeader('keyinfoResult')

    #for r in refNames2find:
    #    print '<tr><td>%s<td>%s<td>%s</tr>' % ('refname',refNames2find[r],r)
    #print CSIDs

    numUpdated = 0
    for row, csid in enumerate(CSIDs):

        index = csid # for now, the index is the csid
        updateItems = {}
        updateItems['objectCsid'] = form.get('csid.' + index)
        updateItems['objectName'] = form.get('onm.' + index)
        updateItems['objectNumber'] = form.get('oox.' + index)
        if fieldset == 'namedesc':
            updateItems['briefDescription'] = form.get('bdx.' + index)
        elif fieldset == 'registration':
            updateItems['pahmaAltNum'] = form.get('anm.' + index)
            updateItems['pahmaAltNumType'] = form.get('ant.' + index)
            updateItems['fieldCollector'] = refNames2find[form.get('pc.' + index)]
        elif fieldset == 'keyinfo':
            updateItems['objectCount'] = form.get('ocn.' + index)
            updateItems['pahmaFieldCollectionPlace'] = refNames2find[form.get('cp.' + index)]
            updateItems['assocPeople'] = refNames2find[form.get('cg.' + index)]
            updateItems['pahmaEthnographicFileCode'] = refNames2find[form.get('fc.' + index)]
        else:
            pass
            #error!

        for i in ('handlerRefName',):
            updateItems[i] = form.get(i)

        #print updateItems
        msg = 'updated.'
        if fieldset == 'keyinfo':
            if updateItems['pahmaFieldCollectionPlace'] == '' and form.get('cp.' + index):
                msg += '<span style="color:red;"> Field Collection Place: term "%s" not found, field not updated.</span>' % form.get('cp.' + index)
            if updateItems['assocPeople'] == '' and form.get('cg.' + index):
                msg += '<span style="color:red;"> Cultural Group: term "%s" not found, field not updated.</span>' % form.get('cg.' + index)
            if updateItems['pahmaEthnographicFileCode'] == '' and form.get('fc.' + index):
                msg += '<span style="color:red;"> Ethnographic File Code: term "%s" not found, field not updated.</span>' % form.get('fc.' + index)
            try:
                int(updateItems['objectCount'])
                int(updateItems['objectCount'][0])
            except ValueError:
                msg += '<span style="color:red;"> Object count: "%s" is not a valid number!</span>' % form.get('ocn.' + index)
                del updateItems['objectCount']
                #updateItems['objectCount'] = mythicalquerymethodtoreturncount(do)
        elif fieldset == 'registration':
            if updateItems['fieldCollector'] == '' and form.get('pc.' + index):
                msg += '<span style="color:red;"> Field Collector: term "%s" not found, field not updated.</span>' % form.get('pc.' + index)
        try:
            #pass
            updateKeyInfo(fieldset, updateItems, config)
            numUpdated += 1
        except:
            raise
            msg = '<span style="color:red;">problem updating</span>'
        print ('<tr>' + (3 * '<td class="ncell">%s</td>') + '</tr>\n') % (
            updateItems['objectNumber'], updateItems['objectCsid'], msg)
        # print 'place %s' % updateItems['pahmaFieldCollectionPlace']

    print "\n</table>"
    print '<h4>', numUpdated, 'of', row + 1, 'object had key information updated</h4>'


def infoHeaders(fieldSet):
    if fieldSet == 'keyinfo':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Count</th>
      <th>Field Collection Place</th>
      <th>Cultural Group</th>
      <th>Ethnographic File Code</th>
      <th>P?</th>
    </tr>"""
    elif fieldSet == 'namedesc':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th></th>
      <th style="text-align:center">Brief Description</th>
      <th>P?</th>
    </tr>"""
    elif fieldSet == 'registration':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Alt Num</th>
      <th>Alt Num Type</th>
      <th>Field Collector</th>
      <th>Donor</th>
      <th>Accession</th>
      <th>P?</th>
    </tr>"""
    else:
        return "<table><tr>DEBUG</tr>"


def doNothing(form, config):
    print '<span style="color:red;">Nothing to do yet! ;-)</span>'


def doUpdateLocations(form, config):
    updateValues = [form.get(i) for i in form if 'r.' in i]

    print getHeader('inventoryResult')

    numUpdated = 0
    for row, object in enumerate(updateValues):

        updateItems = {}
        cells = object.split('|')
        updateItems['objectStatus'] = cells[0]
        updateItems['objectCsid'] = cells[1]
        updateItems['locationRefname'] = cells[2]
        updateItems[
            'subjectCsid'] = '' # cells[3] is actually the csid of the movement record for the current location; the updated value gets inserted later
        updateItems['objectNumber'] = cells[4]
        updateItems['crate'] = cells[5]
        updateItems['inventoryNote'] = form.get('n.' + cells[4]) if form.get('n.' + cells[4]) else ''
        updateItems['locationDate'] = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
        updateItems['computedSummary'] = updateItems['locationDate'][0:10] + (' (%s)' % form.get('reason'))

        for i in ('handlerRefName', 'reason'):
            updateItems[i] = form.get(i)

        # ugh...this logic is in fact rather complicated...
        msg = 'location updated.'
        # if we are moving a crate, use the value of the toLocation's refname, which is stored hidden on the form.
        if config.get('info', 'updatetype') == 'movecrate':
            updateItems['locationRefname'] = form.get('toRefname')
            msg = 'crate moved to %s.' % form.get('toLocAndCrate')

        if config.get('info', 'updatetype') == 'moveobject':
            updateItems['locationRefname'] = form.get('toRefname')
            updateItems['crate'] = form.get('toCrate')
            msg = 'object moved to %s.' % form.get('toLocAndCrate')

        if updateItems['objectStatus'] == 'not found':
            updateItems[
                'locationRefname'] = "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(sl23524)'Not located'"
            updateItems['crate'] = ''
            msg = "moved to 'Not Located'."
            #updateItems['crate'] = "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(crate):item:name(Notlocated1360806150870)'Not located'"

        #print updateItems
        try:
            updateLocations(updateItems, config)
            numUpdated += 1
        except:
            msg = '<span style="color:red;">problem updating</span>'
        print ('<tr>' + (4 * '<td class="ncell">%s</td>') + '</tr>\n') % (
            updateItems['objectNumber'], updateItems['objectStatus'], updateItems['inventoryNote'], msg)
        writeLog(updateItems, config)

    print "\n</table>"
    print '<h4>', numUpdated, 'of', row + 1, 'object locations updated</h4>'


def checkObject(places, objectInfo):
    if places == []:
        return True
    elif objectInfo[6] is None:
        return False
    elif objectInfo[6] in places:
        return True
    else:
        return False


def doPackingList(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    if form.get('groupbyculture') is not None:
        updateType = 'packinglistbyculture'
    if not validateParameters(form, config): return

    place = form.get("cp.place")
    if place != None:
        places = getPlaces.getPlaces(place)
    else:
        places = []

    try:
        locationList = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location2"), MAXLOCATIONS,
                                         config)
    except:
        raise
        handleTimeout(updateType, form)
        locationList = []

    rowcount = len(locationList)

    if rowcount == 0:
        print '<tr><td width="500px"><h2>No locations in this range!</h2></td></tr>'
        return

    print getHeader(updateType)
    totalobjects = 0
    totallocations = 0
    locations = {}
    for l in locationList:

        try:
            objects = cswaDB.getlocations(l[0], '', 1, config, 'packinglist')
        except:
            handleTimeout(updateType + ' getting objects', form)
            return

        rowcount = len(objects)
        if rowcount == 0:
            if updateType != 'packinglistbyculture':
                locationheader = formatRow({'rowtype': 'subheader', 'data': l}, form, config)
                locations[locationheader] = ['<tr><td colspan="3">No objects found at this location.</td></tr>']
        for r in objects:
            if checkObject(places, r):
                totalobjects += 1
                if updateType == 'packinglistbyculture':
                    temp = copy.deepcopy(r)
                    cgrefname = r[11]
                    parentcount = 0
                    if cgrefname is not None:
                        parents = cswaDB.findparents(cgrefname, config)
                        #[sys.stderr.write('term: %s' % x) for x in parents]
                        if parents is None or len(parents) == 1:
                            subheader = 'zzzNo parent :: %s' % r[7]
                        else:
                            subheader = [term[0] for term in parents]
                            subheader = ' :: '.join(subheader)
                            parentcount = len(parents)
                    else:
                        subheader = 'zzzNo cultural group specified'
                        #sys.stderr.write('%s %s' % (str(r[7]), parentcount))
                    temp[0] = subheader
                    temp[7] = r[0]
                    r = temp
                    locationheader = formatRow({'rowtype': 'subheader', 'data': r}, form, config)
                else:
                    locationheader = formatRow({'rowtype': 'subheader', 'data': r}, form, config)
                if locations.has_key(locationheader):
                    pass
                else:
                    locations[locationheader] = []
                    totallocations += 1

                locations[locationheader].append(formatRow({'rowtype': updateType, 'data': r}, form, config))

    locs = locations.keys()
    locs.sort()
    for header in locs:
        print header.replace('zzz', '')
        print '\n'.join(locations[header])
        print """<tr><td align="center" colspan="6">&nbsp;</tr>"""
    print """<tr><td align="center" colspan="6"><hr><td></tr>"""
    headingtypes = 'cultures' if updateType == 'packinglistbyculture' else 'including crates'
    print """<tr><td align="center" colspan="6">Packing list completed. %s objects, %s locations, %s %s</td></tr>""" % (
        totalobjects, len(locationList), totallocations, headingtypes)
    print "\n</table><hr/>"


def doAuthorityScan(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    if not validateParameters(form, config): return

    # yes, I know, it does look a bit odd...
    rare = []
    if form.get('rare'):    rare.append('true')
    if form.get('notrare'): rare.append('false')
    dead = []
    if form.get('dead'):    dead.append('true')
    if form.get('alive'):   dead.append('false')

    if updateType == 'locreport':
        Taxon = form.get("ta.taxon")
        if Taxon != None:
            Taxa = listAuthorities('taxon', 'TaxonTenant35', Taxon, config, form, 'silent')
        else:
            Taxa = []
        tList = [t[0] for t in Taxa]
        column = 1

    elif updateType == 'holdings':
        Place = form.get("px.place")
        if Place != None:
            Places = listAuthorities('places', 'Placeitem', Place, config, form, 'silent')
        else:
            Places = []
        tList = [t[0] for t in Places]
        column = 5

    try:
        objects = cswaDB.getplants('', '', 1, config, 'getalltaxa')
    except:
        raise
        handleTimeout('getalltaxa', form)
        objects = []

    rowcount = len(objects)

    if rowcount == 0:
        print '<h2>No plants in this range!</h2>'
        return
        #else:
    #	showTaxon = Taxon
    #   if showTaxon == '' : showTaxon = 'all Taxons in this range'
    #   print '<tr><td width="500px"><h2>%s locations will be listed for %s.</h2></td></tr>' % (rowcount,showTaxon)

    print getHeader(updateType)
    totalobjects = 0
    accessions = []
    for t in objects:
        if t[column] in tList:
            if updateType == 'locreport' and checkMembership(t[7], rare) and checkMembership(t[8], dead):
                print formatRow({'rowtype': updateType, 'data': t}, form, config)
                totalobjects += 1
            elif updateType == 'holdings':
                print formatRow({'rowtype': updateType, 'data': t}, form, config)
                totalobjects += 1

    #print '\n'.join(accessions)
    print """</table><table>"""
    print """<tr><td align="center">&nbsp;</tr>"""
    print """<tr><td align="center"><hr></tr>"""
    print """<tr><td align="center">Report completed. %s objects displayed</td></tr>""" % (totalobjects)
    print "\n</table><hr/>"


def downloadCsv(form, config):
    try:
        rows = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location2"), 500, config)
    except:
        raise
        handleTimeout('downloadCSV', form)
        rows = []

    place = form.get("cp.place")
    if place != None:
        places = getPlaces.getPlaces(place)
    else:
        places = []

    rowcount = len(rows)
    print 'Content-type: application/octet-stream; charset=utf-8'
    print 'Content-Disposition: attachment; filename="packinglist.xls"'
    print
    writer = csv.writer(sys.stdout, quoting=csv.QUOTE_ALL)
    for r in rows:
        objects = cswaDB.getlocations(r[0], '', 1, config, 'keyinfo')
        for o in objects:
            if checkObject(places, o):
                writer.writerow([o[x] for x in [0, 2, 3, 4, 5, 6, 7, 9]])
    sys.stdout.flush()
    sys.stdout.close()


def doBarCodes(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    action = form.get('action')
    if not validateParameters(form, config): return

    if action == "Create Labels for Locations Only":
        print getHeader('barcodeprintlocations')
    else:
        print getHeader(updateType)

    totalobjects = 0
    #If the museum number field has input, print by object
    if form.get('ob.objectnumber') != '':
        try:
            # we need 3 elements at the beginning which writeCommanderFile will ignore
            obj = ['', '', ''] + cswaDB.getobjinfo(form.get('ob.objectnumber'), config)
            totalobjects = 1
            rowcount = 1
        except:
            raise
            handleTimeout(updateType, form)
            #obj = [-1, -1, '(null)', '(null)', '(null)']
        if action == 'Create Labels for Objects':
            labelFilename = writeCommanderFile(obj[3], form.get("printer"), 'objectLabels', 'objects', [obj, ], config)
            print '<tr><td>%s</td><td>%s</td><tr><td colspan="4"><i>%s</i></td></tr>' % (obj[3], 1, labelFilename)

    else:
        try:
            #If no end location, assume single location
            if form.get("lo.location2"):
                rows = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location2"), 500, config)
            else:
                rows = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location1"), 500, config)
        except:
            raise
            handleTimeout(updateType, form)
            rows = []

        rowcount = len(rows)

        objectsHandled = []
        rows.reverse()
        if action == "Create Labels for Locations Only":
            labelFilename = writeCommanderFile('locations', form.get("printer"), 'locationLabels', 'locations', rows,
                                               config)
            print '<tr><td>%s</td><td colspan="4"><i>%s</i></td></tr>' % (len(rows), labelFilename)
            print "\n</table>"
            return
        else:
            for r in rows:
                objects = cswaDB.getlocations(r[0], '', 1, config, updateType)
                for o in objects:
                    if o[3] + o[4] in objectsHandled:
                        objects.remove(o)
                        print '<tr><td>already printed a label for</td><td>%s</td><td>%s</td><td/></tr>' % (o[3], o[4])
                    else:
                        objectsHandled.append(o[3] + o[4])
                totalobjects += len(objects)
                # hack: move the ethnographic file code to the right spot for this app... :-(
                objects = [o[0:8] + [o[9]] for o in objects]
                labelFilename = writeCommanderFile(r[0], form.get("printer"), 'objectLabels', 'objects', objects,
                                                   config)
                print '<tr><td>%s</td><td>%s</td><tr><td colspan="4"><i>%s</i></td></tr>' % (
                    r[0], len(objects), labelFilename)

    print """<tr><td align="center" colspan="4"><hr/><td></tr>"""
    print """<tr><td align="center" colspan="4">"""
    if totalobjects != 0:
        print "<b>%s object(s)</b> found in %s locations." % (totalobjects, rowcount)
    else:
        print '<span class="save">No objects found in this range.</span>'

    print "\n</td></tr></table><hr/>"


def doAdvancedSearch(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    groupby = form.get('groupby')

    if not validateParameters(form, config): return

    # yes, I know, it does look a bit odd...
    rare = []
    if form.get('rare'):    rare.append('true')
    if form.get('notrare'): rare.append('false')
    dead = []
    if form.get('dead'):    dead.append('true')
    if form.get('alive'):   dead.append('false')

    beds = [form.get(i) for i in form if 'locations.' in i]
    taxa = [form.get(i) for i in form if 'taxon.' in i]
    places = [form.get(i) for i in form if 'places.' in i]

    #taxa: column = 1
    #family: column = 2
    #beds: column = 3
    #place: column = 5

    try:
        objects = cswaDB.getplants('', '', 1, config, 'getalltaxa')
    except:
        raise
        handleTimeout('getalltaxa', form)
        objects = []

    print getHeader(updateType)
    totalobjects = 0
    accessions = []
    for t in objects:
        if checkMembership(t[1], taxa) and checkMembership(t[3], beds) and checkMembership(t[5],
                                                                                           places) and checkMembership(
                t[7], rare) and checkMembership(t[8], dead):
            print formatRow({'rowtype': updateType, 'data': t}, form, config)

    print """</table><table>"""
    print """<tr><td align="center">&nbsp;</tr>"""
    print """<tr><td align="center"><hr></tr>"""
    print """<tr><td align="center">Report completed. %s objects displayed</td></tr>""" % (len(accessions))
    print "\n</table><hr/>"


def checkMembership(item, qlist):
    if item in qlist or qlist == []:
        return True
    else:
        return False


def doBedList(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    groupby = form.get('groupby')

    if not validateParameters(form, config): return

    # yes, I know, it does look a bit odd...
    rare = []
    if form.get('rare'):    rare.append('true')
    if form.get('notrare'): rare.append('false')
    dead = []
    if form.get('dead'):    dead.append('true')
    if form.get('alive'):   dead.append('false')

    if updateType == 'bedlist':
        rows = [form.get(i) for i in form if 'locations.' in i]
    # currently, the location report does not call this function. but it might...
    elif updateType == 'locreport':
        rows = [form.get(i) for i in form if 'taxon.' in i]

    rowcount = len(rows)
    totalobjects = 0
    if groupby == 'none':
        print getHeader(updateType + groupby)
    else:
        print '<table>'
    rows.sort()
    for headerid, l in enumerate(rows):

        try:
            objects = cswaDB.getplants(l, '', 1, config, updateType)
        except:
            raise
            handleTimeout('getplants', form)
            objects = []

        if groupby == 'none':
            pass
        else:
            if len(objects) == 0:
                #print '<tr><td colspan="6">No objects found at this location.</td></tr>'
                pass
            else:
                print formatRow({'rowtype': 'subheader', 'data': [l, ]}, form, config)
                print '<tr><td colspan="6">'
                print getHeader(updateType + groupby if groupby == 'none' else updateType) % headerid

        for r in objects:
            #print "<tr><td>%s<td>%s</tr>" % (len(places),r[6])
            #if checkObject(places,r):
            #if checkMembership(t[7],rare) and checkMembership(t[8],dead):
            if True:
                totalobjects += 1
                print formatRow({'rowtype': updateType, 'data': r}, form, config)

        if groupby == 'none':
            pass
        else:
            if len(objects) == 0:
                pass
            else:
                print '</tbody></table></td></tr>'
                #print """<tr><td align="center" colspan="6">&nbsp;</tr>"""

    if groupby == 'none':
        print "\n</tbody></table>"
    else:
        print '</table>'
    print """<table><tr><td align="center"><hr></tr>"""
    print """<tr><td align="center">Bed List completed. %s objects, %s locations</td></tr>""" % (
        totalobjects, len(rows))
    print "\n</table><hr/>"


def doHierarchyView(form, config):
    query = form.get('authority')
    res = cswaDB.gethierarchy(query, config)
    print '<div id="tree"></div>\n<script>'
    lookup = {concept.PARENT: concept.PARENT}
    for row in res:
        prettyName = row[0].replace('"', "'")
        if prettyName[0] == '@':
            prettyName = '<' + prettyName[1:] + '>'
        lookup[row[2]] = prettyName
    print '''var data = ['''
    #print concept.buildJSON(concept.buildConceptDict(res), 0, lookup)
    res = concept.buildJSON(concept.buildConceptDict(res), 0, lookup)
    print re.sub(r'\n    { label: "(.*?)"},', r'''\n    { label: "no parent >> \1"},''', res)
    print '];'
    print """$(function() {
    $('#tree').tree({
        data: data,
        autoOpen: true,
        useContextMenu: false,
        selectable: false
    });
});</script>"""
    #print "\n</table><hr/>"
    print "\n<hr>"


def writeCommanderFile(location, printerDir, dataType, filenameinfo, data, config):
    auditFile = config.get('files', 'cmdrauditfile')
    # slugify the location
    slug = re.sub('[^\w-]+', '_', location).strip().lower()
    barcodeFile = config.get('files', 'cmdrfmtstring') % (
        config.get('files', 'cmdrfileprefix'), dataType, printerDir, slug,
        datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S"), filenameinfo)

    try:
        barcodeFh = codecs.open(barcodeFile, 'w', 'utf-8-sig')
        alogFh = codecs.open(auditFile, 'a', 'utf-8')
        csvlogfh = csv.writer(barcodeFh, delimiter=",", quoting=csv.QUOTE_ALL)
        audlogfh = csv.writer(alogFh, delimiter=",", quoting=csv.QUOTE_ALL)
        if dataType == 'locationLabels':
            csvlogfh.writerow('termdisplayname'.split(','))
            for d in data:
                csvlogfh.writerow((d[0],))  # writerow needs a tuple or array
                audlogfh.writerow(d)
        elif dataType == 'objectLabels':
            csvlogfh.writerow(
                'MuseumNumber,ObjectName,PieceCount,FieldCollectionPlace,AssociatedCulture,EthnographicFileCode'.split(
                    ','))
            for d in data:
                csvlogfh.writerow(d[3:9])
                audlogfh.writerow(d)
        barcodeFh.close()
        alogFh.close()
        newName = barcodeFile.replace('.tmp', '.txt')
        os.rename(barcodeFile, newName)
    except:
        #raise
        newName = '<span style="color:red;">could not write to %s</span>' % barcodeFile

    return newName


def writeLog(updateItems, config):
    auditFile = config.get('files', 'auditfile')
    myPid = str(os.getpid())
    # writing of individual log files is now disabled. audit file contains the same data.
    #logFile = config.get('files','logfileprefix') + '.' + datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S") + myPid + '.csv'

    # yes, it is inefficient open the log to write each row, but in the big picture, it's insignificant
    try:
        #csvlogfh = csv.writer(codecs.open(logFile,'a','utf-8'), delimiter="\t")
        #csvlogfh.writerow([updateItems['locationDate'],updateItems['objectNumber'],updateItems['objectStatus'],updateItems['subjectCsid'],updateItems['objectCsid'],updateItems['handlerRefName']])
        csvlogfh = csv.writer(codecs.open(auditFile, 'a', 'utf-8'), delimiter="\t")
        csvlogfh.writerow([updateItems['locationDate'], updateItems['objectNumber'], updateItems['objectStatus'],
                           updateItems['subjectCsid'], updateItems['objectCsid'], updateItems['handlerRefName']])
    except:
        print 'log failed!'
        pass


def writeInfo2log(request, form, config, elapsedtime):
    checkServer = form.get('check')
    location1 = str(form.get("lo.location1"))
    location2 = str(form.get("lo.location2"))
    action = str(form.get("action"))
    serverlabel = config.get('info', 'serverlabel')
    apptitle = config.get('info', 'apptitle')
    updateType = config.get('info', 'updatetype')
    checkServer = form.get('check')
    # override updateType if we are just checking the server
    if checkServer == 'check server':
        updateType = checkServer
    sys.stderr.write('%-13s:: %-18s:: %-6s::%8.2f :: %-15s :: %s :: %s\n' % (
        updateType, action, request, elapsedtime, serverlabel, location1, location2))


def uploadFile(actualform, config):
    barcodedir = config.get('files', 'barcodedir')
    barcodeprefix = config.get('files', 'barcodeprefix')
    #print form
    # we are using <form enctype="multipart/form-data"...>, so the file contents are now in the FieldStorage.
    # we just need to save it somewhere...
    fileitem = actualform['file']

    # Test if the file was uploaded
    if fileitem.filename:

        # strip leading path from file name to avoid directory traversal attacks
        fn = os.path.basename(fileitem.filename)
        open(barcodedir + '/' + barcodeprefix + '.' + fn, 'wb').write(fileitem.file.read())
        os.chmod(barcodedir + '/' + barcodeprefix + '.' + fn, 0666)
        message = fn + ' was uploaded successfully'
    else:
        message = 'No file was uploaded'

    print "<h3>%s</h3>" % message


def viewLog(form, config):
    num2ret = int(form.get('num2ret')) if str(form.get('num2ret')).isdigit() else 100

    print '<table width="100%">\n'
    print ('<tr>' + (4 * '<th class="ncell">%s</td>') + '</tr>\n') % (
        'locationDate', 'objectNumber', 'objectStatus', 'handler')
    try:
        auditFile = config.get('files', 'auditfile')
        file_handle = open(auditFile)
        file_size = file_handle.tell()
        file_handle.seek(max(file_size - 9 * 1024, 0))

        lastn = file_handle.read().splitlines()[-num2ret:]
        for i in lastn:
            i = i.replace('urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name', '')
            line = ''
            if i[0] == '#': continue
            for l in [i.split('\t')[x] for x in [0, 1, 2, 5]]: line += ('<td>%s</td>' % l)
            #for l in i.split('\t') : line += ('<td>%s</td>' % l)
            print '<tr>' + line + '</tr>'

    except:
        print '<tr><td colspan="4">failed. sorry.</td></tr>'

    print '</table>'


def OldalreadyExists(txt, elements):
    for e in elements:
        if txt == str(e.text):
            #print "    found,skipping: ",txt
            return True
    return False


def alreadyExists(txt, element):
    if element == []: return False
    # only examine first (preferred) element
    if type(element) == type([]):
        element = element[0]
    if txt == str(element.text):
        #print "    found,skipping: ",txt
        return True
    return False


def updateKeyInfo(fieldset, updateItems, config):
    realm = config.get('connect', 'realm')
    hostname = config.get('connect', 'hostname')
    username = config.get('connect', 'username')
    password = config.get('connect', 'password')

    uri = 'collectionobjects'
    getItems = updateItems['objectCsid']

    #Fields vary with fieldsets
    if fieldset == 'keyinfo':
        fields = ('pahmaFieldCollectionPlace', 'assocPeople', 'objectName', 'pahmaEthnographicFileCode')
    elif fieldset == 'namedesc':
        fields = ('briefDescription', 'objectName')
    elif fieldset == 'registration':
        # nb:  'pahmaAltNumType' is handle with  'pahmaAltNum'
        fields = ('objectName', 'pahmaAltNum', 'fieldCollector')

    # get the XML for this object
    url, content, elapsedtime = getxml(uri, realm, hostname, username, password, getItems)
    root = etree.fromstring(content)
    # add the user's changes to the XML
    for relationType in fields:
        # skip if no refName was provided to update
        list = 'List'
        extra = ''
        if updateItems[relationType] == '':
            continue
        if relationType == 'assocPeople' or relationType == 'pahmaAltNum':
            extra = 'Group'
        elif relationType in ['briefDescription', 'fieldCollector']:
            list = 's'
        else:
            pass
            #print ">>> ",'.//'+relationType+extra+'List'
        sys.stderr.write('tag: ' + relationType + extra + list)
        metadata = root.findall('.//' + relationType + extra + list)
        metadata = metadata[0] # there had better be only one!
        # check if value is already present. if so, skip
        #print(etree.tostring(metadata))
        #print ">>> ",relationType,':',updateItems[relationType]
        if relationType in ['assocPeople', 'objectName', 'pahmaAltNum']:
            #group = metadata.findall('.//'+relationType+'Group')
            if not alreadyExists(updateItems[relationType], metadata.findall('.//' + relationType)):
                newElement = etree.Element(relationType + 'Group')
                leafElement = etree.Element(relationType)
                leafElement.text = updateItems[relationType]
                newElement.append(leafElement)
                if relationType in ['assocPeople', 'pahmaAltNum']:
                    apgType = etree.Element(relationType + 'Type')
                    apgType.text = updateItems[relationType + 'Type'] if relationType == 'pahmaAltNum' else 'made by'
                    newElement.append(apgType)
                metadata.insert(0, newElement)
        elif relationType in ['briefDescription', 'fieldCollector']:
            firstEntry = metadata.findall('.//' + relationType)
            firstEntry[0].text = updateItems[relationType]
        else:
            if alreadyExists(updateItems[relationType], metadata.findall('.//' + relationType)): continue
            newElement = etree.Element(relationType)
            newElement.text = updateItems[relationType]
            metadata.insert(0, newElement)
            #print(etree.tostring(metadata, pretty_print=True))
    objectCount = root.find('.//numberOfObjects')
    if 'objectCount' in updateItems:
        if objectCount is None:
            objectCount = etree.Element('numberOfObjects')
            collectionobjects_common = root.find(
                './/{http://collectionspace.org/services/collectionobject}collectionobjects_common')
            collectionobjects_common.insert(0, objectCount)
        objectCount.text = updateItems['objectCount']
    #print(etree.tostring(root, pretty_print=True))

    uri = 'collectionobjects' + '/' + updateItems['objectCsid']
    payload = '<?xml version="1.0" encoding="UTF-8"?>\n' + etree.tostring(root)
    # update collectionobject..
    #print "<br>pretending to post update to %s to REST API..." % updateItems['objectCsid']
    (url, data, csid, elapsedtime) = postxml('PUT', uri, realm, hostname, username, password, payload)

    #print "<h3>Done w update!</h3>"


def updateLocations(updateItems, config):
    realm = config.get('connect', 'realm')
    hostname = config.get('connect', 'hostname')
    username = config.get('connect', 'username')
    password = config.get('connect', 'password')

    uri = 'movements'

    #print "<br>posting to movements REST API..."
    payload = lmiPayload(updateItems)
    (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)
    updateItems['subjectCsid'] = csid

    uri = 'relations'

    #print "<br>posting inv2obj to relations REST API..."
    updateItems['subjectDocumentType'] = 'Movement'
    updateItems['objectDocumentType'] = 'CollectionObject'
    payload = relationsPayload(updateItems)
    (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)

    # reverse the roles
    #print "<br>posting obj2inv to relations REST API..."
    temp = updateItems['objectCsid']
    updateItems['objectCsid'] = updateItems['subjectCsid']
    updateItems['subjectCsid'] = temp
    updateItems['subjectDocumentType'] = 'CollectionObject'
    updateItems['objectDocumentType'] = 'Movement'
    payload = relationsPayload(updateItems)
    (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)

    #print "<h3>Done w update!</h3>"


def formatRow(result, form, config):
    hostname = config.get('connect', 'hostname')
    rr = result['data']
    rr = [x if x != None else '' for x in rr]

    if result['rowtype'] == 'subheader':
        #return """<tr><td colspan="4" class="subheader">%s</td><td>%s</td></tr>""" % result['data'][0:1]
        return """<tr><td colspan="7" class="subheader">%s</td></tr>""" % result['data'][0]
    elif result['rowtype'] == 'location':
        return '''<tr><td class="objno"><a href="#" onclick="formSubmit('%s')">%s</a></td><td/></tr>''' % (
            result['data'][0], result['data'][0])
    elif result['rowtype'] == 'select':
        rr = result['data']
        boxType = result['boxtype']
        return '''<li class="xspan"><input type="checkbox" name="%s.%s" value="%s" checked> <a href="#" onclick="formSubmit('%s')">%s</a></li>''' % (
            (boxType,) + (rr[0],) * 4)
        #return '''<tr><td class="xspan"><input type="checkbox" name="%s.%s" value="%s" checked> <a href="#" onclick="formSubmit('%s')">%s</a></td><td/></tr>''' % ((boxType,) + (rr[0],) * 4)
    elif result['rowtype'] == 'bedlist':
        groupby = str(form.get("groupby"))
        link = 'http://' + hostname + ':8180/collectionspace/ui/botgarden/html/cataloging.html?csid=%s' % rr[7]
        if groupby == 'none':
            location = '<td>%s</td>' % rr[0]
        else:
            location = ''
            # 3 recordstatus | 4 Accession number | 5 Determination | 6 Family | 7 object csid
        #### 3 Accession number | 4 Data quality | 5 Taxonomic name | 6 Family | 7 object csid 
        return '''<tr><td class="objno"><a target="cspace" href="%s">%s</a</td><td>%s</td><td>%s</td>%s</tr>''' % (
            link, rr[4], rr[6], rr[5], location)
    elif result['rowtype'] == 'locreport' or result['rowtype'] == 'holdings' or result['rowtype'] == 'advsearch':
        rare = 'Yes' if rr[7] == 'true' else 'No'
        dead = 'Yes' if rr[8] == 'true' else 'No'
        link = 'http://' + hostname + ':8180/collectionspace/ui/botgarden/html/cataloging.html?csid=%s' % rr[6]
        #  0 objectnumber, 1 determination, 2 family, 3 gardenlocation, 4 dataQuality, 5 locality, 6 csid, 7 rare , 8 dead , 9 determination (no author)
        return '''<tr><td><a target="cspace" href="%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>''' % (
            link, rr[0], rr[1], rr[2], rr[3], rr[5], rare, dead)
    elif result['rowtype'] == 'was.advsearch':
        link = 'http://' + hostname + ':8180/collectionspace/ui/botgarden/html/cataloging.html?csid=%s' % rr[7]
        # 3 recordstatus | 4 Accession number | 5 Determination | 6 Family | 7 object csid
        #### 3 Accession number | 4 Data quality | 5 Taxonomic name | 6 Family | 7 object csid
        return '''<tr><td class="objno"><a target="cspace" href="%s">%s</a</td><td>%s</td><td>%s</td><td>%s</td></tr>''' % (
            link, rr[4], rr[3], rr[5], rr[6])
    elif result['rowtype'] == 'inventory':
        link = 'http://' + hostname + ':8180/collectionspace/ui/pahma/html/cataloging.html?csid=%s' % rr[8]
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objcount 4 | objname 5| movecsid 6 | locrefname 7 | objcsid 8 | objrefname 9
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return """<tr><td class="objno"><a target="cspace" href="%s">%s</a></td><td class="objname">%s</td><td class="rdo" ><input type="radio" name="r.%s" value="found|%s|%s|%s|%s|%s" checked></td><td class="rdo" ><input type="radio" name="r.%s" value="not found|%s|%s|%s|%s|%s"></td><td><input class="xspan" type="text" size="65" name="n.%s"></td></tr>""" % (
            link, rr[3], rr[5], rr[3], rr[8], rr[7], rr[6], rr[3], rr[14], rr[3], rr[8], rr[7], rr[6], rr[3], rr[14],
            rr[3])
    elif result['rowtype'] == 'moveobject':
        link = 'http://' + hostname + ':8180/collectionspace/ui/pahma/html/cataloging.html?csid=%s' % rr[8]
        # 0 storageLocation | 1 lockey | 2 locdate | 3 objectnumber | 4 objectName | 5 objectCount | 6 fieldcollectionplace | 7 culturalgroup |
        # 8 objectCsid | 9 ethnographicfilecode | 10 fcpRefName | 11 cgRefName | 12 efcRefName | 13 computedcraterefname | 14 computedcrate
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return """<tr><td class="rdo" ><input type="checkbox" name="r.%s" value="moved|%s|%s|%s|%s|%s" checked></td><td class="objno"><a target="cspace" href="%s">%s</a></td><td class="objname">%s</td><td>%s</td><td>%s</td></tr>""" % (
            rr[3], rr[8], rr[1], '', rr[3], rr[13], link, rr[3], rr[4], rr[5], rr[0])
    elif result['rowtype'] == 'keyinfo' or result['rowtype'] == 'objinfo':
        link = 'http://' + hostname + ':8180/collectionspace/ui/pahma/html/cataloging.html?csid=%s' % rr[8]
        link2 = 'http://' + hostname + ':8180/collectionspace/ui/pahma/html/acquisition.html?csid=%s' % rr[24]
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objname 4 | objcount 5| fieldcollectionplace 6 | culturalgroup 7 | objcsid 8 | ethnographicfilecode 9
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return formatInfoReviewRow(form, link, rr, link2)
    elif result['rowtype'] == 'packinglist':
        link = 'http://' + hostname + ':8180/collectionspace/ui/pahma/html/cataloging.html?csid=%s' % rr[8]
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objname 4 | objcount 5| fieldcollectionplace 6 | culturalgroup 7 | objcsid 8 | ethnographicfilecode 9
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname" name="onm.%s">%s</td>
<td class="xspan" name="ocn.%s">%s</td>
<td class="xspan" name="cp.%s">%s</td>
<td class="xspan" name="cg.%s">%s</td>
<td class="xspan" name="fc.%s">%s</td>
<td><input type="checkbox"></td>
</tr>""" % (link, rr[3], rr[8], rr[4], rr[8], rr[5], rr[8], rr[6], rr[8], rr[7], rr[8], rr[9])

    elif result['rowtype'] == 'packinglistbyculture':
        link = 'http://' + hostname + ':8180/collectionspace/ui/pahma/html/cataloging.html?csid=%s' % rr[8]
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objname 4 | objcount 5| fieldcollectionplace 6 | culturalgroup 7x | objcsid 8 | ethnographicfilecode 9x
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname" name="onm.%s">%s</td>
<td class="xspan" name="ocn.%s">%s</td>
<td class="xspan">%s</td>
<td class="xspan" name="fc.%s">%s</td>
<td><input type="checkbox"></td>
</tr>""" % (link, rr[3], rr[8], rr[4], rr[8], rr[5], rr[7], rr[8], rr[6])


def formatInfoReviewRow(form, link, rr, link2):
    """[0 Location, 1 Location Key, 2 Timestamp, 3 Museum Number, 4 Name, 5 Count, 6 Collection Place, 7 Culture, 8 csid,
        9 Ethnographic File Code, 10 Place Ref Name, 11 Culture Ref Name, 12 Ethnographic File Code Ref Name, 13 Crate Ref Name,
        14 Computed Crate 15 Description, 16 Collector, 17 Donor, 18 Alt Num, 19 Alt Num Type, 20 Collector Ref Name,
        21 Accession Number, 22 Donor Ref Name, 23 Acquisition ID, 24 Acquisition CSID]"""
    fieldSet = form.get("fieldset")
    if fieldSet == 'namedesc':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname">
<input class="objname" type="text" name="onm.%s" value="%s">
</td>
<td width="0"></td>
<td>
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<textarea cols="78" rows="1" name="bdx.%s">%s</textarea></td>
<td><input type="checkbox"></td>
</tr>""" % (link, cgi.escape(rr[3], True), rr[8], cgi.escape(rr[4], True), rr[8], cgi.escape(rr[3], True), rr[8], rr[8],
            rr[8], cgi.escape(rr[15], True))
    elif fieldSet == 'registration':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname">
<input class="objname" type="text" name="onm.%s" value="%s">
</td>
<td>
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<input class="xspan" type="text" size="13" name="anm.%s" value="%s"></td>
<td><input class="xspan" type="text" size="13" name="ant.%s" value="%s"></td>
<td><input class="xspan" type="text" size="26" name="pc.%s" value="%s"></td>
<td><span style="font-size:8">%s</span></td>
<td><a target="cspace" href="%s">%s</a></td>
<td><input type="checkbox"></td>
</tr>""" % (link, cgi.escape(rr[3], True), rr[8], cgi.escape(rr[4], True), rr[8], cgi.escape(rr[3], True), rr[8], rr[8],
            rr[8], cgi.escape(rr[18], True), rr[8], cgi.escape(rr[19], True), rr[8], cgi.escape(rr[16], True),
            cgi.escape(rr[17], True), link2, cgi.escape(rr[21], True))
    elif fieldSet == 'keyinfo':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname">
<input class="objname" type="text" name="onm.%s" value="%s">
</td>
<td class="veryshortinput">
<input class="veryshortinput" type="text" name="ocn.%s" value="%s">
</td>
<td>
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<input class="xspan" type="text" size="26" name="cp.%s" value="%s"></td>
<td><input class="xspan" type="text" size="26" name="cg.%s" value="%s"></td>
<td><input class="xspan" type="text" size="26" name="fc.%s" value="%s"></td>
<td><input type="checkbox"></td>
</tr>""" % (link, cgi.escape(rr[3], True), rr[8], cgi.escape(rr[4], True), rr[8], rr[5], rr[8], cgi.escape(rr[3], True),
            rr[8],
            rr[8], rr[8], cgi.escape(rr[6], True), rr[8], cgi.escape(rr[7], True), rr[8], cgi.escape(rr[9], True))


def formatError(cspaceObject):
    return '<tr><th colspan="2" class="leftjust">%s</th><td></td><td>None found.</td></tr>\n' % (cspaceObject)


def getxml(uri, realm, hostname, username, password, getItems):
    server = "http://" + hostname + ":8180"
    passman = urllib2.HTTPPasswordMgr()
    passman.add_password(realm, server, username, password)
    authhandler = urllib2.HTTPBasicAuthHandler(passman)
    opener = urllib2.build_opener(authhandler)
    urllib2.install_opener(opener)
    if getItems == None: getItems = ''
    url = "%s/cspace-services/%s/%s" % (server, uri, getItems)
    elapsedtime = 0.0

    try:
        elapsedtime = time.time()
        f = urllib2.urlopen(url)
        data = f.read()
        elapsedtime = time.time() - elapsedtime
    except urllib2.HTTPError, e:
        print 'The server couldn\'t fulfill the request.'
        print 'Error code: ', e.code
        raise
    except urllib2.URLError, e:
        print 'We failed to reach a server.'
        print 'Reason: ', e.reason
        raise
    else:
        return (url, data, elapsedtime)

        #data = "\n<h3>%s :: %s</h3>" % e


def postxml(requestType, uri, realm, hostname, username, password, payload):
    server = "http://" + hostname + ":8180"
    passman = urllib2.HTTPPasswordMgr()
    passman.add_password(realm, server, username, password)
    authhandler = urllib2.HTTPBasicAuthHandler(passman)
    opener = urllib2.build_opener(authhandler)
    urllib2.install_opener(opener)
    url = "%s/cspace-services/%s" % (server, uri)
    elapsedtime = 0.0

    elapsedtime = time.time()
    request = urllib2.Request(url, payload, {'Content-Type': 'application/xml'})
    # default method for urllib2 with payload is POST
    if requestType == 'PUT': request.get_method = lambda: 'PUT'
    try:
        f = urllib2.urlopen(request)
    except urllib2.URLError, e:
        if hasattr(e, 'reason'):
            sys.stderr.write('We failed to reach a server.\n')
            sys.stderr.write('Reason: ' + str(e.reason) + '\n')
        elif hasattr(e, 'code'):
            sys.stderr.write('The server couldn\'t fulfill the request.\n')
            sys.stderr.write('Error code: ' + str(e.code) + '\n')
        elif True:
            #print 'Error in POSTing!'
            print request
            raise
            sys.stderr.write("Error in POSTing!\n")
            sys.stderr.write(url)
            #sys.stderr.write(payload)
            #print url
        #print payload
    #raise
    data = f.read()
    info = f.info()
    # if a POST, the Location element contains the new CSID
    if info.getheader('Location'):
        csid = re.search(uri + '/(.*)', info.getheader('Location'))
        csid = csid.group(1)
    else:
        csid = ''
    elapsedtime = time.time() - elapsedtime
    return (url, data, csid, elapsedtime)


def getHandlers(form):
    selected = form.get('handlerRefName')
    handlerlist = [ \
        ("Victoria Bradshaw",
         "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7267)'Victoria Bradshaw'"),
        ("Thusa Chu", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7654)'Thusa Chu'"),
        ("Alicja Egbert",
         "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(8683)'Alicja Egbert'"),
        ("Madeleine Fang",
         "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7248)'Madeleine W. Fang'"),
        ("Leslie Freund",
         "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7475)'Leslie Freund'"),
        ("Rowan Gard",
         "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(RowanGard1342219780674)'Rowan Gard'"),
        ("Natasha Johnson",
         "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7652)'Natasha Johnson'"),
        ("Allison Lewis",
         "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(8724)'Allison Lewis'"),
        ("Corri MacEwen",
         "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(9090)'Corri MacEwen'"),
        ("Jon Oligmueller",
         "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(JonOligmueller1372192617217)'Jon Oligmueller'"),
        ("Martina Smith",
         "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(9034)'Martina Smith'"),
        ("Linda Waterfield",
         "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(LindaWaterfield1358535276741)'Linda Waterfield'"),
        ("Jane Williams",
         "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7420)'Jane L. Williams'")
    ]

    handlers = '''
          <select class="cell" name="handlerRefName">
              <option value="None">Select a handler</option>'''

    for handler in handlerlist:
        #print handler
        handlerOption = """<option value="%s">%s</option>""" % (handler[1], handler[0])
        #print "xxxx",selected
        if selected and str(selected) == handler[1]:
            handlerOption = handlerOption.replace('option', 'option selected')
        handlers = handlers + handlerOption

    handlers = handlers + '\n      </select>'
    return handlers, selected


def getReasons(form):
    reason = form.get('reason')

    reasons = '''
<select class="cell" name="reason">
<option value="None">(none selected)</option>
<option value="(not entered)">(not entered)</option>
<option value="Inventory">Inventory</option>
<option value="GeneralCollManagement">General Collections Management</option>
<option value="Research">Research</option>
<option value="NAGPRA">NAGPRA</option>
<option value="pershelflabel">per shelf label</option>
<option value="NewHomeLocation">New Home Location</option>
<option value="Loan">Loan</option>
<option value="Exhibit">Exhibit</option>
<option value="ClassUse">Class Use</option>
<option value="PhotoRequest">Photo Request</option>
<option value="Tour">Tour</option>
<option value="Conservation">Conservation</option>
<option value="CulturalHeritage">cultural heritage</option>
<option value="">----------------------------</option>
<option value="2012 HGB surge pre-move inventory">2012 HGB surge pre-move inventory</option>
<option value="AsianTextileGrant">Asian Textile Grant</option>
<option value="BasketryRehousingProj">Basketry Rehousing Proj</option>
<option value="BORProj">BOR Proj</option>
<option value="BuildingMaintenance">Building Maintenance: Seismic</option>
<option value="CaliforniaArchaeologyProj">California Archaeology Proj</option>
<option value="CatNumIssueInvestigation">Cat. No. Issue Investigation</option>
<option value="DuctCleaningProj">Duct Cleaning Proj</option>
<option value="FederalCurationAct">Federal Curation Act</option>
<option value="FireAlarmProj">Fire Alarm Proj</option>
<option value="FirstTimeStorage">First Time Storage</option>
<option value="FoundinColl">Found in Collections</option>
<option value="HearstGymBasementMoveKroeber20">Hearst Gym Basement move to Kroeber 20A</option>
<option value="HGB Surge">HGB Surge</option>
<option value="Kro20MezzLWeaponProj2011">Kro20Mezz LWeapon Proj 2011</option>
<option value="Kroeber20AMoveRegatta">Kroeber 20A move to Regatta</option>
<option value="MarchantFlood2007">Marchant Flood 12/2007</option>
<option value="NAAGVisit">Native Am Adv Grp Visit</option>
<option value="NEHEgyptianCollectionGrant">NEH Egyptian Collection Grant</option>
<option value="Regattamovein">Regatta move-in</option>
<option value="Regattapremoveinventory">Regatta pre-move inventory</option>
<option value="Regattapremoveobjectprep">Regatta pre-move object prep.</option>
<option value="Regattapremovestaging">Regatta pre-move staging</option>
<option value="SATgrant">SAT grant</option>
<option value="TemporaryStorage">Temporary Storage</option>
<option value="TextileRehousingProj">Textile Rehousing Proj</option>
<option value="YorubaMLNGrant">Yoruba MLN Grant</option>
</select>
'''
    reasons = reasons.replace(('option value="%s"' % reason), ('option selected value="%s"' % reason))
    return reasons, reason


def getPrinters(form):
    selected = form.get('printer')

    printerlist = [ \
        ("Kroeber Hall", "kroeberBCP"),
        ("Regatta Building", "regattaBCP")
    ]

    printers = '''
          <select class="cell" name="printer">
              <option value="None">Select a printer</option>'''

    for printer in printerlist:
        printerOption = """<option value="%s">%s</option>""" % (printer[1], printer[0])
        if selected and str(selected) == printer[1]:
            printerOption = printerOption.replace('option', 'option selected')
        printers = printers + printerOption

    printers + '\n      </select>'
    return printers, selected


def getFieldset(form):
    selected = form.get('fieldset')

    fields = [ \
        ("Key Info", "keyinfo"),
        ("Name & Desc.", "namedesc"),
        ("Registration", "registration")
    ]

    fieldset = '''
          <select class="cell" name="fieldset">'''

    for field in fields:
        fieldsetOption = """<option value="%s">%s</option>""" % (field[1], field[0])
        if selected and str(selected) == field[1]:
            fieldsetOption = fieldsetOption.replace('option', 'option selected')
        fieldset = fieldset + fieldsetOption

    fieldset += '\n      </select>'
    return fieldset, selected


def getHierarchies(form):
    selected = form.get('authority')

    authoritylist = [ \
        ("Ethnographic Culture", "concept"),
        ("Places", "places"),
        ("Archaeological Culture", "archculture"),
        ("Ethnographic File Codes", "ethusecode"),
        ("Materials", "material_ca")
    ]

    authorities = '''
<select class="cell" name="authority">
<option value="None">Select an authority</option>'''

    #sys.stderr.write('selected %s\n' % selected)
    for authority in authoritylist:
        authorityOption = """<option value="%s">%s</option>""" % (authority[1], authority[0])
        #sys.stderr.write('check hierarchy %s %s\n' % (authority[1], authority[0]))
        if selected == authority[1]:
            #sys.stderr.write('found hierarchy %s %s\n' % (authority[1], authority[0]))
            authorityOption = authorityOption.replace('option', 'option selected')
        authorities = authorities + authorityOption

    authorities + '\n </select>'
    return authorities, selected


def selectWebapp():
    files = os.listdir(".")

    programName = os.path.basename(__file__).replace('Utils', 'Main') + '?webapp=' # yes, this is fragile!
    apptitles = {}
    serverlabels = {}
    badconfigfiles = ''
    for f in files:
        if '.cfg' in f:
            config = ConfigParser.RawConfigParser()
            config.read(f)
            try:
                configfile = f.replace('.cfg', '')
                logo = config.get('info', 'logo')
                updateType = config.get('info', 'updatetype')
                schemacolor1 = config.get('info', 'schemacolor1')
                serverlabel = config.get('info', 'serverlabel')
                serverlabelcolor = config.get('info', 'serverlabelcolor')
                serverlabels[f] = '<span style="color:%s;"><a target="%s" href="%s">%s</a></span>' % (
                    serverlabelcolor, serverlabel, programName + configfile, configfile)
                apptitles[updateType] = config.get('info', 'apptitle')
            except:
                badconfigfiles += '<tr><td>%s</td></tr>' % f

    webapps = {
        'pahma': ['inventory', 'keyinfo', 'objinfo', 'objdetails', 'moveobject', 'packinglist', 'movecrate', 'upload', \
                  'barcodeprint', 'hierarchyViewer', 'collectionStats'],
        'ucbg': ['ucbgAccessions', 'ucbgAdvancedSearch', 'ucbgBedList', 'ucbgLocationReport', 'ucbgCollHoldings'],
        'ucjeps': ['ucjepsLocationReport']}

    #exceptions = { "barcodeprint": "BarcodePrint",
    #               "upload": "BarcodeUpload",
    #               "keyinfo": "KeyInfoRev",
    #               "packlist": "PackingList",
    #               "sysinv": "SystematicInventory" }

    exceptions = {}

    line = '''Content-type: text/html; charset=utf-8


<html><head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">''' + getStyle('lightblue') + '''
<title>Select web app</title>
</head>
<body>
<h1>UC Berkeley CollectionSpace Deployments: Available Webapps</h1><table cellpadding="4px">
<p>The following table lists the webapps available on this server as of ''' + datetime.datetime.utcnow().strftime(
        "%Y-%m-%dT%H:%M:%SZ") + '''.</p>'''

    for museum in webapps:
        line += '<tr><td colspan="6"><h2>%s</h2></td></tr><tr><th>Webpp Name</th><th>App. Abbrev.</th><th>v3.2.x Production</th><th>v3.2.x Dev "Test"</th></tr>\n' % museum
        for webapp in webapps[museum]:
            apptitle = apptitles[webapp] if apptitles.has_key(webapp) else webapp
            line += '<tr><th>%s</th><th>%s</th>' % (apptitle, webapp)
            for sys in ['V321', 'Dev']:
                available = ''
                if webapp in exceptions and sys not in ['Dev', 'V321']:
                    if os.path.isfile(exceptions[webapp] + sys + '.py'):
                        available = '<a target="%s" href="%s">%s</a>' % (
                            sys, exceptions[webapp] + sys + '.py', exceptions[webapp] + sys)
                    elif os.path.isfile(exceptions[webapp] + '.py') and sys == 'Prod':
                        available = '<a target="%s" href="%s">%s</a>' % (
                            sys, exceptions[webapp] + '.py', exceptions[webapp])
                else:
                    available = '<a target="%s" href="%s">%s</a>' % (sys, programName + webapp + sys, webapp + sys)
                if os.path.isfile(webapp + sys + '.cfg'):
                    available = serverlabels[webapp + sys + '.cfg']
                    #available = '<span style="color:%s;"><a target="%s" href="%s">%s</a></span><span style="color:%s;"><a target="%s" href="%s">%s</a></span>' % (sys,programName+webapp+sys,webapp+sys)
                    #''' + apptitle + ' : ' + serverlabel + '''</title>''' + getStyle(schemacolor1) + '''
                else:
                    available = ''
                line += ' <td>%s</td>\n' % available
            line += '</tr>\n'
    if badconfigfiles != '':
        line += '<tr><td colspan="6"><h2>%s</h2></td></tr>' % 'bad config files'
        line += badconfigfiles
    line += '''
</table>
<hr/>
<h4>jblowe@berkeley.edu   7 Feb 2013</h4>
</body>
</html>'''

    return line


def printCollectionStats(form, config):
    writeInfo2log('start', form, config, 0.0)
    logo = config.get('info', 'logo')
    schemacolor1 = config.get('info', 'schemacolor1')
    serverlabel = config.get('info', 'serverlabel')
    serverlabelcolor = config.get('info', 'serverlabelcolor')
    apptitle = config.get('info', 'apptitle')
    updateType = config.get('info', 'updatetype')

    divsize = '''<div id="sidiv" style="position:relative; width:1300px; height:750px; color:black; ">'''

    print '''Content-type: text/html; charset=utf-8

    
<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>''' + apptitle + ' : ' + serverlabel + '''</title>
<style type="text/css">
body { margin:10px 10px 0px 10px; font-family: Arial, Helvetica, sans-serif; }
table { width: 100%; }
td { cell-padding: 3px; }
.stattitle { font-weight: normal; text-align:right; }
.statvalue { font-weight: bold; text-align:left; }
.statvaluecenter { font-weight: bold; text-align:center; }
th { text-align: left ;color: #666666; font-size: 16px; font-weight: bold; cell-padding: 3px;}
h1 { font-size:32px; float:left; padding:10px; margin:0px; border-bottom: none; }
h2 { font-size:12px; float:left; color:white; background:black; }
p { padding:10px 10px 10px 10px; }

button { font-size: 150%; width:85px; text-align: center; text-transform: uppercase;}

.statsection { font-size:21px; font-weight:bold; border-bottom: thin dotted #aaaaaa; color: ''' + schemacolor1 + '''; }
.statheader { font-weight: bold; text-align:center; font-size:medium; }
.stattitle { font-weight: bold; text-align:right; font-size:small; }
.statvalue { font-weight: normal; text-align:left; font-size:x-small; }
.statbignumber { font-weight: bold; text-align:center; font-size:medium; }
.statnumber { font-weight: bold; text-align:right; font-size:x-small; }
.statpct { font-weight: normal; text-align:left; font-size:x-small; }
.objtitle { font-size:28px; float:left; padding:2px; margin:0px; border-bottom: thin dotted #aaaaaa; color: #000000; }
.objsubtitle { font-size:28px; float:left; padding:2px; margin:0px; border-bottom: thin dotted #aaaaaa; font-style: italic; color: #999999; }
.notentered { font-style: italic; color: #999999; }
.askjohn { font-style: italic; color: #009999; }

.addtoquery { font-style: italic; color: #aa0000; }
.cell { line-height: 1.0; text-indent: 2px; color: #666666; font-size: 16px;}
.enumerate { background-color: green; font-size:20px; color: #FFFFFF; font-weight:bold; vertical-align: middle; text-align: center; }
img#logo { float:left; height:50px; padding:10px 10px 10px 10px;}
.locations { color: #000000; background-color: #FFFFFF; font-weight: bold; font-size: 18px; }
.ncell { line-height: 1.0; cell-padding: 2px; font-size: 16px;}
.objname { font-weight: bold; font-size: 16px; font-style: italic; width:200px; }
.objno { font-weight: bold; font-size: 16px; font-style: italic; width:110px; }
.objno { font-weight: bold; font-size: 16px; font-style: italic; width:160px; }
.ui-tabs .ui-tabs-panel { padding: 0px; min-height:120px; }
.ui-tabs .ui-tabs-nav li { height:40px; font-size:16px; }
.ui-tabs .ui-tabs-nav li a { position:relative; top:0px }
#tabs { padding: 0px; background: none; border-width: 0px; } 
#tabs .ui-tabs-nav { padding-left: 0px; background: transparent; border-width: 0px 0px 1px 0px;
  -moz-border-radius: 0px; -webkit-border-radius: 0px; border-radius: 0px; text-align: center; height: 2.35em; }
#tabs .ui-tabs-panel { background: #ffffff repeat-x scroll 50% top; border-width: 1px 1px 1px 1px; }
#tabs .ui-tabs-nav li { display: inline-block; float: none; top: 0px; margin: 0em; }
.rdo { text-align: center; }
.save { background-color: BurlyWood; font-size:20px; color: #000000; font-weight:bold; vertical-align: middle; text-align: center; }
.shortinput { font-weight: bold; width:150px; }
.subheader { background-color: ''' + schemacolor1 + '''; color: #FFFFFF; font-size: 24px; font-weight: bold; }
.veryshortinput { width:60px; }
.xspan { color: #000000; background-color: #FFFFFF; font-weight: bold; font-size: 12px; }


</style>
<style type="text/css">
  /*<![CDATA[*/
    @import "../css/jquery-ui-1.8.22.custom.css";
  /*]]>*/
  </style>
<script type="text/javascript" src="../js/jquery-1.7.2.min.js"></script>
<script type="text/javascript" src="../js/jquery-ui-1.8.22.custom.min.js"></script>
<script type="text/javascript" src="../js/provision.js"></script>
<script type="text/javascript" src="https://www.google.com/jsapi"></script>
<style>
.ui-autocomplete-loading { background: white url('../images/ui-anim_basic_16x16.gif') right center no-repeat; }
</style>
<script type="text/javascript">
function formSubmit(location)
{
    console.log(location);
    document.getElementById('lo.location1').value = location
    document.getElementById('lo.location2').value = location
    //document.getElementById('num2ret').value = 1
    //document.getElementById('actionbutton').value = "Next"
    document.forms['sysinv'].submit();
}
</script>
</head>
<body>
<form id="sysinv" enctype="multipart/form-data" method="post">
<table width="100%" cellpadding="0" cellspacing="0" border="0">
  <tbody><tr><td width="3%">&nbsp;</td><td align="center">''' + divsize + '''
    <table width="100%">
    <tbody>
      <tr>
	<td style="width: 400px; color: #000000; font-size: 32px; font-weight: bold;">''' + apptitle + '''</td>
        <td><span style="color:''' + serverlabelcolor + ''';">''' + serverlabel + '''</td>
	<th style="text-align:right;"><img height="60px" src="''' + logo + '''"></th>
      </tr>
      <tr><td colspan="3"></td></tr>
      <tr>
	<td colspan="3">
	<table>
	  <tr><td><table>
	</table>
        </td><td style="width:3%"/>
	<td style="width:120px;text-align:center;"></td>
      </tr>
      </table></td></tr>
      <tr><td colspan="3"><div id="status"><hr/></div></td></tr>
    </tbody>
    </table>'''

    dbsource = 'pahma.cspace.berkeley.edu'

    print '''<div id="tabs">
 <ul>
   <li><a href="#tabs-1"><span>At A Glance</span></a></li>
   <li><a href="#tabs-2"><span>By Object Types</span></a></li>
   <li><a href="#tabs-3"><span>By Catalog or Department</span></a></li>
   <li><a href="#tabs-4"><span>By Accession Status</span></a></li>
   <li><a href="#tabs-5"><span>By Collection Manager</span></a></li>
   <li><a href="#tabs-6"><span>By Ethnographic Use Code</span></a></li>
 </ul>
'''
    cswaCollectionUtils.makeglancetab(dbsource, config)

    print '''<div id="tabs-2">'''
    statgroup = 'objByObjType'
    sectiontitle = 'By object type'
    charttype = 'piechart'
    cswaCollectionUtils.makethreecharts(dbsource, charttype, statgroup, config)
    cswaCollectionUtils.maketableofcounts(dbsource, sectiontitle, statgroup, config)
    print '''</div>'''

    print '''<div id="tabs-3">'''
    statgroup = 'objByLegCat'
    sectiontitle = 'By legacy catalog'
    charttype = 'barchartvertical'
    cswaCollectionUtils.makethreecharts(dbsource, charttype, statgroup, config)
    cswaCollectionUtils.maketableofcounts(dbsource, sectiontitle, statgroup, config)
    print '''</div>'''

    print '''<div id="tabs-4">'''
    statgroup = 'objByAccStatus'
    sectiontitle = 'By accession status'
    charttype = 'barchartvertical'
    cswaCollectionUtils.makethreecharts(dbsource, charttype, statgroup, config)
    cswaCollectionUtils.maketableofcounts(dbsource, sectiontitle, statgroup, config)
    print '''</div>'''

    print '''<div id="tabs-5">'''
    statgroup = 'objByCollMan'
    sectiontitle = 'By collection manager'
    charttype = 'piechart'
    cswaCollectionUtils.makethreecharts(dbsource, charttype, statgroup, config)
    cswaCollectionUtils.maketableofcounts(dbsource, sectiontitle, statgroup, config)
    print '''</div>'''

    print '''<div id="tabs-6">'''
    statgroup = 'objByFileCode'
    sectiontitle = 'By ethnographic use code'
    charttype = 'piechart'
    cswaCollectionUtils.makethreecharts(dbsource, charttype, statgroup, config)
    cswaCollectionUtils.maketableofcounts(dbsource, sectiontitle, statgroup, config)
    print '''</div>
</div>'''


def getStyle(schemacolor1):
    return '''
<style type="text/css">
body { margin:10px 10px 0px 10px; font-family: Arial, Helvetica, sans-serif; }
table { width: 100%; }
td { cell-padding: 3px; }
th { text-align: left ;color: #666666; font-size: 16px; font-weight: bold; cell-padding: 3px;}
h1 { font-size:32px; padding:10px; margin:0px; border-bottom: none; }
h2 { font-size:24px; color:white; background:blue; }
p { padding:10px 10px 10px 10px; }
li { text-align: left; list-style-type: none; }
a { text-decoration: none; }
button { font-size: 150%; width:85px; text-align: center; text-transform: uppercase;}
.cell { line-height: 1.0; text-indent: 2px; color: #666666; font-size: 16px;}
.enumerate { background-color: green; font-size:20px; color: #FFFFFF; font-weight:bold; vertical-align: middle; text-align: center; }
img#logo { float:left; height:50px; padding:10px 10px 10px 10px;}
.authority { color: #000000; background-color: #FFFFFF; font-weight: bold; font-size: 18px; }
.ncell { line-height: 1.0; cell-padding: 2px; font-size: 16px;}
.objname { font-weight: bold; font-size: 16px; font-style: italic; width:200px; }
.objno { font-weight: bold; font-size: 16px; font-style: italic; width:160px; }
.ui-tabs .ui-tabs-panel { padding: 0px; min-height:120px; }
.rdo { text-align: center; width:60px; }
.save { background-color: BurlyWood; font-size:20px; color: #000000; font-weight:bold; vertical-align: middle; text-align: center; }
.shortinput { font-weight: bold; width:150px; }
.subheader { background-color: ''' + schemacolor1 + '''; color: #FFFFFF; font-size: 24px; font-weight: bold; }
.veryshortinput { width:60px; }
.xspan { color: #000000; background-color: #FFFFFF; font-weight: bold; font-size: 12px; }
th[data-sort]{ cursor:pointer; }

.imagecell { padding: 8px ; align: center; }
.rightlabel { text-align: right ; vertical-align: top; padding: 2px 12px 2px 2px; width: 30%; }
.objtitle { font-size:28px; float:left; padding:4px; margin:0px; border-bottom: thin dotted #aaaaaa; color: #000000; }
.objsubtitle { font-size:28px; float:left; padding:2px; margin:0px; border-bottom: thin dotted #aaaaaa; font-style: italic; color: #999999; }
.notentered { font-style: italic; color: #999999; }
</style>
'''


def starthtml(form, config):
    writeInfo2log('start', form, config, 0.0)
    logo = config.get('info', 'logo')
    schemacolor1 = config.get('info', 'schemacolor1')
    serverlabel = config.get('info', 'serverlabel')
    serverlabelcolor = config.get('info', 'serverlabelcolor')
    apptitle = config.get('info', 'apptitle')
    updateType = config.get('info', 'updatetype')

    #num2ret   = str(form.get('num2ret')) if str(form.get('num2ret')).isdigit() else '50'

    button = '''<input id="actionbutton" class="save" type="submit" value="Search" name="action">'''

    groupbyelement = '''
          <th><span class="cell">group by:</span></th>
          <th>
          <span class="cell">none </span><input type="radio" name="groupby" value="none">
          <span class="cell">name </span><input type="radio" name="groupby" value="determination">
          <span class="cell">family </span><input type="radio" name="groupby" value="family">
          <span class="cell">location </span><input type="radio" name="groupby" value="gardenlocation">
          </th>'''
    #groupby   = str(form.get("groupby")) if form.get("groupby") else 'gardenlocation'

    # temporary, until the other groupings and sortings work...
    groupbyelement = '''
          <th><span class="cell">group by:</span></th>
          <th>
          <span class="cell">none </span><input type="radio" name="groupby" value="none">
          <span class="cell">location </span><input type="radio" name="groupby" value="location">
          </th>'''

    groupby = str(form.get("groupby")) if form.get("groupby") else 'location'
    groupbyelement = groupbyelement.replace(('value="%s"' % groupby), ('checked value="%s"' % groupby))

    location1 = str(form.get("lo.location1")) if form.get("lo.location1") else ''
    location2 = str(form.get("lo.location2")) if form.get("lo.location2") else ''
    otherfields = '''
	  <tr><th><span class="cell">start location:</span></th>
	  <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
          <th><span class="cell">end location:</span></th>
          <th><input id="lo.location2" class="cell" type="text" size="40" name="lo.location2" value="''' + location2 + '''" class="xspan"></th></tr>
    '''

    if updateType == 'keyinfo':
        location1 = str(form.get("lo.location1")) if form.get("lo.location1") else ''
        location2 = str(form.get("lo.location2")) if form.get("lo.location2") else ''
        fieldset, selected = getFieldset(form)

        otherfields = '''
	    <tr><th><span class="cell">start location:</span></th>
	    <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
        <th><span class="cell">end location:</span></th>
        <th><input id="lo.location2" class="cell" type="text" size="40" name="lo.location2" value="''' + location2 + '''" class="xspan"></th>
        <th><th><span class="cell">set:</span></th><th>''' + fieldset + '''</th></tr>
    '''
        otherfields += '''
        <tr></tr>'''

    elif updateType == 'objinfo':
        objno1 = str(form.get("ob.objno1")) if form.get("ob.objno1") else ''
        objno2 = str(form.get("ob.objno2")) if form.get("ob.objno2") else ''
        fieldset, selected = getFieldset(form)

        otherfields = '''
        <tr><th><span class="cell">start object no:</span></th>
        <th><input id="ob.objno1" class="cell" type="text" size="32" name="ob.objno1" value="''' + objno1 + '''" class="xspan"></th>
        <th><span class="cell">end object no:</span></th>
        <th><input id="ob.objno2" class="cell" type="text" size="32" name="ob.objno2" value="''' + objno2 + '''" class="xspan"></th>
        <th><th><span class="cell">set:</span></th><th>''' + fieldset + '''</th></tr>
        '''
        otherfields += '''
        <tr></tr>'''

    elif updateType == 'objdetails':
        objectnumber = str(form.get('ob.objectnumber')) if form.get('ob.objectnumber') else ''
        otherfields = '''
	  <tr><td><span class="cell">Museum Number:</span></td>
	  <td><input id="ob.objectnumber" class="cell" type="text" size="40" name="ob.objectnumber" value="''' + objectnumber + '''" class="xspan"></td></tr>'''

    elif updateType == 'moveobject':
        objno1 = str(form.get("ob.objno1")) if form.get("ob.objno1") else ''
        objno2 = str(form.get("ob.objno2")) if form.get("ob.objno2") else ''
        crate = str(form.get("lo.crate")) if form.get("lo.crate") else ''
        handlers, selected = getHandlers(form)
        reasons, selected = getReasons(form)

        otherfields = '''
        <tr><th><span class="cell">start object no:</span></th>
        <th><input id="ob.objno1" class="cell" type="text" size="40" name="ob.objno1" value="''' + objno1 + '''" class="xspan"></th>
        <th><span class="cell">end object no:</span></th>
        <th><input id="ob.objno2" class="cell" type="text" size="40" name="ob.objno2" value="''' + objno2 + '''" class="xspan"></th></tr>
        '''
        otherfields += '''
	  <tr><th><span class="cell">destination:</span></th>
	  <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
          <th><span class="cell">reason:</span></th><th>''' + reasons + '''</th>
          <tr><th><span class="cell">crate:</span></th>
          <th><input id="lo.crate" class="cell" type="text" size="40" name="lo.crate" value="''' + crate + '''" class="xspan"></th>
          <th><span class="cell">handler:</span></th><th>''' + handlers + '''</th></tr>
        '''

    elif updateType == 'movecrate':
        crate = str(form.get("lo.crate")) if form.get("lo.crate") else ''
        otherfields = '''
	  <tr><th><span class="cell">from:</span></th>
	  <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
          <th><span class="cell">to:</span></th>
          <th><input id="lo.location2" class="cell" type="text" size="40" name="lo.location2" value="''' + location2 + '''" class="xspan"></th></tr>
          <tr><th><span class="cell">crate:</span></th>
          <th><input id="lo.crate" class="cell" type="text" size="40" name="lo.crate" value="''' + crate + '''" class="xspan"></th></tr>
    '''

        handlers, selected = getHandlers(form)
        reasons, selected = getReasons(form)
        otherfields += '''
          <tr><th><span class="cell">reason:</span></th><th>''' + reasons + '''</th>
          <th><span class="cell">handler:</span></th><th>''' + handlers + '''</th></tr>'''

    elif updateType == 'bedlist':
        location1 = str(form.get("lo.location1")) if form.get("lo.location1") else ''
        otherfields = '''
	  <tr>
          <th><span class="cell">bed:</span></th>
	  <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
          ''' + groupbyelement + '''
          </tr>
    '''
    elif updateType == 'locreport':

        deadoralive = '''
         <th><span class="cell">rare </span>
	  <input id="rare" class="cell" type="checkbox" name="rare" value="rare" class="xspan">
          <span class="cell">not rare </span>
	  <input id="notrare" class="cell" type="checkbox" name="notrare" value="notrare" class="xspan">
          ||
	  <span class="cell">alive </span>
	  <input id="alive" class="cell" type="checkbox" name="alive" value="alive" class="xspan">
	  <span class="cell">dead </span>
	  <input id="dead" class="cell" type="checkbox" name="dead" value="dead" class="xspan"></th>'''

        for v in ['rare', 'notrare', 'dead', 'alive']:
            if form.get(v):
                deadoralive = deadoralive.replace('value="%s"' % v, 'checked value="%s"' % v)
            else:
                deadoralive = deadoralive.replace('checked value="%s"' % v, 'value="%s"' % v)

        taxName = str(form.get('ta.taxon')) if form.get('ta.taxon') else ''
        otherfields = '''
	  <tr><th><span class="cell">taxonomic name:</span></th>
	  <th><input id="ta.taxon" class="cell" type="text" size="40" name="ta.taxon" value="''' + taxName + '''" class="xspan"></th>
          ''' + deadoralive + '''</tr> '''

    elif updateType == 'holdings':
        place = str(form.get('px.place')) if form.get('px.place') else ''
        otherfields = '''
	  <tr><th><span class="cell">collection place:</span></th>
	  <th><input id="px.place" class="cell" type="text" size="40" name="px.place" value="''' + place + '''" class="xspan"></th></tr>
    '''

    elif updateType == 'advsearch':
        location1 = str(form.get("lo.location1")) if form.get("lo.location1") else ''
        taxName = str(form.get('ta.taxon')) if form.get('ta.taxon') else ''
        objectnumber = str(form.get('ob.objectnumber')) if form.get('ob.objectnumber') else ''
        place = str(form.get('px.place')) if form.get('px.place') else ''
        concept = str(form.get('cx.concept')) if form.get('cx.concept') else ''

        deadoralive = '''
         <th><span class="cell">filters:</span></th><th><span class="cell">rare </span>
	  <input id="rare" class="cell" type="checkbox" name="rare" value="rare" class="xspan">
	  <span class="cell">dead </span>
	  <input id="dead" class="cell" type="checkbox" name="dead" value="dead" class="xspan"></th>'''

        #alive = str(form.get('alive')) if form.get('alive') else ''
        #  <span class="cell">alive </span>
        #  <input id="alive" class="cell" type="checkbox" name=""alive" value="''' + alive + '''" class="xspan"></th>

        #  <th><span class="cell">sort by:</span></th>
        #  <th>
        #  <span class="cell">name </span><input type="radio" name="sortby" value="name">
        #  <span class="cell">family </span><input type="radio" name="sortby" value="family">
        #  <span class="cell">location </span><input type="radio" name="sortby" value="location" checked>
        #  </th>
        if form.get('rare'): deadoralive = deadoralive.replace('value="rare"', 'checked value="rare"')
        if form.get('dead'): deadoralive = deadoralive.replace('value="dead"', 'checked value="dead"')

        otherfields = '''
	  <tr><th><span class="cell">taxonomic name:</span></th>
	  <th><input id="ta.taxon" class="cell" type="text" size="40" name="ta.taxon" value="''' + taxName + '''" class="xspan"></th>
          ''' + groupbyelement + '''</tr>
	  <tr>
          <th><span class="cell">bed:</span></th>
	  <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
          ''' + deadoralive + '''</tr>
	  <tr><th><span class="cell">collection place:</span></th>
	  <th><input id="px.place" class="cell" type="text" size="40" name="px.place" value="''' + place + '''" class="xspan"></th>
	  </tr>
          '''

        saveForNow = '''
	  <tr><th><span class="cell">concept:</span></th>
	  <th><input id="cx.concept" class="cell" type="text" size="40" name="cx.concept" value="''' + concept + '''" class="xspan"></th></tr>'''

    elif updateType == 'search':
        objectnumber = str(form.get('ob.objectnumber')) if form.get('ob.objectnumber') else ''
        place = str(form.get('cp.place')) if form.get('cp.place') else ''
        concept = str(form.get('co.concept')) if form.get('co.concept') else ''
        otherfields += '''
	  <tr><th><span class="cell">museum number:</span></th>
	  <th><input id="ob.objectnumber" class="cell" type="text" size="40" name="ob.objectnumber" value="''' + objectnumber + '''" class="xspan"></th></tr>
	  <tr><th><span class="cell">concept:</span></th>
	  <th><input id="co.concept" class="cell" type="text" size="40" name="co.concept" value="''' + concept + '''" class="xspan"></th></tr>
	  <tr><th><span class="cell">collection place:</span></th>
	  <th><input id="cp.place" class="cell" type="text" size="40" name="cp.place" value="''' + place + '''" class="xspan"></th></tr>'''
    elif updateType == 'barcodeprint':
        printers, selected = getPrinters(form)
        objectnumber = str(form.get('ob.objectnumber')) if form.get('ob.objectnumber') else ''
        otherfields += '''
<tr><th><span class="cell">museum number:</span></th>
<th><input id="ob.objectnumber" class="cell" type="text" size="40" name="ob.objectnumber" value="''' + objectnumber + '''" class="xspan"></th></tr>
<tr><th><span class="cell">printer:</span></th><th>''' + printers + '''</th></tr>'''
    elif updateType == 'inventory':
        handlers, selected = getHandlers(form)
        reasons, selected = getReasons(form)
        otherfields += '''
          <tr><th><span class="cell">reason:</span></th><th>''' + reasons + '''</th>
          <th><span class="cell">handler:</span></th><th>''' + handlers + '''</th></tr>'''

    elif updateType == 'packinglist' or updateType == 'packinglistbyculture':
        place = str(form.get('cp.place')) if form.get('cp.place') else ''
        otherfields += '''
	  <tr><th><span class="cell">collection place:</span></th>
	  <th><input id="cp.place" class="cell" type="text" size="40" name="cp.place" value="''' + place + '''" class="xspan"></th>'''
        otherfields += '''
          <th><span class="cell">group by culture </span></th>
	  <th><input id="groupbyculture" class="cell" type="checkbox" name="groupbyculture" value="groupbyculture" class="xspan"></th</tr>'''
        if form.get('groupbyculture'): otherfields = otherfields.replace('value="groupbyculture"',
                                                                         'checked value="groupbyculture"')

    elif updateType == 'upload':
        button = '''<input id="actionbutton" class="save" type="submit" value="Upload" name="action">'''
        otherfields = '''<tr><th><span class="cell">file:</span></th><th><input type="file" name="file"></th><th/></tr>'''

    elif updateType == 'hierarchyviewer':
        hierarchies, selected = getHierarchies(form)
        button = '''<input id="actionbutton" class="save" type="submit" value="View Hierarchy" name="action">'''
        otherfields = '''<tr><th><span class="cell">Authority:</span></th><th>''' + hierarchies + '''</th></tr>'''

    elif False:
        otherfields += '''
          <th><span class="cell">number to retrieve:</span></th>
          <th><input id="num2ret" class="cell" type="text" size="4" name="num2ret" value="''' + num2ret + '''" class="xspan"></th></tr>
          <tr><th/><th/><th/><th/></tr>'''

    username = ''

    return '''Content-type: text/html; charset=utf-8

    
<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>''' + apptitle + ' : ' + serverlabel + '''</title>''' + getStyle(schemacolor1) + '''
<style type="text/css">
/*<![CDATA[*/
@import "../css/jquery-ui-1.8.22.custom.css";
@import "../css/blue/style.css";
@import "../css/jqtree.css";
/*]]>*/
</style>
<script type="text/javascript" src="../js/jquery-1.7.2.min.js"></script>
<script type="text/javascript" src="../js/jquery-ui-1.8.22.custom.min.js"></script>
<script type="text/javascript" src="../js/jquery.tablesorter.js"></script>
<script src="../js/tree.jquery.js"></script>
<style>
.ui-autocomplete-loading { background: white url('../images/ui-anim_basic_16x16.gif') right center no-repeat; }
</style>
<script type="text/javascript">
function formSubmit(location)
{
    console.log(location);
    document.getElementById('lo.location1').value = location
    document.getElementById('lo.location2').value = location
    //document.getElementById('actionbutton').value = "Next"
    document.forms['sysinv'].submit();
}
</script>
</head>
<body>
<form id="sysinv" enctype="multipart/form-data" method="post">
<table width="100%" cellpadding="0" cellspacing="0" border="0">
  <tbody><tr><td width="2%">&nbsp;</td>
  <td align="center">
  <div id="sidiv" style="position:relative;width:1000px;height:750px;">
    <table width="100%">
    <tbody>
      <tr>
	<td class="cell" style="width: 500px; color: #000000; font-size: 32px; font-weight: bold;">''' + apptitle + '''</td>
    <td style="width: 120px; text-align: right; padding-right: 10px;">
    <span class="tiny">server</span>
    <br/>
    <span class="tiny">user</span>
    <br/>
    <span class="tiny">&nbsp;</span>
    </td>
    <td style="width: 100px; text-align: left; padding-right: 10px;"><span class="tiny" style="color:''' + serverlabelcolor + ''';">''' + serverlabel + '''</span>
    <br/>
    <span class="ncell">''' + username + '''</span>
    <br/>
    <span class="tiny">&nbsp;</span>
    </td>
    <td><div style="width:80px; ";" id="appstatus"><img height="60px" src="../images/timer-animated.gif"></div></td>
	<th style="text-align:right;"><img height="60px" src="''' + logo + '''"></th>
      </tr>
      <tr><td colspan="5"><hr/></td></tr>
      <tr><th colspan="5">
    <table>
        <tr>
        <th>
        <table>
	  ''' + otherfields + '''
        </table>
        </th>
        <td style="width:80px;text-align:center;">''' + button + '''</td>
        </tr>
        </table>
      </th></tr>
      <tr><td colspan="5"><div id="status"><hr/></div></td></tr>
    </tbody>
    </table>
'''


def endhtml(form, config, elapsedtime):
    writeInfo2log('end', form, config, elapsedtime)
    #user = form.get('user')
    count = form.get('count')
    connect_string = config.get('connect', 'connect_string')
    focusSnippet = ""
    addenda = ""
    # for object details, clear out the input field on focus, for everything else, just focus
    if config.get('info', 'updatetype') == 'objdetails':
        focusSnippet = '''$('input:text:first').focus().val("");'''
    else:
        focusSnippet = '''$('input:text:first').focus();'''
    if config.get('info', 'updatetype') == 'collectionstats':
        addenda = '''$("#gototab2").click(function() {
    $("#tabs").tabs("select","#tabs-2");
});
$("#gototab3").click(function() {
    $("#tabs").tabs("select","#tabs-3");
});
$("#gototab4").click(function() {
    $("#tabs").tabs("select","#tabs-4");
});
$("#gototab5").click(function() {
    $("#tabs").tabs("select","#tabs-5");
});
$("#gototab6").click(function() {
    $("#tabs").tabs("select","#tabs-6");
});'''
    return '''
  <table width="100%">
    <tbody>
    <tr>
      <td width="80px"><input id="checkbutton" class="cell" type="submit" value="check server" name="check"></td>
      <td width="180px" class="xspan">''' + time.strftime("%b %d %Y %H:%M:%S", time.localtime()) + '''</td>
      <td width="120px" class="cell">elapsed time: </td>
      <td class="xspan">''' + ('%8.2f' % elapsedtime) + ''' seconds</td>
      <td style="text-align: right;" class="cell">powered by </td>
      <td style="text-align: right;width: 170;" class="cell"><img src="http://collectionspace.org/sites/all/themes/CStheme/images/CSpaceLogo.png" height="30px"></td>
    </tr>
    </tbody>
  </table>
</div>
</td><td width="2%">&nbsp;</td></tr>
</tbody></table>
</form>
<script>
$(function () {
       $("[name^=select-]").click(function (event) {
           var selected = this.checked;
           var mySet    = $(this).attr("name");
           mySet = mySet.replace('select-','');
           // console.log(mySet);
           // Iterate each checkbox
           $("[name^=" + mySet + "]").each(function () { this.checked = selected; });
       });
    });

$(document).ready(function () {

''' + focusSnippet + '''

$(function() {
  $('[id^="sortTable"]').map(function() {
        // console.log(this);
        $(this).tablesorter({debug: true})
     });
  });
  
$('[name]').map(function() {
    var elementID = $(this).attr('name');
    if (elementID.indexOf('.') == 2) {
        // console.log(elementID);
        $(this).autocomplete({
            source: function(request, response) {
                $.ajax({
                    url: "../cgi-bin/autosuggest.py?connect_string=''' + connect_string + '''",
                    dataType: "json",
                    data: {
                        q : request.term,
                        elementID : elementID
                    },
                    success: function(data) {
                        response(data);
                    }
                });
            },
            minLength: 2,
        });
    }
});

d = document.getElementById("appstatus");
d.innerHTML = '&nbsp;';

});

''' + addenda + '''
</script>
</body></html>
'''


def relationsPayload(f):
    payload = """<?xml version="1.0" encoding="UTF-8"?>
<document name="relations">
  <ns2:relations_common xmlns:ns2="http://collectionspace.org/services/relation" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <relationshipType>affects</relationshipType>
    <objectCsid>%s</objectCsid>
    <objectDocumentType>%s</objectDocumentType>
    <subjectCsid>%s</subjectCsid>
    <subjectDocumentType>%s</subjectDocumentType>
  </ns2:relations_common>
</document>
"""
    payload = payload % (f['objectCsid'], f['objectDocumentType'], f['subjectCsid'], f['subjectDocumentType'])
    return payload


def lmiPayload(f):
    payload = """<?xml version="1.0" encoding="UTF-8"?>
<document name="movements">
<ns2:movements_common xmlns:ns2="http://collectionspace.org/services/movement" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<reasonForMove>%s</reasonForMove>
<currentLocation>%s</currentLocation>
<currentLocationFitness>suitable</currentLocationFitness>
<locationDate>%s</locationDate>
<movementNote>%s</movementNote>
</ns2:movements_common>
<ns2:movements_anthropology xmlns:ns2="http://collectionspace.org/services/movement/domain/anthropology" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<computedSummary>%s</computedSummary>
<crate>%s</crate>
<locationHandlers>
<locationHandler>%s</locationHandler>
</locationHandlers>
</ns2:movements_anthropology>
</document>
"""
    payload = payload % (
        f['reason'], f['locationRefname'], f['locationDate'], f['inventoryNote'], f['computedSummary'], f['crate'],
        f['handlerRefName'])
    return payload


if __name__ == "__main__":

    # to test this module on the command line you have to pass in two cgi values:
    # $ python cswaUtils.py "lo.location1=Hearst Gym, 30, L 12,  2&lo.location2=Hearst Gym, 30, L 12,  7"
    # $ python cswaUtils.py "lo.location1=X&lo.location2=Y"

    # this will load the config file and attempt to update some records in server identified
    # in that config file!


    form = {'webapp': 'keyinfoDev', 'action': 'Update Object Information',
            'fieldset': 'namedesc',
            #'fieldset': 'registration',
            'onm.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'Cradle',
            'oox.70d40782-6d11-4346-bb9b-2f85f1e00e91': '1-1',
            'csid.70d40782-6d11-4346-bb9b-2f85f1e00e91': '70d40782-6d11-4346-bb9b-2f85f1e00e91',
            'bdx.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'brief description 999 888 777',
            'anm.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'xxx',
            'ant.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'xxx',
            'pc.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'Dr. Philip Mills Jones',
    }

    config = getConfig(form)
    doUpdateKeyinfo(form, config)

    sys.exit()

    import cswaDB

    realm = config.get('connect', 'realm')
    hostname = config.get('connect', 'hostname')
    username = config.get('connect', 'username')
    password = config.get('connect', 'password')

    #print lmiPayload(f)
    #print relationsPayload(f)

    f2 = {'objectStatus': 'found',
          'subjectCsid': '',
          'inventoryNote': '',
          'crate': "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(crate):item:name(cr2113)'Faunal Box 421'",
          'handlerRefName': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(999)'Michael T. Black'",
          'objectCsid': '35d1e048-e803-4e19-81de-ac1079f9bf47',
          'reason': 'Inventory',
          'computedSummary': 'systematic inventory test',
          'locationRefname': "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(sl12158)'Kroeber, 20A, AA 1, 2'",
          'locationDate': '2012-07-24T05:45:30Z',
          'objectNumber': '9-12689'}

    #updateLocations(f2,config)
    #print "updateLocations succeeded..."
    #sys.exit(0)



    uri = 'movements'

    print "<br>posting to movements REST API..."
    payload = lmiPayload(updateItems)
    (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)
    updateItems['subjectCsid'] = csid
    print 'got csid', csid, '. elapsedtime', elapsedtime
    print "relations REST API post succeeded..."

    uri = 'relations'

    print "<br>posting inv2obj to relations REST API..."
    updateItems['subjectDocumentType'] = 'Movement'
    updateItems['objectDocumentType'] = 'CollectionObject'
    payload = relationsPayload(updateItems)
    (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)
    print 'got csid', csid, '. elapsedtime', elapsedtime
    print "relations REST API post succeeded..."

    # reverse the roles
    print "<br>posting obj2inv to relations REST API..."
    temp = updateItems['objectCsid']
    updateItems['objectCsid'] = updateItems['subjectCsid']
    updateItems['subjectCsid'] = temp
    updateItems['subjectDocumentType'] = 'CollectionObject'
    updateItems['objectDocumentType'] = 'Movement'
    payload = relationsPayload(updateItems)
    (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)
    print 'got csid', csid, '. elapsedtime', elapsedtime
    print "relations REST API post succeeded..."

    print "<h3>Done w update!</h3>"

    sys.exit()

    print cswaDB.getplants('Velleia rosea', '', 1, config, 'locreport')
    sys.exit()

    starthtml(form, config)
    endhtml(form, config, 0.0)

    #print "starting packing list"
    #doPackingList(form,config)
    #sys.exit()
    print '\nlocations\n'
    for loc in cswaDB.getloclist('range', '1001, Green House 1', '1003, Tropical House', 1000, config):
        print loc
    sys.exit()

    print '\nlocations\n'
    for loc in cswaDB.getloclist('set', 'Kroeber, 20A, W B', '', 10, config):
        print loc

    print '\nlocations\n'
    for loc in cswaDB.getloclist('set', 'Kroeber, 20A, CC  4', '', 3, config):
        print loc

    print '\nobjects\n'
    rows = cswaDB.getlocations('Kroeber, 20A, CC  4', '', 3, config, 'keyinfo')
    for r in rows:
        print r

    #urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(sl31520)'Regatta, A150, RiveTier 1, B'
    f = {'objectCsid': '242e9ee7-983a-49e9-b3b5-7b49dd403aa2',
         'subjectCsid': '250d75dc-c704-4b3b-abaa',
         'locationRefname': "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(sl284)'Kroeber, 20Mez, 53 D'",
         'locationDate': '2000-01-01T00:00:00Z',
         'computedSummary': 'systematic inventory test',
         'inventoryNote': 'this is a test inventory note',
         'objectDocumentType': 'CollectionObject',
         'subjectDocumentType': 'Movement',
         'reason': 'Inventory',
         'handlerRefName': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7412)'Madeleine W. Fang'"

    }

    #print lmiPayload(f)
    #print relationsPayload(f)

    form = {'webapp': 'barcodeprintDev', 'ob.objectnumber': '1-504', 'action': 'Create Labels for Objects'}

    config = getConfig(form)

    print doBarCodes(form, config)
    sys.exit()
