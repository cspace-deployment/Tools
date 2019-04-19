import requests
import os
import re
import time
import sys
import socket
import ssl
import getpass as gp

try:
	from http.client import HTTPConnection
except ImportError:
	from httplib import HTTPConnection
from requests.packages.urllib3.connection import VerifiedHTTPSConnection

class MyHTTPConnection(HTTPConnection):
    def connect(self):
        self.sock = socket.socket(socket.AF_INET)
        self.sock.connect((self.host, self.port))
        if self._tunnel_host:
            self._tunnel()

requests.packages.urllib3.connectionpool.HTTPConnection = MyHTTPConnection
requests.packages.urllib3.connectionpool.HTTPConnectionPool.ConnectionCls = MyHTTPConnection

# HTTPS
class MyHTTPSConnection(VerifiedHTTPSConnection):
    def connect(self):
        self.sock = socket.socket(socket.AF_INET)
        self.sock.connect((self.host, self.port))
        if self._tunnel_host:
            self._tunnel()
        self.sock = ssl.wrap_socket(self.sock, self.key_file, self.cert_file)

requests.packages.urllib3.connectionpool.HTTPSConnection = MyHTTPSConnection
requests.packages.urllib3.connectionpool.VerifiedHTTPSConnection = MyHTTPSConnection
requests.packages.urllib3.connectionpool.HTTPSConnectionPool.ConnectionCls = MyHTTPSConnection
	

start = time.time()

args = sys.argv
if (len(args) == 1):
    print("Need to include --prod or --dev")
    sys.exit()

mode = '' if (args[1] == '--prod') else '-dev'


BASE_URL = 'https://bampfa{0}.cspace.berkeley.edu/cspace-services/personauthorities/1e3308ba-9d64-49e7-9541/items/'.format(mode)
PAGE_OPT =  '?pgSz=2500&pgNum={0}'

try: 
  user = input('Username: ')
except:
  print ('Error: Username should be in quotes.')
  user = input('Username: ')

password = gp.getpass()

failed_gets_file = open("/tmp/failed_gets.txt", "w+")
failed_puts_file = open("/tmp/failed_puts.txt", "w+")
success_file = open("/tmp/successful_calls.txt", "w+")

failed_gets = 0
failed_puts = 0
successful_calls = 0

headers={'Content-Type':'application/xml; charset=UTF-8'}

# Basically, the API will only allow you to do PUTs if there is certain data present. In order to be safe, 
# I'm just making it so the script PUTs everything got during the GET to avoid any data loss


for i in range(2):
  initial_get = BASE_URL + PAGE_OPT.format(i)
  r = requests.get(initial_get, auth=(user, password))

  if (r.status_code < 200 or r.status_code > 300):
    print ('The request {0} could not be fulfilled. Please try again.'.format(initial_get))

  csids = re.findall('<csid>\S+?<\/csid>', r.content)

  for c in range(len(csids)):
    current_transaction_start = time.time()
    get_time_s = time.time()
    csid = re.findall('>(\S+?)<', csids[c])[0]

    request = BASE_URL + csid    
  
    get_response = requests.get(request, auth=(user, password))
    if (get_response.status_code < 200 and get_response.status_code >= 300):
      print("The item with CSID {0} failed to be fetched".format(csid))
      failed_reqs_file.write("The item with CSID {0} failed to be fetched with status code {1} because {2}".format(csid, get_response.status_code, get_response.content))
      failed_gets += 1
      continue
    get_time_end = time.time()
    put_time_start = time.time()

    content = get_response.content
    
    put_request = requests.put(request, content, auth=(user, password), headers=headers)
    if (put_request.status_code < 200 and put_request.status_code >= 300): 
      print("The item with CSID {0} failed to be PUTted".format(csid))
      failed_reqs_file.write("The item with CSID {0} failed to be PUTted with status code {1} because {2}".format(csid, put_request.status_code, put_request.content))
      failed_puts += 1
      continue
    put_time_end = time.time()
    successful_calls += 1
    success_file.write("The item with CSID {0} was successfully updated. \n".format(csid))
    if (successful_calls % 250 == 0):
        print ("{0} successes, {1} failed gets, {2} failed puts".format(successful_calls, failed_gets, failed_puts))

    current_transaction_end = time.time()
    print ("Processed {0}. It took {1} seconds.".format(request, str(current_transaction_end - current_transaction_start))) 

end = time.time()
print("Time elapsed: {0} seconds".format(str(end - start)))


success_file.write(str(successful_calls))
failed_gets_file.write(str(failed_gets))
failed_puts_file.write(str(failed_puts))

success_file.close()
failed_gets_file.close()
failed_puts_file.close()