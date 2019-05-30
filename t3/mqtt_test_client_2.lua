local mqtt = require'mqtt'
local socket = require'socket'
local starttime
local tries = 100000
local atonce = 1000
local sent = 0
local received = 0
local intervals = {}

client = mqtt.client{
	uri = 'localhost',
	username = 'a',
	clean = true
}

function tacb()
	local maxtimetaken = 0
	local timetaken = 0
	if sent < tries then
		starttime = socket.gettime() * 1000
		for i = 1, atonce do
			assert(client:publish{
				topic='t/a',
				payload = 'hello',
				qos = 0})
		end
		sent = sent + atonce
	end
end

client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			print("connection failed", connack)
			return
		end

		assert(client:subscribe{ topic="t/a", qos = 0, callback = tacb })
	end,

	message = function(msg)
		assert(client:acknowledge(msg))
		received = received + 1
		if received == sent then
			local endtime = socket.gettime() * 1000
			intervals[#intervals + 1] = endtime - starttime
		end

		if received >= tries then
			local max = 0
			local sum = 0
			for _, i in ipairs(intervals) do
				sum = sum + i;
				if max < i then
					max = i
				end
			end

			print('Messages: ' .. sent)
			print('Block size: ' .. atonce)
			print('Max: ' .. max)
			print('Average: ' .. sum / sent)
			assert(client:disconnect())
		else
			tacb()
		end
	end,

	error = function(err)
		print("MQTT error", err)
	end,
}

mqtt.run_ioloop(client)
