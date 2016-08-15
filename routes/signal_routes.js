var _ = require('lodash');

module.exports = function(app, express, router){

    // route to show a random message (GET http://localhost:8080/api/)
    router.get('/signals', function(req, res) {
      res.json({ message: 'signals api' });
    });

    // route to return all users (GET http://localhost:8080/api/users)
    router.get('/beats', function(req, res) {
        res.json({ message: 'beats api' });
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