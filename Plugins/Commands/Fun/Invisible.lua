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
    Description             Invisibility cloak
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
	local invisibleParts = {}
	
	game:GetService('Players').PlayerRemoving:Connect(function(user)
		invisibleParts[user.UserId] = nil
	end)
	
	SyncAPI('Invisible').Create({
		Description = 'Turns the specified user(s)\'s character(s) invisible. If no user is specified, will make you invisible.',
		PermissionLevel = 1,
		Shorthand = {'Invis','Vanish'},
		Parameters = 'optional:user(s)',
		Run = function(main,user,users)
			if not users then
				users = {user}
			end
			local list = {}
			for iteration,target in pairs(users) do
				if not invisibleParts[target.UserId] then
					invisibleParts[target.UserId] = {}
					table.insert(list,target.DisplayName)
					local function recursive(char)
						for _,item in pairs(char:GetChildren()) do
							recursive(item)
							if item:IsA('BasePart') or item:IsA('Decal') then
								invisibleParts[target.UserId][item] = item.Transparency
								item.Transparency = 1
							end
						end
					end
					recursive(target.Character)
				end
			end
			if #list > 0 then
				return true,'Made '..table.concat(list,', ')..' invisible.',8,users,user.DisplayName..' has made you invisible.',8
			else
				return false,'All users specified are already invisible.',8
			end
		end,
	})
	SyncAPI('Visible').Create({
		Description = 'Removes invisibility from the specified user(s). If no user is specified, will turn you visible.',
		PermissionLevel = 1,
		Shorthand = {'Vis','Appear','Reappear'},
		Parameters = 'optional:user(s)',
		Run = function(main,user,users)
			if not users then
				users = {user}
			end
			local list = {}
			for iteration,target in pairs(users) do
				if invisibleParts[target.UserId] ~= nil then
					table.insert(list,target.DisplayName)
					for part,trans in pairs(invisibleParts[target.UserId]) do
						part.Transparency = trans
					end
					invisibleParts[target.UserId] = nil
				end
			end
			if #list > 0 then
				return true,'Made '..table.concat(list,', ')..' visible.',8,users,user.DisplayName..' has made you visible to others.',8
			else
				return false,'All users specified are already visible.',8
			end
		end,
	})
end
