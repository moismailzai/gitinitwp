#!/bin/sh

# gitinitwp - A POSIX-compliant script that bootstraps a directory for new GitHub-based WordPress projects.
# parsed with http://www.shellcheck.net/ to ensure POSIX-compliance.


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


#### Constants

OPTIND=1 # reinitialize getopts variable
OPTERR=1 # ensure getopts variable is set
PROJECT_NAME_INPUT=""
PROJECT_NAME_PARSED=""
PROJECT_DIRECTORY=""
SCRIPTNAME=$(basename "$0")
YEAR=$(date +'%Y')


##### Functions

usage ()
{
    echo "
    usage: $SCRIPTNAME [[[-a author_name] [-e author_email] [-g github_user_id] [-l local_wp_archive] [-m mysql_host] [-p project_name] [-q mysql_password] [-r remote_wp_url] [-t target_directory] [-u author_url] [-v mysql_user_id]] | [-h]]


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
"
} # end of usage

echoerror () # send error messages to standard error
{
  echonicely "$@" 1>&2;
} # end of echoerror

echonicely () # add padding to echo'd messages
{
  echo "
        ${1}
       "
} # end of echonicely

confirm () # based on https://stackoverflow.com/questions/3231804/in-bash-how-to-add-are-you-sure-y-n-to-any-command-or-alias/3232082#3232082
{
  echonicely "${1:-Are you sure? [y/N]}"
  read -r response
  case "$response" in
      [yY][eE][sS]|[yY])
          return 0
          ;;
      *)
          return 1
          ;;
  esac
} # end of confirm

# shellcheck disable=SC2166
string_contains () # black magic: POSIX-compliant string_contains function found at http://stackoverflow.com/a/20460402 # potential portability issue? --> https://github.com/koalaman/shellcheck/wiki/SC2166
{
  [ -z "${2##*$1*}" ] && [ -z "$1" -o -n "$2" ];
} # end of string_contains

git_init ()
{
  directory_path="$./.git"
  create_git=true
  if [ -d "$directory_path" ];
    then
      if confirm "A local .git folder already exists in \"$directory_path\", git init anyway? [y/N]";
        then
          create_git=true
        else
          create_git=false
          echoerror "Git repository already exists. Skipping git steps."
      fi
    else
      create_git=true
  fi
  if $create_git;
    then
      cd "$PROJECT_DIRECTORY" || exit 1
      git init
      git add .
      git commit -m "First commit."
  fi
} # end of git_init

fix_permissions ()
{
  wordpress_path="$PROJECT_DIRECTORY/wordpress"
  cd $wordpress_path || exit 1
  sudo usermod -a -G "$WEBSERVERGROUP" "$LOCALUSER" || return 1
  sudo find . -exec chown "$LOCALUSER":"$WEBSERVERGROUP" {} + || return 1
  sudo find . -type f -exec chmod 664 {} +
  sudo find . -type d -exec chmod 775 {} +
  sudo chmod 660 wp-config.php
  cd $PROJECT_DIRECTORY || exit 1
} # end of fix_permissions

parse_name ()
{
  if [ "$PROJECT_NAME_INPUT" != "" ]; # if a project name was provided to the script
    then
      PROJECT_NAME_PARSED="$(printf '%s' "$PROJECT_NAME_INPUT" | sed -e 's/[[:blank:]]//g' -e 's/[^a-zA-Z0-9]//g')" # sanitize the input and use it as the project name
      PROJECT_DIRECTORY="$TARGET_DIRECTORY$PROJECT_NAME_PARSED" # set the project directory based on the $TARGET_DIRECTORY and project name
      if [ "$PROJECT_NAME_PARSED" = "$PROJECT_NAME_INPUT" ]; # ensure the sanitized input matches the original input (so the project we create has the expected name)
        then
          if [ -d "$PROJECT_DIRECTORY" ];
            then
              confirm "Local \"$PROJECT_NAME_PARSED\" directory already exists. Use it anyway? [y/N]" || return 1
            else
              mkdir "$PROJECT_DIRECTORY" || return 1
          fi
        else
          if confirm "\"$PROJECT_NAME_INPUT\" is not a valid project name. Use \"$PROJECT_NAME_PARSED\" instead? [y/N]";
            then
              mkdir "$PROJECT_DIRECTORY" || return 1
            else
              return 1
          fi
      fi
    else
      if confirm "No project name specified. Use the current directory for project \"${PWD##*/}\"? [y/N]";
        then
          PROJECT_NAME_PARSED="${PWD##*/}"
          PROJECT_DIRECTORY="${PWD}/" # set the project directory to the current directory
          return 0
        else
          return 1
      fi
  fi
} # end of parse_name

