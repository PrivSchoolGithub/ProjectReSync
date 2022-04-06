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
    Description             Character command to change appearance
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
	local function refresh(target)
		local cFrame = target.Character:FindFirstChild('HumanoidRootPart').CFrame
		wait()
		target:LoadCharacter()
		repeat
			wait()
		until target.Character ~= nil and target.Character:FindFirstChild('HumanoidRootPart') or target == nil
		target.Character:FindFirstChild('HumanoidRootPart').CFrame = cFrame
	end
	SyncAPI('Character').Create({
		Description = 'Changes the user(s)\'s character appearance to match that of the person with the specified username.',
		PermissionLevel = 1,
		Shorthand = {'Char'},
		Parameters = 'user(s) person',
		Run = function(main,user,users,person)
			local list = {}
			for iteration,target in pairs(users) do
				if target.Character:FindFirstChild('HumanoidRootPart') then
					-- If it fails, the command will just throw an error at the user
					local charID
					local success = pcall(function()
						charID = game:GetService('Players'):GetUserIdFromNameAsync(person)
					end)
					if not success then
						return false,'User "'..person..'" does not exist.',8
					end
					person = game:GetService('Players'):GetNameFromUserIdAsync(charID)
					target.CharacterAppearanceId = charID
					refresh(target)
					table.insert(list,target.DisplayName)
				else
					SyncAPI:DisplayNotification(user,{
						Type = 'Sidebar',
						Icon = 'X',
						Sound = 'Error',
						Time = 5,
						Title = target.DisplayName..'\'s avatar could not be converted because they\'re missing a HumanoidRootPart. Try refreshing them.'
					})
				end
			end
			return true,'Changed character appearance of '..table.concat(list,', ')..' to '..person..'.',8,users,user.DisplayName..' has changed your character to '..person..'.',8
		end,
	})
	SyncAPI('ResetCharacterAppearance').Create({
		Description = 'Resets the user(s)\'s character appearance to their own. If no user is specified, will reset your own appearance.',
		PermissionLevel = 1,
		Shorthand = {'UnChar'},
		Parameters = 'optional:user(s)',
		Run = function(main,user,users)
			local list = {}
			if not users then
				users = {user}
			end
			for iteration,target in pairs(users) do
				if target.Character:FindFirstChild('HumanoidRootPart') then
					if target.CharacterAppearanceId ~= target.UserId then
						target.CharacterAppearanceId = target.UserId
					end
					refresh(target)
					table.insert(list,target.DisplayName)
				else
					SyncAPI:DisplayNotification(user,{
						Type = 'Sidebar',
						Icon = 'X',
						Sound = 'Error',
						Time = 5,
						Title = target.DisplayName..'\'s avatar could not be converted because they\'re missing a HumanoidRootPart. Try refreshing them.'
					})
				end
			end
			return true,'Reset character appearance of '..table.concat(list,', '),8,users,user.DisplayName..' has reset your charater\'s appearance.',8
		end,
	})
end
