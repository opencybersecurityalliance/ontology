const $RefParser = require("json-schema-ref-parser");
const fs = require('fs');

var args = process.argv.slice(2);

if (args.length < 1) {
  console.log("Usage: <schema.json> [proxy]");
  process.exit(1);
}

var schema = args[0];
var opts = null;

if (args.length > 1) {
  opts = {
    resolve: {
      http: {
        proxy: args[1]
      }
    },
  };
}

try {
  let mySchema = JSON.parse(fs.readFileSync(schema));
  $RefParser.dereference(mySchema, opts,
    (err, schema) => {
      if (err) {
        console.error(err);
      }
      else {
        console.log(JSON.stringify(schema, null, 4));
      }
    });
}
catch (err) {
  console.error(err);
}
