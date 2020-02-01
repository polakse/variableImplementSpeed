-- variableimplementSpeed specialization for FS19
--
-- Enables adjustment of implement speed limit without have to create a separate mod for each implement.
--
-- Author: scottyp
-- Credits: Idea and code structure: monteur1 (Variable Spray Usage mod), thanks!

variableImplementSpeed = {};
variableImplementSpeed.g_currentModDirectory = g_currentModDirectory

function variableImplementSpeed.prerequisitesPresent(specializations)
    return true
end

function variableImplementSpeed.registerEventListeners(vehicleType)
    EL = vehicleType.eventListeners
    table.insert(EL.onPreLoad, variableImplementSpeed)		
    table.insert(EL.onLoad, variableImplementSpeed)
    table.insert(EL.onPostLoad, variableImplementSpeed)	
    table.insert(EL.onUpdate, variableImplementSpeed)
    table.insert(EL.onUpdateTick, variableImplementSpeed)
    table.insert(EL.onDraw, variableImplementSpeed)
    table.insert(EL.onRegisterActionEvents, variableImplementSpeed)
    table.insert(EL.onReadStream, variableImplementSpeed)
    table.insert(EL.onWriteStream, variableImplementSpeed)
end

function variableImplementSpeed:onPreLoad(savegame)
end

function variableImplementSpeed:getSpeedUnit()
	local distanceUnits =  g_gameSettings.useMiles and g_i18n:getText('unit_miles') or g_i18n:getText('unit_km');
        if (string.lower(distanceUnits) == "kilometers") then
          return "km/h"
        else
          return "MPH"
        end
end

function variableImplementSpeed:onLoad(savegame)
        -- Initialization
	self.variableImplementSpeed = {}
	self.variableImplementSpeed.WorkingWidth       = 1
	self.variableImplementSpeed.SpeedLimit          = 0 -- Speed limit in km/h
        -- Workarea checks and calculations not currently relevant for this speed limit
        -- mod; however, we retain this functionality for possible future use
	self.variableImplementSpeed.HasWorkarea        = false
	self.variableImplementSpeedHasWorkarea         = false
        -- Defaults, km/h
        self.variableImplementSpeed.minSpeedLimit = 2
        self.variableImplementSpeed.maxSpeedLimit = 40
        self.variableImplementSpeed.defaultSpeedLimit = 12
        self.variableImplementSpeed.increment = 2
	
	local key = string.format("vehicle.workAreas.workArea");
	if hasXMLProperty(self.xmlFile, key) then
		self.variableImplementSpeed.HasWorkarea    = true
		self.variableImplementSpeedHasWorkarea     = true
	end
	
	if self.variableImplementSpeed.HasWorkarea == true then
		key = string.format("vehicle.base.speedLimit");
		local initialSpeedLimit = Utils.getNoNil(getXMLInt(self.xmlFile, key.."#value"), self.variableImplementSpeed.defaultSpeedLimit)
                local adjustedSpeedLimit = math.min(math.max(math.floor(initialSpeedLimit/self.variableImplementSpeed.increment+0.5)*self.variableImplementSpeed.increment,self.variableImplementSpeed.minSpeedLimit),self.variableImplementSpeed.maxSpeedLimit)
		self.variableImplementSpeed.SpeedLimit  =  adjustedSpeedLimit
	        --print("speed limit: " .. self.variableImplementSpeed.SpeedLimit)	
		self.variableImplementSpeed.Hud                = {}
		self.variableImplementSpeed.Hud.offset_X       = 0.07
		self.variableImplementSpeed.Hud.offset_Y       = 0.06 --0.03
		
		local currentModDirectory = variableImplementSpeed.g_currentModDirectory	
				
		if savegame ~= nil and not savegame.resetVehicles then
			local key2 = savegame.key ..".FS19_VariableImplementSpeed.variableImplementSpeed"		
			local speedLimit = getXMLInt(savegame.xmlFile, key2.."#speedLimit")
			if speedLimit ~= nil then
				self.variableImplementSpeed.SpeedLimit = speedLimit
			else
				self.variableImplementSpeed.SpeedLimit = self.variableImplementSpeed.defaultSpeedLimit	
			end
		end	
	end	
end

function variableImplementSpeed:onPostLoad(savegame)
end

function variableImplementSpeed:loadFromXMLFile(xmlFile, key)
end

function variableImplementSpeed:saveToXMLFile(xmlFile, key, usedModNames)
	if self.variableImplementSpeed.HasWorkarea == true then
		setXMLInt(xmlFile, key.."#speedLimit", self.variableImplementSpeed.SpeedLimit)
	end
end

function variableImplementSpeed:onUpdateTick(dt, isActiveForInput, isSelected)
end

function variableImplementSpeed:onUpdate(dt, isActiveForInput, isSelected)
  if self:getIsActive() and self.variableImplementSpeed.HasWorkarea == true then
    --local currentSpeed       = self.lastSpeedReal*3600  -- *3600 = km/h -- math.max(3, self.lastSpeedReal*3600)
    local currentSpeedLimit   = self.variableImplementSpeed.SpeedLimit
    --local shiftToMeterPerMin = 16.666
    self.speedLimit = currentSpeedLimit
  end
end

