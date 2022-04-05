--[[
                          _____    _____  _____              
                         |  __ \  / ____||_   _|              
                         | |__) || (___    | |
                         |  _  /  \___ \   | |
                         | | \ \  ____) | _| |_
                         |_|  \_\|_____/ |_____|
                         =======================
                            ReSync Internals
                            ================
                             >> Sezei.me <<
                            
    ------------------------------------------------------------------------------
    
    This Script
    -----------
    Authors                 MasterScootScoot                        
    Description             Sends messages on user entered
    						No commands in this module

    ------------------------------------------------------------------------------

    >> IMPORTANT <<
	Your use of this code is subject to ReSync's Terms of Use & Service.
	See the "About" script in the main model for detailed information regarding
	the TOS.
	
	>> WARNINGS <<
	- Making changes to this script may make ReSync unstable or completely break it
	  altogether. 
	- No support will be made for custom modifications made to this
	  script.
	- Do not steal this and attempt to publish it under your name. Doing so will
	  make you subject to the penalties outlined in the TOS.
    
]]

return function()
	local users = game:GetService('Players')

	local function send(user)
		if CoreAPI:CheckBaseAdmin(user.UserId) then
			SyncAPI:DisplayNotification(user,{
				Type = 'Sidebar',
				Title = 'You\'re a Base Administrator!',
				Icon = 'Exclamation',
				Time = 15,
			})
			if #CoreAPI:ReturnErrorList() > 0 then
				task.spawn(function()
					CoreAPI:DisplaySystemNotification(user,{
						Type = 'Sidebar',
						Title = 'ReSync had one or more issues loading. Type "'..SyncAPI.Prefix..'debuglog" to view debugging information.',
						Icon = 'Warning',
						Time = 15,
					})
				end)
			end
		end
		local userPermission = SyncAPI:GetPermissionLevel(user)
		if userPermission >= 1 then
			local title
			if userPermission == 1 then
				title = 'Moderator'
			elseif userPermission == 2 then
				title = 'Administrator'
			elseif userPermission == 3 then
				title = 'Super Administrator'
			end
			SyncAPI:DisplayNotification(user,{
				Type = 'Sidebar',
				Title = 'You have been given '..title..' permissions.',
				Icon = 'Check',
				Time = 12,
			})
			SyncAPI:DisplayNotification(user,{
				Type = 'Sidebar',
				Title = 'Chat "'..SyncAPI.Prefix..'commands" for a list of all available commands.',
				Icon = 'Question',
				Time = 10,
			})
			SyncAPI:DisplayNotification(user,{
				Type = 'Sidebar',
				Title = 'Press the '..CoreAPI:RetrieveSettings().General.ConsoleKey..' key on your keyboard or chat "/e" before a command to use silent commands.',
				Icon = 'Question',
				Time = 10,
			})
		end
		if CoreAPI:RetrieveSettings().Users.FriendJoinNotifications == true then
			-- Receiving notification on join
			local friendsList = {}
			for iteration,person in next,users:GetPlayers() do
				if user:IsFriendsWith(person.UserId) then
					local displayName = tostring(person.DisplayName) or ''
					if displayName ~= person.Name then
						table.insert(friendsList,displayName..' (@'..person.Name..')')
					else
						table.insert(friendsList,person.Name)
					end
					SyncAPI:DisplayNotification(person,{
						Type = 'Sidebar',
						Title = 'Your friend '..user.Name..' has joined the experience!',
						Icon = 'Question',
						Time = 8,
					})
				end
			end
			-- Receiving notifications from others
			if #friendsList == 1 then
				SyncAPI:DisplayNotification(user,{
					Type = 'Sidebar',
					Title = 'Your friend '..table.concat(friendsList,', ')..' is in the experience!',
					Icon = 'Question',
					Time = 8,
				})
			elseif #friendsList > 1 then
				SyncAPI:DisplayNotification(user,{
					Type = 'Sidebar',
					Title = 'Your friends '..table.concat(friendsList,', ')..' are in the experience!',
					Icon = 'Question',
					Time = 8,
				})
			end
		end
	end

	users.PlayerAdded:Connect(function(user)
		send(user)
	end)
	for iteration,user in ipairs(users:GetPlayers()) do
		send(user)
	end
end
