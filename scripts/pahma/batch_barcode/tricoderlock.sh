LOCKFILE=/tmp/tricoderlock
RUNDIR=/var/cspace/pahma/tricoder/batch_barcode
SUBJECT="Tricoder Batch Script still running on `hostname`"
EMAIL="pahma-tricoder@lists.berkeley.edu,cspace-support@lists.berkeley.edu"

if mkdir $LOCKFILE; then
  echo "Locking succeeded" >&2
  ${RUNDIR}/import_barcode_typeR.sh &> ${RUNDIR}/log/all_barcode_typeR.msg
  # alas, clean_temp.sh only works if invoked from the 'home' directory; not worth refactoring to do better yet...
  cd ${RUNDIR}; ./clean_temp.sh
  rm -rf $LOCKFILE
  echo "Unocking succeeded" >&2
else
  echo "Lock failed - exit" >&2
  echo " The Tricoder Batch script tried to run but found an existing lock. This situation should clear up by itself but if it persists, please notify RIT staff." | mail -s "${SUBJECT}" "${EMAIL}"
  exit 1
fi
