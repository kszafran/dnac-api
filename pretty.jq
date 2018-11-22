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
