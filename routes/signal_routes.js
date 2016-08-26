var _ = require('lodash');
var moment = require('moment');
var fireservice = require('../app/fireservice')();

module.exports = function(app, express, router, notifier){

    router.get('/signals', function(req, res) {
      res.json({ message: 'signals api' });
    });

    router.post('/signals', function(req, res) {

      var id = req.body.id;
      var name = req.body.name;
      var currency = req.body.currency;
      var stoploss = req.body.stoploss;
      var takeprofit = req.body.takeprofit;
      var status = req.body.status;
      var price = req.body.price;
      var position = req.body.position;
      var timestamp = moment().valueOf();

      if(!id || !name || !currency || !stoploss || !takeprofit || !status || !price || !position || !timestamp){
          console.log("invalid signal");
          res.json("invalid signal");
      }

      var signal = {
                      name: name,
                      currency: currency,
                      position: position,
                      price: parseFloat(price,5),
                      stoploss: parseFloat(stoploss,5),
                      takeprofit: parseFloat(takeprofit,5),
                      status: status,
                      timestamp: timestamp
                    };

      fireservice.save(id, signal);
      notifier.notify(signal);
      res.json(signal);
    });

    router.post('/signal/:id', function(req, res) {
      var id = req.params.id;
      var status = req.body.status;
      var name = req.body.name;
      var value = req.body.value;
      var currency = req.body.currency;
      var timestamp = moment().valueOf();

      var data = {
                    status: status
                };

      var result = {
          id: id,
          status: status,
          name: name,
          value: value,
          currency: currency,
          timestamp: timestamp
      };
      
      fireservice.update(id, data);
      console.log(result);
      fireservice.save_result(result);
      

      /*ref.orderByChild("id").equalTo(id).once("value", function(snapshot) {
        snapshot.forEach(function(data) {
            var refer = ref.child(data.key());
            refer.update();
        });
      });*/

      res.json({ message: id });
    });
	
    router.get('/notify', function(req, res) {
        //notifier.notify();
        res.json({ message: 'notification api' });
    }); 
}