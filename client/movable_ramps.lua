-- [esx-tow] client/movable_ramps.lua
local MovableRamps = {
    attachedVehicles = {},
    rampStates = {}
}

function MovableRamps:DeployRamp(vehicle)
    local ped = PlayerPedId()
    local vehicleModel = GetEntityModel(vehicle)
    local modelName = GetDisplayNameFromVehicleModel(vehicleModel)
    
    -- Verificar se o veículo tem rampa móvel
    if not Config.MovableRamps[modelName] then
        lib.notify({
            title = 'Sistema de Rampas',
            description = 'Este veículo não possui rampa móvel!',
            type = 'error'
        })
        return false
    end
    
    local config = Config.MovableRamps[modelName]
    
    -- Verificar se já está deployado
    if self.rampStates[vehicle] and self.rampStates[vehicle].deployed then
        lib.notify({
            title = 'Sistema de Rampas',
            description = 'A rampa já está totalmente estendida!',
            type = 'info'
        })
        return false
    end
    
    -- Animação de deploy
    TaskPlayAnim(ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Inicializar estado da rampa
    if not self.rampStates[vehicle] then
        self.rampStates[vehicle] = {
            deployed = false,
            progress = 0.0,
            attachedVehicles = {}
        }
    end
    
    local startTime = GetGameTimer()
    local deployTime = config.deployTime
    
    Citizen.CreateThread(function()
        while GetGameTimer() - startTime < deployTime do
            local progress = math.min(1.0, (GetGameTimer() - startTime) / deployTime)
            
            -- Controlar a rampa
            if config.rampControl == 'bulldozer_arm' then
                SetVehicleBulldozerArmPosition(vehicle, progress, false)
            end
            
            self.rampStates[vehicle].progress = progress
            
            -- Mover veículos attachados com a rampa
            self:MoveAttachedVehiclesWithRamp(vehicle, progress)
            
            Citizen.Wait(0)
        end
        
        self.rampStates[vehicle].deployed = true
        
        lib.notify({
            title = 'Sistema de Rampas',
            description = Config.Locale.rampDeployed,
            type = 'success'
        })
        
        ClearPedTasks(ped)
    end)
    
    return true
end

function MovableRamps:RetractRamp(vehicle)
    local ped = PlayerPedId()
    local vehicleModel = GetEntityModel(vehicle)
    local modelName = GetDisplayNameFromVehicleModel(vehicleModel)
    local config = Config.MovableRamps[modelName]
    
    -- Verificar se já está recolhido
    if not self.rampStates[vehicle] or not self.rampStates[vehicle].deployed then
        lib.notify({
            title = 'Sistema de Rampas',
            description = 'A rampa já está totalmente recolhida!',
            type = 'info'
        })
        return false
    end
    
    -- Animação de retração
    TaskPlayAnim(ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 8.0, -8.0, -1, 1, 0, false, false, false)
    
    local startTime = GetGameTimer()
    local retractTime = config.retractTime
    
    Citizen.CreateThread(function()
        while GetGameTimer() - startTime < retractTime do
            local progress = 1.0 - math.min(1.0, (GetGameTimer() - startTime) / retractTime)
            
            -- Controlar a rampa
            if config.rampControl == 'bulldozer_arm' then
                SetVehicleBulldozerArmPosition(vehicle, progress, false)
            end
            
            self.rampStates[vehicle].progress = progress
            
            -- Mover veículos attachados com a rampa
            self:MoveAttachedVehiclesWithRamp(vehicle, progress)
            
            Citizen.Wait(0)
        end
        
        self.rampStates[vehicle].deployed = false
        self.rampStates[vehicle].progress = 0.0
        
        lib.notify({
            title = 'Sistema de Rampas',
            description = Config.Locale.rampRetracted,
            type = 'success'
        })
        
        ClearPedTasks(ped)
    end)
    
    return true
end

function MovableRamps:MoveAttachedVehiclesWithRamp(vehicle, rampProgress)
    if not self.rampStates[vehicle] or not Config.Attach.moveWithRamp then return end
    
    local config = Config.MovableRamps[GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))]
    if not config then return end
    
    -- Calcular nova posição baseado no ângulo da rampa
    local rampAngle = rampProgress * config.maxRampAngle
    local yOffset = -2.5 + (rampProgress * 1.5) -- Ajustar posição conforme a rampa se move
    local zOffset = config.attachOffset.z - (rampProgress * 0.2) -- Ajustar altura
    
    local newOffset = vec3(config.attachOffset.x, yOffset, zOffset)
    
    -- Atualizar posição de todos os veículos attachados
    for _, attachedVehicle in ipairs(self.rampStates[vehicle].attachedVehicles) do
        if DoesEntityExist(attachedVehicle) then
            local newPosition = GetOffsetFromEntityInWorldCoords(vehicle, newOffset)
            SetEntityCoords(attachedVehicle, newPosition)
            
            -- Manter nivelado
            if Config.Attach.autoLevel then
                local towRotation = GetEntityRotation(vehicle, 2)
                SetEntityRotation(attachedVehicle, vec3(0.0, 0.0, towRotation.z))
            end
        end
    end
end

function MovableRamps:IsRampDeployed(vehicle)
    return self.rampStates[vehicle] and self.rampStates[vehicle].deployed
end

-- Comandos
RegisterCommand('deployramp', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not IsPlayerAuthorized() then
        lib.notify({
            title = 'Sistema de Rampas',
            description = Config.Locale.notAuthorized,
            type = 'error'
        })
        return
    end
    
    if not DoesEntityExist(vehicle) then
        lib.notify({
            title = 'Sistema de Rampas',
            description = Config.Locale.notInVehicle,
            type = 'error'
        })
        return
    end
    
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        lib.notify({
            title = 'Sistema de Rampas',
            description = Config.Locale.notDriver,
            type = 'error'
        })
        return
    end
    
    MovableRamps:DeployRamp(vehicle)
end, false)

RegisterCommand('retractramp', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not IsPlayerAuthorized() then
        lib.notify({
            title = 'Sistema de Rampas',
            description = Config.Locale.notAuthorized,
            type = 'error'
        })
        return
    end
    
    if not DoesEntityExist(vehicle) then
        lib.notify({
            title = 'Sistema de Rampas',
            description = Config.Locale.notInVehicle,
            type = 'error'
        })
        return
    end
    
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        lib.notify({
            title = 'Sistema de Rampas',
            description = Config.Locale.notDriver,
            type = 'error'
        })
        return
    end
    
    MovableRamps:RetractRamp(vehicle)
end, false)