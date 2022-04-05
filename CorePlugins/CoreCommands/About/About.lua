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
    Description             Displays information about ReSync
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
	SyncAPI('About').Create({
		Description = 'Displays information about Project ReSync.',
		PermissionLevel = 0,
		Shorthand = {'Help','RSInfo'},
		Run = function(main,user)
			SyncAPI:DisplayNotification(user,{
				Type = 'Popup',
				Title = 'Project ReSync',
				Text = 'SyncAdmin is an open API administration system.\nCreativity at your fingertips with SyncAdmin custom plugins.\n\nPolymatic Labs Limited\nCompany Number: 10603790\nRegistered in England',
				Icon = 'Logo',
				Options = {
					{
						Text = 'Close',
						Color = Color3.new(1,0,0),
					},
					{
						Text = 'Get ReSync',
						Color = Color3.new(0,1,0),
					},
					{
						Text = 'Donate',
						Color = Color3.new(0,1,0),
					},
					{
						Text = 'Terms of Use/Service',
						Color = Color3.new(0,1,1),
						Clicked = function()
							SyncAPI:DisplayNotification(user,{
								Type = 'List',
								Title = 'TERMS OF SERVICE',
								Text = require(script:WaitForChild('_TOS')),
								Height = 800,
								Width = 600,
								CloseButtonText = 'CLOSE',
							})
						end,
					},
				},
			})
		end,
	})
end
