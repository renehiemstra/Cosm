local lu = require "luaunit"

-- source and test dirs
local pkgdir = "dev.Pkg.src."
local testdir = "dev.Pkg.test."

local Cm = require(pkgdir.."command")
local Proj = require(pkgdir.."project")
local Reg = require(pkgdir.."registry")

--load convenience functions for testing
local Conv = require(testdir.."conv")

--test adding packages to the registry
function testRegistryAddPkg()
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

    --adding dependency relationships


    --register packages
    for _, pkg in pairs(packages) do
        Reg.register{reg=registry, url="git@github.com:renehiemstra/"..pkg..".git"}
    end

    --cleanup registry
    Conv.delete_reg(registry)
    lu.assertFalse(Reg.isreg(registry))

    --cleanup packages
    for _, pkg in pairs(packages) do
        Conv.delete_pkg(pkg, projectdir)
        Cm.throw{cm="rm -rf "..Proj.terrahome.."/clones/"..pkg}
        Cm.throw{cm="rm -rf "..Proj.terrahome.."/packages/"..pkg}
    end
end

os.exit(lu.LuaUnit.run())