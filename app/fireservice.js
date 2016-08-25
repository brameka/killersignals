var firebase = require("firebase");

module.exports = function(){

  firebase.initializeApp({
    databaseURL: "https://killjoy-fa82b.firebaseio.com/",
    serviceAccount: "./auth/Killjoy-437faf4ebcd1.json",
    databaseAuthVariableOverride: {
      uid: "killjoy-api"
    }
  });

  var save = function(id, signal){
      firebase.database.enableLogging(true);
      var db = firebase.database();
      var ref = db.ref("/signals/" + id);
      ref.set(signal);
  }

  var save_result = function(result){
      var db = firebase.database();
      var ref = db.ref("/results");
      ref.push().set(result);
  }

  var update = function(id, payload){
     var db = firebase.database();
     var ref = db.ref("/signals/" + id);
     ref.update(payload);

     /*ref.orderByChild("id").equalTo(id).once("value", function(snapshot) {
        snapshot.forEach(function(data) {
            var dbs = firebase.database();
            var refs = dbs.ref("/signals/" + data.key());
            refs.update();
        });
    });*/


     //ref.update(payload);
  }

  return {
    save: save,
    update: update,
    save_result: save_result
  }
}