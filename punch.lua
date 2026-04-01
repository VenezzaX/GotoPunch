local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ==========================================
-- 1. Shared Extreme Fling Engine
-- ==========================================
local flingEndTime = 0
local isMassFlinging = false

RunService.Heartbeat:Connect(function()
    if tick() < flingEndTime or isMassFlinging then
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
-- 2. Nearest Target Finder
-- ==========================================
local function getNearestTarget()
    local closestTarget = nil
    local shortestDistance = 12
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return nil end

    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character then
            local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
            
            if targetHrp and targetHum and targetHum.Health > 0 then
                local distance = (hrp.Position - targetHrp.Position).Magnitude
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
-- 3. Universal Tools Setup & Logic
-- ==========================================
local R6_ANIM_ID = 'rbxassetid://12936334'     -- Classic R6 Slash
local R15_ANIM_ID = 'rbxassetid://522635514'    -- Universal R15 Slash

local globalAnim = nil
local isPunching = false
local isEquipped1 = false
local lastAnimTick = 0 
local massFlingCoroutine = nil

local function giveTools()
    local backpack = player:WaitForChild("Backpack")
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    
    -- Auto-detect rig type and load the correct animation
    local anim = Instance.new("Animation")
    if humanoid.RigType == Enum.HumanoidRigType.R6 then
        anim.AnimationId = R6_ANIM_ID
    else
        anim.AnimationId = R15_ANIM_ID
    end
    
    globalAnim = animator:LoadAnimation(anim)
    globalAnim.Priority = Enum.AnimationPriority.Action4

    -- --- TOOL 1: Universal Homing Slash ---
    local tool1 = Instance.new("Tool")
    tool1.Name = "1. Homing Slash"
    tool1.RequiresHandle = false
    tool1.Parent = backpack

    tool1.Equipped:Connect(function()
        isEquipped1 = true
        isMassFlinging = false 
    end)

    tool1.Unequipped:Connect(function()
        isEquipped1 = false
        if globalAnim and globalAnim.IsPlaying then globalAnim:Stop() end
    end)

    -- --- TOOL 2: Universal Dash Fling ---
    local tool2 = Instance.new("Tool")
    tool2.Name = "2. Dash Fling"
    tool2.RequiresHandle = false
    tool2.Parent = backpack
    
    local dashCooldown = false
    tool2.Activated:Connect(function()
        if dashCooldown then return end
        dashCooldown = true
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Keep physics engine active for the duration of the dash
            flingEndTime = tick() + 0.4
            
            if globalAnim then
                if globalAnim.IsPlaying then globalAnim:Stop(0) end
                globalAnim.Looped = false
                globalAnim:Play(0)
                globalAnim:AdjustSpeed(2.5)
            end
            
            -- Dash 40 studs directly forward
            local dashDistance = 40
            local dashTime = 0.25
            local goalCFrame = hrp.CFrame * CFrame.new(0, 0, -dashDistance)
            
            local tweenInfo = TweenInfo.new(dashTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            local dashTween = TweenService:Create(hrp, tweenInfo, {CFrame = goalCFrame})
            dashTween:Play()
            
            task.wait(dashTime + 0.1)
        end
        dashCooldown = false
    end)

    tool2.Unequipped:Connect(function()
        if globalAnim and globalAnim.IsPlaying then globalAnim:Stop() end
    end)

    -- --- TOOL 3: Mass Fling Aura ---
    local tool3 = Instance.new("Tool")
    tool3.Name = "3. Mass Aura"
    tool3.RequiresHandle = false
    tool3.Parent = backpack

    local function massFlingLoop()
        while isMassFlinging do
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then break end

            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if not isMassFlinging then break end 
                
                if targetPlayer ~= player and targetPlayer.Character then
                    local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")

                    if targetHrp and targetHum and targetHum.Health > 0 then
                        -- Tween to the target's initial position
                        local dist = (hrp.Position - targetHrp.Position).Magnitude
                        local travelTime = math.clamp(dist / 800, 0.05, 0.3) 
                        
                        local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
                        local dashTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetHrp.CFrame})
                        dashTween:Play()
                        
                        task.wait(travelTime)
                        if not isMassFlinging then break end 

                        -- Rapid collision loop
                        local startPos = targetHrp.Position
                        local attempts = 0
                        local maxAttempts = 30 

                        while isMassFlinging and attempts < maxAttempts do
                            if not targetHrp or not targetHrp.Parent or targetHum.Health <= 0 then break end
                            
                            local currentVel = targetHrp.AssemblyLinearVelocity.Magnitude
                            local distMoved = (targetHrp.Position - startPos).Magnitude
                            
                            if currentVel > 300 or distMoved > 40 then break end

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
        isMassFlinging = not isMassFlinging
        if isMassFlinging then
            tool3.Name = "3. Mass: ON"
            massFlingCoroutine = coroutine.create(massFlingLoop)
            coroutine.resume(massFlingCoroutine)
        else
            tool3.Name = "3. Mass Aura"
        end
    end)

    tool3.Unequipped:Connect(function()
        isMassFlinging = false
        tool3.Name = "3. Mass Aura"
    end)
end

giveTools()

player.CharacterAdded:Connect(function()
    isEquipped1 = false
    isMassFlinging = false
    globalAnim = nil
    giveTools()
end)

-- Input Logic for Tool 1 (Homing Slash Spam)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not isEquipped1 then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not globalAnim or isPunching then return end
        isPunching = true

        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        flingEndTime = tick() + 1.5

        -- Animation anti-bug buffer
        if tick() - lastAnimTick > 0.1 then
            if globalAnim.IsPlaying then globalAnim:Stop(0) end
            globalAnim.Looped = false 
            globalAnim:Play(0)
            globalAnim:AdjustSpeed(3.0)
            lastAnimTick = tick()
        end

        if hrp then
            local targetHrp = getNearestTarget()
            if targetHrp then
                local tweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Linear) 
                local goalCFrame = targetHrp.CFrame * CFrame.new(0, 0, 0) 
                
                local dashTween = TweenService:Create(hrp, tweenInfo, {CFrame = goalCFrame})
                dashTween:Play()
            end
        end

        task.wait()
        isPunching = false
    end
end)
