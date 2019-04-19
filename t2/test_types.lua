types = require'types'

struct = {{name = "a", type = "double"},
          {name = "b", type = "string"}
}

struct2 = {{name = 'a', type = 'int'},
           {name = 'b', type = struct}
}

t = {{{a = 3.5, b = "foo"},      true},
     {{},                        true},
     {{a = 4},                   true},
     {{b = "bar"},               true},
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

t = {{{a = 3, b = {a = 5, b = "foo"}},     true},
     {{b = {a = 5, b = "foo"}},            true},
     {{a = 4},                             true},
     {{b = {}},                            true},
     {{b = {a = 5}},                       true},
     {{b = {b = "bar"}},                   true},
     {{a = "asd", b = {a = 5, b = "foo"}}, false},
     {{b = {a = "asd", b = "asd"}},        false},
     {{b = {a = 1, b = {}}},               false},
     {{b = {a = {}, b = {}}},              false},
     {{b = {b = {}}},                      false},
}

for n, case in ipairs(t) do
	local input, expected = table.unpack(case)
	local ok, err = types.validate_type(input, struct2)
	print(n, ok, err, ok == expected and '(ok)' or '(fail)')
end
