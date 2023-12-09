# Defold Analytics Module

`Defold Analytics Module` is a simple analytics module that uses Defold's standard `http` API to make HTTP requests to the server.

## Usage

To start using this module in your script you have to require it and then initialize it:

```lua
local analytics = require("analytics/analytics")


analytics.init(server_url, [device_language], [packet_send_period_secs], [buffer_size_to_send], [update_session_id_after_mins], [max_send_attempts], [request_timeout])
```

Parameters of the `init`:

- `server_url` (string) - URL of the server. Required parameter.
- `device_language` (string) - Current language of the app. Default value is en-US.
- `packet_send_period_secs` (number) - Period in seconds after which to send the packet. Default value is 5.
- `buffer_size_to_send` (number) - When the amount of events is equal or exceeds this value, packets are automatically sent. Default value is 3.
- `update_session_id_after_mins` (number) - `session_id` will be updated when the app is in background for more minutes than this number is. Default value is 5.
- `max_send_attempts` (number) - Maximum number of attempts to send an event after which it will be discarded. Set to 0 or lower to attempt to send the events indefinitely. Default value is 5.
- `request_timeout` (number) - HTTP request timeout. Default value is 5.

After this you can call other functions of this module:

```lua
analytics.add_event(name, level_number, [payload])
```

Parameters of the `add_event`:

- `name` (string) - Name of the event. Required parameter.
- `level_number` (number) - Player level. Required parameter.
- `payload` (table) - The event payload i.e. any custom data to be sent to the server.


```lua
analytics.set_device_language(value)
```

Parameters of the `set_device_language`:

- `value` (string) - Current language. For example ru-RU.

Here's an example of using this module:

```lua
local analytics = require("analytics/analytics")

-- Each heartbeat counts as a new level (for testing)
local heartbeat_counter = 1

function init(self)
	analytics.init("http://www.my.server/")

	analytics.add_event("install_event", 1)
	analytics.set_device_language("ru-RU")

	analytics.add_event("heartbeat_event", 1)
	timer.delay(60, true, heartbeat_timer_callback)
end

function heartbeat_timer_callback(self, handle, time_elapsed)
	heartbeat_counter = heartbeat_counter + 1
	analytics.add_event("heartbeat_event", heartbeat_counter)
end
```

---