var zlib = require('zlib');

module.exports = function(awslogs, cb) {
  var zippedInput = new Buffer(awslogs.data, 'base64');

  // decompress the input
  zlib.gunzip(zippedInput, function(error, buffer) {
    if (error) { cb(error); return; }

    // parse the input from JSON
    var awslogsData = JSON.parse(buffer.toString('utf8'));

    // transform the input to Elasticsearch documents
    var elasticsearchBulkData = transform(awslogsData);

    cb(null, elasticsearchBulkData);
  });
};

function transform(payload) {
  var bulk = [];

  if (payload.messageType === 'CONTROL_MESSAGE') {
    console.log('Received a control message');
    return bulk;
  }

  payload.logEvents.forEach(function(logEvent) {
    var timestamp = new Date(1 * logEvent.timestamp);

    // index name format: cwl-YYYY.MM.DD
    var indexName = [
      'cwl-' + timestamp.getUTCFullYear(),              // year
      ('0' + (timestamp.getUTCMonth() + 1)).slice(-2),  // month
      ('0' + timestamp.getUTCDate()).slice(-2)          // day
    ].join('.');

    var source = buildSource(logEvent.message, logEvent.extractedFields);
    source['@id'] = logEvent.id;
    source['@timestamp'] = new Date(1 * logEvent.timestamp).toISOString();
    source['@message'] = logEvent.message;
    source['@owner'] = payload.owner;
    source['@log_group'] = payload.logGroup;
    source['@log_stream'] = payload.logStream;

    var action = { "index": {} };
    action.index._index = indexName;
    action.index._type = payload.logGroup;
    action.index._id = logEvent.id;

    bulk.push(
      JSON.stringify(action),
      JSON.stringify(source)
    );
  });
  return bulk;
}

function buildSource(message, extractedFields) {
  if (extractedFields) {
    var source = {};

    for (var key in extractedFields) {
      if (extractedFields.hasOwnProperty(key) && extractedFields[key]) {
        var value = extractedFields[key];

        if (isNumeric(value)) {
          source[key] = 1 * value;
          continue;
        }

        jsonSubString = extractJson(value);
        if (jsonSubString !== null) {
          source['$' + key] = JSON.parse(jsonSubString);
        }

        source[key] = value;
      }
    }
    return source;
  }

  jsonSubString = extractJson(message);
  if (jsonSubString !== null) { 
    return JSON.parse(jsonSubString); 
  }

  return {};
}

function extractJson(message) {
  var jsonStart = message.indexOf('{');
  if (jsonStart < 0) return null;
  var jsonSubString = message.substring(jsonStart);
  return isValidJson(jsonSubString) ? jsonSubString : null;
}

function isValidJson(message) {
  try {
    JSON.parse(message);
  } catch (e) { return false; }
  return true;
}

function isNumeric(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}
