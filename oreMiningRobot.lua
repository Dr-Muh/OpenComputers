local os = require("os")
local thread = require("thread")
local event = require("event")
local robot = require("robot")
local sides = require("sides")


function checkInventory()
    for i=1, 16 do
        robot.select(i)
        if robot.count(i) > 0 then
            robot.select(1)
            return true
        end
    end
    robot.select(1)
    return false
end

function dropItems()
    for i=1, 16 do
        robot.select(i)
        robot.dropDown(64)
    end
    robot.select(1)
end

function main()
    robot.select(1)
    mainThread = thread.create(function()
        while true do
            for i=1, 64 do
                robot.swing(sides.front)
            end
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
