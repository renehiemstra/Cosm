package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Reg = require("src.registry")

local function abort(message)
    print(message)
    os.exit(1)
end

--extract command line arguments
local nargs = #arg
if nargs==1 then
    local reg = arg[1]
    print("registry: "..reg)
    Reg.synchronize(reg)
    print("Updated registry "..reg.." in "..Reg.regdir.."/"..reg..".\n")
elseif nargs==0 then
    local registries = dofile(Reg.regdir.."/List.lua")
    for i,reg in pairs(registries) do
        print("registry: "..reg)
        Reg.synchronize(reg)
    end
    print("Updated all registries in "..Reg.regdir..".\n")
else
    abort("Invalid arguments: try signature: cosm registry update [--all, <registry name>].\n")
end