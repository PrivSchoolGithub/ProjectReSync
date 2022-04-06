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
    Authors                 MasterScootScoot, lukezammit
    Description             Loads in a user's friends
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
	--//Code by lukezammit
	local players = game:GetService("Players");
	
	local V3, CF, CA, rad = Vector3.new, CFrame.new, CFrame.Angles, math.rad;
	local C3, fromRgb = Color3.new, Color3.fromRGB

	local runService = game:GetService("RunService");
	local heartbeat = runService.Heartbeat;

	local function create(object, properties)
		local new = Instance.new(object);
		for i,v in pairs (properties or {}) do
			if pcall(function() return new[i] end) then
				new[i] = v;
			end
		end
		return new;
	end

	local InitialCFrames = {
		Torso = {C0 = CF(0, -1, 0), C1 = CF(0, -1, 0)},
		Head = {C0 = CF(0, 1.5, 0), C1 = CF(0,0,0)},
		Right_Arm = {C0 = CF(1.5,.5,0), C1 = CF(0, .5, 0)},
		Right_Leg = {C0 = CF(.5, -1, 0), C1 = CF(0, 1, 0)},
		Left_Arm = {C0 = CF(-1.5, .5, 0), C1 = CF(0, .5, 0)},
		Left_Leg = {C0 = CF(-.5, -1, 0), C1 = CF(0, 1, 0)},	
	}

	local buds

	local function generateCharacter(userId, onlineBool, format)
		local appearance = players:GetCharacterAppearanceAsync(userId) or nil;
		if appearance then
			local isOnline;
			if onlineBool then
				isOnline = "[Online]";
			else
				isOnline = "[Offline]";
			end
			local person 	= create("Model", {Name = players:GetNameFromUserIdAsync(userId).."\n"..isOnline, Parent = nil});

			local head 		= create("Part", {Size = V3(2,1,1), CanCollide = false, Anchored = false, Parent = person, Name = "Head"});
			local torso 	= create("Part", {Size = V3(2, 2, 1), CanCollide = false, Anchored = false, Parent = person, Name = "Torso"});
			local humRoot 	= create("Part", {Size = V3(2, 2, 1), CanCollide = false, Anchored = false, Parent = person, Name = "HumanoidRootPart", Transparency = 1, Color = fromRgb(13, 105, 172)});
			local rightArm 	= create("Part", {Size = V3(1, 2, 1), CanCollide = false, Anchored = false, Parent = person, Name = "Right Arm"});
			local leftArm 	= create("Part", {Size = V3(1, 2, 1), CanCollide = false, Anchored = false, Parent = person, Name = "Left Arm"});
			local rightLeg 	= create("Part", {Size = V3(1, 2, 1), CanCollide = false, Anchored = false, Parent = person, Name = "Right Leg"});
			local leftLeg 	= create("Part", {Size = V3(1, 2, 1), CanCollide = false, Anchored = false, Parent = person, Name = "Left Leg"});

			local Torso     = create("Motor6D", {Name = "Torso",Parent = head,     Part0 = humRoot, Part1 = torso,			C0 = InitialCFrames.Torso.C0,       	C1 = InitialCFrames.Torso.C1});
			local Head      = create("Motor6D", {Name = "Head",Parent = head,      Part0 = torso, Part1 = head,            	C0 = InitialCFrames.Head.C0,        	C1 = InitialCFrames.Head.C1});
			local Right_Arm = create("Motor6D", {Name = "Right_Arm",Parent = head, Part0 = torso, Part1 = rightArm,        	C0 = InitialCFrames.Right_Arm.C0,    	C1 = InitialCFrames.Left_Arm.C1});
			local Right_Leg = create("Motor6D", {Name = "Right_Leg",Parent = head, Part0 = torso, Part1 = rightLeg,        	C0 = InitialCFrames.Right_Leg.C0,    	C1 = InitialCFrames.Right_Leg.C1});
			local Left_Arm  = create("Motor6D", {Name = "Left_Arm",Parent = head,  Part0 = torso, Part1 = leftArm,         	C0 = InitialCFrames.Left_Arm.C0,     	C1 = InitialCFrames.Left_Arm.C1});
			local Left_Leg  = create("Motor6D", {Name = "Left_Leg",Parent = head,  Part0 = torso, Part1 = leftLeg,         	C0 = InitialCFrames.Left_Leg.C0,    	C1 = InitialCFrames.Left_Leg.C1});

			local hum		= create("Humanoid", {Parent = person});
			local headMesh 	= create("SpecialMesh", {Scale = V3(1.25, 1.25, 1.25), MeshType = "Head", Parent = head});
			local headDecal = create("Decal", {Texture = "rbxasset://textures/face.png", Face = "Front" , Parent = head});

			hum.MaxHealth = math.huge;
			hum.Health = math.huge;
			person.PrimaryPart = humRoot;
			person:SetPrimaryPartCFrame(format*CA(0,rad(90),0));	

			for i,v in pairs (appearance:GetChildren()) do					
				if v:IsA("Folder") then
					if v.Name == "R6" then
						table.foreach(v:GetChildren(), function(index, obj) obj.Parent = person end);
					end
				elseif v:IsA("Decal") then
					headDecal.Texture = v.Texture;
				elseif v:IsA("BlockMesh") then			
					headMesh:Destroy();
					v.Parent = head;
				else
					v.Parent = person;
				end
			end
			person.Parent = buds;
		end
	end
	
	buds = create("Folder", {Name = "RS_Buddies", Parent = workspace});
	
	--//Code by MasterScootScoot
	SyncAPI('LoadFriends').Create({
		Description = '!! LAG ALERT !!\nLoads in all the friends of the specified user. Spamming this command may cause severe lag and even crash the server. Don\'t say you weren\'t warned. If no user is specified, will load your friends.',
		PermissionLevel = 2,
		Shorthand = {'LoadF','Buddies'},
		Parameters = 'optional:user',
		Run = function(main,user,target)
			if not target then
				target = user
			end
			SyncAPI:DisplayNotification(user,{
				Type = 'Sidebar',
				Title = 'Now loading in '..target.DisplayName..'\'s friends. This might take a while...',
				Time = 15,
				Icon = 'Question',
			})
			
			local friends = players:GetFriendsAsync(target.UserId)
			local userCF = user.Character:WaitForChild('Head').CFrame
			local currentFriends,total = {},0
			
			pcall(function()
				for iteration = 1,4 do
					for _,item in ipairs(friends:GetCurrentPage()) do
						table.insert(currentFriends,item)
						total += 1
					end
					friends:AdvanceToNextPageAsync()
				end
			end)
			
			for iteration,buddy in pairs(currentFriends) do
				generateCharacter(buddy.Id,buddy.IsOnline,CF(userCF.p)*CA(0,(rad(360/total)*iteration),0)*CF(total,0,0))
				heartbeat:Wait()
			end
			
			local popularity = 'F R I E N D L E S S . A L O N E . :,('
			if total < 20 then
				popularity = 'Tell them to get some more buddies!'
			elseif total < 40 then
				popularity = 'Not very well known.'
			elseif total < 60 then
				popularity = 'Known by a few insignificant people.'
			elseif total < 80 then
				popularity = 'A friend of some people.'
			elseif total < 100 then
				popularity = 'Well traveled.'
			elseif total < 120 then
				popularity = 'Has a lot of friends.'
			elseif total < 140 then
				popularity = 'Famous!'
			elseif total < 160 then
				popularity = 'Superstar!!'
			elseif total < 180 then
				popularity = 'h0t'
			elseif total < 200 then
				popularity = 'One of the gods.'
			elseif total == 200 then
				popularity = 'MAXXED OUT!!!'
			end
			
			return true,'Displaying '..target.DisplayName..'\'s friends. Popularity ranking: '..popularity..' Total: '..total,10
		end,
	})
	SyncAPI('RemoveFriends').Create({
		Description = 'Removes any friends that have been loaded into the server by ReSync.',
		PermissionLevel = 1,
		Shorthand = {'KillBuddies','ClearFriends'},
		Run = function(main,user)
			buds:ClearAllChildren()
			return true,'All buddies have been disposed of. No more friends :>',8
		end,
	})
end
