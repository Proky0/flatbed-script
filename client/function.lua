Function = {}

---@param flatbedEntity number
function Function:IsVehicleInBed( flatbedEntity )
	local flatbedModel = GetEntityModel( flatbedEntity )
	local flatbedSize = Shared.Models[flatbedModel].size

	local miscAIndex = GetEntityBoneIndexByName( flatbedEntity, "misc_a" )
	if miscAIndex == -1 then
		return nil
	end

	local centerPos = GetWorldPositionOfEntityBone( flatbedEntity, miscAIndex )

	local vehiclePool = GetGamePool( "CVehicle" )
	local vehicleClosest = table.find_if( vehiclePool, function ( vehicle )
		local vehicleEntity = vehicle
		local vehicleCoords = GetEntityCoords( vehicleEntity )
		local vehicleExist = DoesEntityExist( vehicleEntity )

		if not vehicleExist or vehicleEntity == flatbedEntity then
			return false
		end

		local relativePos = GetOffsetFromEntityGivenWorldCoords( flatbedEntity, vehicleCoords )
		local localMiscA = GetOffsetFromEntityGivenWorldCoords( flatbedEntity, centerPos )

		local diffX = math.abs( relativePos.x - localMiscA.x )
		local diffY = math.abs( relativePos.y - localMiscA.y )
		local diffZ = math.abs( relativePos.z - localMiscA.z )

		return
			diffX <= flatbedSize.width and
			diffY <= flatbedSize.length and
			diffZ <= flatbedSize.height
	end )

	if vehicleClosest == nil then
		return
	end

	return NetworkGetNetworkIdFromEntity( vehicleClosest )
end

---@param flatbedEntity number
function Function:AttachVehicleToBed( flatbedEntity )
	local vehicleNetId = self:IsVehicleInBed( flatbedEntity )

	local vehicleEntity = NetworkGetEntityFromNetworkId( vehicleNetId )
	if not DoesEntityExist( vehicleEntity ) then
		return
	end

	NetworkRequestControlOfNetworkId( vehicleNetId )
	while not NetworkHasControlOfNetworkId( vehicleNetId ) do
		Wait( 0 )
	end

	NetworkRequestControlOfEntity( vehicleEntity )
	while not NetworkHasControlOfEntity( vehicleEntity ) do
		Wait( 0 )
	end

	local vehicleModel = GetEntityModel( vehicleEntity )
	local vehicleCoords = GetEntityCoords( vehicleEntity )
	local vehicleRotation = GetEntityRotation( vehicleEntity, 2 )

	local flatbedModel = GetEntityModel( flatbedEntity )
	local flatbedRotation = GetEntityRotation( flatbedEntity, 2 )
	local flatbedBone = GetEntityBoneIndexByName( flatbedEntity, "misc_a" )
	local flatbedOffset = Shared.Models[flatbedModel].offsets

	local rotationOffsetZ = math.abs( vehicleRotation.z - flatbedRotation.z )
	local minDim, maxDim = GetModelDimensions( vehicleModel )

	AttachEntityToEntity(
		vehicleEntity,
		flatbedEntity,
		flatbedBone,
		flatbedOffset.x,
		flatbedOffset.y,
		-minDim.z + flatbedOffset.z,
		0.0,
		0.0,
		rotationOffsetZ,
		false,
		false,
		false,
		false,
		2,
		true
	)

	SetVehicleEngineOn( vehicleEntity, false, false, true )

	Entity( flatbedEntity ).state:set( "flatbed:attached", true, true )
	Entity( flatbedEntity ).state:set( "flatbed:vehicle", vehicleNetId, true )
end

---@param flatbedEntity number
function Function:DetachVehicleToBed( flatbedEntity )
	local isVehicleAttached = Entity( flatbedEntity ).state["flatbed:attached"]
	if not isVehicleAttached then
		return
	end

	local vehicleNetId = Entity( flatbedEntity ).state["flatbed:vehicle"]
	local vehicleEntity = NetworkGetEntityFromNetworkId( vehicleNetId )

	if not DoesEntityExist( vehicleEntity ) then
		return
	end

	NetworkRequestControlOfNetworkId( vehicleNetId )
	while not NetworkHasControlOfNetworkId( vehicleNetId ) do
		Wait( 0 )
	end

	NetworkRequestControlOfEntity( vehicleEntity )
	while not NetworkHasControlOfEntity( vehicleEntity ) do
		Wait( 0 )
	end

	local vehicleCoords = GetEntityCoords( vehicleEntity )
	local vehicleRotation = GetEntityRotation( vehicleEntity, 2 )

	DetachEntity( vehicleEntity, false, false )

	SetEntityCoordsNoOffset( vehicleEntity, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, false, false, false )
	SetEntityRotation( vehicleEntity, vehicleRotation.x, vehicleRotation.y, vehicleRotation.z, 2, true )

	Entity( flatbedEntity ).state:set( "flatbed:attached", false, true )
	Entity( flatbedEntity ).state:set( "flatbed:vehicle", nil, true )
