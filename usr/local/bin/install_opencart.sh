#!/bin/bash
OIFS=$IFS;
IFS=",";


source /etc/opencart-installer.conf


# An error exit function

function error_exit
{
	echo "$1" 1>&2
	exit 1
}


while getopts ":p:u:d:t:v:m:n:c:h:e:l:?" opt; do
    case $opt in
        p)
            DESTINATION_PATH=$OPTARG
            # echo "-p was triggered, Parameter: $DESTINATION_PATH" >&2
            ;;
        e)
            EXTENSION=$OPTARG
            # echo "-e was triggered, Parameter: $EXTENSION" >&2
            ;;
        u)
            FOR_USER=$OPTARG
            # echo "-u was triggered, Parameter: $FOR_USER" >&2
            ;;
        d)
            DATABASE=$OPTARG
            # echo "-d was triggered, Parameter: $DATABASE" >&2
            ;;
        t)
            TEMPLATE=$OPTARG
            # echo "-t was triggered, Parameter: $TEMPLATE" >&2
            ;;
        v)
            VERSION=$OPTARG
            # echo "-v was triggered, Parameter: $VERSION" >&2
            ;;
           
        h)
             HOST=$OPTARG
            # echo "-h was triggered, Parameter: $HOST" >&2
            ;;

        m)
            DOMAIN=$OPTARG
            # echo "-m was triggered, Parameter: $DOMAIN" >&2
            ;;
        n)
            PROJECT_NAME=$OPTARG
            echo "Project Name given: $PROJECT_NAME" >&2
            ;;
        l)
            VERBOSE=true
            echo "Project Name given: $PROJECT_NAME" >&2
            ;;
        c)
            TRUNCATE=true
            echo "will truncate the database"
            ;;
       
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
        ?)
            echo ""
            echo "Opencart Installer by Jason Clark <mithereal@gmail.com> and Nikos Tsitas <nktsitas@gmail.com>" 
            echo ""
            echo "Usage: opencart -n <project_name> -u <user_name> -d <database_name> -m <domain_url> -h <host_url> -l = verbose" 
            exit 1
            ;;
    esac
done

OPENCART_PATH=$OPENCART_PATH/opencart
templateArray=($TEMPLATE);
extensionArray=($EXTENSION);

echo ""
echo "Opencart Installer"
echo ""
read -p "Enter the hostname of the database: " MYSQL_HOST
read -p "Enter the username for the database: " MYSQL_USERNAME
printf "Enter the password for the database: "
read -s  MYSQL_PASS


if [ ! -d "$TEMP_DIR" ]; then
mkdir $TEMP_DIR;
fi

# -v <version> (version to install)
if [ -z "$VERSION" ]
then
    VERSION="current"
    echo "using version: $STABLE_VERSION" >&2
else
    echo "using version: $VERSION" >&2
OPENCART_PATH=$OPENCART_PATH/opencart-$VERSION
fi


# -p <path> (current folder if none given)
if [ -z "$DESTINATION_PATH" ]
then
    if [ -z "$PROJECT_NAME" ]
    then
        DESTINATION_PATH="mystore"
        echo "no destination path/project name given, setting to: $PWD/mystore" >&2
    else
        DESTINATION_PATH=$PROJECT_NAME
        echo "no destination path given, setting to project name: $DESTINATION_PATH" >&2
    fi
else
    echo "destination path: $DESTINATION_PATH" >&2
fi

# -u <user> (current user if none given)
if [ -z "$FOR_USER" ]
then
    FOR_USER="$USER"
    echo "no user given, setting to: $FOR_USER" >&2
else
    echo "user: $FOR_USER" >&2
fi

# -h <hostname> (http://cheetasoft.gr/<domain> if none given)
if [ -z "$HOST" ]
then
  HOST="cheetasoft.gr"
echo "no hostname given, setting default: $HOST" >&2
else
    echo "host: $HOST" >&2
fi

# -m <domain> (http://<hostname>/mystore if none given)
if [ -z "$DOMAIN" ]
then
    if [ -z "$PROJECT_NAME" ]
    then
        DOMAIN="http://$HOST/mystore/"
        echo "no domain/project name given, setting default: $DOMAIN" >&2
    else
        DOMAIN="http://$HOST/$PROJECT_NAME/"
        echo "no domain given, setting with project name: $DOMAIN" >&2
    fi
else
    echo "domain: $DOMAIN" >&2
fi

