livereload = require 'livereload'
connect = require 'connect'
mincer = require 'mincer'
spawn = require('child_process').spawn
fs = require 'fs'
path = require 'path'
watch = require "watch"
emblem_engine = require './lib/emblem_engine'

root = path.resolve "#{__dirname}/../"

doc_dist_raw = "#{root}/dist/emd.doc.js"

exports.registerTasks = ->
  ################################################################################
  # Documentation
  task 'package:doc', 'generate documentation', ->
    env = new mincer.Environment()
    env.expireIndex()
    env.registerEngine ".emblem", emblem_engine
    env.appendPath "#{root}/doc/src"
    doc_raw = env.findAsset 'doc'
    fs.writeFileSync doc_dist_raw, doc_raw

  task 'doc:server', 'live documentation server', ->
    "doc/src".split(" ").forEach (dir)->
      path = "#{root}/#{dir}"
      test = (file)->
        return unless file.constructor is String
        return unless file.indexOf(path) is 0
        invoke 'package:doc'
      watch.watchTree path, test

    invoke 'package:doc'

    reloader = livereload.createServer port: 4401
    reloader.watch "#{root}/dist"

    server = connect.createServer()
    server.use connect.static "#{root}/doc/support"
    server.use connect.static "#{root}/dist"
    server.listen 4400
    spawn "open", ["http://localhost:4400"]
