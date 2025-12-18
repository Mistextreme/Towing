-- [esx-tow] client/editor.lua
local Editor = {
    active = false,
    mode = 'vehicle',
    selectedVehicle = nil,
    measurements = {},
    tempRamp = nil
}

-- Funções de Cálculo
local function GetLaserDirection()
    local rot = GetGameplayCamRot(2)
    local coords = GetGameplayCamCoord()
    local direction = {
        x = -math.sin(math.rad(rot.z)) * math.abs(math.cos(math.rad(rot.x))),
        y = math.cos(math.rad(rot.z)) * math.abs(math.cos(math.rad(rot.x))),
        z = math.sin(math.rad(rot.x))
    }
    return coords, direction
end

local function GetLaserHit(distance)
    local coords, direction = GetLaserDirection()
    local destination = vector3(
        coords.x + (direction.x * distance),
        coords.y + (direction.y * distance),
        coords.z + (direction.z * distance)
    )
    local ray = StartShapeTestRay(coords, destination, -1, PlayerPedId(), 0)
    local hit, endCoords, surfaceNormal, entity = GetShapeTestResult(ray)
    return hit, endCoords, entity
end

-- Modos de Editor
function Editor:SelectVehicle()
    local hit, coords, entity = GetLaserHit(100.0)
    
    if hit and entity ~= 0 and IsEntityAVehicle(entity) then
        self.selectedVehicle = entity
        self.measurements.vehicle = {
            model = GetEntityModel(entity),
            name = GetDisplayNameFromVehicleModel(GetEntityModel(entity)),
            coords = coords,
            hash = GetEntityModel(entity)
        }
        
        lib.notify({
            title = 'Editor de Veículos',
            description = ('Veículo selecionado: %s'):format(self.measurements.vehicle.name),
            type = 'success'
        })
        
        DrawMarker(1, coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 
                  Config.Editor.markerColor.r, Config.Editor.markerColor.g, Config.Editor.markerColor.b, 200, false, false, 2, false, nil, nil, false)
    end
end

function Editor:SelectBone()
    if not self.selectedVehicle then return end
    
    local hit, coords, entity = GetLaserHit(100.0)
    
    if hit and entity == self.selectedVehicle then
        local bone = self:GetClosestBone(coords)
        self.measurements.bone = {
            name = bone.name,
            index = bone.index,
            coords = coords
        }
        
        lib.notify({
            title = 'Editor de Veículos',
            description = ('Bone selecionado: %s'):format(bone.name),
            type = 'success'
        })
        
        DrawMarker(2, coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 
                  Config.Editor.selectionColor.r, Config.Editor.selectionColor.g, Config.Editor.selectionColor.b, 200, false, false, 2, false, nil, nil, false)
    end
end

function Editor:MeasureOffset()
    if not self.selectedVehicle then return end
    
    local hit, coords, entity = GetLaserHit(100.0)
    
    if hit then
        local offset = GetOffsetFromEntityGivenWorldCoords(self.selectedVehicle, coords)
        self.measurements.offset = {
            worldCoords = coords,
            localOffset = offset,
            formatted = ('vec3(%.3f, %.3f, %.3f)'):format(offset.x, offset.y, offset.z)
        }
        
        lib.notify({
            title = 'Editor de Veículos',
            description = ('Offset medido: %s'):format(self.measurements.offset.formatted),
            type = 'success'
        })
        
        DrawMarker(0, coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 
                  Config.Editor.measurementColor.r, Config.Editor.measurementColor.g, Config.Editor.measurementColor.b, 200, false, false, 2, false, nil, nil, false)
    end
end

function Editor:MeasureWinch()
    local hit, coords, entity = GetLaserHit(100.0)
    
    if hit then
        self.measurements.winch = {
            point = coords,
            distance = #(GetEntityCoords(PlayerPedId()) - coords),
            formatted = ('vec3(%.3f, %.3f, %.3f)'):format(coords.x, coords.y, coords.z)
        }
        
        lib.notify({
            title = 'Editor de Veículos',
            description = ('Ponto de guincho medido: %s'):format(self.measurements.winch.formatted),
            type = 'success'
        })
        
        DrawMarker(4, coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 
                  255, 0, 255, 200, false, false, 2, false, nil, nil, false)
    end
end

function Editor:SpawnTempRamp()
    if not self.selectedVehicle then return end
    
    local vehicleCoords = GetEntityCoords(self.selectedVehicle)
    local spawnCoords = GetOffsetFromEntityInWorldCoords(self.selectedVehicle, vec3(0.0, -8.0, -1.0))
    
    if not self.tempRamp then
        RequestModel(GetHashKey('prop_flatbed_ramp'))
        while not HasModelLoaded(GetHashKey('prop_flatbed_ramp')) do
            Citizen.Wait(100)
        end
        
        self.tempRamp = CreateObject(GetHashKey('prop_flatbed_ramp'), spawnCoords, true, false, false)
        AttachEntityToEntity(self.tempRamp, self.selectedVehicle, GetEntityBoneIndexByName(self.selectedVehicle, 'chassis'), 
                           0.0, -8.0, -1.0, 180.0, 180.0, 0.0, 0, 0, 1, 0, 0, 1)
        
        lib.notify({
            title = 'Editor de Veículos',
            description = 'Rampa temporária criada para testes',
            type = 'success'
        })
    end
end