# -d <database> (Error if none given)
if [ -z "$DATABASE" ]
then
    if [ -z "$PROJECT_NAME" ]
    then
        DATABASE="${FOR_USER}_mystore"
        echo "no database/project name given, setting default: $DATABASE" >&2
    else
        DATABASE="${FOR_USER}_${PROJECT_NAME}"
        echo "no database given, setting with project name: $DATABASE" >&2
    fi
else
    echo "database: $DATABASE" >&2
fi

# create path folder if not exists (this won't work if parent folder missing)
if [ ! -d "$DESTINATION_PATH" ]; then
    mkdir $DESTINATION_PATH
fi

# detect Operating System
OS=`uname`

if [ $VERSION == stable ]
then
# purge tmp folder
rm -drf $TEMP_DIR/opencart

# clone opencart
cd $TEMP_DIR
git clone -b v$STABLE_VERSION $STABLE

# check if opencart is in folder
if [ -f opencart/upload/index.php ];
then
OPENCART_PATH=$TEMP_DIR/opencart/upload
fi 

elif [ $VERSION == upstream ]
then
# purge tmp folder
rm -drf $TEMP_DIR/opencart

# clone opencart
cd $TEMP_DIR
git clone $UPSTREAM

# check if opencart is in folder
if [ -f opencart/upload/index.php ];
then
OPENCART_PATH=$TEMP_DIR/opencart/upload
fi

elif [ $VERSION == origin ]
then
# purge tmp folder
rm -drf $TEMP_DIR/opencart

# clone opencart
cd $TEMP_DIR
git clone $ORIGIN

# check if opencart is in folder
if [ -f opencart/upload/index.php ];
then
OPENCART_PATH=$TEMP_DIR/opencart/upload
fi 
fi

