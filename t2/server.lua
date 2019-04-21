local socket = require'socket'
local binser = require'binser'
local mime = require'mime'
local types = require'types'

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

function validate_args(recv, expected, structinfo)
	return validate_primitive_res(recv, expected, structinfo)
end

function struct(t)
	if not types.validate_struct(t) then
		error('Invalid struct')
	end
	idls[current_idl].structs[t.name] = t.fields
end

function interface(t)
	if not types.validate_interface(t) then
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
    local aux_received = {}
    table.move(received, 1, #received, 1, aux_received)
    validate_args(aux_received, methinfo.args, idl.structs)
    local res = table.pack(pcall(methinfo.func, table.unpack(received)))
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
    local veridict = validate_res(aux_res, methinfo.args, methinfo.resulttype, idl.structs)
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
                    sock:settimeout(1)
                    if unconnected[sock] then
                        local client = sock:accept()
                        if client then
                            connected[client] = unconnected[sock]
                            unconnected[sock] = nil
                            table.insert(sockets, client)
                        end
                    else
                        local line, err = sock:receive('*l')
                        local res, name = parse_incoming(line, connected[sock])
                        res, err = parse_and_check_results(res, connected[sock], name)
                        if res then
                            sock:send(mime.b64(binser.serialize(table.unpack(res))) .. '\n')
                        else
                            sock:send(mime.b64(binser.serialize(false, err)) .. '\n')
                        end
                        --sock:close()
                    end
                end
            end
    end
end
