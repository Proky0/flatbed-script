RegisterNetEvent( "flatbed:server:setBedStatus", function ( flatbedNetId, lowered )
	local flatbedEntity = NetworkGetEntityFromNetworkId( flatbedNetId )
	if not DoesEntityExist( flatbedEntity ) then return end

	local flatbedEntityOwnerId = NetworkGetEntityOwner( flatbedEntity )
	if not DoesPlayerExist( flatbedEntityOwnerId ) then return end

	Function:SetBedStatus( flatbedEntity, lowered )
end )

RegisterNetEvent( "flatbed:server:attach", function ( flatbedNetId )
	local flatbedEntity = NetworkGetEntityFromNetworkId( flatbedNetId )
	if not DoesEntityExist( flatbedEntity ) then return end

	local flatbedEntityOwnerId = NetworkGetEntityOwner( flatbedEntity )
	if not DoesPlayerExist( flatbedEntityOwnerId ) then return end

	TriggerClientEvent( "flatbed:client:attach", flatbedEntityOwnerId, flatbedNetId )
end )
RegisterNetEvent( "flatbed:server:detach", function ( flatbedNetId )
	local flatbedEntity = NetworkGetEntityFromNetworkId( flatbedNetId )
	if not DoesEntityExist( flatbedEntity ) then return end

	local flatbedEntityOwnerId = NetworkGetEntityOwner( flatbedEntity )
	if not DoesPlayerExist( flatbedEntityOwnerId ) then return end

	TriggerClientEvent( "flatbed:client:detach", flatbedEntityOwnerId, flatbedNetId )
end )