;(function (global) {

  var Environment = function Environment () {
    this.modules = {};
  };

  Environment.prototype.define(name, deps, factory) {
    var mod = new Module(this, deps);
    this.modules[name] = mod;
    mod.define(factory);
    return mod;
  };

  Environment.prototype.loadModules = function (deps, next) {
    var progress = deps.length;
    if (!next) {
      next = function () {};
    }
    // Keep running till progress == 0
    var onReady = function (err) {
      if (err) {
        next(err);
        return;
      }
      progress -= 1;
      if (progress <= 0) {
        next(null);
      }
    };
    var onFailed = function (err) {
      next(err);
    };
    deps.forEach(function (dep) {
      var mod = this.modules[dep];
      if (mod) {
        mod.onReady(onReady);
        mod.enable();
      } else {
        onReady(new Error('No module found for ' + dep));
      }
    });
  };

  var MODULE_STATES = {
    DISABLED: -1,
    PENDING: 0,
    ENABLING: 1,
    READY: 2
  }

  var Module = function Module(env, deps) {
    this.env = env;
    this.deps = deps;
    this.state = MODULE_STATES.PENDING;
    this.exports = {};
    this.onReadyListeners = [];
    this.onFailedListeners = [];
  };

  Module.prototype.require = function (dep) {
    return this.env.modules[dep].exports;
  };

  Module.prototype.define = function (factory) {
    this.factory = function () { 
      factory(this.require.bind(this), this);
    };
    return this;
  }

  Module.prototype.onReady = function (cb) {
    if (this.state === MODULE_STATES.READY) {
      cb();
      if (this.onReadyListeners.length > 0) {
        this.dispatchListeners(this.onReadyListeners)
      }
      return this;
    }
    this.onReadyListeners.push(cb);
    return this;
  };

  Module.prototype.onFailed = function (cb) {
    if (this.state === MODULE_STATES.DISABLED) {
      cb();
      if (this.onFailedListeners.length > 0) {
        this.dispatchListeners(this.onFailedListeners)
      }
      return this;
    }
    this.onFailedListeners.push(cb);
    return this;
  };

  Module.prototype.dispatchListeners = function (listeners) {
    var cb;
    while (cb = listeners.pop()) {
      cb();
    }
    return this;
  };

  Module.prototype.enable = function () {
    if (this.state !== MODULE_STATES.PENDING) {
      return this;
    }
    this.state = MODULE_STATES.ENABLING;
    if (this.deps.length === 0) {
      this.factory();
      this.state = MODULE_STATES.READY;
      this.dispatchListeners(this.onReadyListeners);
    } else {
      this.env.loadModules(this.deps, function (err) {
        if (err != null) {
          this.state = MODULE_STATES.DISABLED;
          this.dispatchListeners(this.onFailedListeners);
          return;
        }
        this.factory();
        this.state = MODULE_STATES.READY;
        this.dispatchListeners(this.onReadyListeners);
      }.bind(this));
    }
  };

  global.__quirk_env = new Environment();
  global.__quirk_init = function (main) {
    __quirk_env.loadModules([ main ], function (err) {
      if (err != null) {
        console.error(err);
      }
    });
  };

})(window != null ? window : global);
