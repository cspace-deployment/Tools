To "deploy" these documents:

```
  ssh cspace-dev-01.ist.berkeley.edu
  sudo su - app_webapps
  cd Tools/
  git pull -v
  cp -r webapps/docs/webappmanual/ /var/www/static/webappmanual
```

You should then be see these documents at:

https://webapps.cspace.berkeley.edu/webappmanual/pahma-webappmanual.html

and

https://webapps.cspace.berkeley.edu/webappmanual/bampfa-webappmanual.html

