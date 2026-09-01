local customEventHooks = {}

customEventHooks.validators = {}
customEventHooks.handlers = {}

function customEventHooks.makeEventStatus(validDefaultHandler, validCustomHandlers)
    return {
        validDefaultHandler = validDefaultHandler,
        validCustomHandlers = validCustomHandlers
    }
end

function customEventHooks.updateEventStatus(oldStatus, newStatus)
    if newStatus == nil then
        return oldStatus
    end
    local result = {}
    if newStatus.validDefaultHandler ~= nil then
        result.validDefaultHandler = newStatus.validDefaultHandler
    else
        result.validDefaultHandler = oldStatus.validDefaultHandler
    end
    
    if newStatus.validCustomHandlers ~= nil then
        result.validCustomHandlers = newStatus.validCustomHandlers
    else
        result.validCustomHandlers = oldStatus.validCustomHandlers
    end
    
    return result
end

function customEventHooks.registerValidator(event, callback)
    if customEventHooks.validators[event] == nil then
        customEventHooks.validators[event] = {}
    end
    table.insert(customEventHooks.validators[event], callback)
end

function customEventHooks.registerHandler(event, callback)
    if customEventHooks.handlers[event] == nil then
        customEventHooks.handlers[event] = {}
    end
    table.insert(customEventHooks.handlers[event], callback)
end

--[[
    openz change 0.2.0 (02/09/2026) - one bad script no longer takes the server with it.

    These loops called every registered callback directly. An error in any of them - a nil
    index in a custom script, a helper called with a player who just left - propagated up
    through the event, so the remaining callbacks never ran and, worse, neither did the rest
    of the core handler that raised the event. The cleanup at the end of
    eventHandler.OnPlayerDisconnect is exactly that kind of "rest", which is how a stale
    player could survive a disconnect.

    Each callback is now called under pcall. A failure is reported with the event name, so it
    is visible in the server log instead of silently corrupting state, and the loop carries
    on. A script that throws now breaks only itself.

    The failing callback contributes no event status, which is the conservative choice: a
    validator that crashed has not expressed an opinion, so the default handler stays enabled
    rather than being cancelled by an accident.
]]
local function callHook(event, callback, eventStatus, args)
    local ok, result = pcall(callback, eventStatus, unpack(args))

    if not ok then
        tes3mp.LogMessage(enumerations.log.ERROR,
            "[customEventHooks] a handler for " .. tostring(event) .. " failed: " .. tostring(result))
        return nil
    end

    return result
end

function customEventHooks.triggerValidators(event, args)
    local eventStatus = customEventHooks.makeEventStatus(true, true)
    if customEventHooks.validators[event] ~= nil then
        for _, callback in ipairs(customEventHooks.validators[event]) do
            eventStatus = customEventHooks.updateEventStatus(eventStatus, callHook(event, callback, eventStatus, args))
        end
    end
    return eventStatus
end

function customEventHooks.triggerHandlers(event, eventStatus, args)
    if customEventHooks.handlers[event] ~= nil then
        for _, callback in ipairs(customEventHooks.handlers[event]) do
             eventStatus = customEventHooks.updateEventStatus(eventStatus, callHook(event, callback, eventStatus, args))
        end
    end
end

return customEventHooks
