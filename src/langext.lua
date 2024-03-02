local Cm = require("src.command")

local Lang = {}

--cosm directory for language functionality
Lang.langdir = os.getenv("COSM_DEPOT_PATH").."/lang"

--global replacement of 'old' with 'new' in all files in all
--subdirectories
local function find_and_replace_expr_inside_files(oldexpr, newexpr, root)
    Cm.throw{cm="find . -type f -exec sed -i.backup \"s/"..oldexpr.."/"..newexpr.."/g\" {} \\;", root=root}
    Cm.throw{cm="find . -name \"*.backup\" -type f -delete", root=root}
end

--global replacement of 'old' with 'new' in all filenames
local function find_and_replace_expr_in_file_and_dir_names(oldexpr, newexpr, root)
    Cm.throw{cm="for file in `find . -type f -name '*"..oldexpr.."*'`; do mv -v \"$file\" \"${file/"..oldexpr.."/"..newexpr.."}\"; done", root=root}
end

function Lang.project_from_template(template, pkgname, root)
    --check that language is supported
    if not Cm.parentdir(template) then
        error("Language "..Cm.parentdirname(template).." is not available. Check your local languages folder in "..Lang.langdir..".\n")
    end
    --check that template is supported
    if not Cm.isdir(template) then
        error("Template "..Cm.basename(template).." is not available. Check your local languages folder in "..Cm.parentdir(template)..".\n")
    end
    --copy template to a temporary folder
    Cm.throw{cm="cp -r "..template.." "..Lang.langdir.."/.tmp"}
    --replace all occurences of 'PkgTemplate' with pkgname
    find_and_replace_expr_inside_files("PkgTemplate", pkgname, Lang.langdir.."/.tmp")
    find_and_replace_expr_in_file_and_dir_names("PkgTemplate", pkgname, Lang.langdir.."/.tmp")
    --make results available and clean-up
    Cm.throw{cm="mv .tmp".." "..root.."/"..pkgname, root=Lang.langdir}
end

return Lang