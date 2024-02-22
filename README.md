# Cosm - package manager
`Cosm` and its associated command-line-interface `cosm`, is a package manager and integrated package registry. For now we support [Lua]() and embedded languages such as [Terra]() and soon [Regent](). However, the idea is to provide a general enough set of tools to support any language in the pursuit of package management.

The design of `Cosm` is based on the following ideas
* [Minimal version selection](https://research.swtch.com/vgo-mvs), leading to 100% reproducible builds without the need for a lockfile or pkg manifest. 
* Integrated tools for package registries, allowing both publicly and privately hosted package registries, using the same interface.
* A local depot directory (.cosm) that locally hosts registry and package data and interacts with remotes when required.
* A command-line-interface that is easy and feels like `git`.

Some of these ideas have been drawn from my experiences with the Julia package manager and registry, and the excellent set of [blog posts](https://research.swtch.com/vgo) from Ross Cox on package management in Go. 

`Cosm` depends currently on [Lua]() and bash.

## get status of a package or registry
```
cosm status                             (not implemented)
```
*Gives an overview of a package or registry when evaluated in the root of a package or registry, respectively.*

## instantiate a new package
```
cosm init <name>                        (implemented)
cosm init <name> -l <language>          (not implemented)
cosm init <name> --language <language>  (not implemented)
```
*Evaluate in parent folder of a new package. Adds a new package with name <name> according to a template (in .cosm/templates) of specified language <language>.*

## instantiate a new registry
```
cosm registry init <name> <giturl>       (implemented)
```
*Adds a new package registry with name <name> (in .cosm/registries) with remote located at <giturl>.*

## add/remove/upgrade/downgrade project dependencies
```
cosm add <name>              (not implemented)
cosm add <name> <version>    (implemented)
```
*Evaluate in a package root. Add a dependency to a project. Project <name> with version <version> will be looked up in any of the available local registries. If a package with the same name exists in multiple registries then the user will be prompted to choose the registry from the available listed registries. If no version is specified it will add the newest available version that is compatible with other package dependencies. The registry to look can also be provided as an option.*

```
cosm rm <name>               (implemented)
```
*Evaluate in a package root. Removes a project dependency.*

```
cosm upgrade <name>                          (not implemented)
cosm upgrade <name> -v <version>             (not implemented)
cosm upgrade <name> --version <version>      (not implemented)
```
*Evaluate in a package root. Upgrades a project dependency to a new specified or unspecied (newest possible) version.*

```
cosm downgrade <name> -v <version>           (not implemented)
cosm downgrade <name> --version <version>    (not implemented)
```
*Evaluate in a package root. Downgrade a project dependency to a new specified or unspecied (newest possible) version.*

## register a project to a registry
```
cosm registry add <giturl>     (implemented)
```
*Evaluate in a registry root. Register a package to <registry> (in .cosm/registries). An error is thrown if the current version already exists in the registry. The remote repository of the registry is updated automatically.*


## register a new release of a project
```
cosm release --patch     (not implemented)
cosm release --minor     (not implemented)
cosm release --major     (not implemented)
```
*Evaluate in a package root. Release a package to the registry to which the package has previously been registered (in .cosm/registries) and bump the existing `patch`, `minor`, or `major` version. An error is thrown if the current version already exists in the registry. The package and registry remotes are updated automatically.*
```
cosm release -v <version>            (not implemented)
cosm release --version <version>     (not implemented)
```
*Evaluate in a package root. Release a package to the registry to which the package has previously been registered (in .cosm/registries) and change the version number to the one provided. The version name needs to adhere to the semantic versioning listed below. An error is thrown if the current version already exists in the registry. The remote is updated automatically.*