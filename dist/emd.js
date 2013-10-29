this.EMD = Em.Namespace.create({
  VERSION: '0.1.0'
});
EMD.attr = function(serialized_name, meta) {
  var key, property, property_args;
  if (meta == null) {
    meta = {};
  }
  Em.assert("You must specify a serialized name", meta.serialized_name = serialized_name);
  key = "_data." + serialized_name;
  if (meta.convertTo) {
    Em.deprecate("EMD.attr, use convertToData instead of convertTo");
    meta.convertToData = meta.convertTo;
    delete meta.convertTo;
  }
  if (meta.convertFrom) {
    Em.deprecate("EMD.attr, use convertFromData instead of convertFrom");
    meta.convertFromData = meta.convertFrom;
    delete meta.convertFrom;
  }
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
        this.set(key, meta.convertToData(set));
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
      if (meta.convertFromData) {
        return meta.convertFromData(existing);
      }
      return existing;
    }
  };
  return property.property.apply(property, property_args).meta(meta);
};
EMD.attr.belongsTo = function(serialized_name_to_model_name, meta) {
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
  meta.convertFromData = function(id) {
    if (!raw_type) {
      raw_type = meta.type = Em.get(model_name);
    }
    if (id) {
      return raw_type.find(id);
    }
  };
  meta.convertToData = function(model) {
    if (model) {
      return model.get('id');
    }
  };
  return EMD.attr(serialized_name, meta);
};
EMD.attr.hasMany = function(model_name, meta) {
  var parent_name, query, type;
  if (meta == null) {
    meta = {};
  }
  if (!model_name) {
    Em.assert("You must specify model_name for hasMany");
  }
  type = false;
  query = false;
  parent_name = false;
  return (function() {
    var belongs_to;
    if (!type) {
      type = Em.get(model_name);
      if (!parent_name) {
        parent_name = Em.get(this.constructor, 'singular');
      }
      belongs_to = type.attributes()[parent_name];
      query = {};
      query[belongs_to.serialized_name] = this.get('id');
    }
    return EMD.RecordArrayRelation.create({
      parent: this,
      modelBinding: model_name,
      urlBinding: "parent." + meta.urlBinding,
      query: query
    });
  }).property();
};
EMD.attr.moment = function(serialized_name, meta) {
  if (meta == null) {
    meta = {};
  }
  meta.convertFromData = function(date) {
    if (date) {
      return moment(date);
    }
  };
  meta.convertToData = function(moment) {
    if (moment) {
      return moment.toDate();
    }
  };
  return EMD.attr(serialized_name, meta);
};

