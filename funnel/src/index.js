require("dotenv-safe").load({ sample: "./.env.requirements" });

var post = require("./post");

var processors = {
  "awslogs": require("./awslogs"),
  "Records": require("./kinesis")
};

exports.handler = function(input, context) {
  var keys = Object.keys(input)
  var procKeys = keys.filter(supportedProcessors);

  if (procKeys.length === 0) {
    context.fail("No supported processes found: ", keys);
    return
  }

  procKeys.forEach(function(key) {
    var processor = processors[key];
    var value = input[key];

    processor(value, function(error, bulk) {
      if (error) {
        context.fail(error);
        return;
      }

      if (!bulk.length) {
        context.succeed('Control message handled successfully');
        return;
      }

      console.log("Sending", bulk.length / 2, "records");

      var bulkData = bulk.join("\n") + "\n";
      post(bulkData, function(error, success, statusCode, failedItems) {
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
  });
};

function supportedProcessors(key) {
  return typeof(processors[key]) === "function";
}
