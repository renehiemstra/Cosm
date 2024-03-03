# Cosm - package manager
`Cosm` and its associated command-line-interface `cosm`, is a package manager and integrated package registry. For now we support [Lua]() and embedded languages such as [Terra]() and soon [Regent](). However, the idea is to provide a general framework to support any language in the pursuit of package management.

The design of `Cosm` is based on the following ideas
* [Minimal version selection](https://research.swtch.com/vgo-mvs), leading to 100% reproducible builds without the need for a lockfile or pkg manifest that store the entire dependency tree.
* Clear division of: (1) a language agnostic core functionality for package management, and (2) a language/build system specific top-layer that is extensible.
* Integrated tools for package registries, allowing both publicly and privately hosted package registries, using the same interface.
* A local depot directory (.cosm) that locally hosts registry and package data and interacts with remotes when required.
* A command-line-interface that is easy and feels like `git`.

Some of these ideas have been drawn from my experiences with the [Julia package manager](https://pkgdocs.julialang.org/v1/) and the excellent set of [blog posts](https://research.swtch.com/vgo) from Ross Cox on package management in Go. Compared to the Julia Pkg manager, `cosm` naturally features reproducible builds without the need for a package manifest file. Instead, the dependency tree is evaluated just in time based on a simple criterion. The result is a relatively simple core design that is language agnostic. Specific Language or build system support can be added via simple plugins.

Currently, `Cosm` depends on [Lua]() and bash.

## Instalation
Simply download and run the `install.sh` script. Try the following to check that calling `cosm` is successful
```
cosm --version
```

## get status of a package or registry
```
cosm status                             (implemented)
```
*Gives an overview of a package when evaluated in the root of a package.*
```
cosm registry status <registry name>    (implemented)
```
*Gives an overview of the packages registered to the registry. Can be evaluated anywhere.*

## instantiate a new package
```
cosm init <package name> <language/template>                        (implemented)
```
*Evaluate in parent folder of a new package. Adds a new package with name <package name> according to a template (in .cosm/lang). Currently, only a lua and terra template are implemented.*

## instantiate a new registry / delete a registry / update a registry
```
cosm registry init <registry name> <giturl>       (implemented)
```
*Adds a new package registry with name <name> (in .cosm/registries) with remote located at <giturl>. The <giturl> should point to an empty remote git repository.*

```
cosm registry delete <registry name> [--force]      (implemented)
```
*Remove a registry from .cosm/registries.*

```
cosm registry update <registry name>                (implemented)
cosm registry update --all                          (implemented)
```
Update and synchronize registry with the remote.

## add/remove/upgrade/downgrade project dependencies
```
cosm add <name> v<version>                          (implemented)
cosm add <name> --latest                            (implemented)
```
*Evaluate in a package root. Add a dependency to a project. Project <name> with version <version> will be looked up in any of the available local registries. If a package with the same name exists in multiple registries then the user will be prompted to choose the registry from the available listed registries. If no version is specified it will add the newest available version that is compatible with other package dependencies.*

```
cosm rm <name>                                      (implemented)
```
*Evaluate in a package root. Removes a project dependency.*

```
cosm upgrade <name> v<version>                      (implemented)
cosm upgrade <name> --latest                        (implemented)
```
*Evaluate in a package root. Upgrades a project dependency to a new specified or unspecied (newest possible) version.*

```
cosm downgrade <name> v<version>                    (implemented)
```
*Evaluate in a package root. Downgrade a project dependency to a new specified or unspecied (newest possible) version.*

```
cosm develop <package name>                         (not implemented)
```
*Evaluate in parent folder of a package. Add a dependency to a project, but in development mode, which means it checks out a 'git clone' of the latest version of <package name> in 'cosm/dev' that you can freely develop in. The changes are imediately available in your parent project.*

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
cosm release --patch     (implemented)
cosm release --minor     (implemented)
cosm release --major     (implemented)
```
*Evaluate in a package root. Release a package to the registry to which the package has previously been registered (in .cosm/registries) and bump the existing `patch`, `minor`, or `major` version. An error is thrown if the current version already exists in the registry. The package and registry remotes are updated automatically.*
```
cosm release v<version>     (implemented)
```
*Evaluate in a package root. Release a package to the registry to which the package has previously been registered (in .cosm/registries) and change the version number to the one provided. The version name needs to adhere to semantic versioning and needs to be greater than the previous version. An error is thrown if the current version already exists in the registry. The remote is updated automatically.*
