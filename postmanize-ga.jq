include "pretty";

def desc_param:
  "(" +
  .type +
  if .type == "array" then "[\(.items.type)]" else "" end +
  if .required == true then ", required" else ", optional" end +
  ") " + .description;

def conv_url:
  (.path | gsub("\\{"; ":") | gsub("}"; "")) as $path | {
    raw: ("https://{{dnac}}:{{port}}" + $path),
    protocol: "https",
    host: "{{dnac}}",
    port: "{{port}}",
    path: $path | split("/")[1:],
    variable: [.parameters[] | select(.in == "path") | {
      key: .name,
      value: .default,
      description: desc_param
    }],
    query: [.parameters[] | select(.in == "query") | {
      key: .name,
      value: .default,
      description: desc_param
    }]
  };

def conv_header:
  if .parameters | any(.in == "header" and .name == "Authorization") then [] else [{
    key: "X-Auth-Token",
    value: "{{token}}",
    description: "(string, required) Authorization token"
  }] end +
  [.parameters[] | select(.in == "header") | {
    key: .name,
    value: .default,
    description: desc_param
  }];

def conv_attr:
  if   .type == "boolean" then false
  elif .type == "integer" then 0
  elif .type == "number"  then 0.1
  elif .type == "string"  then if .enum then .enum | join(" | ") else "string" end
  elif .type == "object"  then (.properties // {}) | map_values(conv_attr)
  elif .type == "array"   then [.items | conv_attr]
  else
    error("Unknown attribute type: " + .type)
  end;

def desc_attr($name; $prefix):
  if .type == "object" then
    $prefix + $name + "\n" + (.properties // {} | to_entries | map(.key as $key | .value | desc_attr($key; "  " + $prefix)) | add)
  elif .type == "array" then
    if .items.type == "object" or .items.type == "array" then
      .items | desc_attr($name + ": array"; $prefix)
    else
      $prefix + $name + ": array[" + .items.type + "]\n"
    end
  else
    $prefix + $name + ": " + .type + "\n"
  end;

def find_req:
  if .parameters | any(.in == "body") then
    .parameters[] | select(.in == "body").schema."$ref" | ltrimstr("#/definitions/")
  else
    null
  end;

def find_resp:
  .responses."200".schema."$ref" | ltrimstr("#/definitions/");

.definitions as $defs | {
  info: {
    name: "DNA-C Platform Intent API v1.2.6 GA",
    schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  item: .paths | to_entries | map(.key as $path | .value | to_entries | map(.key as $method | .value | .path = $path | .method = $method)) | flatten | group_by(.tags) | map({
    name: .[0].tags[0],
    item: map(find_req as $req | find_resp as $resp | {
      name: .summary,
      request: {
        method: .method | ascii_upcase,
        url: conv_url,
        header: conv_header,
        body: (if $req then {
          mode: "raw",
          raw: $defs[$req] | conv_attr | tostring | pretty
        } else null end),
        description: (.description +
          (if $req then "\n\n###### Request Model\n" + ($defs[$req] | desc_attr($req; "- ")) else "" end) +
          (if $resp then "\n\n###### Response Model\n" + ($defs[$resp] | desc_attr($resp; "- ")) else "" end))
      },
      response: (if $resp then [{
        name: "Example Response",
        body: $defs[$resp] | conv_attr | tojson | pretty
      }] else null end)
    }) | sort_by(.request.url.raw, .request.method) | map(if .name != "Authentication API" then . else .event = [{
      listen: "test",
      script: {
        type: "text/javascript",
        exec: [
          "var data = JSON.parse(responseBody);",
          "postman.setEnvironmentVariable(\"token\", data.Token);"
        ]
      }
    }] | .request.auth = {
      type: "basic",
      basic: [
        {
          key: "username",
          value: "{{username}}",
          type: "string"
        },
        {
          key: "password",
          value: "{{password}}",
          type: "string"
        },
        {
          key: "saveHelperData",
          value: true,
          type: "boolean"
        },
        {
          key: "showPassword",
          value: false,
          type: "boolean"
        }
      ]
    } end)
  })
}
