Function = {}

---@param flatbedEntity number
---@param lowered boolean
function Function:SetBedStatus( flatbedEntity, lowered )
	local isBedMoving = Entity( flatbedEntity ).state["flatbed:moving"] or false
	if isBedMoving then
		return
	end

	local flatbedModel = GetEntityModel( flatbedEntity )

	local flatbedOpenCoords = Shared.Models[flatbedModel].openedCoords
	local flatbedClosedCoords = Shared.Models[flatbedModel].closedCoords

	local currentBedPosition = Entity( flatbedEntity ).state["flatbed:initCoords"] or flatbedClosedCoords
	local targetBedPosition = lowered and flatbedOpenCoords or flatbedClosedCoords
	local movementDirection = lowered and 1 or -1

	Entity( flatbedEntity ).state:set( "flatbed:initCoords", currentBedPosition, true )
	Entity( flatbedEntity ).state:set( "flatbed:moving", true, true )
	Entity( flatbedEntity ).state:set( "flatbed:lowered", lowered, true )

	if not lowered then
		FreezeEntityPosition( flatbedEntity, lowered )
	end

	CreateThread( function ( threadId )
		while math.abs( currentBedPosition - targetBedPosition ) > 0.001 do
			currentBedPosition += (Shared.MovementSpeed * movementDirection)
			Entity( flatbedEntity ).state:set( "flatbed:initCoords", currentBedPosition, true )

			Wait( Shared.AnimationDelay )
		end

		Entity( flatbedEntity ).state:set( "flatbed:initCoords", currentBedPosition, true )
		Entity( flatbedEntity ).state:set( "flatbed:moving", false, true )
		Entity( flatbedEntity ).state:set( "flatbed:lowered", lowered, true )

		if lowered then
			FreezeEntityPosition( flatbedEntity, true )
		end
	end )
end