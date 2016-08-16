var _ = require('lodash');
var moment = require('moment');



module.exports = function(app, express, router, auth, firebase, notifier){

    router.get('/signals', function(req, res) {
      res.json({ message: 'signals api' });
    });

    router.post('/signals', auth, function(req, res) {
    
      //console.log(req.body.arr[0]); //array
      
      var id = req.body.id;
      var name = req.body.name;
      var currency = req.body.currency;
      var description = req.body.description;
      var stoploss = req.body.stoploss;
      var takeprofit = req.body.takeprofit;
      var signalId = req.body.signalId;
      var status = req.body.status;
      var price = req.body.price;
      var timestamp = moment().valueOf();

      var signal = {
                      id: id,
                      signalId: signalId,
                      name: name,
                      currency: currency,
                      description: description,
                      stoploss: stoploss,
                      takeprofit: takeprofit,
                      status: status,
                      price: price,
                      timestamp: timestamp
                    };

      /*var signal = {};
      signal[id] = {    
                      signal: sig,
                      currency: currency,
                      description: description,
                      stoploss: stoploss,
                      takeprofit: takeprofit,
                      timestamp: timestamp
                   };*/

      //notifier.send(signal);

      var db = firebase.database();
      var ref = db.ref("signals");
      ref.push().set(signal);
      res.json(signal);
    });

    router.post('/signal/:id', auth, function(req, res) {
      var id = req.params.id;
      var db = firebase.database();
      var ref = db.ref("signals");
      ref.orderByChild("id").equalTo(id).limitToFirst(1).on("child_added", function(snapshot){
          var signalRef = ref.child(snapshot.key);
          signalRef.update({
              status: "updated"
          });
      });
      res.json({ id: id });
    });

    router.get('/beats', function(req, res) {
        
        res.json({ message: 'beats api' });
        
    });   
}