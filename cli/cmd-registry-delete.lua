package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Reg = require("src.registry")

local function abort()
    print("Invalid arguments: use 'cosm registry rm <name>'")
    os.exit(1)
end

local function printstats(name, root)
    print("Removed registry "..name.." in "..root..".")
end

--extract command line arguments
local nargs = #arg
if nargs==1 then
    local reg = arg[1]
    if not pcall(Reg.delete, reg) then
        abort() --ToDo: better error message
    end
    printstats(reg, Reg.regdir)
else
    abort()
end