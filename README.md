Emd
=======

An opinionated convention over configuration EmberJs data modeling framework.

Prescribed Format
------

The typical (coffee) JSON format that I would suggest looks like this:

    modelname:
      url: "/link/to/resource/route"
      id: modelid
      under_score_names: "with values!"
      created_at: "date string"
      errors: {key: ["problem"]}
      links:
        relatedmodel: "/link/to/related/model?with=relevant&conditions"

Prescribed API Structure
----

Every API should have a root object, that provides discoverable urls through a
nested links object.

    api:
      url: "/api"
      version: "0.1.0"
      links:
        users: "/api/users"
        articles: "/api/articles"
        comments: "/api/comments"

Example?
-------

Here is the coffee script to deal with the above api structure

    App.Api = D.Model.extend
      url: "/api"
      users: D.hasMany 'App.User', urlBinding: 'links.users'
      articles: D.hasMany 'App.Article', urlBinding: 'links.articles'
      comments: D.hasMany 'App.Comment', urlBinding: 'links.comments'

    App.User = D.Model.extend
      email: D.attr "email"
      phoneNumber: D.attr "phone_number"
      comments: D.hasMany 'App.Comment', urlBinding: 'links.comments'

    api = App.Api.create()
    users = api.get "users"
    users.load().then ->
      first_user = users.get "firstObject"

    new_user = users.get "nextNew"
    new_user.save().then (ok = ->
      console.log "saved user!"
      next_new_user = users.get "nextNew"
      next_new_user != new_user # true
    ), (er = ->
      console.log "errors!", new_user.get 'errors'
    )

Attribute Types
-----

Currently there is support for

    D.attr.belongsTo foreign_key: 'Parent.Model'
    D.attr.hasMany 'Child.Model', urlBinding: 'link.children'
    D.attr.moment 'key_name'
    D.attr 'key_name'
    D.attr.object 'key_name'


Links and Urls?
----

Links represent the state of all models of the same type.
Url's represent the resource location of a specific model or collection.

Whenever a `Certain.Model` is updated, created, or destroyed, the
`Certain.Model.link` is updated and triggers reloads on collections that rely
on that link.


RecordArrays, Relations?
----

RecordArrays are arrays that contain a single model type, url, and link.

Relations are modified `Ember.Array` objects that lazy load their contents
and can extend their parent Relation's query.

They can also be used to create new models.


Testing
----

    brew install phantomjs
    npm install -g coffee-script
    npm install
    cake test

Pull requests are welcome!
