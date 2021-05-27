### How to install and run
``` 
mkdir -p bin/ucjeps_qc
cp -r Tools/scripts/ucjeps/image_qc/* bin/ucjeps_qc/
cd bin/ucjeps_qc/
# make a crontab entry like the line below
crontab -e
# example execution
/home/app_webapps/bin/ucjeps_qc/nightly.sh jblowe@berkeley.edu >> ucjeps_image_qc.log 2>&1
```
