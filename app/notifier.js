var gcm = require('node-gcm');
var querystring = require('querystring');
var http = require('http');
var fs = require('fs');
var request = require('request');

module.exports = function(app){

  var notify = function(signal){
    var notificationMessage = signal.position + " (" + signal.currency + ") " + signal.name;

    /*var requestOptions = {
        proxy: 'http://bronsonr:Ch0wch0w555@proxy.perthmint.com.au:8080',
        timeout: 5000
    };*/

    //var sender = new gcm.Sender("AIzaSyB3wY7DNJQq5-r96eIvif2wsi6e-fl2hEw", requestOptions);
    var sender = new gcm.Sender("AIzaSyB3wY7DNJQq5-r96eIvif2wsi6e-fl2hEw");

    var message = new gcm.Message({
        data: { key1: 'msg1' },
        priority: 'high',
        notification: {
            title: "Killjoy Signal",
            body: notificationMessage
        }
    });

    
    var registrationTokens = [];
    registrationTokens.push('c3AIG-9KzUQ:APA91bFVFuvv-eK72Ce3J3Nj1ONSwiFUs09DNsopXpwCAxdgvcpRpey4onZ_DUeKNxmT3aNv6Xt93h_l_6Vt9KkDd4Pref2VXf4O1gEwferg7XI67_3lg9OG8UWcoAl8df-BJA6wCcG2');
    
    sender.send(message, { registrationTokens: registrationTokens }, 10, function (err, response) {
      if(err) console.error(err);
      else    console.log(response);
    });

  }

  return {
    notify: notify
  }
}