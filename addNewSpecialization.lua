-- Original code and functionality by: monteur1 (Variable Spray Usage mod)
-- Modified by scottyp, 2020-01-27
-- Used to attach variable speed limit functionality to relevant implements
g_specializationManager:addSpecialization("variableImplementSpeed", "variableImplementSpeed", g_currentModDirectory.."variableImplementSpeed.lua")

addNewSpecialization = {}

function addNewSpecialization:register(name)
    local matchTypes = {"Baler", "Cultivator", "Cutter", "FertilizingCultivator", "FertilizingSowingMachine", "ForageWagon", "FruitPreparer", "Mower", "Pickup", "Plow", "SowingMachine", "Sprayer", "Tedder", "TreePlanter", "Weeder", "Windrower"}
    for k, vehicle in pairs(g_vehicleTypeManager:getVehicleTypes()) do
        local typeMatch = false;
        local variableImplementSpeed = false;
        for _, spec in pairs(vehicle.specializationNames) do
            for i,v in ipairs(matchTypes) do
               if (string.lower(spec) == string.lower(v)) then
                  typeMatch = true
               end
            end
            --if string.lower(spec) == "sprayer" or string.lower(spec) == "baler" or string.lower(spec) == "cutter" then -- check for correct implement type
            --    typeMatch = true;
            --end
            
            if spec == "variableImplementSpeed" then -- don't insert if already inserted
                variableImplementSpeed = true;
            end
            
        end    
        if typeMatch and not variableImplementSpeed then
			print("  adding variableImplementSpeed to vehicleType '"..tostring(k).."'")		
            g_vehicleTypeManager:addSpecialization(vehicle.name, "FS19_VariableImplementSpeed.variableImplementSpeed")
        end
    end

end

VehicleTypeManager.finalizeVehicleTypes = Utils.prependedFunction(VehicleTypeManager.finalizeVehicleTypes, addNewSpecialization.register)

function addNewSpecialization:onDraw(isActiveForInput, isSelected)
    local spec = self.spec_attacherJoints
    if self == g_currentMission.controlledVehicle then
        --recursive call draw on implements attached to implements
        local function allImplements(localSpec)
            for _, implement in ipairs(localSpec.attachedImplements) do
                local object = implement.object
                if object ~= nil then
                    if object.draw ~= nil then
                        object.draw(object, isActiveForInput, isSelected)
                    end
                end
                if object.spec_attacherJoints ~= nil then
                    allImplements(object.spec_attacherJoints)                
                end
            end
        end
        -- call draw on all attached implements, selection check is done in the implement
        allImplements(spec)
    end
end

AttacherJoints.onDraw = addNewSpecialization.onDraw 

addModEventListener(addNewSpecialization);


