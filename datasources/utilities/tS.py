import solr
import sys

try:
    core = sys.argv[1]
    host = sys.argv[2]
    query_template = sys.argv[3]
except:
    print('syntax: python %s solar_core hostname query_template' % sys.argv[0])
    print()
    print('e.g     python %s pahma-public https://webapps.cspace.berkeley.edu "*:*"' % sys.argv[0])
    print()
    print('or (using a template with a filler and input from stdin):')
    print()
    print('        python %s pahma-public http://localhost:8983 \'objmusno_txt:"%%s"\' < list_of_musnos.txt > found.txt' % sys.argv[0])
    print()
    print('i.e. will read a list of template fillers from stdin, write fillers and counts to stdout')
    sys.exit(1)

try:
    # create a connection to a solr server
    s = solr.SolrConnection(url = '%s/solr/%s' % (host,core))
except:
    print('could not open connection to "%s/solr/%s" % (host,core)')

# if a template filler query was specified, try to read stdin for fillers
if ('%s' in query_template):
    for query in sys.stdin.readlines():
        # fill in search and try it.
        filled_in_query = 'something bad happened'
        try:
            filled_in_query = query_template % query.rstrip()
            response = s.query(filled_in_query, rows=0)
            print('%s\t%s' % (filled_in_query, response._numFound))
        except:
            print('%s\t%s' % (filled_in_query, "query failed"))

else:
    # just do the one search
    try:
        response = s.query(query_template, rows=0)
        print('%s, records found: %s' % (core,response._numFound))
    except:
        print("could not access %s." % core)