generate_readme ()
{
  github_url="https://github.com/$GITHUB_USER_ID/$PROJECT_NAME_PARSED"
  filename="$PROJECT_DIRECTORY/README.md"
  filecontents="# $PROJECT_NAME_PARSED

#### WordPress fies for $PROJECT_NAME_PARSED.

## Details

**Source code**: [$github_url]($github_url)

**Copyright**: &copy; $YEAR [$AUTHOR_NAME]($AUTHOR_URL) <$AUTHOR_EMAIL>


## Installation

To fix user account permissions on your hosting environment, run the following commands in the remote wordpress directory:
\`\`\`
  sudo usermod -a -G WEBSERVERGROUP USERNAME
  sudo find . -exec chown USERNAME:WEBSERVERGROUP {} +
\`\`\`

To fix WordPress file permissions on your hosting environment, run the following commands in the remote wordpress directory:
\`\`\`
  sudo find . -type f -exec chmod 664 {} +
  sudo find . -type d -exec chmod 775 {} +
  sudo chmod 660 wp-config.php
\`\`\`

"
  [ -e "$filename" ] && echonicely "\"$filename\" already exists, skipping." || echo "$filecontents" >> "$filename"
} # end of generate_readme

generate_gitignore ()
{
  filename="$PROJECT_DIRECTORY/.gitignore"
  filecontents="# Created by https://www.gitignore.io/api/macos,linux,intellij

### macOS ###
*.DS_Store
.AppleDouble
.LSOverride

# Icon must end with two \r
Icon


# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk


### Linux ###
*~

# temporary files which can be created if a process still has a handle open of a deleted file
.fuse_hidden*

# KDE directory preferences
.directory

# Linux trash folder which might appear on any partition or disk
.Trash-*

### Intellij ###
# Covers JetBrains IDEs: IntelliJ, RubyMine, PhpStorm, AppCode, PyCharm, CLion, Android Studio and Webstorm
# Reference: https://intellij-support.jetbrains.com/hc/en-us/articles/206544839

# User-specific stuff:
.idea/workspace.xml
.idea/tasks.xml
.idea/dictionaries
.idea/vcs.xml
.idea/jsLibraryMappings.xml

# Sensitive or high-churn files:
.idea/dataSources.ids
.idea/dataSources.xml
.idea/dataSources.local.xml
.idea/sqlDataSources.xml
.idea/dynamic.xml
.idea/uiDesigner.xml

# Gradle:
.idea/gradle.xml
.idea/libraries

# Mongo Explorer plugin:
.idea/mongoSettings.xml

## File-based project format:
*.iws

## Plugin-specific files:

# IntelliJ
/out/

# mpeltonen/sbt-idea plugin
.idea_modules/

# JIRA plugin
atlassian-ide-plugin.xml

# Crashlytics plugin (for Android Studio and IntelliJ)
com_crashlytics_export_strings.xml
crashlytics.properties
crashlytics-build.properties
fabric.properties

### Intellij Patch ###
# Comment Reason: https://github.com/joeblau/gitignore.io/issues/186#issuecomment-215987721

# *.iml
# modules.xml
# .idea/misc.xml
# *.ipr
"
  [ -e "$filename" ] && echonicely "\"$filename\" already exists, skipping." || echo "$filecontents" >> "$filename"
} # end of generate_gitignore

generate_wpconfig ()
{
  filename="$PROJECT_DIRECTORY/wordpress/wp-config.php"
  generate_salt="< /dev/urandom tr -cd [:alnum:]-[:punct:]-[:print:] | tr -d \"\\\\'\" | head -c\${1:-64}"
  filecontents="<?php
define('DB_NAME', 'wp-$PROJECT_NAME_PARSED');
define('DB_USER', '$MYSQLUSERNAME');
define('DB_PASSWORD', '$MYSQLPASS');
define('DB_HOST', '$MYSQLHOST');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

define('FS_METHOD', 'direct');

define('AUTH_KEY',         '$(eval "$generate_salt")');
define('SECURE_AUTH_KEY',  '$(eval "$generate_salt")');
define('LOGGED_IN_KEY',    '$(eval "$generate_salt")');
define('NONCE_KEY',        '$(eval "$generate_salt")');
define('AUTH_SALT',        '$(eval "$generate_salt")');
define('SECURE_AUTH_SALT', '$(eval "$generate_salt")');
define('LOGGED_IN_SALT',   '$(eval "$generate_salt")');
define('NONCE_SALT',       '$(eval "$generate_salt")');

\$table_prefix  = 'wp_';

define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

require_once(ABSPATH . 'wp-settings.php');
?>
"
  [ -e "$filename" ] && echonicely "\"$filename\" already exists, skipping." && exit 1 || echo "$filecontents" >> "$filename"
} # end of generate_wpconfig


##### Main

while getopts ":ha:e:g:l:m:p:q:r:t:u:v:" opt; do
    case "$opt" in
      h)
          usage
          exit 0
          ;;
      a)
          AUTHOR_NAME="$(printf '%s' "$OPTARG" | sed -e 's/[^a-zA-Z[:blank:]]//g')"
          echonicely "Setting author name to \"$AUTHOR_NAME\"."
          ;;
      e)
          AUTHOR_EMAIL="$(printf '%s' "$OPTARG" | sed -e 's/[[:blank:]]//g' -e 's/[^a-zA-Z0-9@.]//g')"
          if string_contains "@" "$AUTHOR_EMAIL";
            then
              AUTHOR_EMAIL="$OPTARG"
              echonicely "Setting author email address to \"$AUTHOR_EMAIL\"."
            else
              echoerror "\"$OPTARG\" doesn't appear to be a valid email address."
              exit 1
          fi
          ;;
      g)
          GITHUB_USER_ID="$(printf '%s' "$OPTARG" | sed -e 's/[[:blank:]]//g' -e 's/[^a-zA-Z0-9]//g')"
          echonicely "Setting github user id to \"$GITHUB_USER_ID\"."
          ;;
      l)
          WORDPRESSARCHIVELOCAL="$OPTARG"
          if [ -e "$WORDPRESSARCHIVELOCAL" ];
            then
              echonicely "Setting local WordPress archive to \"$WORDPRESSARCHIVELOCAL\"."
            else
              echoerror "Sorry, $WORDPRESSARCHIVELOCAL is inaccessible."
              exit 1
          fi
          ;;
      m)
          MYSQLHOST="$OPTARG"
          echonicely "Setting MySQL host to \"$MYSQLHOST\"."
          ;;
      p)
          PROJECT_NAME_INPUT="$OPTARG"
          ;;
      q)
          MYSQLPASS="$OPTARG"
          echonicely "Setting MySQL password to \"$MYSQLPASS\"."
          ;;
      r)
          WORDPRESSARCHIVEREMOTE="$OPTARG"
          echonicely "Setting remote WordPress archive to \"$WORDPRESSARCHIVEREMOTE\"."
          ;;
      t)
          if [ -d "$OPTARG" ]; # ensure this is a directory
            then
              if [ -w "$OPTARG" ]; # ensure we can write to the directory
                then
                  TARGET_DIRECTORY="$OPTARG/" # add a trailing / (multiple trailing //'s get flattened but this will ensure there's always at least one)
                  echonicely "Setting base directory to \"$TARGET_DIRECTORY\"."
                  else
                  echonicely "Cannot write to directory \"$OPTARG\"."
                  exit 1
              fi
            else
              echonicely "\"$OPTARG\" is not a directory."
              exit 1
          fi
          ;;
      u)
          AUTHOR_URL="$(printf '%s' "$OPTARG" | sed -e 's/[[:blank:]]//g' -e 's/[^a-zA-Z0-9/.]//g')"
          if string_contains "." "$AUTHOR_URL" && string_contains "/" "$AUTHOR_URL";
            then
              AUTHOR_URL="$OPTARG"
              echonicely "Setting author url to \"$AUTHOR_URL\"."
            else
              echoerror "\"$OPTARG\" doesn't appear to be a valid url."
              exit 1
          fi
          ;;
      v)
          MYSQLUSERNAME="$OPTARG"
          echonicely "Setting MySQL user id to \"$MYSQLUSERNAME\"."
          ;;
      *)
          echoerror "Invalid option: -$OPTARG"
          exit 1
          ;;
      :)
          echoerror "Option -$OPTARG requires an argument."
          exit 1
          ;;
    esac
done

if parse_name;
  then
    cd "$PROJECT_DIRECTORY" || exit 1
    if [ -e "$WORDPRESSARCHIVELOCAL" ];
        then
            eval "$WORDPRESSUNPACKCOMMAND" "$WORDPRESSARCHIVELOCAL"
        else
              echoerror "This script requires a valid WordPress archive. Attempting to download one from \"$WORDPRESSARCHIVEREMOTE\" using command \"$WORDPRESSDOWNLOADCOMMAND\"."
              eval "$WORDPRESSDOWNLOADCOMMAND" || echoerror "Sorry, was unable to download WordPress using $WORDPRESSDOWNLOADCOMMAND."
              eval "$WORDPRESSUNPACKCOMMAND" "${WORDPRESSARCHIVEREMOTE##*/}" || echoerror "Sorry, was unable to unpack WordPress using $WORDPRESSUNPACKCOMMAND."
    fi
    cd "$PROJECT_DIRECTORY"/wordpress || exit 1
    generate_readme
    generate_gitignore
    generate_wpconfig
    fix_permissions || exit 1
    git_init
    echonicely ""
    echonicely "SUCCESS!"
    echonicely ""
  else
    echoerror "No changes were made."
fi
