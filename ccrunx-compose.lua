#!/usr/bin/env lua
local title, arrow, dart, bullet, error, quote
do
  local _obj_0 = require("ltext")
  title, arrow, dart, bullet, error, quote = _obj_0.title, _obj_0.arrow, _obj_0.dart, _obj_0.bullet, _obj_0.error, _obj_0.quote
end
local chain, execute
do
  local _obj_0 = require("lrunkit")
  chain, execute = _obj_0.chain, _obj_0.execute
end
local argparse = require("argparse")
local path = require("pl.path")
local yaml = require("lyaml")
table.unpack = table.unpack or (unpack or function() end)
local argl
do
  local _with_0 = argparse()
  _with_0:name("ccrunx-compose")
  _with_0:description("Merge instances of CCRunX together")
  _with_0:epilog("https://ccrunx.daelvn.ga")
  _with_0:command_target("action")
  do
    local _with_1 = _with_0:option("-v --version")
    _with_1:description("Prints the ccrunx-compose version")
    _with_1:action(function()
      return print("ccrunx-compose 0.1")
    end)
  end
  do
    local _with_1 = _with_0:flag("-x --no-cache")
    _with_1:description("Rebuilds the instance again before running")
    _with_1:target("nocache")
  end
  do
    local _with_1 = _with_0:command("build b")
    _with_1:description("Build an instance of ccrunx-compose")
    _with_1:target("build")
    do
      local _with_2 = _with_1:option("-t --timeout")
      _with_2:description("Timeout for configuring an instance")
      _with_2:default("5s")
    end
    do
      local _with_2 = _with_1:argument("instance")
      _with_2:description("Name of the instance to run")
      _with_2:target("instance")
      _with_2:args("?")
      _with_2:default("compose")
    end
  end
  do
    local _with_1 = _with_0:command("up u")
    _with_1:description("Run an instance")
    _with_1:target("up")
    do
      local _with_2 = _with_1:argument("instance")
      _with_2:description("Name of the instance to run")
      _with_2:target("instance")
      _with_2:default("compose")
      _with_2:args(1)
    end
  end
  do
    local _with_1 = _with_0:command("none")
    _with_1:description("???")
    _with_1:target("nyan")
    _with_1:hidden(true)
  end
  argl = _with_0:parse()
end
if argl.nocache then
  print(error("Warning! Running no-cache mode"))
end
local exists_composeyml
exists_composeyml = function()
  return path.isfile("ccrunx-compose.yml")
end
local configure_instance
configure_instance = function(env)
  return (chain(table.unpack({
    function()
      return print(arrow("Configuring ccrunx instance " .. tostring(env)))
    end,
    function()
      return print(dart("Creating folder .ccrunx/" .. tostring(env)))
    end,
    function()
      return path.mkdir(".ccrunx")
    end,
    function()
      return path.mkdir(".ccrunx/" .. tostring(env))
    end,
    function()
      return print(dart("Running CCEmuX for " .. tostring(argl.timeout) .. " to generate configuration files"))
    end,
    function()
      return os.execute("timeout " .. tostring(argl.timeout) .. " ccemux -d .ccrunx/" .. tostring(env) .. " &> /dev/null")
    end,
    function()
      return print(dart("Creating computer/ folder"))
    end,
    function()
      return path.mkdir(".ccrunx/" .. tostring(env) .. "/computer")
    end,
    function()
      return print(dart("Create attach/ folder"))
    end,
    function()
      return path.mkdir(".ccrunx/" .. tostring(env) .. "/attach")
    end
  })))()
end
local handle_id
handle_id = function(envname, envdata)
  local root = ".ccrunx/" .. tostring(argl.instance) .. "/computer/" .. tostring(envdata.id)
  return (chain(table.unpack({
    function()
      return print(arrow("Building " .. tostring(argl.instance) .. ":" .. tostring(envname) .. "..."))
    end,
    function()
      return print(quote("Computer ID:   " .. tostring(envdata.id)))
    end,
    function()
      return print(quote("Name:          " .. tostring(envdata.name or envname)))
    end,
    function()
      if envdata.after then
        return print(quote("Post-trigger: " .. tostring(envdata.after)))
      end
    end,
    function()
      if not (path.isdir(root)) then
        print(dart("Created directory " .. tostring(root)))
        return path.mkdir(root)
      end
    end,
    function()
      if envdata.path then
        local parts
        do
          local _accum_0 = { }
          local _len_0 = 1
          for part in envdata.path:gmatch("[^/]+") do
            _accum_0[_len_0] = part
            _len_0 = _len_0 + 1
          end
          parts = _accum_0
        end
        local acc = tostring(root) .. "/"
        for _index_0 = 1, #parts do
          local part = parts[_index_0]
          if not (path.isdir(acc .. part .. "/")) then
            print(dart("Created directory " .. tostring(acc .. part .. "/")))
            path.mkdir(acc .. part .. "/")
            acc = acc .. (part .. "/")
          end
        end
      end
    end,
    function()
      return print(dart("Copying metafiles..."))
    end,
    function()
      return os.execute("cp -r .ccrunx/" .. tostring(envname) .. "/* .ccrunx/" .. tostring(argl.instance) .. "/")
    end,
    function()
      return print(dart("Copying files onto " .. tostring(root) .. tostring(envdata.path or "") .. "..."))
    end,
    function()
      return os.execute("cp -r " .. tostring(envname) .. "/* " .. tostring(root) .. tostring(envdata.path or "/"))
    end,
    function()
      if envdata.after then
        print(dart("Running post-trigger: " .. tostring(envdata.after:gsub("%?", root))))
        return os.execute(envdata.after:gsub("%?", root))
      end
    end
  })))()
