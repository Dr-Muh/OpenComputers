local os = require("os")
local term = require("term")
local thread = require("thread")
local event   = require("event")
local component = require("component")

local redstone = component.proxy("975bae7d-2743-4992-817d-7eef4bbfdb3f")

local modem = component.modem

local gpu = component.gpu
local screenAdress = "202f972d-2cf6-4b70-97d4-7fa09bdae43f"



function main()
    --term.clear()
    gpu.bind(screenAdress)
    --term.clear()

    mainThread = thread.create(function()
        testThread = thread.create(function()
            while true do
                redstone.setOutput(sides.top, 15)
                os.sleep(1)
                redstone.setOutput(sides.top, 0)
                os.sleep(1)
            end
        end)
    end)
end

main()

while true do
    local id, _, x, y = event.pullMultiple("interrupted")
    if id == "interrupted" then
      print("soft interrupt, closing")
      os.exit()
      break
    end
end
