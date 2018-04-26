if (global.__quirk == null) {

  global.__quirk = { 

    classes: {},

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
      target.__quirk_meta = meta
    }

  };

}
