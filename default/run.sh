#!/usr/bin/env bash
set -e
# Requirements:
# - Azure CLI
# - helm
# - jq
# - kubectl
# - terraform

################################################################################
K3S_CONFIGFILE=k3s.yaml
K3S_CONFIGFILE_LOCAL=local-k3s.yaml
K3S_TEMP=$(mktemp k3s-temp.XXXXXXXXXX) || exit 1
################################################################################
trap 'rm -rf $K3S_TEMP' EXIT

__usage="
Available Commands:
    [-o  log_file]      save the output to log_file.
    [-x  action]        action to be executed.

    Possible verbs are:
        install         creates all of the resources in Azure and in Kubernetes
        destroy         deletes all of the components in Azure plus any KUBECONFIG and Terraform files
        show            shows information about the demo environment (e.g.: connection strings)
"

usage() {
    echo "usage: ${0##*/} [options]"
    echo "${__usage/[[:space:]]/}"
    exit 1
}

timestamp() {
    date +"%r"
}

checkDependencies() {
    # check if the dependencies are installed
    _NEEDED="az jq kubectl terraform"

    echo -e "Checking dependencies ...\n"
    for i in seq ${_NEEDED}
        do
           if hash "$i" 2>/dev/null; then
               # do nothing
               :
           else
               echo -e "\t $_ not installed".
               _DEP_FLAG=true
           fi
        done

    if [[ "${_DEP_FLAG}" == "true" ]]; then
            echo -e "\nDependencies missing. Please fix that before proceeding"
            exit 1
    fi
}

terraformDance () {
# Assumes you're already logged into Azure
    terraform init
    terraform plan -out tfplan
    terraform apply -auto-approve tfplan
}

show() {
   terraform output -json | jq -r 'to_entries[] | [.key, .value.value]'
}

destroy() {
    # remove all of the infrastructured
    terraform destroy -auto-approve
    rm -rf \
        terraform.tfstate \
        terraform.tfstate.backup \
        tfplan \
        .terraform \
        .terraform.lock.hcl
}

run() {
    local _WAITFORCLUTERTOPROVISION=2m

    terraformDance && \

    echo "$(timestamp): Waiting $_WAITFORCLUTERTOPROVISION for cluster to provision..."
    sleep $_WAITFORCLUTERTOPROVISION
    echo "$(timestamp): Done"
    echo "----"

    setKubeconfig
}

exec_case() {
    local _opt=$1

    case ${_opt} in
    install)    checkDependencies && run;;
    destroy)    checkDependencies && destroy;;
    show)       show;;
    *)          usage;;
    esac
    unset _opt
}

while getopts "o:x:" opt; do
    case $opt in
    o)  LOG_FILE="${OPTARG}"
        log_flag=true
        ;;
    x)  exec_flag=true
        EXEC_OPT="${OPTARG}"
        ;;
    *)  usage;;
    esac
done
shift $(( OPTIND - 1 ))

if [ $OPTIND = 1 ]; then
    usage
    exit 0
fi

if [[ "${log_flag}" == "true" ]]; then
    exec > >(tee -i "output/${LOG_FILE}")
fi

if [[ "${exec_flag}" == "true" ]]; then
    exec_case "${EXEC_OPT}"
fi

exit 0
