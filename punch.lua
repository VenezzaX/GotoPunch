local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ==========================================
-- 1. Motor de Fling Extremo (Garantido no Contato)
-- ==========================================
local flingEndTime = 0

RunService.Heartbeat:Connect(function()
    if tick() < flingEndTime then
        local c = player.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp.AssemblyLinearVelocity
            
            -- Velocidade e rotação absurdas
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
-- 2. Rastreador de Alvo Mais Próximo
-- ==========================================
local function getNearestTarget()
    local closestTarget = nil
    local shortestDistance = 12 -- Distância máxima
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
-- 3. Lógica da Ferramenta e Spam Liberado
-- ==========================================
local QUICK_PUNCH_ID = 'rbxassetid://507770453' 
local loadedAnim = nil
local isPunching = false
local isEquipped = false

local function giveTool()
    local backpack = player:WaitForChild("Backpack")
    
    local tool = Instance.new("Tool")
    tool.Name = "Fling Hitkill"
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

giveTool()

player.CharacterAdded:Connect(function()
    isEquipped = false
    loadedAnim = nil
    giveTool()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not isEquipped then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Bloqueia apenas se a animação ainda não carregou
        if not loadedAnim or isPunching then return end
        isPunching = true

        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        -- Mantém a janela de física extrema ativa por 1.5s após CADA clique
        flingEndTime = tick() + 1.5

        -- Reinicia e toca a animação instantaneamente para criar o efeito de spam
        loadedAnim:Stop()
        loadedAnim.Looped = false 
        loadedAnim:Play()
        loadedAnim:AdjustSpeed(3.5) -- Velocidade ainda maior para combinar com o spam

        -- Dash direto para dentro do inimigo
        if hrp then
            local targetHrp = getNearestTarget()
            if targetHrp then
                local tweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Linear) -- Tween mais rápido (0.08s)
                
                local goalCFrame = targetHrp.CFrame * CFrame.new(0, 0, 0) 
                
                local dashTween = TweenService:Create(hrp, tweenInfo, {CFrame = goalCFrame})
                dashTween:Play()
            end
        end

        -- Espera apenas 1 único frame antes de permitir o próximo clique
        task.wait()
        isPunching = false
    end
end)
