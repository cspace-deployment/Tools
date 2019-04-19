# README

This folder contains scripts that updata data in the CollectionSpace BAMPFA deployment.

## Usage
### updatePersons.py
#### To run: 
    python updatePersons.py --(dev | prod)
    

#### Description:
This script uses the REST API to update local persons records. In essence, it generates a GET request from the CollectionSpace server to get up to 2500 CSIDs per GET request. After doing this, it uses each of the CSIDs it obtained to generate another GET request to fetch the record. After doing this, it immediately generates a PUT request to the same record using the data it obtained from the GET. This updates the record and leaves all the data intact. 

PUTting an empty XML template with just the CSID of the record is not possible, as the API checks that there are certain fields (which are required) to be filled out, thus instead of grepping for these required fields, the script safely fetches and puts back the same data it received.

#### Output:
- As the script is running, it prints the url it is trying to GET/PUT. 
- Upon terminating, it generates 3 files:
    - `/tmp/failed_gets.txt`: A file containing all the failed GET requests. Followed by the total number of these failures 
    - `/tmp/failed_puts.txt`: A file containing all the failed PUT requests. Followed by the total number of these failures 
    - `/tmp/successful_calls.txt`: A file containg all of the successful calls to the REST API.
