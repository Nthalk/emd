emblem_engine = require 'mincer-emblem-engine'
mincer = require 'mincer'
livereload = require 'livereload'
connect = require 'connect'
spawn = require('child_process').spawn
fs = require 'fs'
watch = require "watch"
path = require 'path'

emblem_engine.options template_path: "/views/"

root = path.normalize "#{__dirname}/../"

doc_dist_js = "#{root}/dist/emd.doc.js"
doc_dist_css = "#{root}/dist/emd.doc.css"

exports.registerTasks = ->
  ################################################################################
  # Documentation
  task 'package:doc', 'generate documentation', ->
    env = new mincer.Environment()
    env.expireIndex()
    env.registerEngine ".emblem", emblem_engine
    env.appendPath "#{root}/doc/src"

    doc_raw_js = env.findAsset 'doc.js'
    fs.writeFileSync doc_dist_js, doc_raw_js

    doc_raw_css = env.findAsset 'doc.css'
    fs.writeFileSync doc_dist_css, doc_raw_css

  task 'doc:server', 'live documentation server', ->
    "doc/src".split(" ").forEach (dir)->
      doc_path = "#{root}#{dir}"
      test = (file)->
        return unless file.constructor is String
        return unless file.indexOf(doc_path) is 0
        invoke 'package:doc'

      watch.watchTree doc_path, test

    invoke 'package:doc'

    reloader = livereload.createServer port: 4401
    reloader.watch "#{root}/dist"

    server = connect.createServer()
    server.use connect.static "#{root}/doc/support"
    server.use connect.static "#{root}/dist"
    server.listen 4400
    spawn "open", ["http://localhost:4400"]
