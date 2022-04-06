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
    Description             Sends user to another experience/place
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
	SyncAPI('Place').Create({
		Description = 'Requests for the specified user(s) to teleport to the given place. If "true" or "force" is specified as the final parameter, they are teleported without requesting confirmation.',
		PermissionLevel = 1,
		Parameters = 'user(s) number optional:true/force',
		Run = function(main,user,users,placeID,force)
			local MPS = game:GetService('MarketplaceService')
			local TPS = game:GetService('TeleportService')
			local placeInfo
			local success,failed = pcall(function()
				placeInfo = MPS:GetProductInfo(placeID)
			end)
			if not placeInfo then
				return false,'Place does not exist. Verify that the ID is correct and then try again.',8
			end
			local placeName = placeInfo.Name
			local placeOwner = placeInfo.Creator.Name
			
			if #users > 50 then
				return false,'Roblox doesn\'t allow a mass teleport of over 50 users at once. Try teleporting people in smaller groups.',10
			end
			
			local function sendToPlace(people)
				local teleportSuccess,teleportFailure = pcall(function()
					TPS:TeleportAsync(placeID,people,nil)
				end)
				if not teleportSuccess then
					return false,'Teleport failure: '..teleportFailure,8,people,'An error occurred when trying to teleport you.',8
				else
					local personNotify = 'person'
					if #people > 1 then
						personNotify = 'people'
					end
					return true,'Successfully teleported '..#people..' '..personNotify..' to '..placeName..'.',8,people,user.DisplayName..' is moving you to '..placeName..' by '..placeOwner..'...',8
				end
			end
			
			local list = {}
			if force then
				if force:lower() == 'true' or force:lower() == 'force' then
					if SyncAPI:GetPermissionLevel(user) < 3 then
						return false,'Only Super Administrators are permitted to force-place users.',8
					end
					for iteration,target in pairs(users) do
						table.insert(list,target.DisplayName)
					end
					SyncAPI:DisplayNotification(user,{
						Type = 'Hint',
						Icon = 'Exclamation',
						Title = 'Now sending '..table.concat(list,', ')..' to '..placeName..'...',
						Time = 5,
					})
					return sendToPlace(users)
				end
			else
				for iteration,target in pairs(users) do
					table.insert(list,target.DisplayName)
					SyncAPI:DisplayNotification(target,{
						Type = 'Sidebar',
						Icon = 'Question',
						Title = 'New request from '..user.DisplayName..'. Click to view & respond.',
						-- No timer
						Clicked = function()
							SyncAPI:DisplayNotification(target,{
								Type = 'Popup',
								Title = 'Teleport Request',
								Content = user.DisplayName..' is prompting you to go to '..placeName..' by '..placeOwner..'.\nDo you want to go there?',
								Icon = 'Question',
								Options = {
									{
										Text = 'NO',
										Color = Color3.fromRGB(255,0,0),
										Clicked = function()
											SyncAPI:DisplayNotification(user,{
												Type = 'Sidebar',
												Title = target.DisplayName..' does not want to go to '..placeName..'.',
												Time = 8,
												Icon = 'X',
												Sound = 'Random',
											})
										end,
									},
									{
										Text = 'YES',
										Color = Color3.fromRGB(0,255,0),
										Clicked = function()
											SyncAPI:DisplayNotification(user,{
												Type = 'Sidebar',
												Title = target.DisplayName..' wants to go to '..placeName..'.',
												Time = 8,
												Icon = 'Check',
											})
											SyncAPI:DisplayNotification(user,{
												Type = 'Hint',
												Icon = 'Exclamation',
												Title = 'Now sending '..target.DisplayName..' to '..placeName..'...',
												Time = 5,
											})
											sendToPlace({target})
										end,
									},
								}
							})
						end,
					})
				end
				return true,'Request successfully sent to '..table.concat(list,', ')..'. They will be prompted to go to '..placeName..' by '..placeOwner..'.',12
			end
		end,
	})
end
