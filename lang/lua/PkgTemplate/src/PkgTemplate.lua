--Once you have added dependency 'B' to your dependencies in your 
--'Project.lua' file, simply add a dependency as follows:
-- local B = require("B")

local PkgTemplate = {}

function PkgTemplate.hello()
    print("Hello world!. Greetings from PkgTemplate")
end

return PkgTemplate
