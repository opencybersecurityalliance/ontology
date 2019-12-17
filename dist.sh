#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
DATE="$( date '+%Y%m%d%H%S' )"
DIST_DIR=$SCRIPTPATH/dist
DIST_SCHEMA_DIR=$DIST_DIR/schema
DIST_SCHEMA_ACTIONS_DIR=$DIST_SCHEMA_DIR/actions
DIST_SCHEMA_NOTIFICATIONS_DIR=$DIST_SCHEMA_DIR/notifications
ACTIONS_DIR=$SCRIPTPATH/schema/actions
NOTIFICATIONS_DIR=$SCRIPTPATH/schema/notifications
GH_PAGES_INDEX_FILE=$DIST_DIR/index.md

#
# Function that is invoked when the script fails.
#
# $1 - The message to display prior to exiting.
#
function fail() {
    echo $1
    echo "Exiting."
    exit 1
}

#
# Function that processes a schema file 
# (validates, resolves references, generates HTML)
#
# $1 - The schema file
# $2 - The output directory
#
function process_schema() {
    schema=$1
    outdir=$2
    echo "Processing '$schema' schema..."

    schema_dir=$(dirname "$schema")
    schema_basename=$(basename "$schema")
    schema_no_ext="${schema_basename%.*}"
    schema_ref_deref="$outdir/$schema_no_ext-deref.json"

    # Change to schema directory
    cd $schema_dir || { fail "Unable to change to schema dir: $schema_dir"; }
    
    # Copy original schema to outdir
    cp "$schema" "$outdir" || { fail "Error copying: $schema"; }

    # Dereference the json $ref values
    echo "Dereferencing schema file..."
    node /root/deref.js "$schema" > "$schema_ref_deref" \
        || { fail "Error dereferencing: $schema"; }

    # Validate the dereferenced schema
    echo "Validating dereferenced schema file..."
    jsonschema -i "$schema_ref_deref" /root/dxlschema/v0.1/schema.json \
        || { fail "Error validating schema: $schema"; }

    # Generate html
    echo "Generating HTML for schema..."
    schema_html_dir="$outdir/$schema_no_ext"
    bootprint opendxl "$schema_ref_deref" "$schema_html_dir"
}

#
# Walks the specified schema directory
# (validates, resolves references, generates HTML)
#
# $1 - The schema directory
# $2 - The output directory
#
function walk_schema_dir() {    
    schemadir=$1
    outdir=$2
    for f in "$schemadir"/*.json
    do
        if [ -f $f ]; then        
            process_schema "$f" "$outdir"
        fi
    done
}

# Clear dist directory
if [ -d $DIST_DIR ]; then
    echo "Clearing dist directory..."
    rm -rf $DIST_DIR || { fail 'Error clearing dist directory.'; }
fi

# Create dist directories
echo "Creating dist directory..."
mkdir $DIST_DIR || { fail 'Error creating dist directory.'; }
echo "Creating schema directory..."
mkdir $DIST_SCHEMA_DIR || { fail 'Error creating schema directory.'; }
echo "Creating schema actions directory..."
mkdir $DIST_SCHEMA_ACTIONS_DIR || { fail 'Error creating schema actions directory.'; }
echo "Creating schema notifications directory..."
mkdir $DIST_SCHEMA_NOTIFICATIONS_DIR || { fail 'Error creating schema notifications directory.'; }

# Walk actions
walk_schema_dir "$ACTIONS_DIR" "$DIST_SCHEMA_ACTIONS_DIR"

# Walk notifications
walk_schema_dir "$NOTIFICATIONS_DIR" "$DIST_SCHEMA_NOTIFICATIONS_DIR"

# Generate index file for GitHub pages
python $SCRIPTPATH/site/generatepagesindex.py "$GH_PAGES_INDEX_FILE" \
    "$DIST_SCHEMA_ACTIONS_DIR" "$DIST_SCHEMA_NOTIFICATIONS_DIR"
