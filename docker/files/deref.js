const $RefParser = require("json-schema-ref-parser");
const fs = require('fs');

var args = process.argv.slice(2);

if (args.length < 1) {
  console.log("Usage: <schema.json>");
  process.exit(1);
}

var schema = args[0];
var opts = null;

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
