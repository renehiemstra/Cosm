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

remote_add(){
    cwd=$PWD
    pkg=$1
    cd "$DEPOT_PATH/dev/$pkg"
    gh repo create "$pkg" --public
    git remote add origin git@github.com:renehiemstra/"$pkg".git
    git add .
    git commit -m "<dep> added dependencies"
    git push --set-upstream origin main
    cd "$cwd"
}

add_commit_push(){
    cwd=$PWD
    pkg=$1
    cd "$DEPOT_PATH/dev/$pkg"
    git add .
    git commit -m "<wip>"
    git pull
    git push
    cd "$cwd"
}

# code that runs the test
runall(){
    # create registry
    gh repo create TestRegistry --public
    cosm registry init TestRegistry git@github.com:renehiemstra/TestRegistry

    # root folder in which to create packages
    cd $DEPOT_PATH/dev

    # create packages
    cosm init DepA lua/PkgTemplate
    cosm init DepB lua/PkgTemplate
    cosm init DepDep lua/PkgTemplate
    cosm init Example lua/PkgTemplate

    # release DepDep to TestRegistry
    # imagine we make some improvements to DepDep and
    # we bring out several more versions
    cd $DEPOT_PATH/dev/DepDep
    remote_add "DepDep"
    add_commit_push DepDep
    cosm release --patch    # v0.1.1
    add_commit_push DepDep
    cosm release --minor    # v0.2.0
    add_commit_push DepDep
    cosm release --major    # v1.0.0
    add_commit_push DepDep
    cosm release --patch    # v1.0.1
    add_commit_push DepDep
    cosm release v2.1.1
    
    # add some releases to the registry
    cosm registry add TestRegistry v0.1.1 git@github.com:renehiemstra/DepDep
    cosm registry add TestRegistry v0.2.0 git@github.com:renehiemstra/DepDep
    cosm registry add TestRegistry v1.0.0 git@github.com:renehiemstra/DepDep
    cosm registry add TestRegistry v1.0.1 git@github.com:renehiemstra/DepDep
    cosm registry add TestRegistry v2.1.1 git@github.com:renehiemstra/DepDep

    # add dependency to DepA
    cd $DEPOT_PATH/dev/DepA
    cosm add DepDep v0.2.0
    # release DepA to TestRegistry
    remote_add "DepA"
    add_commit_push DepA
    cosm release --patch    # v0.1.1
    add_commit_push DepA
    cosm release --minor    # v0.2.0
    # add to registry
    cosm registry add TestRegistry v0.1.1 git@github.com:renehiemstra/DepA
    cosm registry add TestRegistry v0.2.0 git@github.com:renehiemstra/DepA

    # add dependency to DepB
    cd $DEPOT_PATH/dev/DepB
    cosm add DepDep v1.0.0
    # release DepB to TestRegistry
    remote_add "DepB"
    add_commit_push DepB
    cosm release --minor    # v0.2.0
    add_commit_push DepB
    cosm release --major    # v1.0.0
    add_commit_push DepB
    cosm release --patch    # v1.0.1
    # add to registry
    cosm registry add TestRegistry v0.2.0 git@github.com:renehiemstra/DepB
    cosm registry add TestRegistry v1.0.0 git@github.com:renehiemstra/DepB
    cosm registry add TestRegistry v1.0.1 git@github.com:renehiemstra/DepB

    cd $DEPOT_PATH/dev/Example
    cosm add DepA v0.2.0
    cosm add DepB --latest
    cosm downgrade DepB v1.0.0
    cosm upgrade DepB v1.0.1
    remote_add "Example"
    add_commit_push Example
    cosm release --minor    # v0.2.0
    # add to registry
    cosm registry add TestRegistry v0.2.0 git@github.com:renehiemstra/Example

    # update the registry
    cosm registry update TestRegistry
    cosm registry update --all

    # remove packages
    # cosm registry rm TestRegistry DepDep --force
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