local socket = require'socket'
local binser = require'binser'
local mime = require'mime'
local types = require'types'

idls = {}

idls.interfaces = {}
idls.structs = {}
current_idl = ''

local unconnected = {}
local connected = {}
local sockets = {}

function validate_recv(recv, expected)
        for i, received in ipairs(recv) do
            local ok, err = types.validate_type(received, expected[i].type)
            if not ok then
                return ok, err
            end
        end
        return true
end

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

function struct(t)
	if not validade_struct(t) then
		error('Invalid struct')
	end
	idls[current_idl].structs[t.name] = t.fields
end

function interface(t)
	if not validate_interface(t) then
		error('Invalid interface')
	end
	idls[current_idl].interface.methods = t.methods
end

local function parse_incoming(incoming, idl)
    local data = mime.unb64(incoming)
    local received = binser.deserialize(data)
    local name = received[1]
    table.remove(received, 1)
    local methinfo = idl.interface.methods[name]
    print('args', validate_recv(received, methinfo.args))
    local res = table.pack(pcall(methinfo.func, table.unpack(received)))
    return res, name
end

local function parse_and_check_results(res, idl, name)
    if not res[1] then
        return false, res[2]
    end
    table.remove(res, 1)
    local methinfo = idl.interface.methods[name]
    local exp_results = {{type = methinfo.resulttype}}
    table.move(methinfo.args, 1, #methinfo.args, 2, exp_results)
    local veridict, err = validate_recv(res, exp_results)
    print('rets', veridict, err)
    return veridict and res or false, 'wrong return types'
end

function register_servant(idlname, o)
    current_idl = idlname
    idls[idlname] = {}
    idls[idlname].structs = {}
    idls[idlname].interface = {}
    loadfile(idlname .. '.lua' , 't')()
    local idl = idls[idlname]
    local server = assert(socket.bind('*', 0))
    local ip, port = server:getsockname()
    for name, func in pairs(o) do
        idl.interface.methods[name].func = func
    end
    unconnected[server] = idl
    table.insert(sockets, server)
    return ip, port
end

local function waitincoming()
    while true do
            local socks = socket.select(sockets)
            for _, sock in pairs(socks) do
                if type(sock) == 'userdata' then
                    if unconnected[sock] then
                        sock:settimeout(1)
                        local client = sock:accept()
                        if client then
                            if #connected == 3 then
                                local sock_toclose = next(connected, nil)
                                connected[sock_toclose] = nil
                                sock_toclose:close()
                            end
                            connected[client] = unconnected[sock]
                            table.insert(sockets, client)
                        end
                    else
                        sock:settimeout(1)
                        local line, err = sock:receive('*l')
                        if line then
                            local res, name = parse_incoming(line, connected[sock])
                            res, err = parse_and_check_results(res, connected[sock], name)
                            if res then
                                sock:send(mime.b64(binser.serialize(table.unpack(res))) .. '\n')
                            else
                                sock:send(mime.b64('__RPC_ERROR ' .. err).. '\n')
                            end
                        else
                                sock:send(mime.b64('__RPC_ERROR couldn\'t receive payload').. '\n')
                        end
                    end
                end
            end
    end
end
