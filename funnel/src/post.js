var http = require("http");
var https = require("https");

var endpoint = process.env.ENDPOINT;

module.exports = function(body, callback) {
  var protocol = endpoint.toLowerCase().indexOf("https") === 0 ? https : http;
  var requestParams = {
    host: endpoint,
    method: "POST",
    path: "/_bulk",
    body: body,
    headers: {
      'Content-Type': 'application/json',
      'Host': endpoint,
      'Content-Length': Buffer.byteLength(body)
    }
  };

  var request = protocol.request(requestParams, function(response) {
      var statusCode = response.statusCode;
      var responseBody = "";

      response.on("data", function(chunk) {
        responseBody += chunk;
      });

      response.on("end", function() {
        var failedItems, success;
        var info = {items: []};
        var error = null;

        try {
          if (responseBody !== "") {
            info = JSON.parse(responseBody);
          }
        } catch (ex) {
          callback("Error parsing response: " + responseBody);
          return;
        }

        if (statusCode >= 200 && statusCode < 299) {
          failedItems = info.items.filter(function(x) {
            return x.status >= 300;
          });

          success = {
            "attemptedItems": info.items.length,
            "successfulItems": info.items.length - failedItems.length,
            "failedItems": failedItems.length
          };
        }

        if (statusCode !== 200 || info.errors === true) {
          error = {
            "statusCode": statusCode,
            "responseBody": responseBody
          };
        }

        callback(error, success, statusCode, failedItems);
      });
  }).on("error", function(e) {
      callback(e);
  });

  request.end(requestParams.body);
}
