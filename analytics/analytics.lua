
local function uuid4()
	local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	return string.gsub(template, '[xy]', function (c)
		local v = (c == 'x') and rnd.range(0, 0xf) or rnd.range(8, 0xb)
		return string.format('%x', v)
	end)
end

local analytics = {}

local platforms = {
	["HTML5"]="web",
	["Android"]="android",
	["iPhone OS"]="ios"
}

local packet_buffer = {}
local sent_events = {}
local request_in_progress = false
local _buffer_size_to_send = 3
local _max_send_attempts = 5
local _request_timeout = 5

local session_id = "0"
local _update_session_id_after_mins = 5
local platform = "unknown"
local _server_url = nil
local _device_language = "en-US" -- My implementation assumes that whenever the language is changed it should be applied to all the packets pending to be set


local focus_lost_time = 0
local focus_gained_time = 0

local function server_callback(self, _, response)
	print("Server response status: " .. response.status)
	print("Server response data: " .. response.response)
	
	if response.status ~= 200 then
		for i, event in pairs(sent_events) do
			table.insert(packet_buffer, event)
		end
		sent_events = {}
	end
	request_in_progress = false
end

-- To detect if the app is in background
local function window_callback(self, event, data)
	if event == window.WINDOW_EVENT_FOCUS_LOST then
		focus_lost_time = os.time()
	elseif event == window.WINDOW_EVENT_FOCUS_GAINED then
		focus_gained_time = os.time()

		-- Update session_id if the time difference is more than X minutes
		local diff = os.difftime(focus_gained_time, focus_lost_time)
		if diff >= _update_session_id_after_mins * 60 then
			session_id = uuid4()
		end
	end
end

local function send_packet(self, handle, time_elapsed)
	if not _server_url or request_in_progress then
		return
	end

	-- Filter out events with too many unsuccessful attempts to be sent. Otherwise add necessary data that cannot be added upon creation of the event or is not relevant at that time.
	for i,event in pairs(packet_buffer) do
		packet_buffer[i].attempt_number = event.attempt_number + 1
		if _max_send_attempts > 0 and event.attempt_number > _max_send_attempts then
			packet_buffer[i] = nil
		else
			packet_buffer[i].sent_at = os.time()
			packet_buffer[i].device_language = _device_language
		end
	end

	if #packet_buffer == 0 then
		return
	end

	local json_packet = json.encode(packet_buffer)
	print("Making HTTP request to the server...")
	http.request(_server_url, "POST", server_callback, nil, json_packet, {timeout=_request_timeout})

	for i,event in pairs(packet_buffer) do
		table.insert(sent_events, event)
	end
	packet_buffer = {}
	request_in_progress = true
end

function analytics.set_device_language(value)
	if not _server_url or value == (nil or "") then
		return
	end
	
	_device_language = value
end

function analytics.init(server_url, device_language, packet_send_period_secs, buffer_size_to_send, update_session_id_after_mins, max_send_attempts, request_timeout)
	if not server_url or server_url == "" then
		error("Couldn't initialize analytics: server URL string is empty or nil!")
	end
	_server_url = server_url
	
	session_id = uuid4() -- assuming the module is being initialized when the user enters the game
	platform = platforms[sys.get_sys_info().system_name] or "unknown"
	
	if device_language and not device_language == (nil or "") then
		_device_language = device_language
	end

	if not packet_send_period_secs then
		packet_send_period_secs = 5
	end
	
	if buffer_size_to_send then
		_buffer_size_to_send = buffer_size_to_send
	end
	if update_session_id_after_mins then
		_update_session_id_after_mins = update_session_id_after_mins
	end
	if max_send_attempts then
		_max_send_attempts = max_send_attempts
	end
	if request_timeout then
		_request_timeout = request_timeout
	end

	window.set_listener(window_callback)
	
	timer.delay(packet_send_period_secs, true, send_packet)
end

function analytics.add_event(name, level_number, payload)
	if not _server_url then
		return
	end
	
	if not level_number then
		error("level_number is required to add an event!")
	end

	local event = {
		attempt_number = 0,
		sent_at = 0,
		event_name = name,
		event_uuid = uuid4(),
		generated_at = os.time(),
		session_id = session_id,
		level_number = level_number,
		platform = platform,
	}

	if payload then
		for i,v in pairs(payload) do
			event[i] = v
		end
	end
	
	table.insert(packet_buffer, event)
	if #packet_buffer >= _buffer_size_to_send then
		send_packet()
	end
end

return analytics