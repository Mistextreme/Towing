Config = {}

-- Jobs autorizados
Config.AuthorizedJobs = {
    'tow',
    'mechanic',
    'police',
    'sheriff'
}

-- Veículos com rampas móveis (com controle de braço/rampa)
Config.MovableRamps = {
    ['flatbed'] = {
        name = 'Flatbed',
        rampControl = 'bulldozer_arm', -- Tipo de controle
        attachBone = 'chassis',
        maxRampAngle = 30.0,
        deployTime = 5000,
        retractTime = 4000,
        attachOffset = vec3(0.0, -2.5, 0.3),
        autoLevel = true
    },
    ['towtruck'] = {
        name = 'Guincho',
        boomControl = 'bulldozer_arm',
        winchBone = 'winch',
        attachBone = 'chassis',
        maxBoomHeight = 2.5,
        winchRange = 15.0,
        winchSpeed = 0.1,
        attachOffset = vec3(0.0, -1.5, 0.2)
    }
}

-- Veículos com rampas fixas (deploy)
Config.FixedRamps = {
    ['flatbed'] = {
        name = 'Flatbed com Rampa Fixa',
        rampModel = 'prop_flatbed_ramp',
        deployBone = 'chassis',
        deployOffset = vec3(0.0, -8.0, -1.0),
        deployRotation = vec3(180.0, 180.0, 0.0),
        attachOffset = vec3(0.0, -2.0, 0.2),
        attachBone = 'chassis'
    }
}

-- Configurações de Attach
Config.Attach = {
    maxDistance = 5.0,
    defaultHeight = 0.2,
    rotationOffset = vec3(0.0, 0.0, 0.0),
    autoLevel = true,
    moveWithRamp = true
}

-- Configurações de Guincho
Config.Winch = {
    maxRange = 20.0,
    cableSpeed = 0.5,
    cableThickness = 0.05,
    cableColor = { r = 255, g = 255, b = 255 },
    retractSpeed = 0.1
}

-- Modo de Edição
Config.Editor = {
    laserColor = { r = 255, g = 0, b = 0 },
    markerColor = { r = 0, g = 255, b = 0 },
    selectionColor = { r = 255, g = 255, b = 0 },
    measurementColor = { r = 0, g = 0, b = 255 }
}

-- Mensagens
Config.Locale = {
    notAuthorized = 'Você não tem permissão para usar esta funcionalidade!',
    notInVehicle = 'Você precisa estar em um veículo!',
    notDriver = 'Você precisa estar no assento do motorista!',
    noVehicleNearby = 'Nenhum veículo próximo para rebocar!',
    vehicleAlreadyAttached = 'Este veículo já está attachado!',
    attachSuccess = 'Veículo rebocado com sucesso!',
    detachSuccess = 'Veículo desrebocado com sucesso!',
    deployRamp = 'Rampa sendo deployada...',
    retractRamp = 'Rampa sendo recolhida...',
    rampDeployed = 'Rampa totalmente estendida!',
    rampRetracted = 'Rampa totalmente recolhida!',
    useWinch = 'Use o laser para selecionar o ponto de fixação no segundo veículo. Pressione E para confirmar.',
    winchAttached = 'Cabo de reboque conectado! Iniciando recolhimento...',
    winchSuccess = 'Veículo rebocado com sucesso!',
    editorMode = 'Modo de edição ativado. Use as teclas de seta para mudar de modo.',
    editorSaved = 'Configuração salva com sucesso!',
    editorClosed = 'Modo de edição encerrado'
}