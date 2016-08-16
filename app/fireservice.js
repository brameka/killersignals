var firebase = require("firebase");

module.exports = function(app){

  firebase.initializeApp({
    databaseURL: "https://killjoy-fa82b.firebaseio.com",
    serviceAccount: "../auth/Killjoy-14f8d081e9fd.json",
    databaseAuthVariableOverride: {
      uid: "killjoyapi"
    }
  });

  var save = function(signal){
      var db = firebase.database();
      var ref = db.ref("signals");
      ref.push().set(signal);
  }

  return {
    save: save
  }
}