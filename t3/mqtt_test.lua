local mqtt = require'mqtt'
client = mqtt.client{
	uri = 'localhost',
	username = 'a',
	clean = true
}
print('created')

function tacb(suback)
	print("subscribed", suback)
	assert(client:publish{
		topic='t/a',
		payload = 'hello',
		qos = 0})
end

client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			print("connection failed", connack)
			return
		end
		print("Connected", connack)

		assert(client:subscribe{ topic="t/a", qos = 0, callback = tacb })
	end,

	message = function(msg)
		assert(client:acknowledge(msg))
		print("received", msg)
		assert(client:disconnect())
	end,

	error = function(err)
		print("MQTT error", err)
	end,
}

mqtt.run_ioloop(client)
