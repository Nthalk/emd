var D;

D = Em.Namespace.create({
  VERSION: '0.1.0'
});
D.attr = function(serialized_name, meta) {
  var key, property, property_args;
  if (meta == null) {
    meta = {};
  }
  Em.assert("You must specify a serialized name", meta.serialized_name = serialized_name);
  key = "_data." + serialized_name;
  meta.extra_keys || (meta.extra_keys = []);
  if (!(meta.extra_keys instanceof Array)) {
    meta.extra_keys = [meta.extra_keys];
  }
  meta.extra_keys.unshift(key);
  property_args = meta.extra_keys;
  delete meta.extra_keys;
  property = function(_, set) {
    var existing;
    if (set !== void 0) {
      this.set('isDirty', true);
      if (meta.convertTo) {
        this.set(key, meta.convertTo(set));
      } else {
        this.set(key, set);
      }
      return set;
    } else {
      existing = this.get(key);
      if (existing === void 0 && meta.if_null) {
        if (typeof meta.if_null === 'function') {
          existing = meta.if_null.call(this);
        } else {
          existing = meta.if_null;
        }
      }
      if (meta.convertFrom) {
        return meta.convertFrom(existing);
      }
      return existing;
    }
  };
  return property.property.apply(property, property_args).meta(meta);
};

D.attr.moment = function(serialized_name, meta) {
  if (meta == null) {
    meta = {};
  }
  meta.convertFrom = function(date) {
    if (date) {
      return moment(date);
    }
  };
  meta.convertTo = function(moment) {
    if (moment) {
      return moment.toDate();
    }
  };
  return D.attr(serialized_name, meta);
};

D.attr.duration = function(serialized_name, meta) {
  var unit;
  if (meta == null) {
    meta = {};
  }
  unit = meta.unit || (meta.unit = 'seconds');
  meta.convertFrom = function(unit_value) {
    if (!(unit_value === void 0 || unit_value === null)) {
      return moment.duration(unit_value, unit);
    }
  };
  meta.convertTo = function(duration) {
    if (duration) {
      return duration.as(unit);
    }
  };
  return D.attr(serialized_name, meta);
};

D.attr.object = function(serialized_name, meta) {
  if (meta == null) {
    meta = {};
  }
  meta.convertFrom = function(json) {
    if (meta.optional) {
      json || (json = {});
    }
    return Em.ObjectProxy.create({
      content: json
    });
  };
  meta.convertTo = function(proxy) {
    return proxy.get('content');
  };
  return D.attr(serialized_name, meta);
};

D.attr.hasMany = function(model_name, meta) {
  var property;
  if (meta == null) {
    meta = {};
  }
  if (!model_name) {
    Em.assert("You must specify model_name for hasMany");
  }
  if (!meta.urlBinding) {
    Em.assert("You must specify urlBinding for hasMany");
  }
  return property = (function() {
    var parent_id, _base, _name;
    meta.query || (meta.query = {});
    if (parent_id = this.get('id')) {
      meta.foreign_key || (meta.foreign_key = "" + (Em.get(this.constructor, 'singular')) + "_id");
      (_base = meta.query)[_name = meta.foreign_key] || (_base[_name] = this.get('id'));
    }
    return D.RecordArrayRelation.create({
      parent: this,
      modelBinding: model_name,
      urlBinding: "parent." + meta.urlBinding,
      query: meta.query
    });
  }).property();
};

