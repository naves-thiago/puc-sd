types = require'types'
binser = require'binser'
socket = require'socket'
mime = require'mime'

idl_file = 'idl1.lua'
interfaces = {}
structs = {}

function validade_struct(t)
	if type(t.name) ~= 'string' then return end
	if type(t.fields) ~= 'table' then return end
	if #t.fields == 0 then return end
	for _, f in ipairs(t.fields) do
		if type(f.name) ~= 'string' then return end
		if type(f.type) ~= 'string' then return end
	end
	return true
end

function validate_interface(t)
	if type(t.name) ~= 'string' then return end
	if type(t.methods) ~= 'table' then return end
	for n, m in pairs(t.methods) do
		if type(n) ~= 'string' then return end
		if type(m) ~= 'table' then return end
		if type(m.resulttype) ~= 'string' then return end
		if m.args then
			if type(m.args) ~= 'table' then return end
			for _, a in ipairs(m.args) do
				if type(a.direction) ~= 'string' then return end
				if type(a.type) ~= 'string' then return end
			end
		end
	end
	return true
end

function validate_args(recv, expected)
	if #recv ~= #expected then
		return false, 'Expected ' .. #expected .. ' args, got ' .. #recv
	end
	-- TODO actually validate stuff
	return true
end

function struct(t)
	if not validade_struct(t) then
		error('Invalid struct')
	end
	structs[t.name] = t.fields
end

function interface(t)
	if not validate_interface(t) then
		error('Invalid interface')
	end
	interfaces[t.name] = t.methods
end

function create_proxy(hostname, port, interface)
	local proxy = {_interface_name = interface}
	for name, def in pairs(interfaces[interface]) do
		local params, results = {}, {def.resulttype}
		for i, arg in ipairs(def.args) do
			if arg.direction == 'in' or arg.direction == 'inout' then
				table.insert(params, arg.type)
			else
				table.insert(results, arg.type)
			end
		end

		proxy[name] = function (self, ...)
			local function show_error(msg)
				error(self._interface_name .. '.' .. name .. ': ' .. msg, 3)
			end
			local name, exp_args, results = name, params, results
			local args = {...}
			local ok, err = validate_args(args, exp_args)
			if not ok then show_error(err) end
			ok, err = self._socket:send(mime.b64(binser.serialize(name, ...)) .. '\n')
			if not ok then show_error(err) end

			if #results > 1 or results[1] ~= 'void' then
				local response, err = self._socket:receive('*l')
				if err then show_error(err) end
				response = mime.unb64(response)
				local ok, data = pcall(binser.deserialize(response))
				if not ok then show_error(data) end
				return table.unpack(data, 1, #results)
			end
		end
	end

	loadfile(idl_file)()
	proxy._socket = socket.tcp()
	assert(proxy._socket:connect(hostname, port))
	return proxy
end
