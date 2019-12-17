#
# Simple script that generates the GitHub Pages index file
#

import os
import sys
import fnmatch
import json
import pprint
import re


def process_schema_file(schema_file, result_dict, is_actions):
    with open(schema_file) as json_file:
        data = json.load(json_file)
        title = data["info"]["title"]

        result = {}
        messages = data['requests' if is_actions else 'events']
        baseurl = "schema/" + "actions" if is_actions else 'notifications' + "/"
        m = re.match(".*/(.*)-deref.json", schema_file)
        name = m.group(1)
        schema_url = baseurl + "/" + name

        for key in messages:
            print key
            message = messages[key]
            result[message["description"]] = schema_url + \
                "#" + ("request" if is_actions else 'event') + "-" + \
                key.replace("/", "-")

        result_dict[title] = {
            "url": schema_url,
            "result": result
        }


def walk_schema_dir(output_file, directory, is_actions):
    category = "Actions" if is_actions else "Notifications"
    output_file.write("## " + category + "\n")
    result_dict = {}

    for name in os.listdir(directory):
        full_path = os.path.join(directory, name)
        if os.path.isfile(full_path) and full_path.endswith("-deref.json"):
            process_schema_file(full_path, result_dict, is_actions)

    for action_type in sorted(result_dict.keys()):
        actions = result_dict[action_type]
        url = actions["url"]
        output_file.write("* [" + action_type + "](" + url +
                          ") ([Specification](" + url + ".json))\n")
        result = actions["result"]
        for action_key in sorted(result.keys()):
            action = result[action_key]
            output_file.write("  * [" + action_key + "](" + action + ")\n")


def main():
    # argv[1] : Output file
    # argv[2] : Actions directory
    # argv[3] : Notifications directory
    output_file = open(sys.argv[1], "w+")
    walk_schema_dir(output_file, sys.argv[2], True)
    output_file.write("\n")
    walk_schema_dir(output_file, sys.argv[3], False)
    output_file.close()


if __name__ == "__main__":
    main()