D.attr.belongsTo = function(serialized_name_to_model_name, meta) {
  var model_name, raw_type, serialized_name;
  if (meta == null) {
    meta = {};
  }
  if (!(serialized_name_to_model_name instanceof Object)) {
    Em.assert("You must specify attr_id: 'Assoc.Type' for belongsTo");
  }
  serialized_name = Em.keys(serialized_name_to_model_name)[0];
  model_name = serialized_name_to_model_name[serialized_name];
  meta.typeString = model_name;
  raw_type = null;
  meta.convertFrom = function(id) {
    if (!raw_type) {
      raw_type = meta.type = Em.get(model_name);
    }
    if (id) {
      return raw_type.find(id);
    }
  };
  meta.convertTo = function(model) {
    if (model) {
      return model.get('id');
    }
  };
  return D.attr(serialized_name, meta);
};
Em.onLoad("Ember.Application", function(app) {
  app.initializer({
    name: "store",
    initialize: function(container, app) {
      app.register('store:main', D.Store);
      app.set("defaultStore", container.lookup('store:main'));
      return D.set("defaultStore", container.lookup('store:main'));
    }
  });
  return app.initializer({
    name: "injectStore",
    initialize: function(container, app) {
      app.inject("controller", "store", "store:main");
      return app.inject("route", "store", "store:main");
    }
  });
});
D.Store = Em.Object.extend({
  _cache: {},
  ajax: function(options) {
    options.accepts || (options.accepts = "application/json");
    return $.ajax.apply(this, arguments);
  },
  find: function(type, id) {
    var record;
    Em.assert("Cannot find a record without an id", id || id === null);
    if (type.constructor === String) {
      type = this.container.lookup("model:" + type);
      Em.assert("Cannot find a record without a valid type", type instanceof D.Model);
      type = type.constructor;
    }
    if (record = this.findCached(type, id)) {
      return record;
    }
    record = this.load(type, {
      id: id
    }, null, true);
    record.reload();
    return record;
  },
  cache: function(type, object) {
    var existing, id, type_cache, _base;
    type_cache = (_base = this._cache)[type] || (_base[type] = {});
    if (!(id = object.get("id"))) {
      return;
    }
    if (existing = type_cache[id]) {
      if (existing === object) {
        return;
      }
      return type_cache[id].set('content', object);
    } else {
      return type_cache[id] = object;
    }
  },
  findCached: function(type, id) {
    var type_cache, _base;
    Em.assert("Cannot find " + type + " without an id", id || id === null);
    type_cache = (_base = this._cache)[type] || (_base[type] = {});
    return type_cache[id];
  },
  load: function(type, data, instance, just_id) {
    var cached, key, record, type_cache, value, _base, _ref;
    if (data.errors) {
      _ref = data.errors;
      for (key in _ref) {
        value = _ref[key];
        Em.warn("" + key + " " + (value.join("and")));
      }
    }
    if (data.id || data.id === null) {
      cached = this.findCached(type, data.id);
      if (just_id && cached) {
        return cached;
      }
      type_cache = (_base = this._cache)[type] || (_base[type] = {});
      record = instance || type.create();
      if (just_id) {
        record.set("id", data.id);
      } else {
        record.load(data);
      }
      return type_cache[data.id] = record;
    } else {
      return (instance || type.create()).load(data);
    }
  }
});

D.Store.reopenClass({
  alias: function(method) {
    return function() {
      var args, store;
      store = Em.get(D, "defaultStore");
      args = [].slice.call(arguments);
      return store[method].apply(store, args);
    };
  },
  aliasWithThis: function(method) {
    return function() {
      var args, store;
      store = Em.get(D, "defaultStore");
      args = [].slice.call(arguments);
      args.unshift(this);
      return store[method].apply(store, args);
    };
  }
});
D.Model = Em.Object.extend(Em.Evented, {
  link: null,
  linkChange: function() {
    var cachebust, connector, link;
    link = this.get('link');
    cachebust = "_cacheBust=" + (new Date().getTime());
    if (link.indexOf('_cacheBust') === -1) {
      if (link.indexOf('?' === -1)) {
        connector = '?';
      } else {
        connector = '&';
      }
      link = "" + link + connector + cachebust;
    } else {
      link = link.replace(/([\?&])_cacheBust=\d+/, "$1" + cachebust);
    }
    return this.set('link', link);
  },
  linkDidChange: (function() {
    if (!this.get("isLoaded")) {
      return this.reload();
    }
  }).observes("link"),
  _data: (function() {
    return Em.Object.create();
  }).property(),
  toString: function() {
    return "" + this.constructor + "(" + (this.get('id')) + ")";
  },
  id: D.attr('id', {
    readonly: true
  }),
  created: D.attr.moment('created_at', {
    readonly: true,
    optional: true
  }),
  updated: D.attr.moment('updated_at', {
    readonly: true,
    optional: true
  }),
  errors: D.attr('errors', {
    readonly: true,
    optional: true
  }),
  links: D.attr.object('links', {
    readonly: true,
    optional: true
  }),
  idDidChange: (function() {
    return this.constructor.cache(this);
  }).observes("id"),
  url: D.attr('url', {
    readonly: true,
    extra_keys: ['id', 'link'],
    if_null: function() {
      var id, link;
      if (!(link = this.get("link"))) {
        return false;
      }
      if (!(id = this.get("id") || id === null)) {
        return link;
      }
      return "" + link + "/" + id;
    }
  }),
  then: function(ok, er) {
    if (this.get('isLoaded')) {
      return ok(this);
    }
    this.one('load', ok);
    if (!this.get('isLoading')) {
      return this.reload();
    }
  },
  toJson: function() {
    var props,
      _this = this;
    props = {};
    this.constructor.eachComputedProperty(function(name, meta) {
      var serialized_name, value;
      if (meta.readonly) {
        return;
      }
      if (serialized_name = meta.serialized_name) {
        value = _this.get(name);
        if (meta.convertTo) {
          value = meta.convertTo(value);
        }
        if (value !== void 0) {
          return props[serialized_name] = value;
        }
      }
    });
    return props;
  },
  isDeleted: false,
  isLoading: false,
  isLoaded: false,
  isNew: (function() {
    return this.get('id') === void 0;
  }).property('id'),
  isDirty: (function(_, set) {
    if (set !== void 0) {
      return set;
    }
    if (this.get("id")) {
      return false;
    }
    return true;
  }).property("id"),
  ajax: function() {
    return this.constructor.ajax.apply(this, arguments);
  },
  load: function(data) {
    var key, value, _ref;
    if (typeof data === 'function') {
      return this.one('load', this, data);
    }
    Em.assert("Load with no data?", typeof data === 'object');
    if (data.errors) {
      _ref = data.errors;
      for (key in _ref) {
        value = _ref[key];
        Em.warn("" + (this.get('url')) + " - " + key + " " + (value.join("and")));
      }
    }
    if (this.constructor._needsBeforeLoad) {
      this.constructor._beforeLoad(data);
    }
    this.set("_data", Em.Object.create(data));
    this.set("isDirty", false);
    this.set("isLoaded", true);
    this.set("isLoading", false);
    this.trigger('load', this);
    return this;
  },
  cancel: function() {
    return this.reload();
  },
  reload: function() {
    var id, url,
      _this = this;
    id = this.get("id");
    if (id === void 0) {
      return this;
    }
    if (!(url = this.get("url"))) {
      return this;
    }
    this.set("isLoaded", false);
    this.set("isLoading", true);
    this.ajax({
      url: url,
      cache: false,
      success: function(ok) {
        return _this.constructor.fromJson(ok, _this);
      },
      error: function(err) {
        debugger;
      }
    });
    return this;
  },
  "delete": function() {
    var _this = this;
    if (this.get("id")) {
      this.ajax(this.get("url"), {
        method: 'delete',
        success: function(rsp) {
          return _this.linkChange();
        }
      });
    }
    this.set('isDeleted', true);
    return this.set('_data', null);
  },
  save: function(ok) {
    var _this = this;
    if (ok) {
      this.load(ok);
    }
    return new Em.RSVP.Promise(function(ok, er) {
      var data, method, url;
      if (!_this.get("link")) {
        console.log("deferring");
        return _this.addObserver("link", _this, function() {
          return this.save().then(ok, er);
        });
      } else {
        console.log("saving");
        Em.assert("Cannot save without a link or url", url = _this.get("url"));
        method = _this.get("id") ? "put" : "post";
        data = {};
        data[Em.get(_this.constructor, 'singular')] = _this.toJson();
        if (!_this.get('isDirty')) {
          return ok();
        }
        return _this.ajax({
          method: method,
          contentType: "application/json; charset=utf-8",
          dataType: "json",
          processData: false,
          url: url,
          data: JSON.stringify(data),
          success: function(rsp) {
            _this.load(rsp[Em.get(_this.constructor, "singular")]);
            _this.linkChange();
            return ok();
          },
          error: function(rsp) {
            return er(rsp);
          }
        });
      }
    });
  }
});

