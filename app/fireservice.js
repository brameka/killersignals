var firebase = require("firebase");

module.exports = function(){

  firebase.initializeApp({
    databaseURL: "https://killjoy-fa82b.firebaseio.com",
    serviceAccount: "./auth/Killjoy-14f8d081e9fd.json",
    databaseAuthVariableOverride: {
      uid: "killjoyapi"
    }
  });

  var save = function(signal){
      var db = firebase.database();
      var ref = db.ref("signals");
      ref.push().set(signal);
  }

  var update = function(id, payload){
     var db = firebase.database();
     var ref = db.ref("/signals");

     ref.orderByChild("id").equalTo(id).once("value", function(snapshot) {
        snapshot.forEach(function(data) {
            var dbs = firebase.database();
            var refs = dbs.ref("/signals/" + data.key());
            refs.update();
        });
    });


     //ref.update(payload);
  }

  return {
    save: save,
    update: update
  }
}