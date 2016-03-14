require("dotenv-safe").load({ sample: "./.env.requirements" });

var https = require('https');
var zlib = require('zlib');

var endpoint = process.env.ENDPOINT;
var handlers = {
  "awslogs": require("./awslogs"),
  "kinesis": require("./kinesis")
};

exports.handler = function(input, context) {
  var keys = Object.keys(input);
  keys.forEach(function(key) {
    var handler = handlers[key];
    var value = input[key];

    if (typeof(handler) === "function") {
      handler(value, function(error, bulk) {
        if (err) {
          context.fail(error);
          return;
        }

        if (!bulk.length) {
          context.succeed('Control message handled successfully');
          return;
        }

        var bulkData = bulk.join("\n") + "\n";
        post(elasticsearchBulkData, function(error, success, statusCode, failedItems) {
          console.log("Response: " + JSON.stringify({
            "statusCode": statusCode
          }));

          if (error) {
            console.log("Error: " + JSON.stringify(error, null, 2));

            if (failedItems && failedItems.length > 0) {
              console.log("Failed Items: " +
                JSON.stringify(failedItems, null, 2));
            }

            context.fail(JSON.stringify(error));
          } else {
            console.log("Success: " + JSON.stringify(success));
            context.succeed("Success");
          }
        });
      });
    }
  });
};

function post(body, callback) {
  var requestParams = buildRequest(endpoint, body);

  var request = https.request(requestParams, function(response) {
      var responseBody = "";
      response.on("data", function(chunk) {
        responseBody += chunk;
      });
      response.on("end", function() {
        var info = JSON.parse(responseBody);
        var failedItems;
        var success;

        if (response.statusCode >= 200 && response.statusCode < 299) {
          failedItems = info.items.filter(function(x) {
              return x.index.status >= 300;
          });

          success = { 
            "attemptedItems": info.items.length,
            "successfulItems": info.items.length - failedItems.length,
            "failedItems": failedItems.length
          };
        }

        var error = response.statusCode !== 200 || info.errors === true ? {
          "statusCode": response.statusCode,
          "responseBody": responseBody
        } : null;

        callback(error, success, response.statusCode, failedItems);
      });
  }).on("error", function(e) {
      callback(e);
  });
  request.end(requestParams.body);
}
