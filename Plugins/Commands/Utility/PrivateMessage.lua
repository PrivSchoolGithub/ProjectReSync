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
    Description             Privately messages a user
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
	local chat = game:GetService('Chat')
	
	local function reply(receiving,fromUser,toUser)
		if not toUser then
			return SyncAPI:DisplayNotification(fromUser,{
				Type = 'Sidebar',
				Title = 'The person you are trying to message has left the experience.',
				Icon = 'X',
				Sound = 'Error',
				Time = 8,
			})
		end
		SyncAPI:DisplayNotification(toUser,{
			Type = 'Sidebar',
			Icon = 'Exclamation',
			Title = 'Reply from '..fromUser.DisplayName..'. Click here to view.',
			Clicked = function()
				displayMessage(receiving,toUser,fromUser)
			end,
		})
	end
	
	function displayMessage(receiving,fromUser,toUser)
		SyncAPI:DisplayNotification(toUser,{
			Type = 'Popup',
			Title = 'Message from '..fromUser.DisplayName,
			Content = chat:FilterStringAsync(receiving,fromUser,toUser),
			Icon = 'Exclamation',
			Options = {
				'CLOSE',
				{
					Text = 'REPLY',
					Clicked = function()
						SyncAPI:DisplayNotification(toUser,{
							Type = 'User Input',
							Title = 'Reply to '..fromUser.DisplayName,
							Content = 'Type a response to '..fromUser.DisplayName..' in the box below.',
							Icon = 'Exclamation',
							Options = {
								{
									Text = 'CANCEL',
									Color = Color3.fromRGB(255,0,0)
								},
								{
									Text = 'SEND',
									Color = Color3.fromRGB(0,255,0),
									Clicked = function(response)
										reply(response,fromUser,toUser)
									end,
								},
							},
						})
					end,
				},
			},
		})
	end
	
	SyncAPI('PrivateMessage').Create({
		Description = 'Displays a message to the specified user(s) that they may optionally respond to.',
		PermissionLevel = 1,
		Shorthand = {'PersonalMessage','PM'},
		Parameters = 'user(s) message',
		Run = function(main,user,users,...)
			local list = {}
			local message = table.concat({...},' ')
			for iteration,target in pairs(users) do
				if chat:CanUsersChatAsync(user.UserId,target.UserId) then
					table.insert(list,target.DisplayName)
					SyncAPI:DisplayNotification(target,{
						Type = 'Sidebar',
						Icon = 'Exclamation',
						Title = 'New message from '..user.DisplayName..'. Click here to view.',
						Clicked = function()
							displayMessage(message,user,target)
						end,
					})
				else
					SyncAPI:DisplayNotification(user,{
						Type = 'Sidebar',
						Title = 'You are not allowed to chat with '..target.DisplayName..' because either your or their privacy settings forbid it.',
						Time = 9,
						Icon = 'X',
						Sound = 'Error',
					})
				end
			end
			return true,'Your message has been sent to '..table.concat(list,', ')..'.',8
		end,
	})
end
