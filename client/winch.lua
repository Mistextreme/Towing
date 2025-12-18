-- [esx-tow] client/winch.lua
local WinchSystem = {
    active = false,
    cable = nil,
    vehicle1 = nil,
    vehicle2 = nil,
    cablePoints = {},
    isAttaching = false
}

function WinchSystem:StartCable()
    if not IsPlayerAuthorized() then
        lib.notify({
            title = 'Sistema de Guincho',
            description = Config.Locale.notAuthorized,
            type = 'error'
        })
        return false
    end
    
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not DoesEntityExist(vehicle) then
        lib.notify({
            title = 'Sistema de Guincho',
            description = 'Você precisa estar em um veículo com guincho!',
            type = 'error'
        })
        return false
    end
    
    local vehicleModel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local config = Config.MovableRamps[vehicleModel]
    
    if not config or not config.winchBone then
        lib.notify({
            title = 'Sistema de Guincho',
            description = 'Este veículo não possui guincho!',
            type = 'error'
        })
        return false
    end
    
    self.active = true
    self.vehicle1 = vehicle
    
    lib.showTextUI(Config.Locale.useWinch, {
        position = 'top-center',
        icon = 'anchor',
        style = { backgroundColor = '#1a1a1a', color = '#ffffff' }
    })
    
    Citizen.CreateThread(function()
        while self.active do
            local hit, coords, entity = GetLaserHit(Config.Winch.maxRange)
            
            -- Desenhar laser
            local pedCoords = GetEntityCoords(ped)
            DrawLine(pedCoords, coords or (pedCoords + GetLaserDirection().direction * Config.Winch.maxRange), 
                    Config.Editor.laserColor.r, Config.Editor.laserColor.g, Config.Editor.laserColor.b, 255)
            
            -- Selecionar ponto
            if IsControlJustPressed(0, 38) and hit then
                if IsEntityAVehicle(entity) and entity ~= self.vehicle1 then
                    self:AttachCable(self.vehicle1, entity, coords)
                else
                    lib.notify({
                        title = 'Sistema de Guincho',
                        description = 'Selecione um veículo válido!',
                        type = 'error'
                    })
                end
            end
            
            -- Cancelar
            if IsControlJustPressed(0, 177) then
                self:CancelCable()
                break
            end
            
            Citizen.Wait(0)
        end
    end)
    
    return true
end

function WinchSystem:AttachCable(vehicle1, vehicle2, targetPoint)
    if self.isAttaching then return end
    self.isAttaching = true
    
    local config1 = Config.MovableRamps[GetDisplayNameFromVehicleModel(GetEntityModel(vehicle1))]
    
    -- Obter pontos de fixação
    local winchBoneIndex = GetEntityBoneIndexByName(vehicle1, config1.winchBone)
    local point1 = GetWorldPositionOfEntityBone(vehicle1, winchBoneIndex)
    local point2 = targetPoint
    
    -- Criar cabo
    RopeLoadTextures()
    self.cable = AddRope(point1, 0.0, 0.0, 0.0, 50.0, 2, 50.0, 1.0, 0, 0, 0, 0, 0, 0, 0)
    AttachRopeToEntity(self.cable, vehicle1, point1, 1.0)
    
    -- Anexar ao segundo veículo
    AttachEntitiesToRope(self.cable, vehicle1, vehicle2, point1, point2, 100.0)
    
    -- Iniciar recolhimento
    StartRopeWinding(self.cable)
    
    lib.notify({
        title = 'Sistema de Guincho',
        description = Config.Locale.winchAttached,
        type = 'success'
    })
    
    -- Puxar veículo progressivamente
    Citizen.CreateThread(function()
        while RopeGetDistanceBetweenEnds(self.cable) > 2.0 do
            RopeForceLength(self.cable, RopeGetDistanceBetweenEnds(self.cable) - Config.Winch.retractSpeed)
            Citizen.Wait(50)
        end
        
        lib.notify({
            title = 'Sistema de Guincho',
            description = Config.Locale.winchSuccess,
            type = 'success'
        })
        
        self:DetachCable()
    end)
end

function WinchSystem:DetachCable()
    if self.cable then
        DeleteRope(self.cable)
        self.cable = nil
    end
    self.active = false
    self.isAttaching = false
    self.vehicle1 = nil
    self.vehicle2 = nil
    lib.hideTextUI()
end

function WinchSystem:CancelCable()
    self:DetachCable()
    lib.notify({
        title = 'Sistema de Guincho',
        description = 'Operação de guincho cancelada!',
        type = 'info'
    })
end

-- Comando para usar guincho
RegisterCommand('winch', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if DoesEntityExist(vehicle) then
        WinchSystem:StartCable()
    else
        lib.notify({
            title = 'Sistema de Guincho',
            description = 'Você precisa estar em um veículo com guincho!',
            type = 'error'
        })
    end
end, false)