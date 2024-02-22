#!/usr/bin/env bash

DEPOT_PATH=$COSM_DEPOT_PATH

cleanup_pkg(){
    pkg="$1"
    rm -rf "$DEPOT_PATH/dev/$pkg"
    rm -rf "$DEPOT_PATH/clones/$pkg"
    gh repo delete "$pkg" --yes
}
cleanup_reg(){
    reg="$1"
    gh repo delete "$reg" --yes
    cosm registry rm "$reg"
}

# add a release to TestRegistry
release_add(){
    pkg="$1"
    cd "$DEPOT_PATH/dev/$pkg"
    gh repo create "$pkg" --public
    git remote add origin git@github.com:renehiemstra/"$pkg".git
    git push --set-upstream origin main
    cosm release add TestRegistry git@github.com:renehiemstra/"$pkg".git
}
# ToDo: add a check for validity of the git remote url

# code that runs the test
runall(){
    # create registry
    gh repo create TestRegistry --public
    cosm registry add TestRegistry git@github.com:renehiemstra/TestRegistry

    # root folder in which to create packages
    cd $DEPOT_PATH/dev

    # create packages
    cosm init Example
    cosm init DepA
    cosm init DepB
    cosm init DepDep

    # release DepDep to TestRegistry
    release_add DepDep

    # add dependency to DepA
    cd $DEPOT_PATH/dev/DepA
    cosm add DepDep 0.1.0 
    # release DepA to TestRegistry
    release_add DepA

    # add dependency to DepB
    cd $DEPOT_PATH/dev/DepB
    cosm add DepDep 0.1.0 
    # release DepB to TestRegistry
    release_add DepB

    # add dependencies to Example
    cd $DEPOT_PATH/dev/Example
    cosm add DepA 0.1.0 
    cosm add DepB 0.1.0 
    
    # try to add and remove a package
    cosm add DepDep 0.1.0
    cosm rm DepDep
    
    # release DepB to TestRegistry
    release_add Example
    cd $DEPOT_PATH
}

cleanall(){
    cleanup_pkg Example
    cleanup_pkg DepA
    cleanup_pkg DepB
    cleanup_pkg DepDep
    cleanup_reg TestRegistry
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