# csops - operations scripts for UCB-CSpace

This is a suite of scripts for operating CollectionSpace on UC Berkeley's managed RHEL server environment.

## Installation

Each application owner (e.g. `app_pahma`) should install the scripts.

Clone this repository:

```
cd ~/src/cspace-deployment
git clone https://github.com/cspace-deployment/Tools.git
```

Link the `cs*` executables into the user's `bin` directory:

```
cd ~/bin
ln -s ~/src/cspace-deployment/Tools/scripts/csops/cs* .
```

Some of these scripts run via `cron`. And since they need access to the app user's environment
variables, they may need special handling when installed in the `crontab`.

The following two options have been used here in UCB managed servers:

```
[app_pahma@cspace-prod-01 ~]cat /etc/redhat-release
Red Hat Enterprise Linux Server release 6.10 (Santiago)

[app_pahma@cspace-prod-01 ~]$ crontab -l
00 23 * * * ~/bin/cscleantemp >>~/log/cscleantemp.log.txt 2>&1
15 23 * * * ~/bin/cscleanlog >/dev/null 2>&1
30 18 * * 4 ~/bin/cscheckjava >>~/log/cscheckjava.log.txt 2>&1
*/10 * * * * bash -l -c '~/bin/cscheckmem -dn >/dev/null 2>&1'

[app_pahma@cspace-prod-01 ~]$ cat /etc/redhat-release
Red Hat Enterprise Linux Server release 7.6 (Maipo)

[app_pahma@cspace-prod-02 ~]$ crontab -l
00 23 * * * /bin/bash -l -c '~/bin/cscleantemp >>~/log/cscleantemp.log.txt 2>&1'
15 23 * * * /bin/bash -l -c '~/bin/cscleanlog >/dev/null 2>&1'
30 18 * * 2,4 /bin/bash -l -c '~/bin/cscheckjava >>~/log/cscheckjava.log.txt 2>&1'
*/10 * * * * /bin/bash -l -c '~/bin/cscheckmem -dn >/dev/null 2>&1'
```

## Usage

### csup - start CollectionSpace
##### Synopsis
```
csup
```
##### Description
Starts the CollectionSpace server.

### csdown - stop CollectionSpace
##### Synopsis
```
csdown [-f]
```
##### Description
Stops the CollectionSpace server, if there is no user activity. User activity is heuristically detected using the `csidletime` program. If the idle time is sufficient, the server is stopped. Otherwise, an error is reported. The required amount of idle time may be specified in the `CS_MIN_IDLE_TIME` environment variable, as a number of seconds. If `CS_MIN_IDLE_TIME` is not set, a default of 600 seconds (10 minutes) is used.
##### Options
`-f`
	Force the server to stop, even if user activity is detected within the required idle time.

### csbounce - restart CollectionSpace
##### Synopsis
```
csbounce [-f]
```
##### Description
Restarts the CollectionSpace server, if there is no user activity. User activity is heuristically detected using the `csidletime` program. If the idle time is sufficient, the server is stopped. Otherwise, an error is reported. The required amount of idle time may be specified in the `CS_MIN_IDLE_TIME` environment variable, as a number of seconds. If `CS_MIN_IDLE_TIME` is not set, a default of 600 seconds (10 minutes) is used.
##### Options
`-f`
	Force the server to restart, even if user activity is detected within the required idle time.

### csuptime - show how long CollectionSpace has been running
##### Synopsis
```
csuptime
```
##### Description
Shows the amount of time the CollectionSpace server has been running. The time is printed to standard output, in the `etime` format used by `ps`, which is `[[dd-]hh:]mm:ss`. If CollectionSpace is not running, nothing is printed.

### csidletime - show how long CollectionSpace has been idle
##### Synopsis
```
csidletime
```
##### Description
Shows the amount of time elapsed since the last user activity in CollectionSpace. The time is printed to standard output, in seconds.  The time of last user activity is heuristically determined using log files, and therefore may not be entirely accurate. For example, requests do not appear in certain logs until they have completed, so a long running request that is still in progress may not be detected. If the idle time cannot be determined (for example, if no logs exist), nothing is printed.

