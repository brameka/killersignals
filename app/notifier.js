var gcm = require('node-gcm');

module.exports = function(app){

  var send = function(signal){
    var message = new gcm.Message({
                priority: 'high',
                dryRun: true,
                data: {
                    key1: 'message1',
                    key2: 'message2'
                },
                notification: {
                  title: "Killjoy",
                  body: "Killer signals from Killjoy"
                }
              });

    //var sender = new gcm.Sender(<my Google Server Key>);
    var sender = new gcm.Sender("AIzaSyB3wY7DNJQq5-r96eIvif2wsi6e-fl2hEw");


    //todo get device tokens
    var registrationTokens = [];
    registrationTokens.push('regToken1');
    registrationTokens.push('regToken2');
    
    //send to registrationTokens:
    /*sender.send(message, { 
                  registrationTokens: registrationTokens 
                }, 10, function (err, response) {
      if(err) {
        console.error(err);
      } else {
        console.log(response);
      }
    });*/

    sender.send(message, { 
                  topic: "subscribers" 
                }, 10, function (err, response) {
                
                if(err) {
                    console.error(err);
                } else {
                    console.log(response);
                }
    });
  }

  return {
    send: send
  }
}