local folder = game:GetService('ServerStorage'):WaitForChild('ReSync')

local settingsFolder = folder:FindFirstChild('Settings')
local alreadyRegistered = settingsFolder:FindFirstChild('Registered').Value
local setFunction = settingsFolder:FindFirstChild('Register')

local function childErrror(item)
	error('ReSync | Attempted to insert unknown item '..tostring(item.Name)..' into ReSync ServerStorage folder')
end

folder.ChildAdded:Connect(function(item)
	if item.Name ~= 'Settings' then
		item:Destroy()
		childErrror(item)
	end
	if item.Name == 'Settings' then
		if not item:IsA('Folder') then
			item:Destroy()
			childErrror(item)
		end
	end
end)

folder.Parent = game:GetService('ServerStorage')

setFunction.Event:Connect(function(settingsModule)
	if alreadyRegistered == true then
		error('ReSync | Attempted to re-register settings')
	end
	local settingsTable = require(settingsModule)
	local storage = Instance.new('Folder',settingsFolder)
	storage.Name = 'Storage'
	--//Account Setup
	if not settingsTable.Account then
		warn('ReSync | No Account section of the settings was found. You will be unable to link an account.')
	else
		local account = settingsTable.Account
		if account['Account Username'] and account['System Identification'] and account['Serial Number'] and type(account['Account Username']) == 'string' and type(account['System Identification']) == 'string' and type(account['Serial Number']) == 'string' then
			local username = Instance.new('StringValue',storage)
			username.Name = 'AccountUsername'
			username.Value = account['Account Username']
			local ID = Instance.new('StringValue',storage)
			ID.Name = 'AccountID'
			ID.Value = account['System Identification']
			local serial = Instance.new('StringValue',storage)
			serial.Name = 'AccountSN'
			serial.Value = account['Serial Number']
		else
			warn('ReSync | Account is formatted incorrectly in the settings. You will be unable to link an account.')
		end
	end
	-- Telemetry Setup
	if settingsTable.Telemetry == true then
		local telemetryValue = Instance.new('BoolValue',storage)
		telemetryValue.Name = 'Relay'
		telemetryValue.Value = true
	end
	-- DataKey Setup
	if settingsTable.DataKey ~= nil and settingsTable.DataKey ~= '' then
		local dataKeyValue = Instance.new('StringValue',storage)
		dataKeyValue.Name = 'DataKey'
		dataKeyValue.Value = tostring(settingsTable.DataKey)
	else
		local dataKeyValue = Instance.new('StringValue',storage)
		dataKeyValue.Name = 'DataKey'
		dataKeyValue.Value = 'ReSyncStorage_#DGEF'
	end
	-- Default Permissions
	if not settingsTable.DefaultPermissions then
		warn('ReSync | No DefaultPermissions section of the settings was found. You will be unable to use commands that require a permission greater than 0.')
	else
		local bool = Instance.new('BoolValue',storage)
		bool.Name = 'CreatorAdmin'
		bool.Value = settingsTable.DefaultPermissions['CreatorAdmin']
		local baseAdmins = Instance.new('Folder',storage)
		baseAdmins.Name = 'BaseAdmins'
		for username,ID in next,settingsTable.DefaultPermissions['BaseAdmins'] do
			-- GetIDFromUserAsync is to be used later so it can be
			-- properly debugged. At this point, the API is not constructed yet.
			local entry = Instance.new('NumberValue',baseAdmins)
			entry.Name = username
			entry.Value = tonumber(ID)
		end
	end
	alreadyRegistered = true
end)

setFunction:Fire(settingsFolder:FindFirstChild('ReturnScriptSettings'):Invoke())
