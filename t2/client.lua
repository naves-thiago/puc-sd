local types = require'types'
local binser = require'binser'
local socket = require'socket'
local mime = require'mime'

local m = {}

local function validate_args(recv, expected, structs)
	if #recv ~= #expected then
		return false, 'Expected ' .. #expected .. ' args, got ' .. #recv
	end
	for i, t in ipairs(expected) do
		local exp_type = structs[expected[i]] or expected[i]
		local ok, err = types.validate_type(recv[i], exp_type)
		if not ok then
			return false, err
		end
	end

	return true
end

local function create_proxy(self, hostname, port, interface)
	local proxy = {_interface_name = interface}
	local _structs = self._structs
	for name, def in pairs(self._interfaces[interface]) do
		local params, results = {}, {def.resulttype}
		for i, arg in ipairs(def.args) do
			local arg_type = _structs[arg.type] or arg.type
			if arg.direction == 'in' or arg.direction == 'inout' then
				table.insert(params, arg_type)
			end
			if arg.direction == 'out' or arg.direction == 'inout' then
				table.insert(results, arg_type)
			end
		end

		proxy[name] = function (self, ...)
			local function show_error(msg)
				error(self._interface_name .. '.' .. name .. ': ' .. msg, 3)
			end
			local name, exp_args, results = name, params, results
			local args = {...}
			local ok, err = validate_args(args, exp_args, _structs)
			if not ok then show_error(err) end
			ok, err = self._socket:send(mime.b64(binser.serialize(name, ...)) .. '\n')
			if not ok then show_error(err) end

			local response, err = self._socket:receive('*l')
			if err then show_error(err) end
			response = mime.unb64(response)
			local ok, data = pcall(binser.deserialize, response)
			if not ok then show_error(data) end
			if data[1] then
				table.remove(data, 1)
				local ok, err = validate_args(data, results, _structs)
				if not ok then
					show_error(err)
				end
				return table.unpack(data, 1, #results)
			else
				show_error(data[2])
			end
		end
	end

	proxy._socket = socket.tcp()
	assert(proxy._socket:connect(hostname, port))
	return proxy
end

local function init(self, idl_file)
	_ENV.interfaces = {}
	_ENV.structs = {}
	function _ENV.struct(t)
		if not types.validate_struct(t) then
			error('Invalid struct')
		end
		structs[t.name] = t.fields
		for k, v in pairs(t.fields) do
			if structs[v.type] then
				v.type = structs[v.type]
			end
		end
	end

	function _ENV.interface(t)
		if not types.validate_interface(t) then
			error('Invalid interface')
		end
		interfaces[t.name] = t.methods
	end

	loadfile(idl_file)()
	return {_interfaces = interfaces, _structs = structs, create_proxy = create_proxy}
end
setmetatable(m, {__call = init})



return m
