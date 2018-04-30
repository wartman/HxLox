if (global.__quirk == null) {

  global.__quirk = { 

    classes: {},
    meta: {},

    extend: function (obj, superclass) {
      obj.prototype = Object.create(superclass.prototype);
      return obj;
    },

    addClass: function (name, cls) {
      this.classes[name] = cls;
    },

    getClass: function (name) {
      return this.classes[name];
    },

    addMeta: function (target, meta) {
      this.meta[target.__name] = meta;
    }

  };

}
