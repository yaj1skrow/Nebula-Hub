local Connection = {};
Connection.__index = Connection;

function Connection.new(callback)
	return setmetatable({
		Connected = true;
		Callback = callback;
	}, Connection);
end

function Connection:Disconnect()
	self.Connected = false;
end

local Signal = {};
Signal.__index = Signal;

function Signal.new()
	return setmetatable({
		destroyed = false;
		connections = {}::{Connection};
		parallel_connections = {};
	}, Signal);
end

function Signal:Connect(func)
	if (self.destroyed) then
		error("[Signal] Cannot connect signal while destroyed", 2);
	end
	local connection = Connection.new(func);

	table.insert(self.connections, connection);

	return connection;
end

function Signal:ConnectParallel(func)
	if (self.destroyed) then
		error("[Signal] Cannot connect signal while destroyed", 2);
	end
	local connection = Connection.new(func);

	table.insert(self.parallel_connections, connection);

	return connection;
end

function Signal:Fire(...)
	if (self.destroyed) then
		error("[Signal] Cannot call signal while destroyed", 2);
	end
	for _, connection in self.parallel_connections do
		if (connection.Connected) then
			task.spawn(function(...)
				task.desynchronize();
				connection.Callback(...);
			end, ...)
		end
	end
	for _, connection in self.connections do
		if (connection.Connected) then
			task.spawn(connection.Callback, ...);
		end
	end

	for i = #self.connections, 1, -1 do
		local connection = self.connections[i];
		if (not connection.Connected) then
			table.remove(self.connections, i);
		end
	end

	for i = #self.parallel_connections, 1, -1 do
		local connection = self.parallel_connections[i];
		if (not connection.Connected) then
			table.remove(self.parallel_connections, i);
		end
	end
end

function Signal:Wait()
	local thread = coroutine.running();
	self:Once(function(...)
		coroutine.resume(thread, ...);
	end)
	return coroutine.yield();
end

function Signal:Once(func)
	local connection;
	connection = self:Connect(function(...)
		if (connection and connection.Connected) then
			connection:Disconnect();
		end
		func(...);
	end)
	return connection;
end

function Signal:Clone()
	if (self.destroyed) then
		error("[Signal] Cannot clone signal while destroyed", 2);
	end
	return Signal.new();
end

function Signal:Destroy()
	self.destroyed = true;
	table.clear(self.parallel_connections);
	table.clear(self.connections);
end

_G.NebulaHub.Dependencies.Manager.Signal = Signal;
