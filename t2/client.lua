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

function m.create_proxy(hostname, port, idl_file, interface)
	local proxy = {}
	local _interfaces = {}
	local _structs = {}
	_ENV._interfaces = _interfaces
	_ENV._structs = _structs
	function _ENV.struct(t)
		if not types.validate_struct(t) then
			error('Invalid struct')
		end
		_structs[t.name] = t.fields
		for k, v in pairs(t.fields) do
			if _structs[v.type] then
				v.type = _structs[v.type]
			end
		end
	end

	function _ENV.interface(t)
		if not types.validate_interface(t) then
			error('Invalid interface')
		end
		_interfaces[t.name] = t.methods
	end

	loadfile(idl_file)()

	_ENV._interfaces = nil
	_ENV._structs = nil
	_ENV.interface = nil
	_ENV.struct = nil

	local _socket = socket.tcp()
	assert(_socket:connect(hostname, port))
	for name, def in pairs(_interfaces[interface]) do
		local params, results = {}, {}
		if def.resulttype ~= 'void' then
			table.insert(results, def.resulttype)
		end
		for i, arg in ipairs(def.args) do
			local arg_type = _structs[arg.type] or arg.type
			if arg.direction == 'in' or arg.direction == 'inout' then
				table.insert(params, arg_type)
			end
			if arg.direction == 'out' or arg.direction == 'inout' then
				table.insert(results, arg_type)
			end
		end

		proxy[name] = function (...)
			local function show_error(msg)
				error(interface .. '.' .. name .. ': ' .. msg, 3)
			end
			local name, exp_args, results = name, params, results
			local args = {...}
			local ok, err = validate_args(args, exp_args, _structs)
			if not ok then show_error(err) end
			ok, err = _socket:send(mime.b64(binser.serialize(name, ...)) .. '\n')
			if not ok then show_error(err) end

			local response, err = _socket:receive('*l')
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

	return proxy
end

return m
