#   9 = \t
#  10 = \n
#  13 = \r
#  32 = (space)
#  34 = "
#  44 = ,
#  58 = :
#  91 = [
#  92 = \
#  93 = ]
# 123 = {
# 125 = }

def pretty:
  explode | reduce .[] as $char (
    {out: [], indent: [], string: false, escape: false};
    if .string == true then
      .out += [$char]
      | if $char == 34 and .escape == false then .string = false else . end
      | if $char == 92 and .escape == false then .escape = true else .escape = false end
    elif $char == 91 or $char == 123 then
      .indent += [32, 32] | .out += [$char, 10] + .indent
    elif $char == 93 or $char == 125 then
      .indent = .indent[2:] | .out += [10] + .indent + [$char]
    elif $char == 34 then
      .out += [$char] | .string = true
    elif $char == 58 then
      .out += [$char, 32]
    elif $char == 44 then
      .out += [$char, 10] + .indent
    elif $char == 9 or $char == 10 or $char == 13 or $char == 32 then
      .
    else
      .out += [$char]
    end
  ) | .out | implode;

def desc_param:
  "(" + .dataType + ", " + (if .required then "required" else "optional" end) + ") " + .description;

def conv_url:
  (.basePath + .path | gsub("\\$\\{"; ":") | gsub("}"; "")) as $path | {
    raw: ("https://{{dnac}}:{{port}}" + $path),
    protocol: "https",
    host: "{{dnac}}",
    port: "{{port}}",
    path: $path | split("/")[1:],
    variable: .pathParams | map({
      key: .name,
      value: .defaultValue,
      description: desc_param
    }),
    query: .queryParams | map({
      key: .name,
      value: .defaultValue,
      description: desc_param
    })
  };

def conv_header:
  [{
    key: "X-Auth-Token",
    value: "{{token}}",
    description: "(string, required) Authorization token"
  }] + if .requestSchema.definitions | length == 0 then [] else [{
    key: "Content-Type",
    value: "application/json",
    description: "(string, required) Data format"
  }] end + (.headers | map({
    key: .name,
    value: .value,
    description: desc_param
  }));

def conv_attr($ctx; $type):
  if $type == "any" then "any"
  elif $type == "boolean" then false
  elif $type == "integer" then 0
  elif $type == "number" then 0.0
  elif $type == "string" then "string"
  elif $type == "map" then
    $ctx[.address] | map({(.name): conv_attr($ctx; .type)}) | add // {}
  elif $type == "array" then
    [conv_attr($ctx; .arrayType)]
  else
    error("Unknown attribute type: " + $type)
  end;

def conv_body:
  . as $ctx | .root | conv_attr($ctx; .type);

def desc_attr($ctx; $prefix):
  $prefix + .name + ": (" +
    if .enum | length > 0 then
      "enum" + (.enum | tostring)
    else
      .type + if .type == "array" then "[" + .arrayType + "]" else "" end
    end +
    if .required or prefix == "" then ", required" else ", optional" end +
  ")" +
  if [.type] | inside(["any", "boolean", "integer", "number", "string"]) then
    if .displayText | length > 0 then " " + .displayText else "" end +
    if .default | length > 0 then ", " + .default else "" end
  elif ([.type] | inside(["map", "array"])) and .address then
    $ctx[.address] | map(desc_attr($ctx; "  " + $prefix)) | join("\n") | if length > 0 then "\n" + . else "" end
  else
    ""
  end;

def desc_body:
  . as $ctx | .root | desc_attr($ctx; "- ");

{
  info: {
    name: "DNA-C Platform Intent API v1.2 EFT",
    schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  item: group_by(.domain) | map({
    name: .[0].domain,
    item: group_by(.subDomain) | map({
      name: .[0].subDomain | (if length == 0 then "General" else . end),
      item: map({
        name: .name,
        request: {
          method: .payload.method,
          url:    .payload | conv_url,
          header: .payload | conv_header,
          body:   .payload.requestSchema.definitions | (if .root == null then null else {
            mode: "raw",
            raw: conv_body | tojson | pretty
          } end),
          description: (.description +
            (.payload.requestSchema.definitions | if .root == null then "" else "\n\n###### Request Model\n" + desc_body end) +
            (.payload.responseSchema.definitions | if .root == null then "" else "\n\n###### Response Model\n" + desc_body end))
        },
        response: .payload.responseSchema.definitions | (if .root == null then null else [{
          name: "Example Response",
          body: conv_body | tojson | pretty
        }] end)
      }) | sort_by(.request.url.raw, .request.method)
    })
  })
}
