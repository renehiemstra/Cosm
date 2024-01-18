local pkgdir = "dev.Pkg.src."
local Cm = require(pkgdir.."command")
local Proj = require(pkgdir.."project")
local Reg = require(pkgdir.."registry")

local Pkg = {}

function Pkg.add(pkgdep, version)
    if not Proj.ispkg(".") then
        error("Current directory is not a valid package.")
    end
    --initialize package properties
    local pkg = {}
    pkg.table = dofile("Project.lua")
    pkg.name = pkg.table.name

    --check that pkg and pkgdep are not the same package
    if pkg.name==pkgdep then
      error("Cannot add "..pkgdep.."as a dependency to "..pkg.name..".\n\n")
    end
  
    --find pkgdep in known registries
    local registry = {}
    local found = false
    for _,regname in pairs(Reg.loadregistries("List.lua")) do
        --load registry
        registry.name = regname
        registry.path = Reg.regdir.."/"..registry.name
        registry.table = dofile(registry.path.."/Registry.lua")
        --check if pkgdep is present
        if registry.table.packages[pkgdep]~=nil then
            found = true --package is found
            break --currently we break with the first encountered package
        end
    end
    --case where pkgdep is not found in any of the registries
    if not found then
        error("Package "..pkgdep.."is not a registered package.\n\n")
    end
    --check if version is present in registry
    local specs = registry.table.packages[pkgdep]
    local versionpath = registry.path.."/"..specs.path.."/"..version
    if not Cm.isdir(versionpath) then
        error("Package "..pkgdep.." is registered in "..registry.name..", but version "..version.." is lacking.\n\n")
    end
    --add pkgdep to the project dependencies
    pkg.table.deps[pkgdep] = version
    --save pkg table
    Proj.save(pkg.table, "Project.lua", ".")
end

function Pkg.rm(pkgdep)
    if not Proj.ispkg(".") then
        error("Current directory is not a valid package.")
    end
    --initialize package properties
    local pkg = {}
    pkg.table = dofile("Project.lua")
    --removing pkg dependency
    pkg.table.deps[pkgdep] = nil
    --save pkg table
    Proj.save(pkg.table, "Project.lua", ".")
end

return Pkg