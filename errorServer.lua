local os = require("os")
local term = require("term")
local thread = require("thread")
local event   = require("event")
local sides = require("sides")
local component = require("component")

local redstoneIO1 = component.proxy("975bae7d-2743-4992-817d-7eef4bbfdb3f")

local modem = component.modem

local errorStates = {}
            errorStates["crafting failed"] = false
            errorStates["mekanism generator fuel low"] = false



function locateLamp(errorMessage, errorValue)
    if errorMessage == "crafting failed" then switchLamp(redstoneIO1, sides.top, errorValue, false)
    elseif errorMessage == "mekanism generator fuel low" then switchLamp(redstoneIO1, sides.right, errorValue, true) 
    end
end

local importantThreadBool = false
local importantThread = thread.create(function()
    while true do
        while importantThreadBool do
            redstoneIO1.setOutput(sides.left, 15)
            os.sleep(1)
            redstoneIO1.setOutput(sides.left, 0)
            os.sleep(1)
        end
        os.sleep(1)
    end
end)

local importantCount = 0
function switchLamp(redstoneIO, ioSide, errorValue, importantBoolean)
    if errorValue then
        redstoneIO.setOutput(ioSide, 15)
    else
        redstoneIO.setOutput(ioSide, 0)
    end
    if importantBoolean then
        if errorValue then
            importantCount = importantCount+1
        else
            importantCount = importantCount-1
        end
        if importantCount>0 then
            importantThreadBool = true
        else
            importantThreadBool = false
        end
    end
end

function main_t()
    local _, _, _, _, _, message, errorState = event.pull("modem_message")
    thread.create(function()
        main_t()
    end)
    if errorStates[message] ~= errorState then
        locateLamp(message, errorState)
    end
    errorStates[message] = errorStates
end

function main()
    modem.open(1)
    redstoneIO1.setOutput({0, 0, 0, 0, 0, 0})

    mainThread = thread.create(function()
        main_t()
    end)
end

main()

while true do
    local id, _, x, y = event.pullMultiple("interrupted")
    if id == "interrupted" then
      print("soft interrupt, closing")

      redstoneIO1.setOutput({0, 0, 0, 0, 1, 0})

      os.exit()
      break
    end
end
