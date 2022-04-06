-- Network ping
game:GetService('ReplicatedStorage'):WaitForChild('RSCSPing').OnClientInvoke = function(input)
	return input
end
