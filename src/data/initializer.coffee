########################################################
#
Em.onLoad "Ember.Application", (app)->

  app.initializer
    name: "store"
    initialize: (container, app)->
      app.register('store:main', D.Store);
      app.set("defaultStore", container.lookup('store:main'))
      D.set("defaultStore", container.lookup('store:main'))

  app.initializer
    name: "injectStore"
    initialize: (container, app) ->
      app.inject "controller", "store", "store:main"
      app.inject "route", "store", "store:main"
