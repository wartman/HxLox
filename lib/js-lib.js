var __quirk_classes = [];

var quirk = { 

  extend: function (obj, superclass) {
    obj.prototype = Object.create(superclass.prototype);
    return obj;
  },

  addClass: function (name, cls) {
    __quirk_classes[name] = cls;
  },

  getClass: function (name) {
    return __quirk_classes[name];
  },

  addMeta: function (target, meta) {
    target.__quirk_meta = meta
  }

};

// Standard library implememntations.
var Reflect = {

  getType: function getType(cls) {
    return __quirk_toStr.call(cls).slice(8, -1);
  },

  is: function is(a, b) {

  },

  getSuperclass: function getSuperclass(target) {
    return target.__super || target.prototype.__super;
  },

  getMethod: function getMethod(obj, name) {
    return obj[name];
  },

  getMethodNames: function getMethodNames(cls) {
    // todo: check if this is an instance or a class
    return Object.keys(cls);
  },

  getField: function getField(obj, name) {
    return obj[name];
  },

  getMetadata: function getMetadata(target, name) {
    if (target.__quirk_meta === null) {
      var sup = this.getSuperclass(target);
      if (sup == null) return null;
      return this.getMetadata(sup, name);
    }
    var data = target.__quirk_meta[name];
    if (data === null) {
      var sup = this.getSuperclass(target);
      if (sup === null) return null;
      return this.getMetadata(sup, name);
    }
    return data;
  }

};

var System = {

  print: function (s) {
    console.log(s);
  },

  println: function(s) {
    this.print(s + '\n');
  },

  getCwd: function () {
    throw new Error('Not available on JS target');
  }

};

module.exports = {
  __quirk : quirk,
  Reflect: Reflect,
  System: System
};
