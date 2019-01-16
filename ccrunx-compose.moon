-- cc/ccrunx-compose | 16.09.2018
-- By daelvn
--> # ccrunx-compose
--> Merge several instances together à la docker-compose.
{:title, :arrow, :dart, :bullet, :error, :quote} = require "ltext"
import chain, execute                         from require "lrunkit"
argparse                                         = require "argparse"
path                                             = require "pl.path"
yaml                                             = require "lyaml"

table.unpack or= unpack or ->

--> Collect arguments
local argl
with argparse!
  \name "ccrunx-compose"
  \description "Merge instances of CCRunX together"
  \epilog "https://ccrunx.daelvn.ga"

  \command_target "action"

  with \option "-v --version"
    \description "Prints the ccrunx-compose version"
    \action -> print "ccrunx-compose 0.2"

  with \flag "-x --no-cache"
    \description "Rebuilds the instance again before running"
    \target "nocache"

  with \command "build b"
    \description "Build an instance of ccrunx-compose"
    \target "build"
    with \option "-t --timeout"
      \description "Timeout for configuring an instance"
      \default "5s"
    with \argument "instance"
      \description "Name of the instance to run"
      \target "instance"
      \args "?"
      \default "compose"

  with \command "up u"
    \description "Run an instance"
    \target "up"
    with \argument "instance"
      \description "Name of the instance to run"
      \target "instance"
      \default "compose"
      \args 1

  with \command "none"
    \description "???"
    \target "nyan"
    \hidden true

  argl = \parse!

if argl.nocache then print error "Warning! Running no-cache mode"

exists_composeyml = -> path.isfile "ccrunx-compose.yml"
configure_instance = (env) ->
  (chain table.unpack {
    -> print arrow "Configuring ccrunx instance #{env}"
    -> print dart "Creating folder .ccrunx/#{env}"
    -> path.mkdir ".ccrunx"
    -> path.mkdir ".ccrunx/#{env}"
    -> print dart "Running CCEmuX for #{argl.timeout} to generate configuration files"
    -> os.execute "timeout #{argl.timeout} ccemux -d .ccrunx/#{env} &> /dev/null"
    -> print dart "Creating computer/ folder"
    -> path.mkdir ".ccrunx/#{env}/computer"
    -- path.mkdir ".ccrunx/#{env}/computer/#{argl.id}"
    -> print dart "Create attach/ folder"
    -> path.mkdir ".ccrunx/#{env}/attach"})!

handle_id = (envname, envdata) ->
  root = ".ccrunx/#{argl.instance}/computer/#{envdata.id}"
  (chain table.unpack {
    -> print arrow "Building #{argl.instance}:#{envname}..."
    -> print quote "Computer ID:   #{envdata.id}"
    -> print quote "Name:          #{envdata.name or envname}"
    -> if envdata.after then
         print quote "Post-trigger: #{envdata.after}"
    --> ### Create ID if it doesn't exist
    -> unless path.isdir root
         print dart "Created directory #{root}"
         path.mkdir root
    --> ### Create subpaths if they don't exist
    -> if envdata.path
         parts = [part for part in envdata.path\gmatch "[^/]+"]
         acc   = "#{root}/"
         for part in *parts
           unless path.isdir acc .. part .. "/"
            print dart "Created directory #{acc..part.."/"}"
            path.mkdir acc .. part .. "/"
            acc ..= part .. "/"
    --> ### Copy files
    -> print dart "Copying metafiles..."
    -> os.execute "cp -r .ccrunx/#{envname}/* .ccrunx/#{argl.instance}/"
    -> print dart "Copying files onto #{root}#{envdata.path or ""}..."
    -> os.execute "cp -r #{envname}/* #{root}#{envdata.path or "/"}"
    --> ### Execute final command
    -> if envdata.after
         print dart "Running post-trigger: #{envdata.after\gsub "%?", root}"
         os.execute envdata.after\gsub "%?", root
  })!