D.Model.reopenClass({
  find: D.Store.aliasWithThis('find'),
  cache: D.Store.aliasWithThis('cache'),
  load: D.Store.aliasWithThis('load'),
  ajax: D.Store.alias('ajax'),
  _beforeLoad: function(data) {
    var attributes, has_serialized_keys, property_keys, serialized_keys, shown_data,
      _this = this;
    this._needsBeforeLoad = false;
    attributes = this.attributes();
    has_serialized_keys = {};
    serialized_keys = Em.keys(data);
    property_keys = Em.keys(attributes);
    shown_data = false;
    $.each(property_keys, function(_, property_key) {
      var optional, serialized_name;
      serialized_name = attributes[property_key].serialized_name;
      optional = attributes[property_key].optional;
      has_serialized_keys[serialized_name] = attributes[property_key];
      if (data[serialized_name] === void 0 && !optional) {
        if (!shown_data) {
          shown_data = true;
          Em.warn("" + _this + ": potential issues with model attributes after receiving " + serialized_keys);
        }
        return Em.warn("" + _this + " has extranious attr mapping for: " + serialized_name + " on property " + property_key);
      }
    });
    return $.each(serialized_keys, function(_, serialized_key) {
      if (has_serialized_keys[serialized_key] === void 0) {
        return Em.warn("" + _this + " is missing attr mapping for: " + serialized_key);
      }
    });
  },
  _needsBeforeLoad: true,
  attributes: function() {
    var attributes,
      _this = this;
    attributes = {};
    this.eachComputedProperty(function(name, meta) {
      var serialized_name;
      if (serialized_name = meta.serialized_name) {
        return attributes[name] = meta;
      }
    });
    return attributes;
  },
  singular: (function() {
    return this.toString().split(".").pop().underscore();
  }).property(),
  plural: (function() {
    return Em.assert("Please define a plural plural: 'plural' for " + this.constructor);
  }).property("singular"),
  fromJson: function(data, instance) {
    var plural, singular,
      _this = this;
    singular = Em.get(this, "singular");
    if (data[singular]) {
      return this.load(data[singular], instance);
    }
    Em.assert("Cannot load into an instance without the singular: " + singular, !instance);
    plural = Em.get(this, "plural");
    Em.assert("Cannot load without singular: " + singular + " or plural: " + plural, data[plural]);
    return data[plural].map(function(data) {
      return _this.load(data);
    });
  },
  create: function(config) {
    return this._super().setProperties(config);
  }
});
D.RecordArray = Em.ArrayProxy.extend(Em.Evented, {
  ajax: D.Store.alias('ajax'),
  url: null,
  query: null,
  _model: (function() {
    var model;
    model = this.get('model');
    return model.create();
  }).property(),
  model: null,
  isLoaded: false,
  isLoading: false,
  extractMeta: function(rsp) {
    return null;
  },
  success: function(ok) {
    var model;
    Em.assert("You must specify a model or a success converter", model = this.get('model'));
    return model.fromJson(ok);
  },
  error: function(err, url, query) {
    debugger;
  },
  content: (function(_, set) {
    if (!this._inited) {
      this._init();
    }
    if (set !== void 0) {
      return set;
    }
    this.urlOrQueryDidChange();
    return [];
  }).property(),
  _init: function() {
    this._inited = true;
    this._setupContent();
    return this._setupArrangedContent();
  },
  init: function() {
    return this._inited = false;
  },
  load: function(fn) {
    if (this.get("isLoaded")) {
      return fn.apply(this);
    }
    this.urlOrQueryDidChange();
    return this.one("load", this, fn);
  },
  reload: function(overrides) {
    if (overrides == null) {
      overrides = {};
    }
    return this.set("query", $.extend({}, this.get("query"), overrides));
  },
  urlOrQueryDidChange: (function(_, change_key) {
    var query, url,
      _this = this;
    if (!this._inited) {
      return;
    }
    if (!this.get("_model.link")) {
      return;
    }
    if (!(url = this.get("url"))) {
      return;
    }
    if (!change_key && this.get('isLoading')) {
      return;
    }
    query = this.get("query");
    this.set("isLoaded", false);
    this.set("isLoading", true);
    console.log("" + this + "::" + (this.get('model').toString()) + ".loading(" + change_key + ":" + (change_key ? this.get(change_key) : void 0) + ")", query);
    return this.ajax({
      method: "get",
      url: url,
      data: query
    }).success(function(ok) {
      if (_this.isDestroyed) {
        return;
      }
      _this.extractMeta(ok);
      _this.set("content", _this.success(ok));
      _this.set("isLoaded", true);
      _this.set("isLoading", false);
      return _this.trigger("load", _this);
    }).error(function(err) {
      return _this.error(err, url, query);
    });
  }).observes("query", "url", "_model.link")
});
D.RecordArrayPaged = D.RecordArray.extend({
  page: (function(_, set) {
    if (set !== void 0) {
      this.reload({
        page: set
      });
      return set;
    } else {
      return this.get("query.page") || 1;
    }
  }).property("query.page"),
  totalRecords: null,
  totalPages: null,
  perPage: null,
  nextPageUrl: null,
  previousPageUrl: null,
  hasNextPageBinding: "nextPageUrl",
  hasPreviousPageBinding: "previousPageUrl",
  nextPage: function() {
    return this.set("url", this.get("nextPageUrl"));
  },
  previousPage: function() {
    return this.set("url", this.get("previousPageUrl"));
  },
  extractMeta: function(rsp) {
    return this.setProperties({
      perPage: rsp.meta.per_page,
      totalRecords: rsp.meta.total_records,
      totalPages: rsp.meta.total_pages,
      nextPageUrl: rsp.links.next_page,
      previousPageUrl: rsp.links.previous_page
    });
  }
});
D.RecordArrayRelation = D.RecordArray.extend({
  _parent: null,
  parent: null,
  init: function() {
    return this._super.apply(this, arguments);
  },
  where: function(opts) {
    var new_query, query;
    if (opts == null) {
      opts = {};
    }
    query = this.get('query');
    new_query = $.extend(query, opts);
    return D.RecordArrayRelation.create({
      _parent: this,
      urlBinding: '_parent.url',
      modelBinding: '_parent.model',
      query: new_query
    });
  },
  nextNew: (function(_, set) {
    return this.create();
  }).property(),
  nextNewIsntNew: (function() {
    if (this.get('nextNew.id')) {
      return this.set('nextNew');
    }
  }).observes('nextNew.id'),
  create: function(opts) {
    var model, query;
    if (opts == null) {
      opts = {};
    }
    model = this.get('model');
    query = this.get('query');
    return model.create($.extend(query, opts));
  }
});