function variableImplementSpeed:onDraw(isActiveForInput, isSelected)
	if self.isClient and self.variableImplementSpeed.HasWorkarea == true then	
		if isActiveForInput then	
			if self.variableImplementSpeed.SpeedLimit ~= nil then		
				local speedLimit = self.variableImplementSpeed.SpeedLimit
				local unit = variableImplementSpeed:getSpeedUnit()
                                if (unit == "MPH") then
                                  speedLimit = math.floor(speedLimit*0.62137)
                                end
				g_currentMission:addExtraPrintText(g_i18n:getText("current_Speedlimit") .." : ".. speedLimit .." ".. unit)
			end
		end
	end		
end

function variableImplementSpeed:onReadStream(streamId, connection)
	if self.variableImplementSpeed.HasWorkarea == true then
		self.variableImplementSpeed.SpeedLimit        = streamReadFloat32(streamId)	
		self.variableImplementSpeedHasWorkarea       = streamReadBool(streamId)			
	end
end

function variableImplementSpeed:onWriteStream(streamId, connection)
	if self.variableImplementSpeed.HasWorkarea == true then
		streamWriteFloat32(streamId, self.variableImplementSpeed.SpeedLimit )	
		streamWriteBool(streamId, self.variableImplementSpeedHasWorkarea )	
	end
end

function variableImplementSpeed:onDelete()
end;

function variableImplementSpeed:onRegisterActionEvents(isSelected, isOnActiveVehicle)
    if isOnActiveVehicle and isSelected and self.variableImplementSpeed.HasWorkarea == true then		
		if self.variableImplementSpeedActionEvents == nil then 
			self.variableImplementSpeedActionEvents = {}
		else	
			self:clearActionEventsTable( self.variableImplementSpeedActionEvents )
		end 

		for _,actionName in pairs({ "INCREASE_SPEEDLIMIT", "DECREASE_SPEEDLIMIT" }) do
			local _, eventName = self:addActionEvent(self.variableImplementSpeedActionEvents, InputAction[actionName], self, variableImplementSpeed.actionCallback, false, true, false, true, nil);			
			g_inputBinding.events[eventName].displayPriority = 1
		end
    end
end

function variableImplementSpeed:actionCallback(actionName, keyStatus, arg4, arg5, arg6)	
	if self.variableImplementSpeed.HasWorkarea == true then 
		if actionName == "INCREASE_SPEEDLIMIT" or actionName == "DECREASE_SPEEDLIMIT" then	
			if actionName == "INCREASE_SPEEDLIMIT" then
				local limit = self.variableImplementSpeed.maxSpeedLimit
				local step  = self.variableImplementSpeed.increment
				
				local currentSpeedLimit = self.variableImplementSpeed.SpeedLimit	
				currentSpeedLimit = currentSpeedLimit + step
                                --print("Trying to increase speed, current speed: ".. self.variableImplementSpeed.SpeedLimit .. ", new speed: "..currentSpeedLimit)
				if currentSpeedLimit <= limit then 
					self.variableImplementSpeed.SpeedLimit = currentSpeedLimit
                                        self.speedLimit = currentSpeedLimit
				end				
			end
			
			if actionName == "DECREASE_SPEEDLIMIT" then
				local limit = self.variableImplementSpeed.minSpeedLimit
				local step  = self.variableImplementSpeed.increment
				
				local currentSpeedLimit = self.variableImplementSpeed.SpeedLimit	
				currentSpeedLimit = currentSpeedLimit - step
                                --print("Trying to decrease speed, current speed: ".. self.variableImplementSpeed.SpeedLimit .. ", new speed: "..currentSpeedLimit)
				if currentSpeedLimit >= limit then 
					self.variableImplementSpeed.SpeedLimit = currentSpeedLimit
                                        self.speedLimit = currentSpeedLimit
				end		
			end
			
			if g_server ~= nil then
				g_server:broadcastEvent(variableImplementSpeedChangeSpeedlimit_Event:new(self, self.variableImplementSpeed.SpeedLimit), nil, nil, self);
			else
				g_client:getServerConnection():sendEvent(variableImplementSpeedChangeSpeedlimit_Event:new(self, self.variableImplementSpeed.SpeedLimit));
			end;				
		end
	end
end

addModEventListener(variableImplementSpeed);

-- For Server Event --
variableImplementSpeedChangeSpeedlimit_Event = {};
variableImplementSpeedChangeSpeedlimit_Event_mt = Class(variableImplementSpeedChangeSpeedlimit_Event, Event);

InitEventClass(variableImplementSpeedChangeSpeedlimit_Event, "variableImplementSpeedChangeSpeedlimit_Event");					
					
function variableImplementSpeedChangeSpeedlimit_Event:emptyNew()
    local self = Event:new(variableImplementSpeedChangeSpeedlimit_Event_mt);
    return self;
end;

function variableImplementSpeedChangeSpeedlimit_Event:new(object, data)
    local self = variableImplementSpeedChangeSpeedlimit_Event:emptyNew()
    self.object = object;
    self.data = data;
    return self;
end;

function variableImplementSpeedChangeSpeedlimit_Event:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId);
    self.data = streamReadFloat32(streamId);
    self:run(connection);
end;

function variableImplementSpeedChangeSpeedlimit_Event:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object);
    streamWriteFloat32(streamId, self.data);
end;

function variableImplementSpeedChangeSpeedlimit_Event:run(connection)
    self.object.variableImplementSpeed.SpeedLimit = self.data;
	
    if not connection:getIsServer() then
        g_server:broadcastEvent(variableImplementSpeedChangeSpeedlimit_Event:new(self.object, self.data), nil, connection, self.object);
    end;
end;

