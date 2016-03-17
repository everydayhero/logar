var moment = require("moment");

module.exports = function(records, cb) {
  var bulk = [];

  records.forEach(function(record) {
    try {
      bulk.push.apply(bulk, transform(record));
    } catch (error) {
      cb(error, bulk);
      return false;
    }
  });

  cb(null, bulk);
};

function transform(record) {
  var data = parse(record);
  var timestamp = moment.utc(data["@timestamp"] || data.timestamp || data.time);
  var indexKey = timestamp.format("YYYY.MM.DD");
  var typeKey = data.tag || "kinesis";
  var index = {index: {_index: indexKey, _type: typeKey}};
  var keys = Object.keys(data);

  var object = {};
  keys.forEach(function(key) {
    var value = data[key];
    setValue(object, key, value);
  });
  object["@timestamp"] = timestamp.format();

  return [ JSON.stringify(index), JSON.stringify(object) ];
}

function parse(record) {
  if ("kinesis" in record) {
    return decode(record.kinesis.data);
  } else {
    throw new Error("Invalid kinesis record:", record);
  }
}

function decode(data) {
  var buffer = new Buffer(data, "base64").toString("utf8");
  return JSON.parse(buffer);
}

function setValue(object, path, value) {
  var parts = path.split(".");
  var key = parts.shift();
  var val = value;

  if (parts.length > 0) {
    val = {};
    setValue(val, parts.join("."), value);
  }

  object[key] = value;
}
