#!/usr/bin/env sh
#
# Author: Bo-Yi Wu <appleboy AT gmail.com>
# Home Page: http://blog.wu-boy.com
# Create or remove [apache|nginx] virtual host script.
#

version="1.0"

display() {
    echo $1
    exit
}

print_version() {
    echo "Create apache or nginx virtual host tool (c) 2013 by Bo-Yi Wu, version $version"
}

usage() {
    print_version
    echo
    echo "Usage: $0 [nginx|apache] [add|del] config_name server_path domain_name"
    exit 0
}

[ `whoami` != "root" ] && display "You don't have permission to access it. Please use root permission."

[ $# -lt 5 ] && usage

time=$(date +%Y%m%d%H%M%S)
config_type=$1
action=$2
config_name=$3
server_path=$(echo $4 | sed 's/\/$//g')
server_name=$5

case $config_type in
    nginx)
        config_path="/etc/nginx"
        [ ! -d $config_path ] && display "folder /etc/nginx is not exist. Please check it."
        [ ! -d "${config_path}/sites-available/" ] && mkdir -p "${config_path}/sites-available/"
        [ ! -d "${config_path}/sites-enabled/" ] && mkdir -p "${config_path}/sites-enabled/"
    ;;
    apache)
        config_path="/etc/apache2"
    ;;
    *)
        usage
    ;;
esac

case $action in
    add)
        sed_server_name=$(echo $server_name | sed 's/\./\\\./g')
        sed_server_path=$(echo "${server_path}" | sed 's/\/$//g' | sed 's/\//\\\//g')

        # create empty folder.
        [ ! -d "${server_path}/www" ] && mkdir -p "${server_path}/www"
        [ ! -d "${server_path}/log" ] && mkdir -p "${server_path}/log"
        # backup source file if exits.
        [ -f "${config_path}/sites-available/${config_name}" ] && cp -r "${config_path}/sites-available/${config_name}" "${config_path}/sites-available/${config_name}.${time}"
        [ ! -L "${config_path}/sites-enabled/${config_name}" ] && ln -s "${config_path}/sites-available/${config_name}" "${config_path}/sites-enabled/${config_name}"
        cp -r nginx/sites-available/domain.conf "${config_path}/sites-available/${config_name}"
        sed -i "s/{{server_name}}/${sed_server_name}/g" "${config_path}/sites-available/${config_name}"
        sed -i "s/{{server_path}}/${sed_server_path}/g" "${config_path}/sites-available/${config_name}"
        sed -i "s/{{config_name}}/${config_name}/g" "${config_path}/sites-available/${config_name}"
        echo "========================================"
        echo "Domain: http://${server_name}"
        echo "Web Path: ${server_path}/www"
        echo "Log Path: ${server_path}/log"
        echo "========================================"
    ;;
    del)
        [ -L "${config_path}/sites-enabled/${config_name}" ] && unlink "${config_path}/sites-enabled/${config_name}" && echo "remove ${config_path}/sites-enabled/${config_name} link."
        [ -f "${config_path}/sites-available/${config_name}" ] && rm -rf "${config_path}/sites-available/${config_name}" && echo "remove ${config_path}/sites-available/${config_name} config."
        read -p "Do you want to delete ${server_path} folder [y/n]: " confirm
        test $confirm = "y" -o $confirm = "Y" && rm -rf $server_path
        echo "remove ${config_name} virtual host"
    ;;
    *)
        usage
    ;;
esac
