types = require'types'

t = {{{1, "int"},      true},
     {{1, "double"},   true},
     {{1.5, "double"}, true},
     {{1.5, "int"},    false},
     {{"a", "int"},    false},
     {{"a", "double"}, false},
     {{"a", "string"}, true},
     {{1, "string"},   false},
     {{1.5, "string"}, false},
}

for n, case in ipairs(t) do
	local input, expected = table.unpack(case)
	local ok, err = types.validate_type(table.unpack(input))
	print(n, ok, err, ok == expected and '(ok)' or '(fail)')
end

print('----------------------------')


struct = {{name = "a", type = "double"},
          {name = "b", type = "string"}
}

struct2 = {{name = 'a', type = 'int'},
           {name = 'b', type = struct}
}

t = {{{a = 3.5, b = "foo"},      true},
     {{},                        false},
     {{a = 4},                   false},
     {{b = "bar"},               false},
     {{a = 1, b = "foo", c = 9}, true},
     {{a = "asd", b = 3},        false},
     {{a = {}, b = "asd"},       false},
     {{a = 1, b = {}},           false},
     {{a = {}, b = {}},          false},
}

for n, case in ipairs(t) do
	local input, expected = table.unpack(case)
	local ok, err = types.validate_type(input, struct)
	print(n, ok, err, ok == expected and '(ok)' or '(fail)')
end

print('----------------------------')

t = {{{a = 3, b = {a = 5, b = "foo"}},               true},
     {{a = 3, b = {a = 5, b = "foo", c = 1}},        true},
     {{a = 3, b = {a = 5, b = "foo", c = 1}, d = 2}, true},
     {{a = 3, b = {a = 5, b = "foo"}, c = 1},        true},
     {{b = {a = 5, b = "foo"}},                      false},
     {{a = 4},                                       false},
     {{b = {}},                                      false},
     {{b = {a = 5}},                                 false},
     {{b = {b = "bar"}},                             false},
     {{a = "asd", b = {a = 5, b = "foo"}},           false},
     {{b = {a = "asd", b = "asd"}},                  false},
     {{b = {a = 1, b = {}}},                         false},
     {{b = {a = {}, b = {}}},                        false},
     {{b = {b = {}}},                                false},
}

for n, case in ipairs(t) do
	local input, expected = table.unpack(case)
	local ok, err = types.validate_type(input, struct2)
	print(n, ok, err, ok == expected and '(ok)' or '(fail)')
end
