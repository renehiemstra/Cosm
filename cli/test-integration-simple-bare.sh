#!/usr/bin/env bash

DEPOT_PATH=$COSM_DEPOT_PATH

cleanup_pkg(){
    pkg="$1"
    rm -rf "$DEPOT_PATH/dev/$pkg"
    rm -rf "$DEPOT_PATH/localhub/$pkg"
}
cleanup_reg(){
    reg="$1"
    rm -rf "$DEPOT_PATH/localhub/$reg"
    cosm registry delete "$reg" --force
}

# register pkg to TestRegistry
registry_add(){
    cwd=$(pwd)
    registry="$1"
    pkg="$2"
    cd "$DEPOT_PATH/dev/$pkg"
    localhub_add $pkg
    git remote add origin $DEPOT_PATH/localhub/$pkg
    git add .
    git commit -m "<dep> added dependencies"
    git push --set-upstream origin main
    cd "$DEPOT_PATH/registries/TestRegistry"
    cosm registry add $registry $DEPOT_PATH/localhub/$pkg
    cd "$cwd"
}
# ToDo: add a check for validity of the git remote url

localhub_add(){
    cwd=$PWD
    remote=$1
    mkdir -p $DEPOT_PATH/localhub/$remote
    cd $DEPOT_PATH/localhub/$remote
    git init --bare
    cd "$cwd"
}

# code that runs the test
runall(){
    # create directory for remotes
    mkdir $DEPOT_PATH/localhub
    
    # create local registry
    localhub_add TestRegistry
    cosm registry init TestRegistry $DEPOT_PATH/localhub/TestRegistry

    # root folder in which to create packages
    cd $DEPOT_PATH/dev

    # create packages
    cosm init DepA
    cosm init DepB
    cosm init DepDep
    cosm init Example

    # release DepDep to TestRegistry
    registry_add TestRegistry DepDep
    # imagine we make some improvements to DepDep and
    # we bring out several more versions
    cd $DEPOT_PATH/dev/DepDep
    cosm release --patch    # v0.1.1
    cosm release --minor    # v0.2.0
    cosm release --major    # v1.0.0
    cosm release --patch    # v1.0.1
    cosm release v2.1.1
    
    # add dependency to DepA
    cd $DEPOT_PATH/dev/DepA
    cosm add DepDep v0.2.0
    # release DepA to TestRegistry
    registry_add TestRegistry DepA
    cosm release --patch    # v0.1.1
    cosm release --minor    # v0.2.0

    # add dependency to DepB
    cd $DEPOT_PATH/dev/DepB
    cosm add DepDep v1.0.0
    # release DepB to TestRegistry
    registry_add TestRegistry DepB
    cosm release --minor    # v0.2.0
    cosm release --major    # v1.0.0
    cosm release --patch    # v1.0.1

    cd $DEPOT_PATH/dev/Example
    cosm add DepA v0.2.0
    registry_add TestRegistry Example    # v0.1.0
    cosm add DepB --latest
    cosm downgrade DepB v1.0.0
    cosm upgrade DepB v1.0.1
    git add .
    git commit -m "<dep> added DepB"
    git push --set-upstream origin main
    cosm release --minor    # v0.2.0

    # update the registry (although)
    cosm registry update TestRegistry
    cosm registry update --all

    # remove packages
    cosm registry rm TestRegistry DepDep --force
    cosm registry rm TestRegistry DepA v0.1.0 --force
    cosm registry rm TestRegistry DepA v0.1.1 --force
    cosm registry rm TestRegistry DepA v0.2.0 --force
}

cleanall(){
    cleanup_pkg DepA
    cleanup_pkg DepB
    cleanup_pkg DepDep
    cleanup_pkg Example
    cleanup_reg TestRegistry
    rm -rf "$DEPOT_PATH/clones"
    mkdir "$DEPOT_PATH/clones"
    rm -rf "$DEPOT_PATH/packages"
    mkdir "$DEPOT_PATH/clones"
}

# no input arguments - run test and cleanup
if [ "$#" == 0 ]; then
    cleanall
    runall
fi

# run test  or cleanup
if [ "$#" == 1 ]; then
    case "$1" in
        --run)
            runall
            ;;
        --clean)
            cleanall
            ;;
        *)
            printf "Wrong input arguments. Prodide '--run' and or 'clean'. \n \n"
            exit 1
            ;;
    esac
fi

exit 0