# copy opencart
mkdir $DESTINATION_PATH
cp -r $OPENCART_PATH/* $DESTINATION_PATH
cp $OPENCART_PATH/.htaccess.txt $DESTINATION_PATH/.htaccess
cp $OPENCART_PATH/.gitignore $DESTINATION_PATH/.gitignore

# rename config files 
mv $DESTINATION_PATH/config-dist.php $DESTINATION_PATH/config.php
mv $DESTINATION_PATH/admin/config-dist.php $DESTINATION_PATH/admin/config.php

# change permissions
if [[ "$OS" == 'Linux' ]]; then
if [[ -z "$VERBOSE" ]]; then

    # change permissions
    chown -R $FOR_USER:$FOR_USER $DESTINATION_PATH > /dev/null 2>&1
    chmod -R 755 $DESTINATION_PATH > /dev/null 2>&1

    chmod 0777 $DESTINATION_PATH/config.php > /dev/null 2>&1
    chmod 0777 $DESTINATION_PATH/admin/config.php > /dev/null 2>&1

    chmod 0777 $DESTINATION_PATH/system/cache/ > /dev/null 2>&1
    chmod 0777 $DESTINATION_PATH/system/logs/ > /dev/null 2>&1
    chmod 0777 $DESTINATION_PATH/image/ > /dev/null 2>&1
    chmod 0777 $DESTINATION_PATH/image/cache/ > /dev/null 2>&1
    chmod 0777 $DESTINATION_PATH/image/data/ > /dev/null 2>&1
    chmod 0777 $DESTINATION_PATH/download/ > /dev/null 2>&1
else
    # change permissions
    chown -R $FOR_USER:$FOR_USER $DESTINATION_PATH 
    chmod -R 755 $DESTINATION_PATH 

    chmod 0777 $DESTINATION_PATH/config.php 
    chmod 0777 $DESTINATION_PATH/admin/config.php 

    chmod 0777 $DESTINATION_PATH/system/cache/ 
    chmod 0777 $DESTINATION_PATH/system/logs/
    chmod 0777 $DESTINATION_PATH/image/ 
    chmod 0777 $DESTINATION_PATH/image/cache/ 
    chmod 0777 $DESTINATION_PATH/image/data/ 
    chmod 0777 $DESTINATION_PATH/download/ 
fi
else
    icacls $DESTINATION_PATH /grant:r Everyone:RX /t

    icacls $DESTINATION_PATH/config.php /grant:r Everyone:F /t
    icacls $DESTINATION_PATH/admin/config.php /grant:r Everyone:F /t

    icacls $DESTINATION_PATH/system/cache/ /grant:r Everyone:F /t
    icacls $DESTINATION_PATH/system/logs/ /grant:r Everyone:F /t
    icacls $DESTINATION_PATH/image/ /grant:r Everyone:F /t
    icacls $DESTINATION_PATH/image/cache/ /grant:r Everyone:F /t
    icacls $DESTINATION_PATH/image/data/ /grant:r Everyone:F /t
    icacls $DESTINATION_PATH/download/ /grant:r Everyone:F /t
fi

# create database
if [[ "$MYSQL_PASS" == '' ]]; then
    echo "create database $DATABASE" | mysql -u $MYSQL_USERNAME
else
    echo "create database $DATABASE" | mysql -u $MYSQL_USERNAME -p$MYSQL_PASS
fi

# abort/exit if database creation fails
if [ $? -eq 0 ]; then
    echo "Database $DATABASE Created Successfully."
else
    echo "Error in database creation. Aborting."
    rm -rf $DESTINATION_PATH/
    exit 1
fi


echo "Installing opencart $VERSION..."
if [[ "$MYSQL_PASS" == '' ]]; then
    php $DESTINATION_PATH/install/cli_install.php install --db_host $MYSQL_HOST --db_user $MYSQL_USERNAME --db_password "" --db_name $DATABASE --db_prefix oc_ --username admin --password admin123 --email admin@example.com --agree_tnc yes --http_server $DOMAIN
else
    php $DESTINATION_PATH/install/cli_install.php install --db_host $MYSQL_HOST --db_user $MYSQL_USERNAME --db_password $MYSQL_PASS --db_name $DATABASE --db_prefix oc_ --username admin --password admin123 --email admin@example.com --agree_tnc yes --http_server $DOMAIN
fi



if $TRUNCATE; then
    echo "Truncating opencart $VERSION database..."
    if [[ "$MYSQL_PASS" == '' ]]; then
        cat $TRUNCATE_FILE | mysql -u $MYSQL_USERNAME $DATABASE
    else
        cat $TRUNCATE_FILE | mysql -u $MYSQL_USERNAME -p$MYSQL_PASS $DATABASE
    fi
fi

# remove install folder
rm -rf $DESTINATION_PATH/install/

# install template 
if [ -z "$TEMPLATE" ]
then
    echo "No template given. Using default" >&2
else
for ((i=0; i<${#templateArray[@]}; ++i));
do
    echo "Installing template: $templateArray[$i]" >&2

        cp -r $THEME_DIR/$templateArray[$i]/$VERSION/upload/* $DESTINATION_PATH/
        chown -R $FOR_USER:$FOR_USER $DESTINATION_PATH

        if [[ "$MYSQL_PASS" == '' ]]; then
            cat $JOURNAL_IMAGE_SETUP_SQL | mysql -u $MYSQL_USERNAME $DATABASE
            cat $JOURNAL_MODULES_SETUP_SQL | mysql -u $MYSQL_USERNAME $DATABASE
        else
            cat $JOURNAL_IMAGE_SETUP_SQL | mysql -u $MYSQL_USERNAME -p$MYSQL_PASS $DATABASE
            cat $JOURNAL_MODULES_SETUP_SQL | mysql -u $MYSQL_USERNAME -p$MYSQL_PASS $DATABASE
        fi
done
fi

# install extension 
if [ "$EXTENSION" ]
then
for ((i=0; i<${#extensionArray[@]}; ++i));
do
    echo "Installing template: $extensionArray[$i]" >&2

        cp -r $EXTENSION_DIR/$extensionArray[$i]/$VERSION/upload/* $DESTINATION_PATH/
        chown -R $FOR_USER:$FOR_USER $DESTINATION_PATH

        if [[ "$MYSQL_PASS" == '' ]]; then
            cat $JOURNAL_IMAGE_SETUP_SQL | mysql -u $MYSQL_USERNAME $DATABASE
            cat $JOURNAL_MODULES_SETUP_SQL | mysql -u $MYSQL_USERNAME $DATABASE
        else
            cat $JOURNAL_IMAGE_SETUP_SQL | mysql -u $MYSQL_USERNAME -p$MYSQL_PASS $DATABASE
            cat $JOURNAL_MODULES_SETUP_SQL | mysql -u $MYSQL_USERNAME -p$MYSQL_PASS $DATABASE
        fi
done
fi

IFS=$OIFS;

#set up git repo
cd $DESTINATION_PATH
git init
git add .
git commit -m "initial commit"

exit 0