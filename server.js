// server.js

// BASE SETUP
// =============================================================================

// call the packages we need
var express    = require('express');        // call express
var app        = express();                 // define our app using express
var bodyParser = require('body-parser');


// configure app to use bodyParser()
// this will let us get the data from a POST
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

var port = process.env.PORT || 8080;        // set our port

// ROUTES FOR OUR API
// =============================================================================
var router = express.Router();              // get an instance of the express Router
var signal_routes = require("./routes/signal_routes")(app, express, router);

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