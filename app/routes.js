module.exports = function(router) {
    'use strict';
    
    router.get('/signal', function(req, res) {
	    res.json({ message: 'Sending a signal via notification...' });   
	});

    return router;
}