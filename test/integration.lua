local lu = require "luaunit"

-- source and test dirs
local pkgdir = "dev.Pkg.src."
local testdir = "dev.Pkg.test."

local Cm = require(pkgdir.."command")
local Proj = require(pkgdir.."project")
local Reg = require(pkgdir.."registry")
local Pkg = require(pkgdir.."package")

--load convenience functions for testing
local Conv = require(testdir.."conv")

--test adding packages to the registry
function testIntegrationRegistryPkg()
    --create registry
    local registry = "ExampleRegistry"
    Conv.create_reg(registry)
    lu.assertTrue(Reg.isreg(registry))

    --create packages
    local projectdir = Proj.terrahome.."/tmp"
    local packages = {"ExamplePkg", "ExampleDep1", "ExampleDep2", "ExampleDepDep"}
    for _, pkg in pairs(packages) do
        Conv.create_pkg(pkg, projectdir)
    end

    --register ExampleDepDep
    Reg.register{reg=registry, url="git@github.com:renehiemstra/ExampleDepDep.git"}
    --add dependency and register ExampleDep1
    Pkg.add{dep="ExampleDepDep", version="0.1.0", root=projectdir.."/ExampleDep1"}
    Reg.register{reg=registry, url="git@github.com:renehiemstra/ExampleDep1.git"}
    --add dependency and register ExampleDep2
    Pkg.add{dep="ExampleDepDep", version="0.1.0", root=projectdir.."/ExampleDep2"}
    Reg.register{reg=registry, url="git@github.com:renehiemstra/ExampleDep2.git"}
    --add dependency and register ExamplePkg
    Pkg.add{dep="ExampleDep1", version="0.1.0", root=projectdir.."/ExamplePkg"}
    Pkg.add{dep="ExampleDep2", version="0.1.0", root=projectdir.."/ExamplePkg"}
    Reg.register{reg=registry, url="git@github.com:renehiemstra/ExamplePkg.git"}

    --check some properties
    local pkg = {}
    pkg.table = dofile(projectdir.."/ExamplePkg/Project.lua")
    lu.assertTrue(pkg.table.deps["ExampleDep1"]=="0.1.0")
    lu.assertTrue(pkg.table.deps["ExampleDep2"]== "0.1.0")
    Pkg.rm{dep="ExampleDep1", root=projectdir.."/ExamplePkg"}
    Pkg.rm{dep="ExampleDep2", root=projectdir.."/ExamplePkg"}
    pkg.table = dofile(projectdir.."/ExamplePkg/Project.lua")
    lu.assertFalse(pkg.table.deps["ExampleDep1"]=="0.1.0")
    lu.assertFalse(pkg.table.deps["ExampleDep2"]=="0.1.0")

    --cleanup registry
    Conv.delete_reg(registry)
    lu.assertFalse(Reg.isreg(registry))
    lu.assertFalse(Reg.islisted(registry))

    --cleanup packages
    for _, pkg in pairs(packages) do
        Conv.delete_pkg(pkg, projectdir)
        Cm.throw{cm="rm -rf "..Proj.terrahome.."/clones/"..pkg}
        Cm.throw{cm="rm -rf "..Proj.terrahome.."/packages/"..pkg}
    end
end

os.exit(lu.LuaUnit.run())