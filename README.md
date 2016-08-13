# gitinitwp

#### A POSIX-compliant script that bootstraps a directory for new GitHub-based WordPress projects.


## Details

**Current version**: 0.1.0-0
*(expect breaking changes prior to version 1.0)*

**Source code**: [https://github.com/moismailzai/gitinitwp](https://github.com/moismailzai/gitinitwp)

**License**: [MIT](https://opensource.org/licenses/MIT)

**Copyright**: &copy; 2016 [Misaqe Ismailzai](http://www.moismailzai.com) <moismailzai@gmail.com>


## Installation

**Standalone**: [regular](https://cdn.rawgit.com/moismailzai/gitinitwp/master/gitinitwp.sh)

``` sh
git clone https://github.com/moismailzai/gitinitwp
chmod +x gitinitwp.sh
```

## Dependancies

A POSIX-compliant shell.


## What Does It Do?

Bootstraps a directory for new GitHub-based WordPress projects.

The script creates a new directory and populates it with the following files and folders:
```
|-- wordpress/
|- README.md
|- .gitignore
```
Each file is configured based on user-defined script defaults or command-line arguments. Usage is straightforward:


## Usage:
```
usage: gitinitwp [[[-a author_name] [-e author_email] [-g github_user_id] [-l local_wp_archive] [-m mysql_host] [-p project_name] [-q mysql_password] [-r remote_wp_url] [-t target_directory] [-u author_url] [-v mysql_user_id]] | [-h]]


       -a author_name:      the author's name (used to attribute ownership in various files)
                            (the default value can be configured in \$AUTHOR_NAME and is currently set to \"$AUTHOR_NAME\")

       -e author_email:     the author's email address (used to set contact information in various files)
                            (the default value can be configured in \$AUTHOR_EMAIL and is currently set to \"$AUTHOR_EMAIL\")

       -g github_user_id:   the github.com user id to associate this project with (used to generate links in various files)
                            (the default value can be configured in \$GITHUB_USER_ID and is currently set to \"$GITHUB_USER_ID\")

       -l local_wp_archive: the local WordPress archive to use (if this is not specified, the latest archive will be downloaded)
                            (the default value can be configured in \$WORDPRESSARCHIVELOCAL and is currently set to \"$WORDPRESSARCHIVELOCAL\")

       -m mysql_host:       the MySQL host address (required to generate wp-config.php)
                            (the default value can be configured in \$MYSQLHOST and is currently set to \"$MYSQLHOST\")

       -p project_name:     the project name (used as the project directory name as well)
                            (the default value is the current directory's name, \"${PWD}\")

       -q mysql_password:   the MySQL password (required to generate wp-config.php)
                            (the default value can be configured in \$MYSQLPASS and is currently set to \"$MYSQLPASS\")

       -r remote_wp_url:    the remote WordPress archive to download (will be fetched if a local archive is not present)
                            (the default value can be configured in \$WORDPRESSARCHIVEREMOTE and is currently set to \"$WORDPRESSARCHIVEREMOTE\")

       -t target_directory: the target directory under which the project directory should be created
                            (the default value can be configured in \$TARGET_DIRECTORY and is currently set to \"$TARGET_DIRECTORY\")

       -u author_url:       the author's URL (used to set contact information in various files)
                            (the default value can be configured in \$AUTHOR_URL and is currently set to \"$AUTHOR_URL\")

       -v mysql_user_id:    the MySQL user id (required to generate wp-config.php)
                            (the default value can be configured in \$MYSQLUSERNAME and is currently set to \"$MYSQLUSERNAME\")

       -h:                  display this message   
```

**Setting Project Defaults**

Edit the default variables, found at the top of the script:  
``` sh 
##### User Defaults (change these to set project defaults) #####################
AUTHOR_NAME="Your Name"
AUTHOR_EMAIL="your@email.com"
AUTHOR_URL="http://www.yourwebsite.com"
GITHUB_USER_ID="youruserid"

TARGET_DIRECTORY="${PWD}/"

LOCALUSER="${USER}"
WEBSERVERGROUP="http"

MYSQLHOST="localhost"
MYSQLUSERNAME="${USER}"
MYSQLPASS="local-password"

WORDPRESSARCHIVELOCAL="" # eg. /some/path/to/latest.tar.gz
WORDPRESSARCHIVEREMOTE="https://wordpress.org/latest.tar.gz"

WORDPRESSDOWNLOADCOMMAND="wget $WORDPRESSARCHIVEREMOTE" # eg. wget $WORDPRESSARCHIVEREMOTE
WORDPRESSUNPACKCOMMAND="tar xvzf" # eg. tar xvzf
##### END OF CONFIGURABLE DEFAULTS #############################################
```  


**Bootstrapping a Project**

// the script assumes you've set sane defaults so simply calling it is enough to get you rolling (though you'll be asked to confirm that you want to use the current directory, and its name, as the root directory of a new project).

``` sh
gitinitjs.wp
```

// calling with -p will bootstrap a project called "weareuoft" in a directory called "weareuoft" (provided the directory doesn't already exist). By default, this project directory is placed wherever the script is invoked from but you can alter the behavior by changing the "TARGET_DIRECTORY" variable to a path of your choice.

``` sh
gitinitjs.wp -p weareuoft
```

// you can force the script to completely override all defaults by explicitly providing each parameter:
``` sh
gitinitwp.sh -a "Mo Ismailzai" -e "moismailzai@gmail.com" -g "moismailzai" -u "http://www.moismailzai.com" -p weareuoft -m localhost -q localpassword -r https://wordpress.org/latest.tar.gz -v mo 
```