end
local get_name_for_image
get_name_for_image = function(file)
  return file:match("ccrunx%-image_(.+)%.ccrunx")
end
local handle_image
handle_image = function(envname, envdata)
  return (chain(table.unpack({
    function()
      return print(arrow("Building " .. tostring(argl.instance) .. ":image-" .. tostring(get_name_for_image(envdata.image))))
    end,
    function()
      return print(quote("Image: " .. tostring(envdata.image)))
    end,
    function()
      return print(quote("Name:  " .. tostring(envdata.name or envname)))
    end,
    function()
      if not (path.isfile(envdata.image)) then
        print(error("ccrunx-compose $ image " .. tostring(envdata.image) .. " not found"))
        return os.exit()
      end
    end,
    function()
      return os.execute("ccrunx-image d " .. tostring(envdata.image) .. " --embed")
    end,
    function()
      for insname, insdata in pairs(envdata.instances) do
        handle_id(insname, insdata)
      end
    end
  })))()
end
local put_startup
put_startup = function(id, file)
  path.mkdir(".ccrunx/" .. tostring(argl.instance) .. "/computer/" .. tostring(id))
  if not (path.isfile(file)) then
    print(error("ccrunx-compose $ startup file " .. tostring(file) .. " doesn't exist"))
    os.exit()
  end
  print(dart("Copying startup file " .. tostring(file)))
  return os.execute("cp " .. tostring(file) .. " .ccrunx/" .. tostring(argl.instance) .. "/computer/" .. tostring(id) .. "/startup.lua")
end
local put_config
put_config = function(file)
  if not (path.isfile(file)) then
    print(error("ccrunx-compose $ configuration file " .. tostring(file) .. " doesn't exist"))
    os.exit()
  end
  print(dart("Copying configuration file " .. tostring(file)))
  return os.execute("cp " .. tostring(file) .. " .ccrunx/" .. tostring(argl.instance) .. "/ccemux.json")
end
local put_plugin
put_plugin = function(file)
  if not (path.isfile(file)) then
    print(error("ccrunx-compose $ plugin file " .. tostring(file) .. " doesn't exist"))
    os.exit()
  end
  print(dart("Copying plugin " .. tostring(file)))
  return os.execute("cp " .. tostring(file) .. " .ccrunx/" .. tostring(argl.instance) .. "/plugins/")
end
local build
build = function()
  if not (exists_composeyml()) then
    print(error("ccrunx-compose $ ccrunx-compose.yml not found"))
    os.exit()
  end
  local compose
  do
    local _with_0 = io.open("ccrunx-compose.yml")
    local content = _with_0:read("*a")
    _with_0:close()
    compose = yaml.load(content)
  end
  if not (compose[argl.instance]) then
    print(error("ccrunx-compose $ instance " .. tostring(argl.instance) .. " not found"))
    local _ = os.exit
  end
  print(arrow("Building ccrunx-compose.yml:" .. tostring(argl.instance)))
  configure_instance(argl.instance)
  local instance = compose[argl.instance]
  for envname, envdata in pairs(instance.env) do
    if not ((path.isdir(envname)) and (path.isdir(".ccrunx/" .. tostring(envname)))) then
      print(error("ccrunx-compose " .. tostring(argl.instance) .. ":" .. tostring(envname) .. " doesn't exist"))
      os.exit()
    end
    if envdata.id then
      handle_id(envname, envdata)
    elseif envdata.image then
      handle_image(envname, envdata)
    end
  end
  if instance.startup then
    print(arrow("Placing startup files"))
    for id, startupf in pairs(instance.startup) do
      put_startup(id, startupf)
    end
  end
  if instance.config then
    print(arrow("Placing configuration file"))
    put_config(instance.config)
  end
  if instance.plugins then
    print(arrow("Placing plugins"))
    local _list_0 = instance.plugins
    for _index_0 = 1, #_list_0 do
      local plugin = _list_0[_index_0]
      put_plugin(plugin)
    end
  end
  return print(bullet("Done!"))
end
print(title("ccrunx-compose 0.2"))
argl.instance = argl.instance or "compose"
argl.timeout = argl.timeout or "5s"
local _exp_0 = argl.action
if "build" == _exp_0 then
  return build()
elseif "up" == _exp_0 then
  if argl.nocache then
    build()
  end
  return os.execute("ccemux -d .ccrunx/" .. tostring(argl.instance))
end
