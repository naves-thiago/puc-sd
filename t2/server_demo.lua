local librpc = require'librpc'

local color_list = {}
funcs_colors = {
	add = function (c)
		color_list[c.name] = c.rgb
	end,
	get = function (name)
		if color_list[name] then
			return color_list[name], name
		else
			return {x=0, y=0, z=0}, ""
		end
	end
}

funcs_numbers = {
	add = function (a, b)
		return a + b
	end,
	dup = function (a)
		return a, a
	end,
	swap = function (a, b)
		return b, a
	end
}

print(librpc.register_servant('idl_demo.lua', 'colors', funcs_colors))
print(librpc.register_servant('idl_demo.lua', 'numbers', funcs_numbers))

librpc.waitincoming()
