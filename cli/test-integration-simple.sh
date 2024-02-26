#!/usr/bin/env bash

DEPOT_PATH=$COSM_DEPOT_PATH

cleanup_pkg(){
    pkg="$1"
    rm -rf "$DEPOT_PATH/dev/$pkg"
    gh repo delete "$pkg" --yes
}
cleanup_reg(){
    reg="$1"
    gh repo delete "$reg" --yes
    cosm registry delete "$reg" --force
}

# register pkg to TestRegistry
registry_add(){
    cwd=$(pwd)
    pkg="$1"
    cd "$DEPOT_PATH/dev/$pkg"
    gh repo create "$pkg" --public
    git remote add origin git@github.com:renehiemstra/"$pkg".git
    git add .
    git commit -m "<dep> added dependencies"
    git push --set-upstream origin main
    cd "$DEPOT_PATH/registries/TestRegistry"
    cosm registry add git@github.com:renehiemstra/"$pkg".git
    cd "$cwd"
}
# ToDo: add a check for validity of the git remote url

# code that runs the test
runall(){
    # create registry
    gh repo create TestRegistry --public
    cosm registry init TestRegistry git@github.com:renehiemstra/TestRegistry

    # root folder in which to create packages
    cd $DEPOT_PATH/dev

    # create packages
    cosm init DepA
    cosm init DepB
    cosm init DepDep
    cosm init Example

    # release DepDep to TestRegistry
    registry_add DepDep
    # imagine we make some improvements to DepDep and
    # we bring out several more versions
    cd $DEPOT_PATH/dev/DepDep
    cosm release --patch    # v0.1.1
    cosm release --minor    # v0.2.0
    cosm release --major    # v1.0.0
    cosm release --patch    # v1.0.1
    
    # add dependency to DepA
    cd $DEPOT_PATH/dev/DepA
    cosm add DepDep 0.2.0
    # release DepA to TestRegistry
    registry_add DepA
    cosm release --patch    # v0.1.1
    cosm release --minor    # v0.2.0

    # add dependency to DepB
    cd $DEPOT_PATH/dev/DepB
    cosm add DepDep 1.0.0
    # release DepB to TestRegistry
    registry_add DepB
    cosm release --minor    # v0.2.0
    cosm release --major    # v1.0.0
    cosm release --patch    # v1.0.1

    cd $DEPOT_PATH/dev/Example
    cosm add DepA 0.2.0
    registry_add Example    # v0.1.0
    cosm add DepB 1.0.0
    git add .
    git commit -m "<dep> added DepB"
    git push --set-upstream origin main
    cosm release --minor    # v0.2.0
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
    runall
    cleanall
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