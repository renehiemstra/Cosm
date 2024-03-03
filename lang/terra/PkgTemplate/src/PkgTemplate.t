local cosm = require("lang.lua.cosm")

--Once you have added 'DepA' to your dependencies in your 'Project.lua' file you can add a dependency as follows:
--local A = cosm.require("DepA")

local C = terralib.includecstring [[
   #include <stdio.h>
]]

local PkgTemplate = {}

terra PkgTemplate.hello()
    C.printf("Hello world!. Greetings from PkgTemplate.\n")
end

return PkgTemplate
