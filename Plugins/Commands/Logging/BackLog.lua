--[[
                          _____       _____                  
                         |  __ \     / ____|                 
                         | |__) |___| (___  _   _ _ __   ___ 
                         |  _  // _ \\___ \| | | | '_ \ / __|
                         | | \ \  __/____) | |_| | | | | (__ 
                         |_|  \_\___|_____/ \__, |_| |_|\___|
                                             __/ |           
                                            |___/            
                        
            
            @Description: The revival of SyncAdmin.
            @Authors:
            -    Anna [VolcanoINC]
            -    Marcy [ForPizzaSake]
            -    Engi [EngiAdurite][Sezei#3061]
            -    Scoot [MasterScootScoot][MasterKingSirPlease#6533]
            
            Intellectual Property of Sezei.me
    ======================================================================================
    
    This Script
    -----------
    Authors                 MasterScootScoot
    Description             Tracks all sorts of user data and reports it to
    						administration upon request.
    						NOTE: I would have loaded it only once upon server
    						startup, but this should be accurately updated
    						for each admin in each server.
    --------------------------------------------------------------------------------------
    
    >> Developer Notice <<
    Please refer to the Documentation script for a full comprehensive guide
    on how to create custom plugins.
    IMPORTANT REMINDERS:
    !! | Don't worry if something appears as an unknown global variable (Like SyncAPI)!
    It will have no issues running, provided you use the correct syntax.
    !! | We're here to help!
    If you need support creating a custom plugin, feel free to DM MasterKingSirPlease#6533 or Sezei#3061.
    Alternatively, you could join the community server here: https://discord.gg/Y9cu3ZcvvG   
--]]

return function()
	--//Setup & Vars
	local DSSvc = game:GetService('DataStoreService') -- >_<
	local users = game:GetService('Players')
	local DS = DSSvc:GetDataStore('RS_BackLog_0e3_#DGEF') -- Unique name :)

	if not DS:GetAsync('ServerLogs') then
		DS:SetAsync('ServerLogs',{})
	end

	--//Server
	local serverLog = {
		Date = os.date('%x'),
		UserTable = {}, -- Stores only user IDs for the server log
		JobID = game.JobId,
		ServerChats = 0,
		UserDatabase = {}, -- Stores actual user data
	}
	local function newUser(user)
		if serverLog[user.UserId] == nil then
			table.insert(serverLog.UserTable,user.UserId)
			serverLog.UserDatabase[user.UserId] = {}
			local userLog = serverLog.UserDatabase[user.UserId]
			userLog.Chats = {}
			userLog.TimeEntered = os.time() -- Clock in
			table.insert(userLog.Chats,'[ENTERED SERVER]')
		else
			local userLog = serverLog.UserDatabase[user.UserId]
			table.insert(userLog.Chats,'[REJOINED SERVER]')
		end
		local userLog = serverLog.UserDatabase[user.UserId]
		userLog.ServerID = game.JobId
		userLog.AccountAge = user.AccountAge
		userLog.AccountID = user.UserId
		user.Chatted:Connect(function(message)
			table.insert(userLog.Chats,game:GetService('Chat'):FilterStringForBroadcast(message,user))
			serverLog.ServerChats += 1
		end)
	end

	users.PlayerAdded:Connect(function(user)
		newUser(user)
	end)
	-- Get missed users
	for iteration,user in ipairs(users:GetPlayers()) do
		newUser(user)
	end

	users.PlayerRemoving:Connect(function(user)
		serverLog.UserDatabase[user.UserId].TimeExited = os.time() -- Clock out
		table.insert(serverLog.UserDatabase[user.UserId].Chats,'[LEFT SERVER]')
	end)

	game:BindToClose(function()
		DS:UpdateAsync('ServerLogs',function(callback)
			table.insert(callback,serverLog)
			return callback
		end)
		for userID,userData in pairs(serverLog.UserDatabase) do
			if not DS:GetAsync(userID) then
				DS:SetAsync(userID,{})
			end
			DS:UpdateAsync(userID,function(data)
				table.insert(data,userData)
				return data
			end)
		end
	end)

	--//Retrieval
	local function getServerLogs()
		local bigLog = DS:GetAsync('ServerLogs')
		if bigLog == nil then
			return 'No data to show.'
		end
		local display = ''
		local function add(data)
			display = display..'\n'..data
		end
		local function addLog(sLog)
			local userTbl = ''
			for _,ID in pairs(sLog.UserTable) do
				local username = '[ERR]'
				local success,issue = pcall(function()
					username = users:GetNameFromUserIdAsync(ID)
				end)
				if userTbl == '' then
					userTbl = username
				else
					userTbl = userTbl..', '..username
				end
			end
			add('<EDIT FONT &SIZE:24>')
			if sLog.JobID ~= '' then
				if sLog.JobID == game.JobId then
					add('<INSERT TEXT BOX &COLOR:11,158,255>')
					add(sLog.JobID..' [CURRENT SERVER]')
				else
					add('<INSERT TEXT BOX &COLOR:0,221,73>')
					add(sLog.JobID)
				end
			else
				if sLog.JobID == game.JobId then
					add('<INSERT TEXT BOX &COLOR:255,128,0>')
					add('00000000-0000-0000-0000-000000000000 [STUDIO')
				else
					add('<INSERT TEXT BOX &COLOR:255,128,0>')
					add('00000000-0000-0000-0000-000000000000 [STUDIO]')
				end
			end
			add('<INSERT LINE &COLOR:0,255,81>')
			add('<RESET FONT>')
			add('Date: '..sLog.Date)
			add('Total Chats Sent: '..sLog.ServerChats)
			add('Users: '..userTbl)
			add('<EXIT TEXT BOX>')
		end
		addLog(serverLog)
		for iteration,sLog in pairs(bigLog) do
			addLog(sLog)
		end
		return display
	end

	local function getUserLogs(userID)
		local bigLog = DS:GetAsync(userID)
		if bigLog == nil then
			return 'No data on record to display.'
		end
		local display = ''
		local function add(data)
			display = display..'\n'..data
		end
		local function addLog(uLog)
			local hourFormat = 0
			local minFormat = 0
			local secondsFormat = 0
			local differenceInSeconds
			if uLog.TimeExited ~= nil then
				differenceInSeconds = uLog.TimeExited-uLog.TimeEntered -- Because difftime() hates me
				while differenceInSeconds > 0 do
					differenceInSeconds -= 1
					secondsFormat += 1
					if secondsFormat == 60 then
						secondsFormat = 0
						minFormat += 1
					end
					if minFormat == 60 then
						minFormat = 0
						hourFormat += 1
					end
				end
			end

			add('<EDIT FONT &SIZE:24>')
			if uLog.ServerID ~= '' then
				if uLog.ServerID == game.JobId then
					add('<INSERT TEXT BOX &COLOR:221,66,208>')
					add('SERVER '..uLog.ServerID..' [CURRENT SERVER]')
				else
					add('<INSERT TEXT BOX &COLOR:0,221,73>')
					add('SERVER '..tostring(uLog.ServerID))
				end
			else
				if uLog.ServerID == game.JobId then
					add('<INSERT TEXT BOX &COLOR:255,128,0>')
					add('SERVER '..'00000000-0000-0000-0000-000000000000 [STUDIO')
				else
					add('<INSERT TEXT BOX &COLOR:255,128,0>')
					add('SERVER '..'00000000-0000-0000-0000-000000000000 [STUDIO]')
				end
			end
			add('<INSERT LINE &COLOR:198,190,196>')
			add('<RESET FONT>')
			add('Time In: '..os.date('%I:%M %p UTC',uLog.TimeEntered))
			local tOut = 'N/A'
			if uLog.TimeExited ~= nil then
				tOut = os.date('%I:%M %p UTC',uLog.TimeExited)
			end
			add('Time Out: '..tOut)
			add('Total Time Spent: '..hourFormat..' Hours, '..minFormat..' Minutes, '..secondsFormat..' Seconds')
			local chatNum = 0
			if uLog.Chats ~= nil then
				chatNum = #uLog.Chats-2 -- -2 for the [ENTERED/LEFT] messages
			end
			add('Amount of Chats Sent: '..chatNum)
			add('<INSERT LINE &COLOR:198,190,196>')
			if uLog.Chats ~= nil then
				for _,chat in pairs(uLog.Chats) do
					add(chat)
				end
			end
			add('<EXIT TEXT BOX>')
		end
		addLog(serverLog)
		for iteration,uLog in pairs(bigLog) do
			addLog(uLog)
		end
		return display
	end

	--//Command
	SyncAPI('BackLog').Create({
		Description = 'Pulls up a log of stored user data. Useful for developers who want to monitor their game\'s activity, or for managers of social groups who want to view the activity of staff and guests.',
		PermissionLevel = 2,
		Shorthand = {'History','GlobalLog'},
		Run = function(main,user)
			local bool,returning = nil,'An error occurred.'
			SyncAPI:DisplayNotification(user,{
				Type = 'Popup',
				Title = 'Select Log',
				Content = 'Would you like to view the SERVER log or specific USER DATA?',
				Options = {
					{
						Text = 'SERVER',
						Clicked = function()
							task.spawn(function()
								local log = getServerLogs()
								SyncAPI:DisplayNotification(user,{
									Type = 'List',
									Title = 'SERVER BACKLOG',
									Text = '<EDIT FONT &SIZE:18>\nALL TIMES ARE IN UTC FORMAT.\n'..log,
									CloseButtonText = 'CLOSE BACKLOG',
								})
							end)
							bool,returning = true,'Loading the server backlog... This may take some time.'
						end,
					},
					{
						Text = 'USER',
						Clicked = function()
							SyncAPI:DisplayNotification(user,{
								Type = 'User Input',
								Title = 'Input Name',
								Content = 'Input the desired user\'s FULL username in the box below.',
								PlaceholderText = 'Enter username...',
								Options = {
									{
										Text = 'SEARCH BACKLOG',
										Color = Color3.fromRGB(0,255,0),
										Clicked = function(input)
											local ID
											local success = pcall(function()
												ID = users:GetUserIdFromNameAsync(input)
											end)
											if not success then
												bool,returning = false,'User does not exist.'
											else
												task.spawn(function()
													local log = getUserLogs(ID)
													SyncAPI:DisplayNotification(user,{
														Type = 'List',
														Title = 'USER BACKLOG',
														Text = '<EDIT FONT &SIZE:18>\nALL TIMES ARE IN UTC FORMAT.\n'..log,
														CloseButtonText = 'CLOSE BACKLOG',
													})
												end)
												bool,returning = true,'Loading the user\'s backlog... This may take some time.'
											end
										end,
									},
									{
										Text = 'CANCEL',
										Color = Color3.fromRGB(255,0,0),
										Clicked = function()
											bool,returning = true,'Prompt canceled.'
										end,
									},
								},
							})
						end,
					},
					{
						Text = 'CANCEL',
						Color = Color3.fromRGB(255,0,0),
						Clicked = function()
							bool,returning = true,'Prompt canceled.'
						end,
					},
				},
			})
			repeat
				wait(1)
			until bool ~= nil
			return bool,returning,10
		end,
	})
end
