local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ==========================================
-- 1. Embedded Velocity Fling Logic
-- ==========================================
local flingEndTime = 0

RunService.Heartbeat:Connect(function()
    if tick() < flingEndTime then
        local c = player.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp.Velocity
            -- The velocity spike that causes the fling on impact
            hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, 0.1, 0)
        end
    end
end)

-- ==========================================
-- 2. Nearest Target Finder
-- ==========================================
local function getNearestTarget()
    local closestTarget = nil
    local shortestDistance = 10 -- Maximum range in studs to trigger the homing tween
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return nil end

    -- Check all other players in the game
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character then
            local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
            
            -- Make sure they are alive and have a RootPart
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
-- 3. Tool & Single Quick-Punch Logic (RESPAWN PROOF)
-- ==========================================
local QUICK_PUNCH_ID = 'rbxassetid://507770453' 
local loadedAnim = nil
local isPunching = false
local PUNCH_COOLDOWN = 0.5
local isEquipped = false

-- Function to build the tool
local function giveTool()
    -- Wait for the new backpack to generate
    local backpack = player:WaitForChild("Backpack")
    
    local tool = Instance.new("Tool")
    tool.Name = "Homing Fling Punch"
    tool.RequiresHandle = false
    tool.Parent = backpack

    tool.Equipped:Connect(function()
        isEquipped = true
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")
        local animator = humanoid:WaitForChild("Animator")
        
        local anim = Instance.new("Animation")
        anim.AnimationId = QUICK_PUNCH_ID
        loadedAnim = animator:LoadAnimation(anim)
    end)

    tool.Unequipped:Connect(function()
        isEquipped = false
    end)
end

-- 1. Give the tool immediately when the script first runs
giveTool()

-- 2. Give the tool automatically every time the player respawns
player.CharacterAdded:Connect(function()
    isEquipped = false
    loadedAnim = nil
    giveTool()
end)

-- The input connection stays down here so it doesn't duplicate on death
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not isEquipped then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if isPunching or not loadedAnim then return end
        isPunching = true

        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        -- 1. Trigger the 1.5s fling physics window
        flingEndTime = tick() + 1.5

        -- 2. Play the quick punch animation
        loadedAnim.Looped = false 
        loadedAnim:Play()
        loadedAnim:AdjustSpeed(3.0) -- Tripled speed for a lightning-fast jab

        -- 3. Find target and execute the Tween dash
        if hrp then
            local targetHrp = getNearestTarget()
            if targetHrp then
                -- Create a lightning-fast 0.15-second tween directly to the enemy
                local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Linear)
                
                -- Offset slightly so you hit their hitbox rather than merging into their exact center
                local goalCFrame = targetHrp.CFrame * CFrame.new(0, 0, -1) 
                
                local dashTween = TweenService:Create(hrp, tweenInfo, {CFrame = goalCFrame})
                dashTween:Play()
            end
        end

        -- Wait for cooldown before allowing another punch
        task.wait(PUNCH_COOLDOWN)
        isPunching = false
    end
end)
