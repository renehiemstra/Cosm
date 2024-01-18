local lu = require "luaunit"

local pkgdir = "dev.Pkg.src."
local Cm = require(pkgdir.."command")
local Proj = require(pkgdir.."project")
local Reg = require(pkgdir.."registry")

local run_integration_tests = false

function testLoadRegistries()
    local registries = {"R1", "R2", "R3"}
    Reg.saveregistries(registries, "tmpList.jl")
    local regtmp = Reg.loadregistries("tmpList.jl")
    lu.assertEquals(registries[1], regtmp[1])
    lu.assertEquals(registries[2], regtmp[2])
    lu.assertEquals(registries[3], regtmp[3])
    Cm.throw{cm="rm tmpList.jl", root=Reg.regdir}
end

function testSaveRegistry()

    local table1 = require "registries.MyRegistry.Registry"
    Reg.save(table1, "tmpRegistry.lua", ".")
    local table2 = require "tmpRegistry"

    lu.assertTrue(table1.name == "MyRegistry" and table2.name=="MyRegistry")
    lu.assertEquals(table1.uuid, table2.uuid)
    os.execute("rm tmpRegistry.lua")
end

function testIsRegistry()
    lu.assertTrue(Reg.isreg("MyRegistry"))
    lu.assertFalse(Reg.isreg("RegistryDoesntExist"))
end

function testRegistryCreate()
    Cm.throw{cm="gh repo create ExampleRegistry --public"}
    Reg.create{name="ExampleRegistry", url="git@github.com:renehiemstra/ExampleRegistry"}
    lu.assertTrue(Reg.isreg("ExampleRegistry"))

    --cleanup
    local root = Reg.regdir.."/ExampleRegistry"
    Cm.throw{cm="gh repo delete ExampleRegistry --yes"}
    Cm.throw{cm="rm -rf "..Reg.regdir.."/ExampleRegistry"}
end

local function create_pkg(pkgname, path)
    local root = path.."/"..pkgname
    Proj.create(pkgname, path)
    Cm.throw{cm="gh repo create "..pkgname.." --public"}
    Cm.throw{cm="git remote add origin git@github.com:renehiemstra/"..pkgname..".git", root=root}
    Cm.throw{cm="git push --set-upstream origin main", root=root}
end

local function delete_pkg(pkgname, path)
    if pkgname~="Pkg" then --procaution
        local root = path.."/"..pkgname
        Cm.throw{cm="gh repo delete "..pkgname.." --yes"}
        Cm.throw{cm="rm -rf "..path}
    end
end

local function create_reg(regname)
    Cm.throw{cm="gh repo create "..regname.." --public"}
    Reg.create{name=regname, url="git@github.com:renehiemstra/"..regname}
end

local function delete_reg(regname)
    Cm.throw{cm="gh repo delete "..regname.." --yes"}
    Cm.throw{cm="rm -rf "..Reg.regdir.."/"..regname}
end


if run_integration_tests then

function testRegistryAddPkg()
    --create registry
    local registry = "ExampleRegistry"
    create_reg(registry)
    lu.assertTrue(Reg.isreg(registry))

    --create packages
    local projectdir = Proj.terrahome.."/clones"
    local packages = {"ExamplePkg", "ExampleDep1", "ExampleDep2", "ExampleDepDep"}
    for _, pkg in pairs(packages) do
        create_pkg(pkg, projectdir)
    end

    --register packages
    for _, pkg in pairs(packages) do
        Reg.register{reg=registry, url="git@github.com:renehiemstra/"..pkg..".git"}
    end

    --cleanup registry
    delete_reg(registry)
    lu.assertFalse(Reg.isreg(registry))

    --cleanup packages
    for _, pkg in pairs(packages) do
        delete_pkg(pkg, projectdir)
        Cm.throw{cm="rm -rf "..Proj.terrahome.."/packages/"..pkg}
    end
end

end

-- function testPkgAddDep()
--create registry
local registry = "ExampleRegistry"
create_reg(registry)
lu.assertTrue(Reg.isreg(registry))

--create packages
local projectdir = Proj.terrahome.."/packages"
local packages = {"ExamplePkg", "ExampleDep1", "ExampleDep2", "ExampleDepDep"}
for _, pkg in pairs(packages) do
    create_pkg(pkg, projectdir)
end

--register packages
for _, pkg in pairs(packages) do
    Reg.register{reg=registry, url="git@github.com:renehiemstra/"..pkg..".git"}
end

-- end
-- lu.LuaUnit.run()

-- local registry = "ExampleRegistry"
-- local packages = {"ExamplePkg", "ExampleDep1", "ExampleDep2", "ExampleDepDep"}
    

-- --cleanup registry
-- delete_reg(registry)
-- lu.assertFalse(Reg.isreg(registry))
-- local projectdir = Proj.terrahome.."/packages"

-- --cleanup packages
-- for _, pkg in pairs(packages) do
--     delete_pkg(pkg, projectdir)
--     Cm.throw{cm="rm -rf "..Proj.terrahome.."/packages/"..pkg}
-- end