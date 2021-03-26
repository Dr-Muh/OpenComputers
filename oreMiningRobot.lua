local os = require("os")
local thread = require("thread")
local event = require("event")
local robot = require("robot")
local sides = require("sides")


function checkInventory()
    for i=1, 16 do
        if robot.count(i) > 0 then
            return false
        end
    end
    return true
end

function dropItems()
    for i=1, 16 do
        robot.select(i)
        robot.dropDown(64)
    end
end

function main()
    mainThread = thread.create(function()
        while true do
            robot.swing(sides.front)
            if checkInventory() then
                dropItems()
            end
        end
    end)
    print("hi")
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
