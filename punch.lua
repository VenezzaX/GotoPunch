local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ==========================================
-- 1. Shared Extreme Fling Engine
-- ==========================================
local flingEndTime = 0
local isAuraActive = false

RunService.Heartbeat:Connect(function()
    if tick() < flingEndTime or isAuraActive then
        local c = player.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(50000, 50000, 50000) 
            
            RunService.RenderStepped:Wait()
            hrp.AssemblyLinearVelocity = vel
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            RunService.Stepped:Wait()
            hrp.AssemblyLinearVelocity = vel + Vector3.new(0, 0.1, 0)
        end
    end
end)

-- ==========================================
-- 2. Anti-Void Safety Mechanism
-- ==========================================
local function checkAntiVoid(hrp, startCFrame)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local groundCheck = Workspace:Raycast(hrp.Position, Vector3.new(0, -50, 0), raycastParams)
    
    if not groundCheck and hrp.Position.Y < (startCFrame.Position.Y - 5) then
        hrp.CFrame = startCFrame
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

-- ==========================================
-- 3. Dynamic Target Finder
-- ==========================================
local function getNearestTarget(originPos, maxDist, ignoreList)
    local closestTarget = nil
    local shortestDistance = maxDist or 12
    ignoreList = ignoreList or {}

    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character and not ignoreList[targetPlayer.Character] then
            local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
            
            if targetHrp and targetHum and targetHum.Health > 0 then
                local distance = (originPos - targetHrp.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestTarget = targetHrp
                end
            end
        end
    end
    
    return closestTarget
end

-- ==========================================
-- 4. 12-Slot Boss Arsenal Setup
-- ==========================================
local R6_ANIM_ID = 'rbxassetid://12936334'     
local R15_ANIM_ID = 'rbxassetid://522635514'    
local KICK_ANIM_ID = 'rbxassetid://2515090838' -- Updated custom Kick ID

local globalAnim = nil
local globalKickAnim = nil
local isPunching = false
local isEquipped1 = false
local lastAnimTick = 0 
local activeCoroutine = nil

local function playCombatAnimation(animTrack, speed)
    if animTrack then
        if tick() - lastAnimTick > 0.1 then
            if animTrack.IsPlaying then animTrack:Stop(0) end
            animTrack.Looped = false
            animTrack:Play(0)
            animTrack:AdjustSpeed(speed or 2.5)
            lastAnimTick = tick()
        end
    end
end

local function giveTools()
    local backpack = player:WaitForChild("Backpack")
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    
    -- Load Slash Animation
    local anim = Instance.new("Animation")
    if humanoid.RigType == Enum.HumanoidRigType.R6 then anim.AnimationId = R6_ANIM_ID
    else anim.AnimationId = R15_ANIM_ID end
    globalAnim = animator:LoadAnimation(anim)
    globalAnim.Priority = Enum.AnimationPriority.Action4

    -- Load Kick Animation
    local kickAnim = Instance.new("Animation")
    kickAnim.AnimationId = KICK_ANIM_ID
    globalKickAnim = animator:LoadAnimation(kickAnim)
    globalKickAnim.Priority = Enum.AnimationPriority.Action4

    local function makeTool(name)
        local t = Instance.new("Tool")
        t.Name = name
        t.RequiresHandle = false
        t.Parent = backpack
        return t
    end

    -- --- 1. Homing Slash ---
    local tool1 = makeTool("1. Homing Slash")
    tool1.Equipped:Connect(function() isEquipped1 = true; isAuraActive = false end)
    tool1.Unequipped:Connect(function() isEquipped1 = false; if globalAnim.IsPlaying then globalAnim:Stop() end end)

    -- --- 2. Dash Fling ---
    local tool2 = makeTool("2. Dash Fling")
    local dashCooldown = false
    tool2.Activated:Connect(function()
        if dashCooldown then return end; dashCooldown = true
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local startCFrame = hrp.CFrame
            flingEndTime = tick() + 0.6
            playCombatAnimation(globalAnim, 2.5)
            
            local dashTime = 0.25
            local goalCFrame
            local targetHrp = getNearestTarget(hrp.Position, 100) 
            
            if targetHrp then
                local direction = (targetHrp.Position - hrp.Position).Unit
                local piercePosition = targetHrp.Position + (direction * 25)
                goalCFrame = CFrame.new(piercePosition, piercePosition + direction)
            else
                goalCFrame = hrp.CFrame * CFrame.new(0, 0, -45)
            end
            
            TweenService:Create(hrp, TweenInfo.new(dashTime, Enum.EasingStyle.Linear), {CFrame = goalCFrame}):Play()
            task.wait(dashTime + 0.1)
            checkAntiVoid(hrp, startCFrame)
        end
        dashCooldown = false
    end)

    -- --- 3. Mass Aura ---
    local tool3 = makeTool("3. Mass Aura")
    local function massFlingLoop()
        while isAuraActive do
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then break end
            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if not isAuraActive then break end 
                if targetPlayer ~= player and targetPlayer.Character then
                    local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
                    if targetHrp and targetHum and targetHum.Health > 0 then
                        local dist = (hrp.Position - targetHrp.Position).Magnitude
                        local travelTime = math.clamp(dist / 800, 0.05, 0.3) 
                        TweenService:Create(hrp, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {CFrame = targetHrp.CFrame}):Play()
                        task.wait(travelTime)
                        if not isAuraActive then break end 

                        local startPos = targetHrp.Position
                        local attempts = 0
                        while isAuraActive and attempts < 30 do
                            if not targetHrp or not targetHrp.Parent or targetHum.Health <= 0 then break end
                            if targetHrp.AssemblyLinearVelocity.Magnitude > 300 or (targetHrp.Position - startPos).Magnitude > 40 then break end
                            local offsetModulo = attempts % 4
                            if offsetModulo == 0 then hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 1.2)
                            elseif offsetModulo == 1 then hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, -1.2)
                            elseif offsetModulo == 2 then hrp.CFrame = targetHrp.CFrame * CFrame.new(1.2, 0, 0)
                            else hrp.CFrame = targetHrp.CFrame * CFrame.new(-1.2, 0, 0) end
                            attempts = attempts + 1
                            task.wait() 
                        end
                    end
                end
            end
            task.wait(0.1) 
        end
    end
    tool3.Activated:Connect(function()
        isAuraActive = not isAuraActive
        if isAuraActive then tool3.Name = "3. Mass: ON"; activeCoroutine = coroutine.create(massFlingLoop); coroutine.resume(activeCoroutine)
        else tool3.Name = "3. Mass Aura" end
    end)
    tool3.Unequipped:Connect(function() isAuraActive = false; tool3.Name = "3. Mass Aura" end)

    -- --- 4. Meteor Drop ---
    local tool4 = makeTool("4. Meteor Drop")
    local dropCooldown = false
    tool4.Activated:Connect(function()
        if dropCooldown then return end; dropCooldown = true
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local startCFrame = hrp.CFrame
            local targetHrp = getNearestTarget(hrp.Position, 200) 
            if targetHrp then
                hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 100, 0)
                task.wait(0.1)
                flingEndTime = tick() + 0.8
                playCombatAnimation(globalAnim, 2.5)
                TweenService:Create(hrp, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {CFrame = targetHrp.CFrame * CFrame.new(0, 0, 0)}):Play()
                task.wait(0.25)
                checkAntiVoid(hrp, startCFrame)
            end
        end
        dropCooldown = false
    end)

    -- --- 5. Orbit Tornado ---
    local tool5 = makeTool("5. Orbit Fling")
    local function orbitLoop()
        local angle = 0
        while isAuraActive do
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then break end
            local targetHrp = getNearestTarget(hrp.Position, 50)
            if targetHrp then
                hrp.CFrame = targetHrp.CFrame * CFrame.new(math.cos(angle) * 2, 0, math.sin(angle) * 2)
                angle = angle + 1.5 
            end
            task.wait()
        end
    end
    tool5.Activated:Connect(function()
        isAuraActive = not isAuraActive
        if isAuraActive then tool5.Name = "5. Orbit: ON"; activeCoroutine = coroutine.create(orbitLoop); coroutine.resume(activeCoroutine)
        else tool5.Name = "5. Orbit Fling" end
    end)
    tool5.Unequipped:Connect(function() isAuraActive = false; tool5.Name = "5. Orbit Fling" end)

    -- --- 6. Chain Strike ---
    local tool6 = makeTool("6. Chain Strike")
    local chainCooldown = false
    tool6.Activated:Connect(function()
        if chainCooldown then return end; chainCooldown = true
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local startCFrame = hrp.CFrame
            local currentOrigin = hrp.Position
            local hitTargets = {} 
            flingEndTime = tick() + 2.5 
            
            for i = 1, 5 do 
                local targetHrp = getNearestTarget(currentOrigin, 150, hitTargets)
                if targetHrp then
                    hitTargets[targetHrp.Parent] = true 
                    currentOrigin = targetHrp.Position
                    hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 0)
                    playCombatAnimation(globalAnim, 3.5)
                    
                    for j = 1, 6 do
                        if j%2 == 0 then hrp.CFrame = targetHrp.CFrame * CFrame.new(1,0,0)
                        else hrp.CFrame = targetHrp.CFrame * CFrame.new(-1,0,0) end
                        task.wait()
                    end
                    task.wait(0.1) 
                else break end
            end
            checkAntiVoid(hrp, startCFrame)
        end
        chainCooldown = false
    end)

    -- --- 7. Uppercut ---
    local tool7 = makeTool("7. Uppercut")
    local upperCooldown = false
    tool7.Activated:Connect(function()
        if upperCooldown then return end; upperCooldown = true
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local startCFrame = hrp.CFrame
            local targetHrp = getNearestTarget(hrp.Position, 80)
            if targetHrp then
                flingEndTime = tick() + 1.0
                playCombatAnimation(globalAnim, 2.5)
                hrp.CFrame = targetHrp.CFrame * CFrame.new(0, -4, 0)
                task.wait(0.05)
                TweenService:Create(hrp, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {CFrame = targetHrp.CFrame * CFrame.new(0, 150, 0)}):Play()
                task.wait(0.4)
                checkAntiVoid(hrp, startCFrame)
            end
        end
        upperCooldown = false
    end)

    -- --- 8. SPARTA KICK (Updated ID) ---
    local tool8 = makeTool("8. Sparta Kick")
    local kickCooldown = false
    tool8.Activated:Connect(function()
        if kickCooldown then return end; kickCooldown = true
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local startCFrame = hrp.CFrame
            local targetHrp = getNearestTarget(hrp.Position, 40)
            if targetHrp then
                local lookAtCFrame = CFrame.lookAt(targetHrp.Position + (targetHrp.CFrame.LookVector * 3), targetHrp.Position)
                hrp.CFrame = lookAtCFrame
                
                playCombatAnimation(globalKickAnim, 1.8)
                task.wait(0.15) 
                
                flingEndTime = tick() + 0.8
                TweenService:Create(hrp, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {CFrame = targetHrp.CFrame * CFrame.new(0,0,1)}):Play()
                
                task.wait(0.2)
                checkAntiVoid(hrp, startCFrame)
            end
        end
        kickCooldown = false
    end)

    -- --- 9. PINBALL BOUNCE ---
    local tool9 = makeTool("9. Pinball Bounce")
    local pinballCooldown = false
    tool9.Activated:Connect(function()
        if pinballCooldown then return end; pinballCooldown = true
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local startCFrame = hrp.CFrame
            flingEndTime = tick() + 2.0
            
            local targets = {}
            for _, tPlayer in ipairs(Players:GetPlayers()) do
                if tPlayer ~= player and tPlayer.Character then
                    local tHrp = tPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if tHrp and (hrp.Position - tHrp.Position).Magnitude <= 60 then
                        table.insert(targets, tHrp)
                    end
                end
            end
            
            for _, tHrp in ipairs(targets) do
                playCombatAnimation(globalAnim, 4.0)
                hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 0)
                task.wait(0.08) 
            end
            
            task.wait(0.1)
            checkAntiVoid(hrp, startCFrame)
        end
        pinballCooldown = false
    end)

    -- --- 10. PHANTOM FLURRY ---
    local tool10 = makeTool("0. Phantom Flurry")
    local flurryCooldown = false
    tool10.Activated:Connect(function()
        if flurryCooldown then return end; flurryCooldown = true
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local startCFrame = hrp.CFrame
            local targetHrp = getNearestTarget(hrp.Position, 80)
            
            if targetHrp then
                flingEndTime = tick() + 1.5
                for i = 1, 8 do
                    if not targetHrp or not targetHrp.Parent then break end
                    playCombatAnimation(globalAnim, 3.5)
                    local randomOffset = CFrame.new(math.random(-4, 4), math.random(-2, 4), math.random(-4, 4))
                    hrp.CFrame = CFrame.lookAt((targetHrp.CFrame * randomOffset).Position, targetHrp.Position)
                    task.wait(0.05)
                end
                
                if targetHrp and targetHrp.Parent then hrp.CFrame = targetHrp.CFrame * CFrame.new(0,0,0) end
                task.wait(0.2)
                checkAntiVoid(hrp, startCFrame)
            end
        end
        flurryCooldown = false
    end)

    -- --- 11. VELQFY VORTEX (New) ---
    local tool11 = makeTool("11. Velqfy Vortex")
    local vortexCooldown = false
    tool11.Activated:Connect(function()
        if vortexCooldown then return end; vortexCooldown = true
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local startCFrame = hrp.CFrame
            flingEndTime = tick() + 3.0
            playCombatAnimation(globalAnim, 3.0)
            
            local targets = {}
            for _, tPlayer in ipairs(Players:GetPlayers()) do
                if tPlayer ~= player and tPlayer.Character then
                    local tHrp = tPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if tHrp and (hrp.Position - tHrp.Position).Magnitude <= 100 then
                        table.insert(targets, tHrp)
                    end
                end
            end
            
            -- Cycle through all nearby targets rapidly to create a vortex effect
            for i = 1, 15 do
                for _, tHrp in ipairs(targets) do
                    if tHrp and tHrp.Parent then
                        hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 0)
                        task.wait()
                    end
                end
            end
            
            checkAntiVoid(hrp, startCFrame)
        end
        vortexCooldown = false
    end)

    -- --- 12. DISASTER QUAKE (New) ---
    local tool12 = makeTool("12. Disaster Quake")
    local quakeCooldown = false
    tool12.Activated:Connect(function()
        if quakeCooldown then return end; quakeCooldown = true
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local startCFrame = hrp.CFrame
            flingEndTime = tick() + 2.5
            
            local targets = {}
            for _, tPlayer in ipairs(Players:GetPlayers()) do
                if tPlayer ~= player and tPlayer.Character then
                    local tHrp = tPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if tHrp and (hrp.Position - tHrp.Position).Magnitude <= 150 then
                        table.insert(targets, tHrp)
                    end
                end
            end
            
            -- Teleport deep under each player and rocket upwards
            for _, tHrp in ipairs(targets) do
                if tHrp and tHrp.Parent then
                    hrp.CFrame = tHrp.CFrame * CFrame.new(0, -5, 0)
                    task.wait(0.05)
                    playCombatAnimation(globalAnim, 1.5)
                    TweenService:Create(hrp, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {CFrame = tHrp.CFrame * CFrame.new(0, 10, 0)}):Play()
                    task.wait(0.15)
                end
            end
            
            checkAntiVoid(hrp, startCFrame)
        end
        quakeCooldown = false
    end)

end

giveTools()

player.CharacterAdded:Connect(function()
    isEquipped1 = false
    isAuraActive = false
    globalAnim = nil
    globalKickAnim = nil
    giveTools()
end)

-- ==========================================
-- Tool 1 Input Binding (Homing Slash Spam)
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not isEquipped1 then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not globalAnim or isPunching then return end
        isPunching = true

        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        flingEndTime = tick() + 1.5
        playCombatAnimation(globalAnim, 3.0)

        if hrp then
            local targetHrp = getNearestTarget(hrp.Position, 12)
            if targetHrp then
                TweenService:Create(hrp, TweenInfo.new(0.08, Enum.EasingStyle.Linear), {CFrame = targetHrp.CFrame * CFrame.new(0, 0, 0)}):Play()
            end
        end

        task.wait()
        isPunching = false
    end
end)
