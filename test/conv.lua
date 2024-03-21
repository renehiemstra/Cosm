local Cm = require("src.command")
local Proj = require("src.project")
local Reg = require("src.registry")

--convenience functions for testing
local Conv = {}

function Conv.create_pkg(pkgname, path)
    local root = path.."/"..pkgname
    Proj.create(pkgname, "lua", path)
    Cm.throw{cm="gh repo create "..pkgname.." --public"}
    Cm.throw{cm="git remote add origin git@github.com:renehiemstra/"..pkgname..".git", root=root}
    Cm.throw{cm="git push --set-upstream origin main", root=root}
end

function Conv.delete_pkg(pkgname, path)
    if pkgname~="Pkg" then --precaution
        local root = path.."/"..pkgname
        Cm.throw{cm="gh repo delete "..pkgname.." --yes"}
        Cm.throw{cm="rm -rf "..path}
    end
end

function Conv.create_reg(regname)
    Cm.throw{cm="gh repo create "..regname.." --public"}
    Reg.create{name=regname, url="git@github.com:renehiemstra/"..regname}
end

function Conv.delete_reg(regname)
    Cm.throw{cm="gh repo delete "..regname.." --yes"}
    Cm.throw{cm="rm -rf "..Reg.regdir.."/"..regname}
    Reg.rmfromlist(regname)
end

return Conv