#<!--
# = require_self
# = require_tree ./emd
#-->

#
# `EMD` is an attempt to create a model layer for EmberJS that just works, and
# works well.
#
# The source is located at the [EMD github repo](http://github.com/Nthalk/emd).
#
# Getting started
# ----
#
# 1. Download the latest [minified](http://raw.github.com/Nthalk/emd/master/dist/emd.min.js)
# or [development](http://raw.github.com/Nthalk/emd/master/dist/emd.js) distributable.
#
# 1. Include it via sprockets, or html after your ember dependencies and before
# your application code.
#
# 1. Checkout the example documentation.
#
@EMD = Em.Namespace.create
  VERSION: '0.1.0'
