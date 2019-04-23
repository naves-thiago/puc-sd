local socket = require'socket'
local binser = require'binser'
local mime = require'mime'
local types = require'types'

local m = {}

local unconnected = {}
local connected = {}
local sockets = {}


local function validate_recv(recv, expected, structs)
        for i, received in ipairs(recv) do
            local exp_type = structs[expected[i].type] or expected[i].type
            local ok, err = types.validate_type(received, exp_type)
            if not ok then
                return ok, err
            end
        end
        return true
end

local function parse_incoming(incoming, idl, interface_name)
    local data = mime.unb64(incoming)
    local received = binser.deserialize(data)
    local func_name = received[1]
    table.remove(received, 1)
    local methinfo = idl.interfaces[interface_name].methods[func_name]
    local ok, err = validate_recv(received, methinfo.args, idl.structs)
    if not ok then return ok, err end
    local res = table.pack(pcall(methinfo.func, table.unpack(received)))
    return res, func_name
end

local function parse_and_check_results(res, idl, interface_name, func_name)
    if not res[1] then
        return false, res[2]
    end
    table.remove(res, 1)
    local methinfo = idl.interfaces[interface_name].methods[func_name]
    local exp_results = {}
	if methinfo.resulttype ~= 'void' then
		table.insert(exp_results, {type = methinfo.resulttype})
	end
    table.move(methinfo.args, 1, #methinfo.args, #exp_results + 1, exp_results)
    local veridict, err = validate_recv(res, exp_results, idl.structs)
    return veridict and res or false, err
end

function m.register_servant(idl_name, interface_name, o)
	local idl = {}
	idl.interfaces = {}
	idl.structs = {}

	function struct(t)
		if not types.validate_struct(t) then
			error('Invalid struct')
		end
		idl.structs[t.name] = t.fields
		for k, v in pairs(t.fields) do
			if idl.structs[v.type] then
				v.type = idl.structs[v.type]
			end
		end
	end

	function interface(t)
		if not types.validate_interface(t) then
			error('Invalid interface')
		end
		idl.interfaces[t.name] = {}
		idl.interfaces[t.name].methods = t.methods
	end

	loadfile(idl_name, 't')()

	local server = assert(socket.bind('*', 0))
	local ip, port = server:getsockname()
	for name, func in pairs(o) do
		idl.interfaces[interface_name].methods[name].func = func
	end
	unconnected[server] = { _idl = idl, _interface = interface_name }
	table.insert(sockets, server)
	return ip, port
end

function m.waitincoming()
	while true do
		local connected_size = 0
		local socks = socket.select(sockets)
		for _, sock in pairs(socks) do
			if type(sock) == 'userdata' then
				sock:settimeout(1)
				if unconnected[sock] then
					local client = sock:accept()
					if client then
						for _ in pairs(connected) do
							connected_size = connected_size + 1
						end
						if connected_size == 3 then
							local sock_toclose = next(connected, nil)
							print('saporra', sock_toclose)
							connected[sock_toclose] = nil
							sock_toclose:close()
						end
						connected[client] = unconnected[sock]
						table.insert(sockets, client)
					end
				elseif connected[sock] then
					local line, err = sock:receive('*l')
					if line then
						local res, func_name = parse_incoming(line, connected[sock]._idl,
														connected[sock]._interface)
						if not res then
							local err = func_name
							sock:send(mime.b64(binser.serialize(false, err)).. '\n')
							goto continue
						end
						local res, err = parse_and_check_results(res, connected[sock]._idl,
														connected[sock]._interface, func_name)
						if res then
							sock:send(mime.b64(binser.serialize(true, table.unpack(res))) .. '\n')
						else
							sock:send(mime.b64(binser.serialize(false, err)).. '\n')
						end
					else
						if err == 'closed' then
							connected[sock] = nil
						end
					end
				end
				::continue::
			end
		end
	end
end
return m
