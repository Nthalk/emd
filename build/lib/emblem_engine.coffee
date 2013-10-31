vm = require 'vm'
fs = require 'fs'
sys = require 'sys'
mincer = require 'mincer'


shim = """
       // DOM
       var Element = {};
       Element.firstChild = function () { return Element; };
       Element.innerHTML = function () { return Element; };
       Element.childNodes = [0,1]
       var document = { createRange: false, createElement: function() { return Element; } };
       var window = this;
       this.document = document;
       // Console
       var console = window.console = {};
       console.log = console.info = console.warn = console.error = function(){};
       // jQuery
       var jQuery = function() { return jQuery; };
       jQuery.ready = function() { return jQuery; };
       jQuery.inArray = function() { return jQuery; };
       jQuery.jquery = "1.7.1";
       jQuery.event = { fixHooks: {} };
       var $ = jQuery;
       """

################################################################################
# Required libs
includeInThisContext = ((path)->
  code = fs.readFileSync path
  code = shim + code
  vm.runInThisContext code, path
).bind this

includeInThisContext "#{__dirname}/../vendor/handlebars.js"
includeInThisContext "#{__dirname}/../vendor/ember.js"
includeInThisContext "#{__dirname}/../vendor/emblem.js"

################################################################################
# EmblemEngine

options =
  template_path: '/templates/'

EmblemEngine = module.exports = ->
  mincer.Template.apply @, arguments

EmblemEngine.options = (opts = {})->
  options = opts

EmblemEngine.defaultMimeType = 'application/javascript'

EmblemEngine.prototype.evaluate = (context, locals)->
  template = Emblem.precompile(Ember.Handlebars, @data).toString()
  root = false

  context.environment.paths.forEach (path)=>
    path = path + options.template_path
    root = path if @file.indexOf(path) is 0

  template_path = @file.substring root.length
  template_path = template_path.split('.')[0]
  "Ember.TEMPLATES['#{template_path}'] = Ember.Handlebars.template(#{template});\n"
