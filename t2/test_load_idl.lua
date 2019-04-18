types = { string = "string",
          double = "number",
          int    = "number",
}

function validade_struct(t)
	if type(t.name) ~= "string" then return end
	if type(t.fields) ~= "table" then return end
	if #t.fields == 0 then return end
	for _, f in ipairs(t.fields) do
		if type(f.name) ~= "string" then return end
		if type(f.type) ~= "string" then return end
	end
	return true
end

function validate_interface(t)
	if type(t.name) ~= "string" then return end
	if type(t.methods) ~= "table" then return end
	for n, m in pairs(t.methods) do
		if type(n) ~= "string" then return end
		if type(m) ~= "table" then return end
		if type(m.resulttype) ~= "string" then return end
		if m.args then
			if type(m.args) ~= "table" then return end
			for _, a in ipairs(m.args) do
				if type(a.direction) ~= "string" then return end
				if type(a.type) ~= "string" then return end
			end
		end
	end
	return true
end

function struct(t)
	if not validade_struct(t) then
		print("Invalid struct")
		return
	end
	print("Struct: " .. t.name)
	print("\tFields:")
	for i, j in ipairs(t.fields) do
		print("\t", j.name, j.type)
	end
end

function interface(t)
	if not validate_interface(t) then
		print("Invalid interface")
		return
	end
	print("Interface: " .. t.name)
	print("\tMethods: ")
	for i, j in pairs(t.methods) do
		print("\t", i, j.resulttype)
		print("\t\t\targs")
		for _, a in ipairs(j.args) do
			print("\t\t\t", a.direction, a.type)
		end
	end
end

loadfile("idl1.lua")()

