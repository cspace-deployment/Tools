#!/usr/bin/env /usr/bin/python

import sys, json, re
import cgi
import cgitb;

cgitb.enable()  # for troubleshooting
import pgdb

form = cgi.FieldStorage()

timeoutcommand = 'set statement_timeout to 500'


def dbtransaction(form):
    postgresdb = pgdb.connect(form.getvalue('connect_string'))
    cursor = postgresdb.cursor()

    q = form.getvalue("q")
    elementID = form.getvalue("elementID")
    # elementID is of the form cs_tablecolumn
    srchindex = re.search(r'^(..)\.(.*)', elementID)
    srchindex = srchindex.group(1)
    if srchindex in ['lo']:
        srchindex = 'location'
    elif srchindex in ['cp']:
        srchindex = 'longplace'
    elif srchindex in ['ob']:
        srchindex = 'object'
    elif srchindex in ['pl']:
        srchindex = 'place'
    elif srchindex in ['ta']:
        srchindex = 'taxon'
    elif srchindex in ['cx']:
        srchindex = 'concept2'
    elif srchindex in ['px']:
        srchindex = 'longplace2'
    else:
        srchindex = 'concept'

    try:
        if srchindex == 'location':
            table = 'loctermgroup'
            template = "select distinct(termdisplayname),replace(termdisplayName,' ','0') locationkey from %s where termdisplayname like '%s%%' order by locationkey limit 30;"
        elif srchindex == 'object':
            table = 'collectionobjects_common'
            template = "select objectnumber from %s where objectnumber like '%s%%' order by objectnumber limit 30;"
        elif srchindex == 'place':
            table = 'placetermgroup'
            template = "select distinct(termname) from %s where termname ilike '%%%s%%' and termtype='descriptor' order by termname limit 30;"
        elif srchindex == 'longplace':
            table = 'placetermgroup'
            template = "select distinct(termdisplayname) from %s where termdisplayname like '%s%%' and termtype='descriptor' order by termdisplayname limit 30;"
        elif srchindex == 'concept':
            table = 'concepttermgroup'
            template = "select distinct(termname) from %s where termname ilike '%%%s%%' and termtype='descriptor' order by termname limit 30;"
        elif srchindex == 'concept2':
            table = 'concepttermgroup'
            template = "select distinct(termname) from %s where termname ilike '%%%s%%' order by termname limit 30;"
        elif srchindex == 'longplace2':
            table = 'placetermgroup'
            template = "select distinct(termdisplayname) from %s where termdisplayname like '%s%%' order by termdisplayname limit 30;"
        elif srchindex == 'taxon':
            table = 'taxontermgroup'
            template = "select distinct(termdisplayname) from %s where termdisplayname like '%s%%' order by termdisplayname limit 30;"

        # double single quotes that appear in the data, to make psql happy
        q = q.replace("'","''")
        query = template % (table, q)
        #sys.stderr.write("autosuggest query: %s" % query)
        cursor.execute(query)
        result = []
        for r in cursor.fetchall():
            result.append({'value': r[0]})

        result.append({'s': srchindex})

        print 'Content-Type: application/json\n\n'
        #print 'debug autosuggest', srchindex,elementID
        print json.dumps(result)    # or "json.dump(result, sys.stdout)"

    except pgdb.DatabaseError, e:
        sys.stderr.write('autosuggest select error: %s' % e)
        return result
    except:
        sys.stderr.write("some other autosuggest database error!")
        return result


dbtransaction(form)