EMD.attr.duration = function(serialized_name, meta) {
  var unit;
  if (meta == null) {
    meta = {};
  }
  unit = meta.unit || (meta.unit = 'seconds');
  meta.convertFromData = function(unit_value) {
    if (!(unit_value === void 0 || unit_value === null)) {
      return moment.duration(unit_value, unit);
    }
  };
  meta.convertToData = function(duration) {
    if (duration) {
      return duration.as(unit);
    }
  };
  return EMD.attr(serialized_name, meta);
};
EMD.attr.object = function(serialized_name, meta) {
  if (meta == null) {
    meta = {};
  }
  meta.convertFromData = function(json) {
    if (meta.optional) {
      json || (json = {});
    }
    return Em.ObjectProxy.create({
      content: json
    });
  };
  meta.convertToData = function(proxy) {
    return proxy.get('content');
  };
  return EMD.attr(serialized_name, meta);
};
Em.onLoad("Ember.Application", function(app) {
  app.initializer({
    name: "store",
    initialize: function(container, app) {
      app.register('store:main', EMD.Store);
      app.set("defaultStore", container.lookup('store:main'));
      return EMD.set("defaultStore", container.lookup('store:main'));
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
EMD.Store = Em.Object.extend({
  _cache: {},
  ajax: function(options) {
    var _base;
    options.headers || (options.headers = {});
    (_base = options.headers).Accept || (_base.Accept = "application/json");
    return $.ajax.apply(this, arguments);
  },
  find: function(type, id) {
    var record;
    Em.assert("Cannot find a record without an id", id || id === null);
    if (type.constructor === String) {
      type = this.container.lookup("model:" + type);
      Em.assert("Cannot find a record without a valid type", type instanceof EMD.Model);
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

EMD.Store.reopenClass({
  alias: function(method) {
    return function() {
      var args, store;
      store = Em.get(EMD, "defaultStore");
      args = [].slice.call(arguments);
      return store[method].apply(store, args);
    };
  },
  aliasWithThis: function(method) {
    return function() {
      var args, store;
      store = Em.get(EMD, "defaultStore");
      args = [].slice.call(arguments);
      args.unshift(this);
      return store[method].apply(store, args);
    };
  }
});
EMD.Model = Em.Object.extend(Em.Evented, {
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
  url: EMD.attr('url', {
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
  id: EMD.attr('id', {
    readonly: true
  }),
  idDidChange: (function() {
    return this.constructor.cache(this);
  }).observes("id"),
  then: function(ok, er) {
    if (this.get('isLoaded')) {
      return ok(this);
    }
    if (!this.get('id')) {
      return ok(this);
    }
    this.one('load', ok);
    return this.reload();
  },
  toString: function() {
    return "" + this.constructor + "(" + (this.get('id')) + ")";
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
        if (meta.convertToData) {
          value = meta.convertToData(value);
        }
        if (value !== void 0) {
          return props[serialized_name] = value;
        }
      }
    });
    return props;
  },
  _data: (function() {
    return Em.Object.create();
  }).property(),
  ajax: function() {
    return this.constructor.ajax.apply(this, arguments);
  },
  load: function(data) {
    var key, value, _ref;
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
    return this.ajax({
      url: url,
      cache: false,
      success: function(ok) {
        return _this.constructor.fromJson(ok, _this);
      },
      error: function(err) {
        debugger;
      }
    });
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
  created: EMD.attr.moment('created_at', {
    readonly: true,
    optional: true
  }),
  updated: EMD.attr.moment('updated_at', {
    readonly: true,
    optional: true
  }),
  errors: EMD.attr('errors', {
    readonly: true,
    optional: true
  }),
  links: EMD.attr.object('links', {
    readonly: true,
    optional: true
  })
});

EMD.Model.reopenClass({
  find: EMD.Store.aliasWithThis('find'),
  cache: EMD.Store.aliasWithThis('cache'),
  load: EMD.Store.aliasWithThis('load'),
  ajax: EMD.Store.alias('ajax'),
  extend: function() {
    var args;
    args = Array.prototype.slice.call(arguments);
    args = $.map(args, function(arg) {
      if (arg instanceof Function) {
        return arg();
      }
      return arg;
    });
    return this._super.apply(this, args);
  },
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
    var _this = this;
    if (this._attributes) {
      return this._attributes;
    }
    this._attributes = {};
    this.eachComputedProperty(function(name, meta) {
      var serialized_name;
      if (serialized_name = meta.serialized_name) {
        return _this._attributes[name] = meta;
      }
    });
    return this._attributes;
  },
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
  },
  singular: (function() {
    return this.toString().split(".").pop().underscore();
  }).property(),
  pluralizer: (function() {
    if (inflect !== void 0) {
      return function(model) {
        var name;
        name = model.toString().split('.').pop().underscore();
        return inflect.pluralize(name);
      };
    }
  }).property(),
  plural: (function() {
    var pluralize;
    if (pluralize = Em.get(this, "pluralizer")) {
      return pluralize(this);
    }
    return Em.assert("Please define a plural plural: 'plural' for " + this.constructor + " or register a pluralizer with EMD.Model.set('pluralizer', ((model)->'models')");
  }).property("singular")
});
EMD.RecordArray = Em.ArrayProxy.extend(Em.Evented, {
  ajax: EMD.Store.alias('ajax'),
  url: null,
  query: null,
  _model: (function() {
    var model;
    model = this.get('model');
    return model.create();
  }).property(),
  model: null,
  isLoaded: (function(_, set) {
    if (set !== void 0) {
      return set;
    }
    this._init();
    return false;
  }).property(),
  isLoading: (function(_, set) {
    if (set !== void 0) {
      return set;
    }
    this._init();
    return false;
  }).property(),
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
    if (set !== void 0) {
      return set;
    }
    this._init();
    return [];
  }).property(),
  _init: function() {
    if (this._inited) {
      return;
    }
    this._inited = true;
    this._setupContent();
    this._setupArrangedContent();
    if (!this._initial_content_load) {
      this._initial_content_load = true;
      return this.urlOrQueryDidChange();
    }
  },
  init: function() {
    this._inited = false;
    return this._initial_content_load = false;
  },
  load: function(fn) {
    if (this.get("isLoaded")) {
      return fn.apply(this);
    }
    this.urlOrQueryDidChange();
    this.one("load", this, fn);
    return this;
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
EMD.RecordArrayPaged = EMD.RecordArray.extend({
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
EMD.RecordArrayRelation = EMD.RecordArray.extend({
  _parent: null,
  parent: null,
  where: function(opts) {
    var new_query, query;
    if (opts == null) {
      opts = {};
    }
    query = this.get('query');
    new_query = $.extend(query, opts);
    return EMD.RecordArrayRelation.create({
      _parent: this,
      urlBinding: '_parent.url',
      modelBinding: '_parent.model',
      query: new_query
    });
  },
  nextNew: (function(_, set) {
    return this.create();
  }).property(),
  then: function(ok, er) {
    if (ok) {
      this.one('load', ok);
    }
    if (er) {
      this.one('error', er);
    }
    this.get('content');
    return this;
  },
  nextNewIsntNew: (function() {
    if (this.get('nextNew.id')) {
      return this.set('nextNew');
    }
  }).observes('nextNew.id')
});
