var __quirk = { 

  extend: function (obj, superclass) {
    obj.prototype = Object.create(superclass.prototype);
    return obj;
  },

  addMeta: function (target, meta) {
    target.__quirk_meta = meta
  }

};

// Standard library implememntations.
var Reflect = {

  getType: function getType(cls) {
    // todo: check instances
    return cls.__name;
  },

  is: function is(a, b) {

  },

  getSuperclass: function getSuperclass(target) {
    return target.__super || target.prototype.__super;
  },

  getMethod: function getMethod(obj, name) {
    return obj[name];
  }

  getMethodNames: function getMethodNames(cls) {
    // todo: check if this is an instance or a class
    return Object.keys(cls);
  },

  getField: function getField(obj, name) {
    return obj[name];
  },

  getMetadata: function getMetadata(target, name) {
    if (target.__quirk_meta === null) return null;
    var data = target.__quirk_meta[name];
    if (data === null) {
      var sup = this.getSuperclass(target);
      if (sup === null) return null;
      return this.getMetadata(sup, name);
    }
    return data;
  }

};


module.exports = {
  __quirk : quirk,
  Reflect: Reflect
};
