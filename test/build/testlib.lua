-- created by lua-merge(https://github.com/wuluwululang/lua-merge)
-- datetime: 2019/04/06 16:45:25

local args = { ... }; local oriRequire = require; local loadstring = loadstring; local unpack = unpack; local preload = {}; local loaded = {}; local _require = function(path, ...) if loaded[path] then     return loaded[path] end if preload[path] then     local func = preload[path]     local mod = func(...) or true     loaded[path] = mod     return mod end return oriRequire(path, ...) end local define = function(path, factory) preload[path] = factory end

-- define modules start

define('api', loadstring([==[function(require, ...)return {
    testfunc = require('impl').testfunc,
}end]==],'?.api')())

define('impl', loadstring([==[function(require, ...)return {
    testfunc = function() end
}end]==],'?.impl')())

-- define modules end

return _require('api', unpack(args))