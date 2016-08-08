[![Build Status](https://travis-ci.org/cyber-dojo/web.svg?branch=master)](https://travis-ci.org/cyber-dojo/web)

<img src="https://raw.githubusercontent.com/cyber-dojo/web/master/public/images/home_page_logo.png" alt="cyber-dojo yin/yang logo" width="50px" height="50px"/>

Main repo for a [cyber-dojo](http://cyber-dojo.org) web server.<br/>

  * Hi. I'm [Jon Jagger](http://jonjagger.blogspot.co.uk/). Welcome to cyber-dojo :-)
  * a [dojo](http://en.wikipedia.org/wiki/Dojo) is a place where martial artists meet to practice their martial art
  * a cyber-dojo is where programmers meet to [practice](http://jonjagger.blogspot.co.uk/2013/10/practice.html) programming!
  * a cyber-dojo is <em>not</em> an Individual Development Environment
  * a cyber-dojo is an Interactive Dojo Environment!
  * a cyber-dojo is about [shared](http://jonjagger.blogspot.co.uk/2013/10/teams.html) [learning](http://jonjagger.blogspot.co.uk/2013/10/learning.html)
  * in a cyber-dojo you [practice](http://jonjagger.blogspot.co.uk/2013/10/practice.html) by going <em>slower</em> and focusing on [improving](http://jonjagger.blogspot.co.uk/2014/02/improving.html) rather than finishing
  * [cyber-dojo foundation](http://blog.cyber-dojo.org/2015/08/cyber-dojo-foundation.html) is a registered Scottish Charitable Incorporated Organisation
  * [how do I use cyber-dojo?](http://blog.cyber-dojo.org/2014/08/getting-started.html)
  * [learn more](http://blog.cyber-dojo.org/p/learn-more.html)

---

Running your own cyber-dojo server...

(1) make sure docker, docker-engine, and docker-compose are installed

```
$ curl -O https://raw.githubusercontent.com/cyber-dojo/web/master/cli/install-docker.sh
$ chmod +x install-docker.sh
$ sudo ./install-docker.sh
```

(2) download the cyber-dojo shell script

```
$ curl -O https://raw.githubusercontent.com/cyber-dojo/web/master/cli/cyber-dojo
$ chmod +x cyber-dojo
```

(3) use the script to bring up your server

```
$ sudo ./cyber-dojo up
```
