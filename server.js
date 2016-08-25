// server.js

// BASE SETUP
// =============================================================================

// call the packages we need
var express    = require('express');        // call express
var app        = express();                 // define our app using express
var bodyParser = require('body-parser');
var basicAuth = require('basic-auth-connect');



// Initialize Firebase
/*var config = {
    apiKey: "AIzaSyCDcC8RdtDVLu09K4s2Aaa5ncwkv9CjE38",
    authDomain: "killjoy-fa82b.firebaseapp.com",
    databaseURL: "https://killjoy-fa82b.firebaseio.com",
    storageBucket: "killjoy-fa82b.appspot.com",
};
firebase.initializeApp(config);*/




//firebase xmpp fcm server
//fcm-xmpp.googleapis.com:5235 //LIVE
//fcm-xmpp.googleapis.com:5236 //DEV



/*var uid = "R9JIJZUgWHaTz27zN7vIs2xv27C2";
var additionalClaims = {
  premiumAccount: true
};
var token = firebase.auth().createCustomToken(uid, additionalClaims);*/



// configure app to use bodyParser()
// this will let us get the data from a POST
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
//var auth = basicAuth('sixsignals', 'roadtothef@stl@n3');

var port = process.env.PORT || 8080;        // set our port

// ROUTES FOR OUR API
// =============================================================================
var router = express.Router();              // get an instance of the express Router

var notifier = require("./app/notifier")(app);


var signal_routes = require("./routes/signal_routes")(app, express, router, notifier);

// test route to make sure everything is working (accessed at GET http://localhost:8080/api)
router.get('/', function(req, res) {
    res.json({ message: 'wicked signals api' });   
});


app.use('/api', router);

app.get('/', function(req, res) {
    res.send('Wicked signals are getting published at http://localhost:' + port + '/api');
});

// START THE SERVER
// =============================================================================
app.listen(port);
console.log('Magic happens on port ' + port);