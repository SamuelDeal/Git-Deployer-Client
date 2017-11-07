Git-Deployer-Client - A client for interacting with the Git-Deployer-Server (GDS)
==================================================================================

Table of Contents:
------------------

* [Introduction] (#intro)
* [Install] (#install)


<a name="intro"></a>
### Introduction
Git Deployer Client is a script who trigger an update by contacting the GDS (Git Deployer Server).
It simply hat to be put in a bare repository git hook.  
So it works well with all central git management tool such as : Gitolite, Gitlab, Gitorious, etc.

<a name="install"></a>
### Install and Config
The project needs sevral Perl plugins to work properly:

* IO::Socket (installed by default on main systems)
* Data::Dumper (installed by default on main systems)
* Config::Auto

To install them : 


```
$ perl -MCPAN -e shell
> install Config::Auto
> install IO::Socket
> install Data::Dumper
```

or for Debian :

```
$ apt-get install libconfig-auto-perl
```

Clone the project into your favorite directory :
```
$ git clone https://github.com/DrGkill/Git-Deployer-Client.git
```

Place the script call into your project Hook:

```
$ vim /path/to/my/project_bare_repository/hooks/post-update

#!/bin/sh
#
# An example hook script to prepare a packed repository for use over
# dumb transports.
#
# To enable this hook, rename this file to "post-update".

/path/to/git-deployer-client/GDC.pl $1

exec git update-server-info

```


Finally, configure your projects by editing the main configuration file :

Begin lines by '#' to make comments

```
$ cp GDC.config.sample GDC.config
$ vim GDC.config
# This file define which git deployer server to contact for given project
# Here some specification about the config format: 
#   * The repository matching is [project pattern/banch pattern]
#   * The pattern use full length PCRE.
#   * If the branch is not specified, all branches are accepted
#   * The matching is done from bottom to up
#   * You can use "ignore" to specify a project or branch to be ignored
#   * You can specify several servers, separated by ';'
#   * Each address should be at the following format: ipv4:port
#   * If you dont specify the port, the default one will be used

[.*]
    # This disable any project by default (except if defined further in this file) 
    ignore = 1

[test]
    # Match any branch of the project 'test'
    # Note that if no port is specified, 32337 will be used by default
    address = 127.0.0.1;

[test2/mybranch]
        # You can specify several servers to deploy on this way:
        address = 192.168.0.1:32337;127.0.0.1:32337;192.168.0.6:8888

[test2/master]
        # Here the master branch of the project has to be updated on one server
        address = my.testprod.com:32337

