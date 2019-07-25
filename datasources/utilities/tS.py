import solr
import sys

try:
    core = sys.argv[1]
    host = sys.argv[2]
except:
    print("syntax: python %s solar_core hostname" % sys.argv[0])
    print("e.g     python %s pahma-public https://webapps.cspace.berkeley.edu" % sys.argv[0])
    sys.exit(1)

try:
    # create a connection to a solr server
    s = solr.SolrConnection(url = '%s/solr/%s' % (host,core))

    # do a search
    response = s.query('*:*', rows=20)
    print('%s, records found: %s' % (core,response._numFound))

    details = False

    if details:
        for hit in response.results:
            for h in hit:
                print(hit[h])
except:
    print("could not access %s." % core)

