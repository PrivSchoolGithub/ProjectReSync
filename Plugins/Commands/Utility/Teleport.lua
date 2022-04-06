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
    Description             This module contains four commands, each appearing in
    						this order:
    						Teleport
    						To
    						Bring
    						TeleportAsk
    						Each command serves a function of teleportation to/from
    						different CFrames in the current server
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

--//TPA Setting
local reqDelay = 300 -- Users cannot send another request to that person for 5 minutes after the last denial

return function()
	local function teleport(victim,target)
		if -- Very long if statement, so I broke it into multiple lines
			--//Character check
			victim.Character
			and target.Character
			--//HRP check
			and victim.Character:FindFirstChild('HumanoidRootPart')
			and target.Character:FindFirstChild('HumanoidRootPart')
			--//Humanoid check
			and victim.Character:FindFirstChild('Humanoid')
			--//Sit check then
			and victim.Character:FindFirstChild('Humanoid').Sit == false
		then
			local rootPart = victim.Character:FindFirstChild('HumanoidRootPart')
			rootPart.Velocity = Vector3.new() -- So if they're flying or moving fast nobody is flung
			rootPart.CFrame = target.Character:FindFirstChild('HumanoidRootPart').CFrame*CFrame.new(Vector3.new(math.random()-0.5,0,math.random()-0.5)*10)
			return true
		else
			return false
		end
	end
	
	SyncAPI('Teleport').Create({
		Description = 'Teleports the victim(s) to the target user. If no victim is specified, you will be teleported to yourself. If a victim is specified but not a target, the victim will be brought to you.',
		PermissionLevel = 1,
		Shorthand = 'TP',
		Parameters = 'optional:user(s) optional:user',
		Run = function(main,user,users,target)
			if not users then
				users = {user}
			end
			if not target then
				target = user
			end
			local successList,failList = {},{}
			for iteration,victim in pairs(users) do
				local success = teleport(victim,target)
				if success then
					table.insert(successList,victim)
				else
					table.insert(failList,victim.DisplayName)
				end
			end
			if #failList > 0 then
				for iteration,failure in pairs(failList) do
					SyncAPI:DisplayNotification(user,{
						Type = 'Sidebar',
						Title = 'Could not teleport '..failure..' to '..target.DisplayName..'. One of them is missing a Humanoid, HumanoidRootPart, or is currently sitting.',
						Time = 10,
						Icon = 'X',
						Sound = 'Error',
					})
				end
			end
			for iteration,teleported in pairs(successList) do
				SyncAPI:DisplayNotification(teleported,{
					Type = 'Sidebar',
					Icon = 'Exclamation',
					Title = user.DisplayName..' has teleported you to '..target.DisplayName..'.',
					Time = 8,
					Sound = 'Random',
				})
			end
			if #successList > 0 then
				return true,'Successfully teleported '..table.concat(successList,', ')..' to '..target.DisplayName..'.',8,{target},user.DisplayName..' has teleported '..#successList..(#successList > 1 and 'users' or 'user')..' to you.',7
			end
		end,
	})
	SyncAPI('To').Create({
		Description = 'Teleports you to the target user. If no target is specified, you will be teleported to yourself.',
		PermissionLevel = 1,
		Shorthand = 'TeleportTo',
		Parameters = 'optional:user',
		Run = function(main,user,target)
			if not target then
				target = user
			end
			local success = teleport(user,target)
			if success then
				return true,'Successfully teleported to '..target.DisplayName..'.',7,{target},user.DisplayName..' has teleported to you.',7
			else
				return false,'Cannot teleport at this time. One of you is missing a Humanoid, HumanoidRootPart, or is currently sitting.',7
			end
		end,
	})
	SyncAPI('Bring').Create({
		Description = 'Teleports the victims to you. If no victims are specified, you will be teleported to yourself.',
		PermissionLevel = 1,
		Shorthand = {'BringUsers','BringPlayers'},
		Parameters = 'optional:user(s)',
		Run = function(main,user,users)
			if not users then
				users = {user}
			end
			local successList,failList = {},{}
			for iteration,victim in pairs(users) do
				local success = teleport(victim,user)
				if success then
					table.insert(successList,victim)
				else
					table.insert(failList,victim.DisplayName)
				end
			end
			if #failList > 0 then
				for iteration,failure in pairs(failList) do
					SyncAPI:DisplayNotification(user,{
						Type = 'Sidebar',
						Title = 'Could not bring '..failure..' to you. One of you is missing a Humanoid, HumanoidRootPart, or is currently sitting.',
						Time = 10,
						Icon = 'X',
						Sound = 'Error',
					})
				end
			end
			for iteration,teleported in pairs(successList) do
				SyncAPI:DisplayNotification(teleported,{
					Type = 'Sidebar',
					Icon = 'Exclamation',
					Title = user.DisplayName..' has brought you to them.',
					Time = 8,
					Sound = 'Random',
				})
			end
			if #successList > 0 then
				return true,'Successfully brought '..table.concat(successList,', ')..' to you.',8
			end
		end,
	})
	local onCooldown = {}
	SyncAPI('TeleportAsk').Create({
		Description = 'Allows you to request to teleport to another user. They can then choose to either allow or deny your request. If no target is specified, you will be teleported to yourself.',
		PermissionLevel = 1,
		Shorthand = 'TPA',
		Parameters = 'optional:user',
		Run = function(main,user,target)
			if not target then
				target = user
			end
			
			if target == user then
				local success = teleport(user,user)
				if success then
					return true,'Teleported to yourself.',6
				else
					return false,'Could not teleport to yourself. You\'re missing a Humanoid, HumanoidRootPart, or are currently sitting.'
				end
			end
			
			if onCooldown[user] ~= nil and onCooldown[user][target] ~= nil then
				local timeRemaining = onCooldown[user][target]-tick()
				if timeRemaining > 0 then
					return false,'You cannot send '..target.DisplayName..' a request for another '..math.floor(timeRemaining/60)..' minutes and '..math.floor(timeRemaining%60)..' seconds.',8
				end
			end
			
			local returning
			
			local options = {
				{
					Text = 'ACCEPT',
					Color = Color3.fromRGB(0,255,0),
					Clicked = function()
						SyncAPI:DisplayNotification(target,{
							Type = 'Sidebar',
							Icon = 'Check',
							Sound = 'Complete',
							Title = 'Accepted '..user.DisplayName..'\'s teleport request.',
							Time = 8,
						})
						SyncAPI:DisplayNotification(user,{
							Type = 'Sidebar',
							Icon = 'Check',
							Sound = 'Complete',
							Title = target.DisplayName..' accepted your teleport request.',
							Time = 8,
						})
						returning = teleport(user,target)
					end,
				},
				{
					Text = 'DENY',
					Color = Color3.fromRGB(255,0,0),
					Clicked = function()
						SyncAPI:DisplayNotification(target,{
							Type = 'Sidebar',
							Icon = 'Check',
							Sound = 'Random',
							Title = 'Denied '..user.DisplayName..'\'s teleport request.',
							Time = 8,
						})
						SyncAPI:DisplayNotification(user,{
							Type = 'Sidebar',
							Icon = 'X',
							Sound = 'Error',
							Title = target.DisplayName..' denied your teleport request. You will not be able to send them another request for five minutes.',
							Time = 11,
						})
						if onCooldown[user] == nil then
							onCooldown[user] = {}
						end
						onCooldown[user][target] = tick()+reqDelay
					end,
				},
				'IGNORE',
			}
			
			SyncAPI:DisplayNotification(target,{
				Type = 'Popup',
				Icon = 'Question',
				Title = 'Teleport Request',
				Content = user.DisplayName..' wishes to teleport to you. Allow this?',
				Options = options,
			})
			
			repeat
				wait()
			until returning ~= nil
			
			if returning then
				return true,'Successfully teleported to '..target.DisplayName..'.',7,{target},user.DisplayName..' has teleported to you.',7
			else
				return false,'Cannot teleport at this time. One of you is missing a Humanoid, HumanoidRootPart, or is currently sitting.',9,{target},user.DisplayName..' could not teleport to you at this time. One of you is missing a Humanoid, HumanoidRootPart, or is currently sitting.',10
			end
		end,
	})
end