### csstarttime - show when CollectionSpace started
##### Synopsis
```
csstarttime [+FORMAT]
```
##### Description
Shows the date/time the CollectionSpace server was started. The time is printed to standard output, using the format specified. If CollectionSpace is not running, nothing is printed. The format string is interpreted by the `date` program. Note that the format must start with a plus sign.

### cspid - show the PID of the CollectionSpace process
##### Synopsis
```
cspid
```
##### Description
Shows the process ID of the CollectionSpace server. The pid is printed to standard output. If CollectionSpace is not running, nothing is printed.

### csver - show the installed CollectionSpace version number
##### Synopsis
```
csver
```
##### Description
Shows the version number of the installed version of CollectionSpace. This corresponds to a tag in git. The version number is printed to standard output. This program assumes that CollectionSpace releases are created using the [`make-release`](../make-release) program, and may not work correctly if that program's conventions are not followed.

### csname - show the name of the CollectionSpace deployment
##### Synopsis
```
csname
```
##### Description
Shows the name of the CollectionSpace deployment. This is the name of the deployment's primary tenant. The name is printed to standard output.

### csservname - show the name of the CollectionSpace service
##### Synopsis
```
csservname
```
##### Description
Shows the name of the CollectionSpace service, suitable for passing to the `systemctl` program. The name is printed to standard output.

### csi - install CollectionSpace
##### Synopsis
```
csi [versionnumber]
```
##### Description
Installs the specified version of CollectionSpace. The version number must correspond to a tag in git. If no version number is specified, the most recently created tag that is appropriate for the user is used. Installation may require that the CollectionSpace server be stopped and started. If this is necessary, the `csdown` program is invoked, which will do its usual user activity check.

### cscleantemp - remove old files from the CollectionSpace server's temporary file directory
##### Synopsis
```
cscleantemp
```
##### Description
Removes old files from the CollectionSpace temporary file directory. Files with names matching the pattern `*-*-*-*-*`, and that have not been modified for some amount of time are removed. The minimum time since last modification may be specified in the `CS_TEMP_MMIN` environment variable, in minutes. If `CS_TEMP_MMIN` is not set, a default of 60 minutes (1 hour) is used.

### cscleanlog - rotate log files
##### Synopsis
```
cscleanlog
```
##### Description
Rotates log files. This program rotates tomcat's catalina.out log, archives (using tar and gzip) access logs over two months old, and deletes other log files over two months old.

### cscheckjava - check for Java updates
##### Synopsis
```
cscheckjava
```
##### Description
Checks if the Java installation used by CollectionSpace has been updated. If an update to Java is detected that occurred after the start time of the running CollectionSpace server, the CollectionSpace server is restarted using the `csbounce` program. This ensures that CollectionSpace is using the newest version of Java, and prevents bugs that occur from Java files disappearing out from under the running JVM. This program should be run shortly after the scheduled OS update times. The UNIX team schedules updates for Tuesday at 6pm on dev, and Thursday at 6pm on production.

### cscheckmem - check for high Java memory (heap) usage
##### Synopsis
```
cscheckmem [-d] [-n]
```
##### Description
Checks if the the CollectionSpace Tomcat JVM exhibits high heap usage. Prints a report to standard output, and appends memory usage data to a tab-delimited log file (`~/log/cscheckmem.*.csv`). Optionally saves diagnostic files and/or sends a notification if usage exceeds a threshold.

##### Options
`-d`
	If the usage of the old or permanent generations exceeds 90%, save diagnostic files to `~/log/GC.heap_dump.*.hprof` and `~/log/GC.class_histogram.*.txt`.

`-n`
	If the usage of the old or permanent generations exceeds 90%, send an email notification to the cspace-support mailing list.

### csdeployreports - (re)deploy reports for this deployment
##### Synopsis
```
csdeployreports
```
##### Description
Copies report JRXML files for this deployment into the cspace reports directory, and removes existing compiled reports. CollectionSpace will recompile them as needed.

### cssetup - perform one-time set up of a new CollectionSpace service

##### Synopsis
```
cssetup
```
##### Description
Sets up a new CollectionSpace service. This program should be run once in each application owner account, after that account has been created. The program performs the set up that can be automated, and prints instructions for manually completing the installation. This program is not designed to be run more than once by an application owner.
