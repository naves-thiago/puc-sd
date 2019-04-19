local module = {}

local types = {string = "string",
               double = "number",
               int    = "number",
}

local function validate_struct(s, fields)
	if s == nil then return true end
	for _, f in ipairs(fields) do
		local ok, err = module.validate_type(s[f.name], f.type)
		if not ok then return false, err end
	end
	return true
end

function module.validate_type(value, exptype)
	if value == nil then return true end
	if type(exptype) == 'table' then
		return validate_struct(value, exptype)
	end
	if type(value) ~= types[exptype] then
		return false, 'Expected ' .. exptype .. ', got ' .. type(value)
	end
	return true
end

return module
