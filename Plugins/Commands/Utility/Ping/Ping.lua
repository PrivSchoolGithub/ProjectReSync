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
    Description             Performs connection tests upon execution
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
	local httpService = game:GetService('HttpService')
	
	local remote = script:WaitForChild('Send')
	remote.Parent = game:GetService('ReplicatedStorage')
	remote.Name = 'RSCSPing'
	
	local function round(num1,num2)
		local mult = 10^(num2 or 0)
		return math.floor(num1*mult+0.5) / mult
	end
	
	SyncAPI('Ping').Create({
		Description = 'Returns connection statistics based on Client or Server connection.',
		PermissionLevel = 0,
		Shorthand = {'Tick','Lag'},
		Parameters = 'client/server/c/s',
		Run = function(main,user,option)
			if option:lower() == 'client' or option:lower() == 'c' then
				SyncAPI:DisplayNotification(user,{
					Type = 'Sidebar',
					Title = 'Testing Client\'s connection to Server...',
					Time = 5,
					Icon = 'Question',
					Sound = 'Random',
				})
				-- Would use PlayerScripts but Server can't access those :(
				local userGUI = user:WaitForChild('PlayerGui')
				local conScript
				if not userGUI:FindFirstChild('RSTestConnection') then
					conScript = script:FindFirstChild('TestConnection'):Clone()
					conScript.Parent = userGUI
					conScript.Name = 'RSTestConnection'
				end
				local pingTime = 1e9
				local ok,issue = pcall(function()
					local random = math.random(0,pingTime)
					local initialTick = tick()
					local result = remote:InvokeClient(user,random)
					if result == random then
						pingTime = tick() - initialTick
					end
				end)
				if ok then
					conScript:Destroy()
					
					local delayStat = 'Laggy'
					if round(pingTime,2) <= 0.020 then
						delayStat = 'Optimal'
					elseif round(pingTime,2) <= 0.050 then
						delayStat = 'No noticeable delay'
					elseif round(pingTime,2) <= 0.080 then
						delayStat = 'Slight delay'
					elseif round(pingTime,2) <= 0.130 then
						delayStat = 'Some delay'
					elseif round(pingTime,2) <= 0.180 then
						delayStat = 'Laggy'
					end
					
					return true,'Your ping is '..math.floor(pingTime*1000)..' milliseconds ('..delayStat..')',10
				else
					return false,'An error occurred with your request.',10
				end
			elseif option:lower() == 'server' or option:lower() == 's' then
				if SyncAPI:GetPermissionLevel(user) < 2 then
					return false,'For security reasons, only Administrators+ can view the server status.'
				end
				
				local tick1 = tick()
				local actualWait = wait()
				local tick2 = tick()
				local wait1 = math.abs(tick1-tick2)
				
				local TPSValue = 'Very bad'
				if round(1/wait1,2) >= 32 then -- 32 - 33.33
					TPSValue = 'Perfect'
				elseif round(1/wait1,2) >= 30 then -- 30 - 31.99
					TPSValue = 'Optimal'
				elseif round(1/wait1,2) >= 27 then -- 27 - 29.99
					TPSValue = 'Good'
				elseif round(1/wait1,2) >= 23 then -- 23 - 26.99
					TPSValue = 'Fair'
				elseif round(1/wait1,2) >= 20 then -- 20 - 22.99
					TPSValue = 'Poor'
				end
				
				local accuracy = 'Very inaccurate'
				if round((math.abs(actualWait-math.abs(tick1-tick2))*100),5) <= 0.0005 then
					accuracy = 'Perfect'
				elseif round((math.abs(actualWait-math.abs(tick1-tick2))*100),5) <= 0.001 then
					accuracy = 'Very accurate'
				elseif round((math.abs(actualWait-math.abs(tick1-tick2))*100),5) <= 0.002 then
					accuracy = 'Accurate'
				elseif round((math.abs(actualWait-math.abs(tick1-tick2))*100),5) <= 0.005 then
					accuracy = 'Fairly accurate'
				elseif round((math.abs(actualWait-math.abs(tick1-tick2))*100),5) <= 0.01 then
					accuracy = 'Likely inaccurrate'
				elseif round((math.abs(actualWait-math.abs(tick1-tick2))*100),5) <= 0.02 then
					accuracy = 'Inaccurate'
				end
				
				local display = '<INSERT TEXT BOX>\n<EDIT FONT &SIZE:18>\nServer TPS\n<RESET FONT>\n<INSERT LINE &COLOR:255,255,255>\n'..tostring(round(1/wait1,2))..'\n['..round(wait1,3)..']\n('..TPSValue..')\n<EXIT TEXT BOX>\n<EDIT FONT &SIZE:18>\n<INSERT TEXT BOX>\nwait() Accuracy\n<INSERT LINE &COLOR:255,255,255>\n<RESET FONT>\n'..tostring(round((math.abs(actualWait-math.abs(tick1-tick2))*100),5))..' ('..accuracy..')\n<EXIT TEXT BOX>\n<EDIT FONT &SIZE:18>\n<INSERT TEXT BOX &COLOR:'
				
				local webCon = 'Web Connection\n<RESET FONT>\n<INSERT LINE &COLOR:255,255,255>\n'
				
				local function checkHttp()
					return pcall(function()
						task.spawn(function()
							httpService:GetAsync('https://google.com')
						end)
					end)
				end
				
				local httpCheck,httpIssue = checkHttp()
				if httpCheck then
					display = display..'0,221,73>\n'..webCon..'Connected to the web'
				else
					display = display..'253,79,56>\n'..webCon..'Not connected to the web'
				end
				
				display = display..'\n<EXIT TEXT BOX>\n<INSERT TEXT BOX &COLOR:'
				
				local APIStat = '>\n<EDIT FONT &SIZE:18>\nEndpoint Status\n<RESET FONT>\n<INSERT LINE &COLOR:255,255,255>\n'
				local response = 'Unreachable'
				
				local tick3 = tick()
				local APIresponse = httpService:GetAsync('http://api.sezei.me/')
				
				if APIresponse then
					local tick4 = tick()
					local responsiveness = round((math.abs(math.abs(tick3-tick4))*1000),2)
					if responsiveness <= 30 then
						response = 'Lightning fast'
					elseif responsiveness <= 60 then
						response = 'Very fast'
					elseif responsiveness <= 100 then
						response = 'Fast'
					elseif responsiveness <= 150 then
						response = 'Fairly fast'
					elseif responsiveness <= 250 then
						response = 'Fairly slow'
					elseif responsiveness <= 450 then
						response = 'Slow'
					elseif responsiveness < 450 then
						response = 'Very slow'
					end
					response = tostring(responsiveness)..' ('..response..')'
				end
				
				local color = '11,158,255'
				
				if response == 'Unreachable then' then
					color = '0,0,0'
				end
				
				display = display..color..APIStat..response..'\n<EXIT TEXT BOX>'
				
				SyncAPI:DisplayNotification(user,{
					Type = 'List',
					Title = 'SERVER STATUS',
					Text = display,
					CloseButtonText = 'CLOSE',
				})
			else
				return false,'Option must be either "Client" or "Server."',10
			end
		end,
	})
end
