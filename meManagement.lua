local os = require("os")
local thread = require("thread")
local component = require("component")

local meController = component.me_controller

local meAutoCrafts = {}
            meAutoCrafts["Calculation Processor"] = 16
            meAutoCrafts["Engineering Processor"] = 16
            meAutoCrafts["Logic Processor"] = 16
            meAutoCrafts["Enriched Alloy"] = 32
            meAutoCrafts["Reinforced Alloy"] = 32
            meAutoCrafts["Atomic Alloy"] = 32
            meAutoCrafts["Glass"] = 32
            meAutoCrafts["Quartz Glass"] = 16
            meAutoCrafts["Bread"] = 128
            meAutoCrafts["Steel Ingot"] = 32
            meAutoCrafts["Water Bucket"] = 2
            meAutoCrafts["Refined Obsidian Dust"] = 8
            meAutoCrafts["Speed Upgrade"] = 8
            meAutoCrafts["Energy Upgrade"] = 8
            meAutoCrafts["Elite Universal Cable"] = 32
            meAutoCrafts["Muffling Upgrade"] = 4



local craftingStatus = {}
for k, v in pairs(meAutoCrafts) do
    craftingStatus[k] = nil
end

function construct(itemName, amount, itemID)
    if amount>0 then
        craftables = meController.getCraftables()
        for i, craftable in pairs(craftables) do
            if i~="n" then
                itemStack = craftable.getItemStack()
                craftableLabel = itemStack["label"]
                craftableID = itemStack["name"]
                if (craftableLabel==itemName) and (craftableID==itemID) then
                    if craftingStatus[craftableLabel]~=nil then
                        if (not craftingStatus[craftableLabel].isCanceled()) and (not craftingStatus[craftableLabel].isDone()) then
                            print(craftableLabel .. " already in progress")
                            return
                        end
                    end
                    print("need to produce: " .. craftableLabel .. " x " .. amount)
                    craftingStatus[craftableLabel] = craftable.request(amount)
                    return
                end
            end
        end
    end
end

function testAmount(itemName, itemCount, itemID)
    goal = meAutoCrafts[itemName]
    if goal ~= nil then
        print(itemName .. " " .. itemCount .. " " .. goal)
        construct(itemName, goal-itemCount, itemID)
    end
end

function readME(itemsInNetwork)
    for i, itemTable in pairs(itemsInNetwork) do
        if type(itemTable)=="table" then
            itemCount = itemTable["size"]
            itemName = itemTable["label"]
            itemID = itemTable["name"]
            testAmount(itemName, itemCount, itemID)
        end
    end
end

function main()
    while true do
        itemsInNetwork = meController.getItemsInNetwork()
        readME(itemsInNetwork)
        os.sleep(30)
    end    
end

main()