end

function Function:IsVehicleAttached( flatbedEntity )
	local vehicleNetId = Entity( flatbedEntity ).state["flatbed:vehicle"] or nil
	local vehicleNetworkExist = NetworkDoesEntityExistWithNetworkId( vehicleNetId )
	if not vehicleNetworkExist then
		return false
	end

	local vehicleEntity = NetworkGetEntityFromNetworkId( vehicleNetId )
	local vehicleExist = DoesEntityExist( vehicleEntity )
	if not vehicleExist then
		return false
	end

	return true
end

---@param flatbedEntity number
---@param coords vector3
function Function:CanInteractWithWheels( flatbedEntity, coords )
	local rearLeftWheel = GetEntityBoneIndexByName( flatbedEntity, "wheel_lr" )
	local rearRightWheel = GetEntityBoneIndexByName( flatbedEntity, "wheel_rr" )

	local leftWheelCoord = GetEntityBonePosition_2( flatbedEntity, rearLeftWheel )
	local rightWheelCoord = GetEntityBonePosition_2( flatbedEntity, rearRightWheel )

	local isClosestLeftWheel = #(leftWheelCoord - coords) <= 1.5
	local isClosestRightWheel = #(rightWheelCoord - coords) <= 1.5

	local isMoving = Entity( flatbedEntity ).state["flatbed:moving"] or false
	if isMoving then return false end

	if isClosestLeftWheel then return true end
	if isClosestRightWheel then return true end

	return false
end

-- # Ox Locales # --

lib.locale()

-- ## Ox Target ## --

exports.ox_target:addModel( { `flatbed3`, `muler` }, {
	-- * Lowered & Raises * --
	{
		icon = "fa-solid fa-car-side",
		label = locale( "lower_bed" ),
		canInteract = function ( entity, distance, coords )
			return
				Function:CanInteractWithWheels( entity, coords ) and
				not Entity( entity ).state["flatbed:lowered"]
		end,
		onSelect = function ( data )
			local flatbedEntity = data.entity
			local flatbedNetId = NetworkGetNetworkIdFromEntity( flatbedEntity )

			local flatbedExist = DoesEntityExist( flatbedEntity )
			if not flatbedExist then
				return
			end

			TriggerServerEvent( "flatbed:server:setBedStatus", flatbedNetId, true )
		end
	},
	{
		icon = "fa-solid fa-car-side",
		label = locale( "raise_bed" ),
		canInteract = function ( entity, distance, coords )
			return
				Function:CanInteractWithWheels( entity, coords ) and
				Entity( entity ).state["flatbed:lowered"]
		end,
		onSelect = function ( data )
			local flatbedEntity = data.entity
			local flatbedNetId = NetworkGetNetworkIdFromEntity( flatbedEntity )

			local flatbedExist = DoesEntityExist( flatbedEntity )
			if not flatbedExist then
				return
			end

			TriggerServerEvent( "flatbed:server:setBedStatus", flatbedNetId, false )
		end
	},

	-- * Attach & Detach * --
	{
		icon = "fa-solid fa-car-side",
		label = locale( "attach_vehicle" ), -- Traduit
		canInteract = function ( entity, distance, coords )
			return
				not Entity( entity ).state["flatbed:moving"] and
				Entity( entity ).state["flatbed:lowered"] and
				not Function:IsVehicleAttached( entity )
		end,
		onSelect = function ( data )
			local flatbedEntity = data.entity
			local flatbedNetId = NetworkGetNetworkIdFromEntity( flatbedEntity )

			local flatbedExist = DoesEntityExist( flatbedEntity )
			if not flatbedExist then
				return
			end

			TriggerServerEvent( "flatbed:server:attach", flatbedNetId )
		end
	},
	{
		icon = "fa-solid fa-car-side",
		label = locale( "detach_vehicle" ), -- Traduit
		canInteract = function ( entity, distance, coords )
			return
				not Entity( entity ).state["flatbed:moving"] and
				Entity( entity ).state["flatbed:lowered"] and
				Function:IsVehicleAttached( entity )
		end,
		onSelect = function ( data )
			local flatbedEntity = data.entity
			local flatbedNetId = NetworkGetNetworkIdFromEntity( flatbedEntity )

			local flatbedExist = DoesEntityExist( flatbedEntity )
			if not flatbedExist then
				return
			end

			TriggerServerEvent( "flatbed:server:detach", flatbedNetId )
		end
	},
} )