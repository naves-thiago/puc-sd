local module = {}

local valid = {}
function valid.string(s)
	return type(s) == 'string'
end

function valid.int(i)
	if type(i) ~= 'number' then return false end
	return math.floor(i) == i
end

function valid.double(d)
	return type(d) == 'number'
end

local function validate_struct(s, fields)
	if s == nil then return false end
	for _, f in ipairs(fields) do
		local ok, err = module.validate_type(s[f.name], f.type)
		if not ok then return false, err end
	end
	return true
end

function module.validate_type(value, exptype)
	if type(exptype) == 'table' then
		return validate_struct(value, exptype)
	end
	if not valid[exptype](value) then
		return false, 'Expected ' .. exptype .. ', got ' .. type(value)
	end
	return true
end

return module
