local args = {...}
local configPath = args[1]
local config = assert(loadfile(configPath))()
local lfs = require('lfs')
--获取路径
local function stripfilename(filepath)
    return string.match(filepath, "(.+)/[^/]*%.%w+$") --*nix system
    --return string.match(filepath, “(.+)\\[^\\]*%.%w+$”) — windows
end

--获取文件名
local function strippath(filepath)
    return string.match(filepath, ".+/([^/]*%.%w+)$") -- *nix system
    --return string.match(filepath, “.+\\([^\\]*%.%w+)$”) — *windows
end

--去除扩展名
local function stripextension(filepath)
    local idx = filepath:match(".+()%.%w+$")
    if (idx) then
        return filepath:sub(1, idx - 1)
    else
        return filepath
    end
end

--获取扩展名
local function getextension(filepath)
    return filepath:match(".+%.(%w+)$")
end

local replSep = function(s)
    return (string.gsub(s, "/", "."))
end

local readfile = function(filepath)
    local file = assert(io.open(filepath, 'r'))
    local str = assert(file:read('*a'))
    file:close()
    return str
end
local attrDir
attrDir = function(path, func)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            --过滤linux目录下的"."和".."目录
            local f = path .. '/' .. file
            local attr = lfs.attributes(f)
            if attr.mode == "directory" then
                attrDir(f, func)                          --如果是目录，则进行递归调用
            else
                func(f)
            end
        end
    end
end
print('start!')
local currentdir = lfs.currentdir()
local projectdir = stripfilename(configPath)
lfs.mkdir(currentdir ..'/'..projectdir..'/'.. (config.exportdir))
local mergefile = assert(io.open(currentdir ..'/'..projectdir..'/'..(config.exportdir)..'/'..(config.exportfile), 'w+'))
local mergefilestr = string.format([[-- created by lua-merge(https://github.com/wuluwululang/lua-merge)
-- datetime: %s]], os.date('%Y/%m/%d %H:%M:%S'))
mergefilestr = mergefilestr..'\n\n'..[[local args = { ... }; local oriRequire = require; local loadstring = loadstring; local unpack = unpack; local preload = {}; local loaded = {}; local _require = function(path, ...) if loaded[path] then     return loaded[path] end if preload[path] then     local func = preload[path]     local mod = func(...) or true     loaded[path] = mod     return mod end return oriRequire(path, ...) end local define = function(path, factory) preload[path] = factory end]]
mergefilestr = mergefilestr..[[


-- define modules start

]]
attrDir(projectdir..'/'..config.workdir, function(filepath)
    if getextension(filepath) == 'lua' then
        local route = filepath:sub(#(projectdir..'/'..config.workdir) + 2, -5)
        route = replSep(route)
        print('register:', route)
        mergefilestr = mergefilestr .. ([[define(']] .. route .. "', loadstring([==[function(require, ...)")
        mergefilestr = mergefilestr .. (readfile(filepath))
        mergefilestr = mergefilestr .. ([[end]==],'?.]]..route..[[')())]])
        mergefilestr = mergefilestr .. ('\n')
        mergefilestr = mergefilestr .. ('\n')
    end
end)
mergefilestr = mergefilestr..[[
-- define modules end

]]
mergefilestr = mergefilestr .. ([[return _require(']] .. config.entrancefile .. [[', unpack(args))]])
mergefile:write(mergefilestr)
mergefile:close()
print('done!')