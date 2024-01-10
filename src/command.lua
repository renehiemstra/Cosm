local Cm = {}

function Cm.capturestdout(command)
    local handle = io.popen(command)
    local output = handle:read("*a")
    handle:close()
    return output:gsub('[\n\r]', '')
end

function Cm.isfile(file)
    local exitcode = Cm.capturestdout("test -f "..file.."; echo $?")
    return exitcode=="0"
end

function Cm.isfolder(folder)
    local exitcode = Cm.capturestdout("test -d "..folder.."; echo $?")
    return exitcode=="0"
end

function Cm.getfileextension(file)
    return file:match "[^.]+$"
end

return Cm