RegisterNetEvent( "flatbed:client:attach", function ( flatbedNetId )
	local flatbedEntity = NetworkGetEntityFromNetworkId( flatbedNetId )
	if not DoesEntityExist( flatbedEntity ) then return end

	Function:AttachVehicleToBed( flatbedEntity )
end )

RegisterNetEvent( "flatbed:client:detach", function ( flatbedNetId )
	local flatbedEntity = NetworkGetEntityFromNetworkId( flatbedNetId )
	if not DoesEntityExist( flatbedEntity ) then return end

	Function:DetachVehicleToBed( flatbedEntity )
end )

AddStateBagChangeHandler( "flatbed:initCoords", nil, function ( bagName, _, initPos )
	local vehicleEntity = GetEntityFromStateBagName( bagName )
	if not DoesEntityExist( vehicleEntity ) then
		return
	end

	SetVehicleBulldozerArmPosition( vehicleEntity, initPos, false )
	ActivatePhysics( vehicleEntity )
end )