# Cosm - package manager
`Cosm` and its associated command-line-interface `cosm`, is a package manager and integrated package registry that is language agnostic. Support for new languages is implemented by writing a simple plugin. This makes `Cosm` ideally suited for multi-language projects.

The design of `Cosm` is based on the following ideas
* [Minimal version selection](https://research.swtch.com/vgo-mvs), leading to 100% reproducible builds without the need for a lockfile.
* Clear division of: (1) a language agnostic core functionality for package management, and (2) a language/build system specific top-layer that is extensible.
* Integrated tools for package registries, allowing both publicly and privately hosted package registries, using the same interface.
* A local depot directory (.cosm) that locally hosts registry and package data and interacts with remotes when required.
* A command-line-interface that is easy and feels like `git`.

Currently the following languags are supported through plugins
* [Lua](https://www.lua.org/)
* [Terra](https://terralang.org/)

Some of these ideas have been drawn from my experiences with the [Julia package manager](https://pkgdocs.julialang.org/v1/) and the excellent set of [blog posts](https://research.swtch.com/vgo) from Ross Cox on package management in Go. `Cosm` naturally features reproducible builds without the need for a lock file. Instead, the dependency tree is evaluated just in time based on a simple criterion. The result is a relatively simple core design that is language agnostic. Specific Language or build system support can be added via simple plugins.

## Installation
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

## Minimal version selection
[Minimal version selection](https://research.swtch.com/vgo-mvs) provides a consistent and simple approach to package management that leads to 100% reproducible build without the need for a lockfile. It works as follows:
1. Each project provides minimal versions of each dependency.
2. The algorithm inspects versions of all transitive dependencies and takes the maximum of the minimum versions for each encountered dependency.
3. If you want to work with newer versions you can adjust, locally, the minimal requirments of a dependency, which then overrides the minimal version of said project.

In cosm all of this is encapsulated in a simple set of commands, see below for the API.

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
*Evaluate in root directory of an existing project. A 'Project.lua' file is created for project package name.*
```
cosm init <package name> --template <language/template>
```
*Evaluate in parent folder of a new package. Adds a new package with name package name according to a template (in .cosm/lang). Currently, only a lua and terra template are implemented.*

## instantiate a new registry / delete a registry / update a registry
```
cosm registry init <registry name> <giturl>
```
*Adds a new package registry with name name (in .cosm/registries) with remote located at giturl. The giturl should point to an empty remote git repository.*

```
cosm registry clone <giturl>
```
*Adds an existing package registry (in .cosm/registries) with remote located at giturl. The giturl should point to a valid existing package registry.*

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
*Evaluate in a package root. Add a dependency to a project. Project name with version version will be looked up in any of the available local registries. If a package with the same name exists in multiple registries then the user will be prompted to choose the registry from the available listed registries.*

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
*Evaluate in a package root. Open a dependency to a project, but in development mode, which means it checks out a 'git clone' of the latest version of package name in `cosm/dev/<package name>@v<major>` that you can freely develop in. The changes are imediately available in your parent project.*

```
cosm free <package name>
```
*Evaluate in a package root. Close development mode and return to the latest release. If you brought out a new release of your development package, then you can directly start usign them.*

## downgrade project dependencies
```
cosm downgrade <name> v<version>                    (not implemented)
```
*Evaluate in a package root. Downgrade a project dependency to a new specified or unspecied (newest possible) version.*

## register a new release of a project
Its easy to publish new releases of your projects
```
cosm release v<version>
```
*Evaluate in a package root. Publish a new release to your remote repository with version tag `<version>`. The version number in your project file is updated automatically. The version name needs to adhere to semantic versioning and needs to be greater than the previous version. An error is thrown if the current version already exists in the registry. The remote is updated automatically.*
```
cosm release --patch
cosm release --minor
cosm release --major
```
*Evaluate in a package root. Convenience commands that publish a new `patch`, `minor`, or `major` version. An error is thrown if the current version already exists in the registry. The package and registry remotes are updated automatically.*

## Register a project to a registry
Once you have published one or more releases to your remote repository, you can add them to a registry as follows
```
cosm registry add <registry name> v<version tag> <giturl>
```
*Can be evaluated anywhere. Register a package version to a registry (in .cosm/registries). An error is thrown if the current version already exists in the registry. The remote repository of the registry is updated automatically.*

## Remove a version or project from a registry
```
cosm registry rm <registry name> <package name> [--force]
cosm registry rm <registry name> <package name> v<version> [--force]
```
*Remove a version of a package or a package entirely from the registry (in .cosm/registries). The remote repository of the registry is updated automatically.*