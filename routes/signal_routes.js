var _ = require('lodash');


module.exports = function(app, express, router, auth, firebase){

    // route to show a random message (GET http://localhost:8080/api/)
    router.get('/signals', function(req, res) {
      res.json({ message: 'signals api' });
    });

    router.post('/signals', auth, function(req, res) {
      //console.log(req.body.arr[0]); //array
      var sig = req.body.signal;
      var currency = req.body.currency;
      var description = req.body.description;
      var stoploss = req.body.stoploss;
      var takeprofit = req.body.takeprofit;

      var signal = {    signal: sig,
                        currency: currency,
                        description: description,
                        stoploss: stoploss,
                        takeprofit: takeprofit
                   };

      var db = firebase.database();
      var ref = db.ref("signals");
      ref.set(signal);

      res.json(signal);
    });

    // route to return all users (GET http://localhost:8080/api/users)
    router.get('/beats', function(req, res) {
        
        res.json({ message: 'beats api' });

        //console.log(req.body.arr[0]);
        /*var user_id = req.query.user_id;
        console.log("userid: " + user_id);
        var id = mongoose.Types.ObjectId(user_id);
        Snap.find({_id:id}).populate('user','name password').lean().exec(function(err, snaps){
            var results = _.map(snaps, function(snap){
                return {
                    id : snap._id,
                    user: snap.user,
                    caption:  snap.caption,
                    number:  snap.number
                }
            })
            res.json(results);
        });*/
    });   
}