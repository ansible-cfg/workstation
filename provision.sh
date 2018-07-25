#!/bin/bash

set -e

# Execute this script with the root user or an user with sudo privileges:

WORKSTATION_FOLDER="/workstation"
TMP_FOLDER="/tmp/workstation/ansible"

main() {
    prepare_paths_and_values

    # http proxy could be set in env instead of ansible/defaults/main.yaml, if running without vagrant mount
    if [[ $values_proxy_use_proxy_for_bootstrap == "true" ]] || [[ -v https_proxy ]] ; then
      setup_proxy "temporary" # "persistent" to export it system-wide TODO brauchen wir persistent?
    else
      printf "\nNo proxy used for bootstrap\n"
    fi

    execute "Setup basics" setup_basics
    execute "Cloning workstation repository" "check_clone ${values_repository_url:-https://github.com/sbueringer/workstation.git} $WORKSTATION_FOLDER"
    execute "Setup workstation" setup_workstation

    if [ -d $TMP_FOLDER ]; then
        execute "Do you want to delete the $TMP_FOLDER (incl. main.yaml)?" "rm -rf $TMP_FOLDER"
    fi
}

function log {
  message=$1
  if [[ tput -eq 0 ]]; then
    printf "\n###\n# %s\n###\n\n" "${white}${message}${normal}"
  else
    printf "\n###\n# %s\n###\n\n" "${message}"
  fi
}

function prepare_paths_and_values {
    unset CDPATH
    provision_sh_dir=$( dirname ${BASH_SOURCE[0]})
    cd $provision_sh_dir
    mkdir -p $TMP_FOLDER

    if [ -f ansible/defaults/main.yaml ]; then
        # workstation already there so just parse the main.yaml.
        #TODO wer hat den da reinkonfiguriert, vorher auf Windows?
        printf "\nParsing $provision_sh_dir/ansible/defaults/main.yaml\n\n"
        eval $(YamlParse__parse ansible/defaults/main.yaml "values_")
        YamlParse__parse ansible/defaults/main.yaml "values_"
    fi   
}

function execute {
  title=$1
  command=$2

  log "$title"

  response=$(vagrant_response "Execute? [Y/n]: " "Y")
  response=${response,,} # toLowerCase

  if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
    printf "\nExecuting $command\n\n"
    $command
  else
    printf "\nSkipping\n\n"
  fi  
}


function setup_basics {

  # TODO ohne -E sind die proxy variablen weg, für was ist -i da gewesen?
  echo "Execute: dnf update -y"
  sudo -E dnf update -y

  # TODO ohne -E sind die proxy variablen weg, für was ist -i da gewesen?
  echo "Execute: dnf install -y dnf-plugins-core git ansible libselinux-python"
  sudo -E dnf install -y dnf-plugins-core git ansible libselinux-python

  echo "localhost" | sudo tee /etc/ansible/hosts > /dev/null

}

function setup_proxy {
    if [[ $1 == "persistent" ]]; then
        target="/etc/profile.d/env.sh"
    else
        target="/dev/null"
    fi

    if [[ $https_proxy ]]; then
        printf "\nExporting proxy from env variable https_proxy\n"
        eval $(export_proxy $https_proxy $target)
    else
        if [[ -z "$values_proxy_hostname" ]]; then
            printf "No proxy variables found in ansible/defaults/main.yaml\n"
        else
            printf "\nUsing proxy from ansible/defaults/main.yaml\n"
            if [[ -z "${values_proxy_username}" ]]; then
                https_proxy="http://$values_proxy_hostname:$values_proxy_port"
            else
                https_proxy="http://$values_proxy_username:$values_proxy_password@$values_proxy_hostname:$values_proxy_port"
            fi
            printf "Exporting proxy from ansible/defaults/main.yaml\n"
            eval $(export_proxy $https_proxy $target)
        fi
    fi
}

function export_proxy {
    echo export http_proxy=$1 | tee "$2"
    echo export https_proxy=$1 | tee -a "$2"
    echo export HTTP_PROXY=$1 | tee -a "$2"
    echo export HTTPS_PROXY=$1 | tee -a "$2"
}


function check_clone {
  if [[ -z $1 ]] || [[ -z $2 ]]; then
    echo "Missing Parameters for check_clone"
    exit 1
  fi
  GIT_REPO=$1
  TARGET_FOLDER=$2
  if [[ -d $TARGET_FOLDER ]] || [[ -L $TARGET_FOLDER ]]; 
  then
    response=$(vagrant_response "folder $TARGET_FOLDER is already checked out, do you want to overwrite it? [Y/n]: " "n")
    response=${response,,} # toLowerCase
    if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
      sudo rm -rf $TARGET_FOLDER
      clone $GIT_REPO $TARGET_FOLDER
    fi
  else
    clone $GIT_REPO $TARGET_FOLDER
  fi
}


function clone {
  GIT_REPO=$1
  TARGET_FOLDER=$2

  sudo mkdir -p $TARGET_FOLDER
  sudo chmod 777 $TARGET_FOLDER
  cd $TARGET_FOLDER

  if [[ $INITIAL_HTTP_PROXY ]]; then
    git config --global http.proxy $INITIAL_HTTP_PROXY
  fi

  git init
  git remote add origin $GIT_REPO
  git fetch
  git checkout -b master
  git pull origin master
  git push --set-upstream origin master
  
  if [[ $INITIAL_HTTP_PROXY ]]; then
    git config --global --unset http.proxy
  fi
}


function setup_workstation {
  sudo sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux

  # If not running in vagrant mount mode, we're using the main.yaml from $WORKSTATION_FOLDER
  if [ ! -f ansible/defaults/main.yaml ]; then
      cd $WORKSTATION_FOLDER
  fi
  cp -i ansible/defaults/main.yaml $TMP_FOLDER/main.yaml

  vi $TMP_FOLDER/main.yaml
  vi ansible/tasks/main.yaml

  # Virtual Box shows 'Hypervisor detected: KVM', VMWare shows 'Hypervisor detected: VMWare'
  
  if dmesg | grep -i hypervisor | grep -i KVM ; then
    echo "Detected Virtual Box: installing guest additions..."
    ansible-playbook -v ansible/_tasks_vbox/vbox.yaml
  fi
  ansible-playbook -v workstation.yaml --extra-vars "@$TMP_FOLDER/main.yaml"
}

function vagrant_response {
  read -r -p "$1" response
  if [[ $response == "exit" ]]; then
    response=$2
  fi
  echo $response
}

# From https://github.com/ash-shell/yaml-parse
function YamlParse__parse() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# From https://github.com/ash-shell/yaml-parse
function YamlParse__has_key() {
    local line=$(grep -x "^$2:.*" "$1")
    if [[ "$line" != "" ]]; then
        echo "$Ash__TRUE"
    else
        echo "$Ash__FALSE"
    fi
}

main "$@"
