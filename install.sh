#!/bin/bash
#
# installation script for the COSM package manager

COSM_DEPOT_PATH="${HOME}"/cosm
BASH_PROFILE=""

# check use of zprofile or bash_profile
set_bash_profile() {
    if test -f "${HOME}/.bash_profile"; then
        echo "Setting bash profile"
        BASH_PROFILE="${HOME}/.bash_profile" # linux, intel macos
    elif test -f "${HOME}/.zprofile"; then
        echo "Setting z-profile"
        BASH_PROFILE="${HOME}/.zprofile" # m-series macos
    else
        echo "No profile found"
        exit 1
    fi
}

# receive user input to set the cosm depot path variable
set_depot_path(){
    echo "Install the cosm depot in '${HOME}' [y/n]: "
    read reply
    case "$reply" in
      y)
        # continue
        ;;
      n)
        echo "Specify root directory: "
        read path
        if test -d "${path}"; then
          COSM_DEPOT_PATH="${path}/cosm"
        fi
        ;;
      
      *)
        echo "Wrong input arguments. Aborting."
        exit 1
        ;;
    esac
}

# create depot and export environment variables
create_depot(){
  mkdir "${COSM_DEPOT_PATH}"
  cd "${COSM_DEPOT_PATH}"
  # create folder structure
  mkdir clones packages dev compiled registries templates
  # add files to handle refgistries
  echo "local List = {}" >> registries/List.lua
  echo "return List" >> registries/List.lua
  # add to path
  echo "export COSM_DEPOT_PATH=\"${COSM_DEPOT_PATH}\"" >> ${BASH_PROFILE}
  echo "The COSM_DEPOT_PATH variable is set to ${COSM_DEPOT_PATH} and is exported to your profile."
  # append COSM_DEPOT_PATH to the LUA_PATH and add to your profile
  if [ -z "${LUA_PATH}" ]; then
    echo "export LUA_PATH=\"${COSM_DEPOT_PATH}/?.lua;;\"" >> ${BASH_PROFILE}
  else
    echo "export LUA_PATH=\"${COSM_DEPOT_PATH}/?.lua;${LUA_PATH}\"" >> ${BASH_PROFILE}
  fi
}

# download and install cosm cli
install_cosm_cli(){
  
}

# install depot
set_bash_profile
set_depot_path
create_depot

# exit with success
echo "The depot is set and ready for use. Open a new terminal window to continue."
exit 0






