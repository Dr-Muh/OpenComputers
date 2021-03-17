local os = require("os")
local thread = require("thread")
local component = require("component")

local adapter = component.proxy("41d6298c-f468-45b0-bf2f-47f678419db2")

local meAutoCrafts = {"calculationProcessor", 16,
                        "engineeringProcessor", 16,
                        "logicProcessor", 16}



function testCount(name, goal)
    
end

function readList()
    for i, v in ipairs(meAutoCrafts) do
        if i%2 ~=0 then
            name = meAutoCrafts[i]
            goal = meAutoCrafts[i+1]
            --print(meAutoCrafts[i] .. " " .. meAutoCrafts[i+1])
            testCount(name, goal)
        end
    end
end

function main()
    readList()
end

main()
