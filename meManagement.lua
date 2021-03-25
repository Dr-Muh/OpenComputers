local os = require("os")
local term = require("term")
local thread = require("thread")
local event   = require("event")
local component = require("component")

local meController = component.me_controller
local modem = component.modem

local modemReceiverAdress = "969842a8-c66e-41e1-9627-9103ba340afe"

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
            meAutoCrafts["Printed Circuit Board (PCB)"] = 8
            meAutoCrafts["Stick"] = 64
            meAutoCrafts["Block of Coal"] = 64



local craftingStatus = {}
for k, v in pairs(meAutoCrafts) do
    craftingStatus[k] = nil
end

local craftingFailures = {}
for k, v in pairs(meAutoCrafts) do
    craftingFailures[k] = false
end

function testForError(craftingProgress)
    cpuCount = 0
    cpuBusy = 0
    for _, cpu in pairs(meController.getCpus()) do
        if type(cpu)=="table" then
            if cpu["busy"] then
                cpuBusy = cpuBusy+1
            end
        else
            cpuCount = cpu
        end
    end
    --print(cpuCount .. " " .. cpuBusy)
    if craftingProgress.isCanceled() and cpuCount>cpuBusy then
        return true
    else
        return false
    end
end

function testSendMessage(label, failedBool)
    failuresCount = 0
    for _, b in pairs(craftingFailures) do
        if b then
            failuresCount = failuresCount+1
        end
    end

    if failuresCount==0 and failedBool then
        modem.send(modemReceiverAdress, 1, "crafting failed", true)
    elseif failuresCount==1 and (not failedBool) then
        if craftingFailures[label]==true then
            modem.send(modemReceiverAdress, 1, "crafting failed", false)
        end
    end
    craftingFailures[label] = failedBool
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

                    if testForError(craftingStatus[craftableLabel]) then
                        print("Crafting failed: " .. craftableLabel)
                        testSendMessage(craftableLabel, true)
                    else
                        testSendMessage(craftableLabel, false)
                    end
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
    mainThread = thread.create(function()
        while true do
            term.clear()
            itemsInNetwork = meController.getItemsInNetwork()
            readME(itemsInNetwork)
            os.sleep(30)
        end
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
