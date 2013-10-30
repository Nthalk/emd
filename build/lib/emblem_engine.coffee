vm = require 'vm'
fs = require 'fs'
sys = require 'sys'
mincer = require 'mincer'

includeInThisContext = ((path)->
  code = fs.readFileSync path
  vm.runInThisContext code, path
).bind this

includeInThisContext "#{__dirname}/../vendor/handlebars.js"
includeInThisContext "#{__dirname}/../vendor/emblem.js"

EmblemEngine = module.exports = ->
  mincer.Template.apply @, arguments

options = template_path: '/templates/'
EmblemEngine.options = (opts = {})->
  options = opts

EmblemEngine.defaultMimeType = 'application/javascript'

EmblemEngine.prototype.evaluate = (context, locals)->
  template = Emblem.precompile(Handlebars, @data).toString()
  root = false
  context.environment.paths.forEach (path)=>
    path = path + options.template_path
    root = path if @file.indexOf(path) is 0
  template_path = @file.substring root.length
  template_path = template_path.split('.')[0]
  "Ember.TEMPLATES['#{template_path}'] = Ember.Handlebars.template(" + template + ");\n"
