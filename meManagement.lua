local os = require("os")
local thread = require("thread")
local component = require("component")

local adapter = component.proxy("41d6298c-f468-45b0-bf2f-47f678419db2")

local meAutoCrafts = {{name = "calculationProcessor", goal = 16},
                        {name = "engineeringProcessor", goal = 16},
                        {name = "logicProcessor", goal = 16}}

function testForCraft()
    for itemToCraft in meAutoCrafts do
        print(itemToCraft.name)
        print(itemToCraft.goal)
    end
end

function main()
    testForCraft()
end

main()
