local socket = require'socket'
local binser = require'binser'
local mime = require'mime'

local idl_file = 'idl1.lua'
idls = {}

idls.interfaces = {}
idls.structs = {}
current_idl = ''

local unconnected = {}
local connected = {}
local sockets = {}

local type_translate = {
    string = 'string',
    int = 'number',
    double = 'number',
    void = 'nil',
}

local function validate_primitive_res(res, args, structinfo)
    for _, arg in ipairs(args) do
        if arg.type ~= 'double' and arg.type ~= 'int' and arg.type ~= 'string' and arg.type ~= 'void' then
            local fields
            for _, struct in pairs(structinfo) do
               if struct.name== arg.type  then
                   fields = struct.fields
               end
            end
            if not fields then return end
            return validate_primitive_res(res, fields, structinfo)
        else
            if type_translate[arg.type] ~= type(res[1]) and arg.type ~= 'void' then return end
            table.remove(res, 1)
        end
    end
    return true
end

local function validate_res(results, args, res_type, structinfo)
    if #results == 0 and #args == 1 and res_type == 'void' then return true end
    local inout_args = {}
    inout_args[1] = {type = res_type}
    for _, arg in ipairs(args) do
        if arg.direction == 'inout' then
            table.insert(inout_args, arg)
        end
    end
    return validate_primitive_res(results, inout_args, structinfo)
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
	idls[current_idl].structs[t.name] = t.fields
end

function interface(t)
	if not validate_interface(t) then
		error('Invalid interface')
	end
	idls[current_idl].interface.methods = t.methods
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

local function parse_incoming(incoming, idl)
    local data = mime.unb64(incoming)
    local received = binser.deserialize(data)
    local name = received[1]
    table.remove(received, 1)
    local methinfo = idl.interface.methods[name]
    validate_args(received, methinfo.args)
    local args = table.unpack(received)
    local res = table.pack(pcall(methinfo.func, args))
    return res, name
end

local function parse_and_check_results(res, idl, name)
    if not res[1] then
        return false, res[2]
    end
    table.remove(res, 1)
    local methinfo = idl.interface.methods[name]
    local aux_res = {}
    table.move(res, 1, #res, 1, aux_res)
    validate_res(aux_res, methinfo.args, methinfo.resulttype, idl.structs)
    return res
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
                            connected[client] = unconnected[sock]
                            table.insert(sockets, client)
                        end
                    else
                        sock:settimeout(1)
                        local line, err = sock:receive('*l')
                        local res, name = parse_incoming(line, connected[sock])
                        res = parse_and_check_results(res, connected[sock], name)
                        sock:send(mime.b64(binser.serialize(table.unpack(res))) .. '\n')
                        --sock:close()
                    end
                end
            end
    end
end
