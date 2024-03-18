# Cosm - package manager
`Cosm` and its associated command-line-interface `cosm`, is a package manager and integrated package registry that is language agnostic. Support for new languages is implemented by writing a simple plugin. This makes `Cosm` ideally suited for multi-language projects.

The design of `Cosm` is based on the following ideas
* [Minimal version selection](https://research.swtch.com/vgo-mvs), leading to 100% reproducible builds without the need for a lockfile or pkg manifest that store the entire dependency tree.
* Clear division of: (1) a language agnostic core functionality for package management, and (2) a language/build system specific top-layer that is extensible.
* Integrated tools for package registries, allowing both publicly and privately hosted package registries, using the same interface.
* A local depot directory (.cosm) that locally hosts registry and package data and interacts with remotes when required.
* A command-line-interface that is easy and feels like `git`.

Currently the following languags are supported through plugins
* [Lua](https://www.lua.org/)
* [Terra](https://terralang.org/)

Some of these ideas have been drawn from my experiences with the [Julia package manager](https://pkgdocs.julialang.org/v1/) and the excellent set of [blog posts](https://research.swtch.com/vgo) from Ross Cox on package management in Go. Compared to the Julia Pkg manager, `cosm` naturally features reproducible builds without the need for a package manifest file. Instead, the dependency tree is evaluated just in time based on a simple criterion. The result is a relatively simple core design that is language agnostic. Specific Language or build system support can be added via simple plugins.

## Instalation
Currently, `Cosm` depends on [Lua]() and bash. Simply download and run the `install.sh` script. Try the following to check that calling `cosm` is successful
```
cosm --version
```

## Versioning
Consequent versioning is central to good package management. We follow the rules in [Semantic Versioning 2.0.0](https://semver.org/) and utilize the [semver.lua](https://github.com/kikito/semver.lua) library. In `cosm`, a specific instance of a package is uniquely defined by
```
    <name>@v<major>.<minor>.<patch>-<prerelease>+<build>
```
Packages with different major version numbers are considered as different packages. You can even use `<name>@v0` and `<name>@v1` in the same project. This could be useful when you want to move slowly to a new stable release. Simply add `<name>@v1`, import its functionality inside a new namespace, and start migrating some of the api calls from `<name>@v0` to `<name>@v1`.

## get status of a package or registry
```
cosm status
```
*Gives an overview of a package when evaluated in the root of a package.*
```
cosm registry status <registry name>
```
*Gives an overview of the packages registered to the registry. Can be evaluated anywhere.*

## instantiate a new package
```
cosm init <package name>
```
Evaluate in root directory of an existing project. A 'Project.lua' file is created for project <package name>.
```
cosm init <package name> --template <language/template>
```
*Evaluate in parent folder of a new package. Adds a new package with name <package name> according to a template (in .cosm/lang). Currently, only a lua and terra template are implemented.*

## instantiate a new registry / delete a registry / update a registry
```
cosm registry init <registry name> <giturl>
```
*Adds a new package registry with name <name> (in .cosm/registries) with remote located at <giturl>. The <giturl> should point to an empty remote git repository.*

```
cosm registry delete <registry name> [--force]
```
*Remove a registry from .cosm/registries.*

```
cosm registry update <registry name>
cosm registry update --all
```
Update and synchronize registry with the remote.

## Add project dependencies
```
cosm add <name> v<version>
```
*Evaluate in a package root. Add a dependency to a project. Project <name> with version <version> will be looked up in any of the available local registries. If a package with the same name exists in multiple registries then the user will be prompted to choose the registry from the available listed registries.*

## Remove project dependencies
```
cosm rm <name>
```
*Evaluate in a package root. Removes a project dependency.*

## Upgrade project dependencies
You can upgrade any direct or transitive dependency separately using one of the following commands:
```
cosm upgrade <name>
cosm upgrade <name> v<x>
cosm upgrade <name> v<x.y>
cosm upgrade <name> v<x.y.z>
cosm upgrade <name> v<x.y.z-alpha>
```
*Evaluate in a package root. Upgrading is done conservatively, meaning that the latest compatible version is chosen by default that satisfies the provided constraint. For example,*
```
cosm upgrade <name> v<x.y>
```
*Upgrades a package to version 'x.y.z' where z is the latest patch version in the series. If you want to upgrade to an exact version then you simply specify the constraint*
```
cosm upgrade <name> v<x.y.z>
```
*The '--latest' option changes the default behavior and pickes the latest registered version of the package.*
```
cosm upgrade <name> --latest
```
*If you want to upgrade all direct and transitive project dependencies you can use one of the following commands.*
```
cosm upgrade --all
cosm upgrade --all --latest
```
*By default, an upgrade seeks the latest compatible version. The `--latest` option is used to get the latest of each package, which may be incompatible with the current version you are using. The order of the options is not relevant.*

## Develop a project dependency
Its possible to extend functionality or fix bugs in one of your managed dependencies and directly use it in your parent project without issuing new releases of your dependency. This is particularly useful at early development stages and simply works as follows
```
cosm develop <package name>
```
*Open a dependency to a project, but in development mode, which means it checks out a 'git clone' of the latest version of <package name> in `cosm/dev/<package name>@v<major>` that you can freely develop in. The changes are imediately available in your parent project.*


## downgrade project dependencies
```
cosm downgrade <name> v<version>                    (not implemented)
```
*Evaluate in a package root. Downgrade a project dependency to a new specified or unspecied (newest possible) version.*

## register a project to a registry / remove from registry
```
cosm registry add <registry name> <giturl>          (implemented)
```
*Register a package to <registry> (in .cosm/registries). An error is thrown if the current version already exists in the registry. The remote repository of the registry is updated automatically.*

```
cosm registry rm <registry name> <package name> [--force]                (implemented)
cosm registry rm <registry name> <package name> v<version> [--force]     (implemented)
```
*Remove a <version> of a package or a package entirely from the <registry> (in .cosm/registries). The remote repository of the registry is updated automatically.*

## register a new release of a project
```
cosm release --patch
cosm release --minor
cosm release --major
```
*Evaluate in a package root. Release a package to the registry to which the package has previously been registered (in .cosm/registries) and bump the existing `patch`, `minor`, or `major` version. An error is thrown if the current version already exists in the registry. The package and registry remotes are updated automatically.*
```
cosm release v<version>
```
*Evaluate in a package root. Release a package to the registry to which the package has previously been registered (in .cosm/registries) and change the version number to the one provided. The version name needs to adhere to semantic versioning and needs to be greater than the previous version. An error is thrown if the current version already exists in the registry. The remote is updated automatically.*
