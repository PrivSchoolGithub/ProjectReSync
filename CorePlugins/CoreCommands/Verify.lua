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
    Description             Verifies whether or not the user in question is a valid
    						member of the RS staff team.

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
	SyncAPI('Verify').Create({
		Description = 'Verifies whether or not the user in question is an official member of the ReSync staff team.',
		PermissionLevel = 0,
		Parameters = 'user',
		Run = function(main,user,target)
			local name = target.Name
			if target.Name ~= target.DisplayName then
				name = name..' (@'..target.DisplayName..')'
			end
			if CoreAPI:CheckSupportStaff(target) then
				return true,name..' is ReSync support verified. It is safe to give them access to your settings.',10
			else
				return false,name..' is not ReSync support verified. Ensure that you trust them personally before allowing them access to your settings.',10
			end
		end,
	})
end
