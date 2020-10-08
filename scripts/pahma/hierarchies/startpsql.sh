TENANT=$1
HOSTNAME="dba-postgres-prod-45.ist.berkeley.edu port=$2 sslmode=prefer"
USERNAME="reporter_${TENANT}"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$HOSTNAME dbname=$DATABASE"
psql -U $USERNAME -d "$CONNECTSTRING"
