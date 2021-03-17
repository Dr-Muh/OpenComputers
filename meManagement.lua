local os = require("os")
local thread = require("thread")
local component = require("component")

local meController = component.me_controller

local meAutoCrafts = {}
            meAutoCrafts["Calculation Processor"] = 16
            meAutoCrafts["Engineering Processor"] = 16
            meAutoCrafts["Logic Processor"] = 16



function construct(itemName, amount, itemTable)
    if amount>0 then
        craftables = meController.getCraftables()
        for i, craftable in pairs(craftables) do
            if i~="n" then
                craftableLabel = craftable.getItemStack()["label"]
                if craftableLabel==itemName then
                    print("produce: " .. craftableLabel .. " x " .. amount)
                    craftable.request(amount)
                    do return end
                end
            end
        end
    end
end

function testAmount(itemName, itemCount, itemTable)
    goal = meAutoCrafts[itemName]
    if goal ~= nil then
        print(itemName .. " " .. itemCount .. " " .. goal)
        construct(itemName, goal-itemCount, itemTable)
    end
end

function readME(itemsInNetwork)
    for i, itemTable in pairs(itemsInNetwork) do
        if type(itemTable)=="table" then
            itemCount = itemTable["size"]
            itemName = itemTable["label"]
            testAmount(itemName, itemCount, itemTable)
        end
    end
end

function main()
    itemsInNetwork = meController.getItemsInNetwork()
    readME(itemsInNetwork)
end

main()
