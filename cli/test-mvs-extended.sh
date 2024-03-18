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
# ToDo: add a check for validity of the git remote url
remote_add(){
    cwd=$PWD
    # create remote repo
    pkg=$1
    mkdir -p $DEPOT_PATH/localhub/$pkg
    cd $DEPOT_PATH/localhub/$pkg
    git init --bare &> /dev/null;
    # add remote to project
    cd "$DEPOT_PATH/dev/$pkg"
    git remote add origin $DEPOT_PATH/localhub/$pkg &> /dev/null;
    git add . > /dev/null
    git commit -m "<dep> added dependencies" &> /dev/null;
    git push --set-upstream origin main &> /dev/null;
    cd "$cwd"
}

add_commit_push(){
    cwd=$PWD
    pkg=$1
    cd "$DEPOT_PATH/dev/$pkg"
    git add . &> /dev/null;
    git commit -m "<wip>" &> /dev/null;
    git pull &> /dev/null;
    git push &> /dev/null;
    cd "$cwd"
}

# code that runs the test
runall(){
    # create directory for remotes
    mkdir $DEPOT_PATH/localhub
    
    # create local registry
    mkdir -p $DEPOT_PATH/localhub/TestRegistry
    cd $DEPOT_PATH/localhub/TestRegistry
    git init --bare > /dev/null
    cosm registry init TestRegistry $DEPOT_PATH/localhub/TestRegistry

    # root folder in which to create packages
    cd $DEPOT_PATH/dev

    # create packages
    cosm init A --template lua/PkgTemplate
    cosm init B --template lua/PkgTemplate
    cosm init C --template lua/PkgTemplate
    cosm init D --template lua/PkgTemplate
    cosm init E --template lua/PkgTemplate
    cosm init F --template lua/PkgTemplate

    # releases of E
    cd $DEPOT_PATH/dev/E
    remote_add "E"
    add_commit_push E
    cosm release v0.2.0
    add_commit_push E
    cosm release v0.2.1
    add_commit_push E
    cosm release v0.6.5
    add_commit_push E
    cosm release v1.0.0
    add_commit_push E
    cosm release v1.1.0
    add_commit_push E
    cosm release v1.2.0
    add_commit_push E
    cosm release v1.3.0

    # add releases of E to the registry
    cosm registry add TestRegistry v0.2.0 $DEPOT_PATH/localhub/E
    cosm registry add TestRegistry v0.2.1 $DEPOT_PATH/localhub/E
    cosm registry add TestRegistry v0.6.5 $DEPOT_PATH/localhub/E
    cosm registry add TestRegistry v1.0.0 $DEPOT_PATH/localhub/E
    cosm registry add TestRegistry v1.1.0 $DEPOT_PATH/localhub/E
    cosm registry add TestRegistry v1.2.0 $DEPOT_PATH/localhub/E    
    cosm registry add TestRegistry v1.3.0 $DEPOT_PATH/localhub/E

    # releases of F
    cd $DEPOT_PATH/dev/F
    remote_add "F"
    add_commit_push F
    cosm release v0.7.1
    add_commit_push F
    cosm release v0.8.2
    add_commit_push F
    cosm release v1.0.0
    add_commit_push F
    cosm release v1.1.0

    # add releases of F to the registry
    cosm registry add TestRegistry v0.7.1 $DEPOT_PATH/localhub/F
    cosm registry add TestRegistry v0.8.2 $DEPOT_PATH/localhub/F
    cosm registry add TestRegistry v1.0.0 $DEPOT_PATH/localhub/F
    cosm registry add TestRegistry v1.1.0 $DEPOT_PATH/localhub/F

    # releases of D
    cd $DEPOT_PATH/dev/D
    remote_add "D"
    cosm add E v0.2.1
    add_commit_push D
    cosm release v0.4.0
    cosm upgrade E v0.6
    add_commit_push D
    cosm release v0.5.1
    cosm upgrade E v1.1
    add_commit_push D
    cosm release v1.1.0
    add_commit_push D
    cosm release v1.2.0
    cosm upgrade E v2.0
    add_commit_push D
    cosm release v1.3.0
    add_commit_push D
    cosm release v1.4.0
    
    # add releases of D to the registry
    cosm registry add TestRegistry v0.4.0 $DEPOT_PATH/localhub/D
    cosm registry add TestRegistry v0.5.1 $DEPOT_PATH/localhub/D
    cosm registry add TestRegistry v1.1.0 $DEPOT_PATH/localhub/D
    cosm registry add TestRegistry v1.2.0 $DEPOT_PATH/localhub/D    
    cosm registry add TestRegistry v1.3.0 $DEPOT_PATH/localhub/D
    cosm registry add TestRegistry v1.4.0 $DEPOT_PATH/localhub/D

    # releases of B
    cd $DEPOT_PATH/dev/B
    remote_add "B"
    cosm add D v0.4.0
    add_commit_push B
    cosm release v0.3.0
    add_commit_push B
    cosm release v0.3.1
    add_commit_push B
    cosm release v0.4.0
    cosm upgrade D v1.1.0
    add_commit_push B
    cosm release v1.0.0
    add_commit_push B
    cosm release v1.1.0
    cosm upgrade D v1.3.0
    add_commit_push B
    cosm release v1.2.0

    # add releases of B to the registry
    cosm registry add TestRegistry v0.3.0 $DEPOT_PATH/localhub/B
    cosm registry add TestRegistry v0.3.1 $DEPOT_PATH/localhub/B
    cosm registry add TestRegistry v0.4.0 $DEPOT_PATH/localhub/B
    cosm registry add TestRegistry v1.0.0 $DEPOT_PATH/localhub/B
    cosm registry add TestRegistry v1.1.0 $DEPOT_PATH/localhub/B
    cosm registry add TestRegistry v1.2.0 $DEPOT_PATH/localhub/B

    # releases of C
    cd $DEPOT_PATH/dev/C
    remote_add "C"
    cosm add D v0.4.0
    add_commit_push C
    cosm release v0.3.0
    add_commit_push C
    cosm release v0.4.0
    cosm rm D
    add_commit_push C
    cosm release v1.1.0
    cosm add D v1.4.0
    add_commit_push C
    cosm release v1.2.0
    cosm rm D
    cosm add F v1.1.0
    add_commit_push C
    cosm release v1.3.0

    # add releases of C to the registry
    cosm registry add TestRegistry v0.3.0 $DEPOT_PATH/localhub/C
    cosm registry add TestRegistry v0.4.0 $DEPOT_PATH/localhub/C
    cosm registry add TestRegistry v1.1.0 $DEPOT_PATH/localhub/C
    cosm registry add TestRegistry v1.2.0 $DEPOT_PATH/localhub/C
    cosm registry add TestRegistry v1.3.0 $DEPOT_PATH/localhub/C

    # releases of A
    cd $DEPOT_PATH/dev/A
    remote_add "A"
    add_commit_push A
    cosm add B v0.3.0
    cosm add C v0.3.0
}

cleanall(){
    cleanup_pkg A
    cleanup_pkg B
    cleanup_pkg C
    cleanup_pkg D
    cleanup_pkg E
    cleanup_pkg F
    cleanup_reg TestRegistry
    rm -rfv "$DEPOT_PATH/clones/*"
    rm -rfv "$DEPOT_PATH/packages/*"
    rm -rfv "$DEPOT_PATH/localhub/*"
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