get_name_for_image = (file) -> file\match "ccrunx%-image_(.+)%.ccrunx"

handle_image = (envname, envdata) ->
  (chain table.unpack {
    -> print arrow "Building #{argl.instance}:image-#{get_name_for_image envdata.image}"
    -> print quote "Image: #{envdata.image}"
    -> print quote "Name:  #{envdata.name or envname}"
    --> ### Check that the image exists
    -> unless path.isfile envdata.image
         print error "ccrunx-compose $ image #{envdata.image} not found"
         os.exit!
    --> ### Decompress image 
    --> We decompress in the current directory so that it gets stored
    --> in ./.ccrunx: the directory for other instances. after this,
    --> we can just build as any other instance.
    -> os.execute "ccrunx-image d #{envdata.image} --embed"
    --> ### Act for all instances from the image
    -> for insname, insdata in pairs envdata.instances
         handle_id insname, insdata
  })!
  
put_startup = (id, file) ->
  --> ### Create (or not) computer ID
  path.mkdir ".ccrunx/#{argl.instance}/computer/#{id}"
  --> ### Check that file exists
  unless path.isfile file
    print error "ccrunx-compose $ startup file #{file} doesn't exist"
    os.exit!
  --> ### Copy file
  print dart "Copying startup file #{file}"
  os.execute "cp #{file} .ccrunx/#{argl.instance}/computer/#{id}/startup.lua"

put_config = (file) ->
  --> ### Check that file exists
  unless path.isfile file
    print error "ccrunx-compose $ configuration file #{file} doesn't exist"
    os.exit!
  --> ### Copy file
  print dart "Copying configuration file #{file}"
  os.execute "cp #{file} .ccrunx/#{argl.instance}/ccemux.json"

put_plugin = (file) ->
  --> ### Check that file exists
  unless path.isfile file
    print error "ccrunx-compose $ plugin file #{file} doesn't exist"
    os.exit!
  --> ### Copy file
  print dart "Copying plugin #{file}"
  os.execute "cp #{file} .ccrunx/#{argl.instance}/plugins/"

build = ->
  --> ### Check that ccrunx-compose.yml exists
  unless exists_composeyml!
    print error "ccrunx-compose $ ccrunx-compose.yml not found"
    os.exit!
  --> ### Read YAML
  local compose
  with io.open "ccrunx-compose.yml"
    content = \read "*a"
    \close!
    compose = yaml.load content
  --> ### Check that $instance exists
  unless compose[argl.instance]
    print error "ccrunx-compose $ instance #{argl.instance} not found"
    os.exit
  --> ### Configuring
  print arrow "Building ccrunx-compose.yml:#{argl.instance}"
  configure_instance argl.instance
  --> ### Iterate through the instances
  instance = compose[argl.instance]
  for envname, envdata in pairs instance.env
    --> ### Check that the $envname exists
    unless (path.isdir envname) and (path.isdir ".ccrunx/#{envname}")
      print error "ccrunx-compose #{argl.instance}:#{envname} doesn't exist"
      os.exit!
    --> ### Handle
    if envdata.id
      handle_id envname, envdata
    elseif envdata.image
      handle_image envname, envdata
  --> ### Place startup files
  if instance.startup
    print arrow "Placing startup files"
    for id, startupf in pairs instance.startup
      put_startup id, startupf
  --> ### Place ccemux.json
  if instance.config
    print arrow "Placing configuration file"
    put_config instance.config
  --> ### Place plugins
  if instance.plugins
    print arrow "Placing plugins"
    for plugin in *instance.plugins
      put_plugin plugin
  --
  print bullet "Done!"

print title "ccrunx-compose 0.2"
argl.instance or= "compose"
argl.timeout  or= "5s"
switch argl.action
  when "build"
    build!
  when "up"
    if argl.nocache then build!
    os.execute "ccemux -d .ccrunx/#{argl.instance}"
