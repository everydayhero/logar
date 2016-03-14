var moment = require("moment");

var INDEX_FORMAT = "[logstash-]YYYY.MM.DD";
var TYPE_KEY = "fluentd";

module.exports = function(records, cb) {
  var bulk = [];

  records.forEach(function(record) {
    bulk.apply(bulk, transform(record));
  });

  cb(null, bulk);
};

function transform(record) {
  var buffer = new Buffer(record.kinesis.data, 'base64').toString('utf8');
  var data = JSON.parse(buffer);
  var timestamp = moment.utc(data["@timestamp"] || data.timestamp || data.time);
  var indexKey = timestamp.format(INDEX_FORMAT);
  var index = {index: {_index: indexKey, _type: TYPE_KEY}};

  data["@timestamp"] = timestamp.format();

  return [ JSON.stringify(index), JSON.stringify(data) ];
}
