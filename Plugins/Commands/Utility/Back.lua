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
    Description             Back command that teleports an avatar back to its
    						last recorded location upon command execution.
    --------------------------------------------------------------------------------------
    
    >> Developer Notice <<
    Please refer to the Documentation script for a full comprehensive guide
    on how to create custom plugins.
    IMPORTANT REMINDERS:
    !! | Don't worry if something appears as an unknown global variable (Like SyncAPI)!
    It will have no issues running, provided you use the correct syntax and include it in the imports.
    !! | We're here to help!
    If you need support creating a custom plugin, feel free to DM MasterKingSirPlease#6533 or Sezei#3061.
    Alternatively, you could join the community server here: https://discord.gg/Y9cu3ZcvvG   
--]]

return function()
	local recentPositions,loopingUsers = {},{}

	local users = game:GetService('Players')

	users.PlayerAdded:Connect(function(user)
		user.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild('Humanoid')
			local rootPart = character:WaitForChild('HumanoidRootPart')
			humanoid.Died:Connect(function()
				recentPositions[user.UserId] = rootPart.CFrame
				if loopingUsers[user.UserId] then
					user:LoadCharacter() -- So they aren't respawned AFTER being teleported
					if user.Character:FindFirstChild('HumanoidRootPart') then
						user.Character:FindFirstChild('HumanoidRootPart').CFrame = recentPositions[user.UserId]
						SyncAPI:DisplayNotification(user,{
							Type = 'Sidebar',
							Title = 'Teleported your avatar back to its last known location before it died.',
							Time = 10,
							Icon = 'Check',
						})
					else
						SyncAPI:DisplayNotification(user,{
							Type = 'Sidebar',
							Title = 'An error occurred when trying to take you back to your previous location because your Humanoid Root Part has not loaded yet.',
							Time = 10,
							Icon = 'X',
							Sound = 'Error',
						})
					end
				end
			end)
		end)
	end)

	SyncAPI('Back').Create({
		Description = 'Teleports your avatar back to the last location it was before it died.\nPersists even if you leave and rejoin the server.',
		PermissionLevel = 1,
		Shorthand = {},
		Parameters = 'optional:auto/stop',
		Run = function(main,user,loop,...)
			if loop then
				if loop:lower() == 'auto' then
					if loopingUsers[user.UserId] then
						return false,'You\'re already doing this.',10
					end
					loopingUsers[user.UserId] = true
					return true,'You will now be returned to your last location whenever your avatar dies.',10
				elseif loop:lower() == 'stop' then
					if not loopingUsers[user.UserId] then
						return false,'You are not automatically setting your character\'s position back to where is was when it dies.',10
					end
					loopingUsers[user.UserId] = false
					return true,'You will no longer be automatically returned to your last location whenever your avatar dies and will have to manually execute the command in order to return.',10
				end
			end

			if user.Character and user.Character:FindFirstChild('HumanoidRootPart') and user.Character:FindFirstChild('HumanoidRootPart'):IsA('BasePart') then
				if recentPositions[user.UserId] then
					user.Character:FindFirstChild('HumanoidRootPart').CFrame = recentPositions[user.UserId]
					return true,'Teleported your avatar back to its last known location before it died.',10
				else
					return false,'There are no recent positions saved for you.',10
				end
			else
				return false,'You do not seem to have a Humanoid Root Part. Try refreshing your avatar to solve this issue.',10
			end
		end,
	})
end
