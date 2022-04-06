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
    Description             Kick command
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
	SyncAPI('Kick').Create({
		Description = 'Forcefully removes the specified user(s) from the server with an optional reason.',
		PermissionLevel = 1,
		Shorthand = 'Boot',
		Parameters = 'user(s) optional:reason',
		Run = function(main,user,users,...)
			local successList,failedList = {},{}
			for iteration,target in pairs(users) do
				if target == user then
					-- Just something a little fun
					failedList[user.DisplayName] = 'I think kicking yourself is like, borderline self-harm. Let\'s use this command on someone ELSE next time, okay?'
				end
				if SyncAPI:GetPermissionLevel(target) >= SyncAPI:GetPermissionLevel(user) then
					if user ~= target then -- Can't do and above
						failedList[target.DisplayName] = 'You lack sufficient power to remove them from the server, weakling.'
					end
				else
					table.insert(successList,target.DisplayName)
					target:Kick('By '..user.DisplayName..'\n'..game:GetService('Chat'):FilterStringAsync(table.concat({...},', '),user,target))
				end
			end
			for person,reason in pairs(failedList) do
				SyncAPI:DisplayNotification(user,{
					Type = 'Sidebar',
					Title = 'Could not remove '..person..': '..reason,
					Time = 10,
					Icon = 'X',
					Sound = 'Error',
				})
			end
			if #successList > 0 then
				return true,'Kicked '..table.concat(successList,', ')..' with reason "'..game:GetService('Chat'):FilterStringAsync(table.concat({...},', ')..'"'),8,users,'Disconnecting client...',3
			end
		end,
	})
end