function Editor:MoveTempRamp()
    if not self.tempRamp then return end
    
    local hit, coords, entity = GetLaserHit(100.0)
    
    if hit then
        local vehicleCoords = GetEntityCoords(self.selectedVehicle)
        local offset = GetOffsetFromEntityGivenWorldCoords(self.selectedVehicle, coords)
        
        DetachEntity(self.tempRamp, false, false)
        SetEntityCoords(self.tempRamp, coords)
        
        self.measurements.rampPosition = {
            worldCoords = coords,
            localOffset = offset,
            formatted = ('vec3(%.3f, %.3f, %.3f)'):format(offset.x, offset.y, offset.z)
        }
        
        lib.notify({
            title = 'Editor de Veículos',
            description = ('Posição da rampa ajustada: %s'):format(self.measurements.rampPosition.formatted),
            type = 'success'
        })
    end
end

-- Funções Auxiliares
function Editor:GetClosestBone(coords)
    local bones = {
        'chassis', 'bodyshell', 'engine', 'wheel_lr', 'wheel_rr', 'wheel_lf', 'wheel_rf',
        'door_dside_f', 'door_pside_f', 'door_dside_r', 'door_pside_r', 'bonnet', 'boot', 'wing_lr', 'wing_rr'
    }
    local closestBone = nil
    local closestDistance = math.huge
    
    for _, boneName in ipairs(bones) do
        local boneIndex = GetEntityBoneIndexByName(self.selectedVehicle, boneName)
        if boneIndex ~= -1 then
            local boneCoords = GetWorldPositionOfEntityBone(self.selectedVehicle, boneIndex)
            local distance = #(coords - boneCoords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestBone = { name = boneName, index = boneIndex }
            end
        end
    end
    
    return closestBone or { name = 'chassis', index = 0 }
end

-- Interface do Editor
function Editor:Open()
    if not IsPlayerAuthorized() then
        lib.notify({
            title = 'Editor de Veículos',
            description = Config.Locale.notAuthorized,
            type = 'error'
        })
        return
    end
    
    self.active = true
    self.mode = 'vehicle'
    
    lib.showTextUI(Config.Locale.editorMode, {
        position = 'top-center',
        icon = 'wrench',
        style = { backgroundColor = '#1a1a1a', color = '#ffffff' }
    })
    
    Citizen.CreateThread(function()
        while self.active do
            local coords, direction = GetLaserDirection()
            local destination = coords + (direction * 100.0)
            
            -- Desenhar laser
            DrawLine(coords, destination, Config.Editor.laserColor.r, Config.Editor.laserColor.g, Config.Editor.laserColor.b, 255)
            
            -- Seleção por modo
            if IsControlJustPressed(0, 38) then -- E
                if self.mode == 'vehicle' then self:SelectVehicle()
                elseif self.mode == 'bone' then self:SelectBone()
                elseif self.mode == 'offset' then self:MeasureOffset()
                elseif self.mode == 'winch' then self:MeasureWinch()
                elseif self.mode == 'ramp' then self:MoveTempRamp() end
            end
            
            -- Mudar modo
            if IsControlJustPressed(0, 174) then -- Direita
                self:ChangeMode('next')
            elseif IsControlJustPressed(0, 175) then -- Esquerda
                self:ChangeMode('prev')
            end
            
            -- Spawn/Remover rampa temporária
            if IsControlJustPressed(0, 173) then -- Cima
                if self.tempRamp then
                    DeleteEntity(self.tempRamp)
                    self.tempRamp = nil
                    lib.notify({
                        title = 'Editor de Veículos',
                        description = 'Rampa temporária removida',
                        type = 'info'
                    })
                else
                    self:SpawnTempRamp()
                end
            end
            
            -- Salvar configuração
            if IsControlJustPressed(0, 176) then -- Baixo
                self:SaveConfiguration()
            end
            
            -- Cancelar
            if IsControlJustPressed(0, 177) then -- Esc
                self:Close()
            end
            
            Citizen.Wait(0)
        end
    end)
end

function Editor:ChangeMode(direction)
    local modes = {'vehicle', 'bone', 'offset', 'winch', 'ramp'}
    local currentIndex = table.indexOf(modes, self.mode)
    
    if direction == 'next' then
        currentIndex = currentIndex + 1
        if currentIndex > #modes then currentIndex = 1 end
    else
        currentIndex = currentIndex - 1
        if currentIndex < 1 then currentIndex = #modes end
    end
    
    self.mode = modes[currentIndex]
    lib.notify({
        title = 'Editor de Veículos',
        description = ('Modo: %s'):format(self.mode:upper()),
        type = 'info'
    })
end

function Editor:SaveConfiguration()
    if not self.selectedVehicle then
        lib.notify({
            title = 'Editor de Veículos',
            description = 'Selecione um veículo primeiro!',
            type = 'error'
        })
        return
    end
    
    local configData = {
        vehicle = self.measurements.vehicle,
        bone = self.measurements.bone,
        offset = self.measurements.offset,
        winch = self.measurements.winch,
        rampPosition = self.measurements.rampPosition,
        timestamp = os.time()
    }
    
    TriggerServerEvent('esx-tow:saveEditorConfig', configData)
    lib.notify({
        title = 'Editor de Veículos',
        description = Config.Locale.editorSaved,
        type = 'success'
    })
end

function Editor:Close()
    self.active = false
    self.mode = nil
    self.selectedVehicle = nil
    self.measurements = {}
    
    if self.tempRamp then
        DeleteEntity(self.tempRamp)
        self.tempRamp = nil
    end
    
    lib.hideTextUI()
    lib.notify({
        title = 'Editor de Veículos',
        description = Config.Locale.editorClosed,
        type = 'info'
    })
end

-- Comando para abrir editor
RegisterCommand('toweditor', function()
    Editor:Open()
end, false)

-- Verificar autorização
function IsPlayerAuthorized()
    local playerData = ESX.GetPlayerData()
    return playerData.job and table.contains(Config.AuthorizedJobs, playerData.job.name)
end