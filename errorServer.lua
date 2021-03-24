local os = require("os")
local term = require("term")
local thread = require("thread")
local component = require("component")

local redstone = component.get("9d1615ea-0b23-4b08-93c6-5a4378e44423")

local modem = component.modem

local gpu = component.gpu
local screenAdress = "202f972d-2cf6-4b70-97d4-7fa09bdae43f"



function main()
    term.clear()
    gpu.bind(screenAdress)
    term.clear()

    mainThread = thread.create(function()
        testThread = thread.create(function()
            while true do
                redstone.setOutput(sides.top, true)
                os.sleep(1)
                redstone.setOutput(sides.top, false)
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
