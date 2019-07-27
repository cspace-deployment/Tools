#
# redeploy the Solr ETL from github
#
# 1. check to see we are plausibly able to do something...
cd
SOLRETLDIR=~/solrdatasources
TOOLS=~/Tools
if [ ! -d $TOOLS ];
then
   echo "Tools directory $TOOLS not found. Please clone from GitHub and provide it as the first argument."
   exit 1
fi
if [ ! -d $SOLRETLDIR ];
then
   echo "Solr ETL  directory $SOLRETLDIR not found. Please specify the correct directory"
   exit 1
fi
#
# 2. make a backup directory and move the current ETL directory contents to it.
YYMMDD=`date +%y%m%d`
BACKUPDIR=${SOLRETLDIR}.${YYMMDD}
if [ -d $BACKUPDIR ];
then
   echo "Backup ETL directory $BACKUPDIR already exists. Please move or remove it and try again"
   exit 1
fi
mv ${SOLRETLDIR} ${BACKUPDIR}
mkdir ${SOLRETLDIR}

# 3. deploy fresh code from github
cd ${TOOLS}
git pull -v
cp datasources/utilities/o*.sh ~
cp datasources/utilities/optimize.sh ~
cp datasources/utilities/checkstatus.sh ~
cp datasources/utilities/redeploy-etl.sh ~

rsync -av Tools/datasources/ solrdatasources/

# 4. try to put botgarden's pickle file back; it takes hours to recreate from scratch.
cp ${BACKUPDIR}/botgarden/gbif/names.pickle ${SOLRETLDIR}/botgarden/gbif
#
echo "double-check configuration of code in ${SOLRETLDIR}!"
