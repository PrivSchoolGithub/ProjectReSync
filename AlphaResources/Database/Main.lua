
return {
	Plugin = function()
		local users = game:GetService('Players')
		local loggedIn = {false,nil}
		local dStore = game:GetService('DataStoreService'):GetDataStore('User Accounts')
		local tempStore = game:GetService('DataStoreService'):GetDataStore('Accounts Awaiting Approval')
		local httpService = game:GetService('HttpService')
		
		local menuPopup,manageReSync
		
		local yeet = ''
		
		local function testPTSV2()
			local lua = {
				Hello = 'HI!',
			}
			local encoded = httpService:JSONEncode(lua)
			yeet = httpService:PostAsync('http://ptsv2.com/t/ReSync/post',encoded)
		end
		
		testPTSV2()
		
		print(yeet)
		
		local tbl = httpService:GetAsync(yeet)
		print(tbl)
		local decoded = httpService:JSONDecode(tbl)
		for a,b in next,decoded do
			print(b)
		end
		
		local function auth()
			if not SyncAPI:CheckHTTP() then -- authorizeShutdown/authSD
				return false,SyncAPI:EmergencyShutdown()
			end
			local status = SyncAPI:RequestEndpoint('https://putsreq.com/ReSync')
			if status.Code ~= 204 then
				return false,status
			end
			local serverResponse = SyncAPI:SubmitHTTPRequest(status.URL,{
					JSONEncode = true,
					Post = {
						Method = 'GET',
						Trello = true,
						PTS = true,
					},
			})
			if serverResponse['Status Code'][1] ~= 201 then
				return false,serverResponse
			end
			return true,serverResponse
		end
		
		local trelloAPI = require(0) -- Trello module
		
		local function submitSettings(user,directory,submitting)
			local username = loggedIn[2]
			local success,response = auth()
			if not success then
				return SyncAPI:DisplayNotification({
						Target = user,
						Type = 'Popup',
						Title = tostring('HTTP '..response['Status Code'][1]..' ('..response['Status Code'][2]..')'),
						Info = response.Description,
						Options = {
							{
								Text = 'RETURN',
								Clicked = function()
									manageReSync(user)
								end,
							},
						}
					})
			end
			local trelloURL,ptsURL = response.Data.Trello,response.Data.PostTestServer
			local JSONURL = SyncAPI:SubmitHTTPRequest(ptsURL,{
					JSONEncode = true,
					Post = submitting,
			})
			-- Get Trello here & post async
		end

		local function displayAboutList(user)
			local about = require(script:FindFirstChild('RSInfo')) -- Require about module
			SyncAPI:DisplayNotification({
				Target = user,
				Type = 'List',
				Title = 'About ReSync',
				Text = about,
				Height = 600,
				Width = 800,
				CloseButtonText = 'CLOSE',
				Clicked = function()
					menuPopup(user)
				end,
			})
		end

		local function displayDonorMenu(user)
			-- NOTE: Prompt purchase MUST be a dev product that can be bought MULTIPLE times!!
			SyncAPI:DisplayNotification({
				Target = user,
				Type = 'Popup',
				Title = 'Donor Menu',
				Icon = 7406487334, -- Robux
				Info = 'If you appreciate the system and would like to support the creators and encourage us to do more, feel free to donate here.\nYou can buy it more than once if you\'re feeling excessively generous ;)\nRefund policy: No refunds.',
				Options = {
					{
						Text = 'MENU',
						Clicked = function()
							menuPopup(user)
						end,
					},
					{
						Text = 'R$ 5',
						Color = Color3.fromRGB(255,217,0),
						Clicked = function()
							-- Prompt purchase
						end,
					},
					{
						Text = 'R$ 10',
						Color = Color3.fromRGB(255,191,0),
						Clicked = function()
							-- Prompt purchase
						end,
					},
					{
						Text = 'R$ 25',
						Color = Color3.fromRGB(255,157,0),
						Clicked = function()
							-- Prompt purchase
						end,
					},
					{
						Text = 'R$ 50',
						Color = Color3.fromRGB(255,218,0),
						Clicked = function()
							-- Prompt purchase
						end,
					},
					{
						Text = 'R$ 75',
						Color = Color3.fromRGB(255,102,0),
						Clicked = function()
							-- Prompt purchase
						end,
					},
					{
						Text = 'R$ 100',
						Color = Color3.fromRGB(255,42,0),
						Clicked = function()
							-- Prompt purchase
						end,
					},
				},
			})
		end

		local function signUp(user)
			local toS = require(script:FindFirstChild('RSInfo')) -- TOS Module
			local firstScreen,termsScreen,creationScreen
			firstScreen = function()
				SyncAPI:DisplayNotification({
					Target = user,
					Type = 'Popup',
					Title = 'End-user Agreement',
					Info = 'Please read and agree to the terms and conditions of using the software before continuing.',
					Options = {
						{
							Text = 'MENU',
							Clicked = function()
								menuPopup(user)
							end,
						},
						{
							Text = 'TOS',
							Color = Color3.fromRGB(25,226,237),
							Clicked = function()
								termsScreen()
							end,
						},
						{
							Text = 'AGREE',
							Color = Color3.fromRGB(23,237,106),
							Clicked = function()
								creationScreen()
							end,
						},
					},
				})
			end
			termsScreen = function()
				SyncAPI:DisplayNotification({
					Target = user,
					Type = 'List',
					Title = 'Terms of Use & Service',
					Text = toS,
					CloseButtonText = 'CLOSE',
					Clicked = function()
						firstScreen()
					end,
				})
			end
			creationScreen = function()
				SyncAPI:DisplayNotification({
					Target = user,
					Type = 'User Input',
					Title = 'Create Account',
					Info = 'What Should People Call You?',
					PlaceholderText = 'Enter a username...',
					Options = {
						{
							Text = 'CANCEL',
							Color = Color3.fromRGB(255,0,0),
							Clicked = function()
								firstScreen()
							end,
						},
						{
							Text = 'PROCEED',
							Color = Color3.fromRGB(0,255,42),
							Clicked = function(returnedString)
								if returnedString == nil or returnedString == '' or string.sub(returnedString,3) == '' or string.match(returnedString,' ') then
									creationScreen()
									return SyncAPI:DisplayNotification({
										Target = user,
										Type = 'Hint',
										Title = 'Username must be at least three characters long and cannot contain spaces.',
										Icon = 'X',
										Time = 10,
									})
								end
								if tempStore:GetAsync(returnedString) or dStore:GetAsync(returnedString) then
									creationScreen()
									return SyncAPI:DisplayNotification({
										Target = user,
										Type = 'Hint',
										Title = returnedString..' is taken, please try a different username. (You could try with a different letter case, as it is case sensitive)',
										Icon = 'X',
										Time = 10,
									})
								end
								local function finalize(password,twoFA) -- 2fa name err
									tempStore:SetAsync(returnedString,{CreatorID = user.UserId,CreationTime = tostring(os.time),Password = password,twoFA = twoFA})
									--//POST ASYNC TO DISCORD!!
									-- Returns to Main Menu
									SyncAPI:DisplayNotification({
										Target = user,
										Type = 'Popup',
										Title = 'Congratulations!',
										Info = 'Your account is pending creation. It must be verified by Support before it can be used.\nPlease feel free to contact Support if there is no response within 24 hours.',
										Time = 15,
									})
									wait(17)
									menuPopup(user)
								end
								SyncAPI:DisplayNotification({
									Target = user,
									Type = 'User Input',
									Title = 'Create a Password',
									Info = '',
									PlaceholderText = 'Enter a password...',
									Options = {
										{
											Text = 'CANCEL',
											Color = Color3.fromRGB(255,0,0),
											Clicked = function()
												firstScreen()
											end,
										},
										{
											Text = 'SUBMIT',
											Color = Color3.fromRGB(0,255,42),
											Clicked = function(password)
												if password == nil or string.sub(password,5) == '' then
													creationScreen()
													return SyncAPI:DisplayNotification({
														Target = user,
														Type = 'Hint',
														Title = 'Your password must be at least five characters to be a strong password.',
														Icon = 'X',
														Time = 10,
													})
												end
												SyncAPI:DisplayNotification({
													Target = user,
													Type = 'Popup',
													Title = 'Two-factor Authentication',
													Info = 'If this is enabled, you will only be able to access your ReSync account from your Roblox user account.\nThis is not recommended if you\'re using a shared account or an account for a group.\nThis CAN be changed later in your account settings.',
													Icon = '60950630', --lock icon
													Options = {
														{
															Text = 'DON\'T USE',
															Color = Color3.fromRGB(255,0,0),
															Clicked = function()
																finalize(password,false)
															end,
														},
														{
															Text = 'USE 2FA',
															Color = Color3.fromRGB(0,255,42),
															Clicked = function()
																finalize(password,true)
															end,
														},
													},
												})
											end,
										},
									},
								})
							end,
						},
					},
				})
			end
			firstScreen()
		end

		local function signIn(user)
			local firstScreen,promptLogin
			promptLogin = function(account)
				SyncAPI:DisplayNotification({
					Target = user,
					Type = 'User Input',
					Title = 'Account Validation',
					Info = '',
					PlaceholderText = 'Input your password...',
					Options = {
						{
							Text = 'BACK',
							Color = Color3.fromRGB(255,0,0),
							Clicked = function()
								firstScreen()
							end,
						},
						{
							Text = 'ENTER',
							Color = Color3.fromRGB(),
							-- WHERE I LEFT OFF
						},
					},
				})
			end
			firstScreen = function()
				SyncAPI:DisplayNotification({
					Target = user,
					Type = 'User Input',
					Title = 'Login',
					PlaceholderText = '[CASE SENSITIVE] Enter your username...',
					Options = {
						{
							Text = 'MENU',
							Clicked = function()
								menuPopup(user)
							end,
						},
						{
							Text = 'CONTINUE',
							Color = Color3.fromRGB(0,255,42),
							Clicked = function(username)
								if not dStore:GetAsync(username) and username ~= 'ADMIN' then
									firstScreen()
									return SyncAPI:DisplayNotification({
										Target = user,
										Type = 'Hint',
										Title = 'Account does not exist. Check your spelling and try again, or sign up for a new account from the Main Menu.',
										Icon = 'X',
									})
								end
								if username ~= 'ADMIN' then
									local account = dStore:GetAsync(username)
									if account.twoFA then
										if account.CreatorID ~= user.UserId then
											firstScreen()
											return SyncAPI:DisplayNotification({
												Target = user,
												Type = 'Hint',
												Title = username..' has 2FA enabled on their account. You must sign into the account with the Roblox account that made it.',
												Icon = 'X',
											})
										end
										promptLogin(account)
									else
										promptLogin(account)
									end
								else
									-- Username is ADMIN
									SyncAPI:DisplayNotification({
										Target = user,
										Type = 'User Input',
										Title = 'Administrator Login',
										Info = 'Enter the Admin password to proceed.',
										Icon = '5898573541', -- Admin shield
										PlaceholderText = 'Network Security Key...',
										Options = {
											{
												Text = 'CANCEL',
												Color = Color3.new(1,0,0),
												Clicked = function()
													firstScreen()
												end,
											},
											{
												Text = 'SUBMIT',
												Color = Color3.fromRGB(0,255,42),
												Clicked = function(key)
													-- Roses are red; ReSync is blue. You will dead; when I come after you!
													if key ~= '[REDACTED]' then -- Redacted when moved into public Alpha directory
														firstScreen()
														return SyncAPI:DisplayNotification({
															Target = user,
															Type = 'Hint',
															Title = 'Invalid Network Key, returning to menu...',
															Icon = 'X',
														})
													else
														loggedIn = {true,'ADMIN'}
														menuPopup(user)
														SyncAPI:DisplayNotification({
															Target = user,
															Type = 'Sidebar',
															Title = 'You have been given Root permissions.',
															Time = 10,
														})
														return SyncAPI:DisplayNotification({
															Target = user,
															Type = 'Hint',
															Title = 'Successfully logged in as System Administrator.',
															Icon = 'Check',
														})
													end
												end,
											},
										},
									})
								end
							end,
						},
					},
				})
			end
			firstScreen(user)
		end

		local function forgotAccount(user)
		end

		local function accountMenu(user)
			SyncAPI:DisplayNotification({
				Target = user,
				Type = 'Popup',
				Title = 'Account Menu',
				Info = 'Select an option to continue.',
				Options = {
					{
						Text = 'MENU',
						Clicked = function()
							menuPopup(user)
						end,
					},
					{
						Text = 'SIGN IN',
						Color = Color3.fromRGB(85,0,255),
						Clicked = function()
							signIn(user)
						end,
					},
					{
						Text = 'CREATE ACCOUNT',
						Color = Color3.fromRGB(158,127,219),
						Clicked = function()
							signUp(user)
						end,
					},
					{
						Text = 'LOST CREDENTIALS',
						Color = Color3.fromRGB(237,61,26),
						Clicked = function()
							forgotAccount(user)
						end,
					},
				},
			})
		end

		manageReSync = function(user)
			if not loggedIn[1] then
				return SyncAPI:DisplayNotification({
					Target = user,
					Type = 'Popup',
					Title = 'Validation Failed',
					Icon = 'X',
					Info = 'Your login credentials are invalid. This might be because you forgot to sign in or you have provided an invalid username/password.',
					Options = {
						{
							Text = 'MENU',
							Clicked = function()
								menuPopup(user)
							end,
						},
						{
							Text = 'SIGN IN',
							Color = Color3.fromRGB(85,0,255),
							Clicked = function()
								accountMenu(user)
							end,
						},
					}
				})
			end
			-- Validated!
			SyncAPI:DisplayNotification({
				Target = user,
				Type = 'Popup',
				Title = 'Options',
				Icon = 'Question Mark',
				Info = 'Selecting VIEW will display a list of your current synced settings.\nSelecting NEW will create a new directory.\nSelecting EDIT will allow you to edit a currently existing directory.',
				Options = {},
			})
		end

		menuPopup = function(user)
			local optionsList = {
				{
					Text = 'LEARN MORE',
					Color = Color3.fromRGB(50,168,82),
					Clicked = function()
						displayAboutList(user)
					end,
				},
				{
					Text = 'DONATE',
					Color = Color3.fromRGB(135,50,168),
					Clicked = function()
						displayDonorMenu(user)
					end,
				},
				{
					Text = 'MANAGEMENT',
					Color = Color3.fromRGB(61,184,212),
					Clicked = function()
						manageReSync(user)
					end,
				},
			}
			if not loggedIn[1] then
				table.insert(optionsList,{
					Text = 'SIGN IN',
					Color = Color3.fromRGB(85,0,255),
					Clicked = function()
						accountMenu(user)
					end,
				})
			end
			SyncAPI:DisplayNotification({
				Target = user,
				Type = 'Popup',
				Title = 'Welcome to ReSync!',
				Info = 'ReSync is a plugin system to help you manage your experiences. It comes with an admin system and easy-to-use API.',
				Icon = 'ReSync Logo',
				Options = optionsList,
			})
		end

		users.PlayerAdded:Connect(function(user)
			menuPopup(user)
		end)
	end
}
