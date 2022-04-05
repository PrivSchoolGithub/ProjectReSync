-- Notice of RSI

return function()
	local settingsUI = script:WaitForChild('RSSettings')
	settingsUI.Parent = game:GetService('ServerStorage')
	
	local debounce,currentEditor = script:WaitForChild('Debounce')
	
	debounce.Changed:Connect(function(property)
			-- I don't want to use wait() here because of issues with the command running
			if property == 'Value' and debounce.Value == true then
				wait(10)
				debounce.Value = false
			end
	end)
	
	game:GetService('Players').PlayerRemoving:Connect(function(leaving)
			if leaving == currentEditor then
				currentEditor = nil
			end
	end)
	
	local settings = CoreAPI:RetrieveSettings()
	
	CoreAPI('Settings').SetValues({
			Run = function(main,user)
				if CoreAPI.PullBlocked('Settings') then
					return false,currentEditor.Name..' is currently editing the settings.',10
				end
				CoreAPI:BlockPull('Settings',true)
				currentEditor = user
				local settingsClone = settingsUI:Clone()
				settingsClone.Parent = user:WaitForChild('PlayerGui')
				settingsClone:FindFirstChild('ServerGateway'):FireClient(user,settings)
				settingsClone:FindFirstChild('ServerGateway').OnServerEvent:Connect(function(person,option,submitting)
						SyncAPI:DisplayNotification(person,{
								Type = 'Sidebar',
								Title = 'Verifying...',
								Icon = 'Exclamation',
								Time = 3,
						})
						if person ~= user then
							if SyncAPI.AntiExploitEnabled then
								user:Kick('\nAn error occurred.') -- Keeping it generic, not too specific
							end
							return false,'An error occurred.',8
						end
						if SyncAPI:GetPermissionLevel(user) < settings.Permissions.ViewRank then
							currentEditor = nil
							settingsClone:ClearAllChildren()
							settingsClone:Destroy()
							return false,'Access denied.',5
						end
						if option == 'Close' then
							currentEditor = nil
							settingsClone:ClearAllChildren()
							settingsClone:Destroy()
						elseif option == 'Save' then
							if SyncAPI:GetPermissionLevel(user) < settings.Permissions.EditRank then
								return false,'You do not have permission to make changes to the settings.',10
							end
							if debounce.Value == true then
								return false,'Please wait for a bit before attempting to submit new settings.',10
							end
							if submitting.General ~= settings.General then
								if not CoreAPI:CheckBaseAdmin(user) then
									return false,'Only Root Administrators are permitted to make changes to the General settings.',10
								end
							end
							if settings == submitting then
								return false,'🤔 Shouldn\'t you make changes first?',5
							end
							-- All checks should have been made by now, so we're good to tell the server that
							-- it's okay to submit the settings changes
							SyncAPI:DisplayNotification(user,{
									Type = 'Sidebar',
									Title = 'Submitting...',
									Icon = 'Question Mark',
									Time = 3,
							})
							debounce.Value = true
							local changes = CoreAPI:SubmitSettings(submitting)
							for iteration,edit in pairs(changes) do
								SyncAPI:DisplayNotification(user,{
										Type = 'Sidebar',
										Title = change,
										Icon = 'Check',
										Time = 8,
								})
							end
							return true,'Made '..tostring(#changes)..' changes to the settings.',10
						end
				end)
				settingsClone.Enabled = true
			end,
	})
end
