local inet = require("internet")
local os = require("os")
local term = require("term")
local thread = require("thread")

local colors = require("colors")
local component = require("component")
local gpu = component.gpu
local unicode = require("unicode")


local TimeCorrectionFactorInSeconds = 8     -- Zeitverzögerung durch Serveranfrage 


local Time = {year = 0, month = 0, monthName = "", day = 0, dayName = "", hour = 0, minute = 0, second = 0}   -- Zeitvariable

function displayLoading_f()   -- zeigt eine Ladeanimation
  displayString = {"loading.", "loading .", "loading  ."}
  while true do
    for i = 1, 3 do
      term.clear()
      print(displayString[i])
      os.sleep(1)
    end
  end
end


local body = ""
function loadTime_f()     -- läd einen Websitequelltext herunter und speichert einen Teil davon, in dem die Zeitvariable vorkommt in body
--  print("start load")
  body = ""

  local response = inet.request("https://www.worldtimeserver.com/current_time_in_DE.aspx")
  os.sleep(0)

  body = ""

  for chunk in response do
    if string.match(chunk, "theTime") then
      body = body .. chunk
      break
    end

  end

  booting = false
end

function table.indexOf(t, object)         -- indexOf Hilfsfunktion
  if type(t) ~= "table" then error("table expected, got " .. type(t), 2) end

  for i, v in pairs(t) do
      if object == v then
          return i
      end
  end
end

function createTimeVariable()
  timeStringA, timeStringB = string.find(body, "Server Time with seconds:")   -- Uhrzeit in Bestandteile zerlegen und in Time speichern
  timeString = string.sub(body, timeStringB+4, timeStringB+11)
  Time.hour = tonumber(string.sub(timeString, 1, 2))
  Time.minute = tonumber(string.sub(timeString, 4, 5))
  Time.second = tonumber(string.sub(timeString, 7, 8)) + TimeCorrectionFactorInSeconds

  dateStringA, dateStringB = string.find(body, "<h4>")          -- Datum String herausfiltern
  dateStringC, dateStringD = string.find(body, "</h4>")
  dateString = string.sub(body, dateStringB+2, dateStringC-1)

  dateStringCP = dateString                       -- Datum String in Bestandteile zerlegen
  dayStringA = string.find(dateStringCP, ",")
  Time.dayName = string.sub(dateStringCP, 0, dayStringA-1)
  dateStringCP = string.sub(dateStringCP, dayStringA+2, string.len(dateStringCP))
  dayStringA = string.find(dateStringCP, ",")
  Time.monthName = string.sub(dateStringCP, 0, dayStringA-4)
  Time.day = tonumber(string.sub(dateStringCP, dayStringA-3, dayStringA-1))
  dateStringCP = string.sub(dateStringCP, dayStringA+2, string.len(dateStringCP))
  Time.year = tonumber(dateStringCP)

  dayNames = {"Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"}    -- Uebersetzungstabelle
  dayNamesE = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
  monthNames = {"Januar", "Februar", "Merz", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"}
  monthNamesE = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "Oktober", "November", "December"}

                                  -- Uebersetzung
  Time.dayName = dayNames[table.indexOf(dayNamesE, Time.dayName)]
  Time.month = table.indexOf(monthNamesE, Time.monthName)
  Time.monthName = monthNames[Time.month]

  term.clear()
  print(timeString)
  print(dateString)
--  print(Time.dayName)
--  print(Time.monthName)
--  print(Time.day)
--  print(Time.year)
end

function clock()

  displayLoading = thread.create(function()   -- Aufruf Ladeanimation
    displayLoading_f()
  end)
  loadTime = thread.create(function()         -- Aufruf Zeitdownload
    loadTime_f()
  end)
  thread.waitForAll({loadTime})               -- Wenn zeit gedownloaded, weitermachen
  displayLoading:suspend()                    -- Ladeanimation stoppen

  createTimeVariable()                        -- Time variablen belegen

  --dofile("clock")
end

--clock()

local refreshing = false
function refreshTime()      -- gleich wie clock() nur ohne Ladeanimation

  if refreshing then        -- keine Doppeltausfuehrung
    return
  end
  refreshing = true

  loadTime = thread.create(function()         -- Aufruf Zeitdownload
    loadTime_f()
  end)
  thread.waitForAll({loadTime})               -- Wenn zeit gedownloaded, weitermachen
  displayLoading:suspend()                    -- Ladeanimation stoppen

  createTimeVariable()                        -- Time variablen belegen

  refreshing = false
end

-- Bis hier her geht der Code um die RTC von einer Website zu ziehen

-- Code um die Uhr weiter zu zaehlen

local TimeCounting = Time             -- counted clock

function addSeconds_f()               -- function for thread to count clock
  while true do
    os.sleep(1)
    Time.second = Time.second + 1
    if Time.second > 59 then
      Time.second = Time.second - 60
      Time.minute = Time.minute + 1
      refreshCheck()
      if Time.minute > 59 then
        Time.minute = Time.minute - 60
        Time.hour = Time.hour + 1
        if Time.hour > 23 then
          refreshTime()
        end
      end
    end
  end
end

local lastRefreshTime = 0
function refreshCheck()
  lastRefreshTime = lastRefreshTime + 1
  if lastRefreshTime > 15 then
    refreshTime()
  end
end

function count()          -- main counting function

  addSeconds = thread.create(function()
    addSeconds_f()
  end)

  os.sleep(2)

  while false do
    term.clear()
    print(tostring(Time.hour) .. ":" .. tostring(Time.minute) .. ":" .. tostring(Time.second))
    print(Time.dayName .. ", " .. Time.monthName .. " " .. Time.day .. ", " .. Time.year)
    os.sleep(0.5)
  end

end

--count()

-- Ab hier kommt Code um die Uhr anzuzeigen

MT_BG    = 0x000000
MT_FG    = 0xFFFFFF
DAY      = 0xFFFF00
EVENING  = 0x202080
NIGHT    = 0x000080
MORNING  = 0x404000
RT_BG    = 0x000000
RT_FG    = 0xFFFFFF
TIMEZONE = 0
CORRECT  = 0
W, H     = 40, 8
REDSTONE = false
TOUCH    = true
KEY1     = 13
KEY2     = 28
SHOWSECS = true
AUTOMODE = true
SWDATEMT = true
SWDATERT = true
SWDTMMT  = true
SWDTMRT  = true

oldw, oldh = gpu.getResolution()
--gpu.setResolution(W, H)
w, h = gpu.getResolution()
mode = AUTOMODE
noExit = true

local nums = {}
nums[0] = {"███", "█ █", "█ █", "█ █", "███"}
nums[1] = {"██ ", " █ ", " █ ", " █ ", "███"}
nums[2] = {"███", "  █", "███", "█  ", "███"}
nums[3] = {"███", "  █", "███", "  █", "███"}
nums[4] = {"█ █", "█ █", "███", "  █", "  █"}
nums[5] = {"███", "█  ", "███", "  █", "███"}
nums[6] = {"███", "█  ", "███", "█ █", "███"}
nums[7] = {"███", "  █", "  █", "  █", "  █"}
nums[8] = {"███", "█ █", "███", "█ █", "███"}
nums[9] = {"███", "█ █", "███", "  █", "███"}

dts = {}
dts[1] = "Night"
dts[2] = "Morning"
dts[3] = "Day"
dts[4] = "Evening"

local function centerX(str)
  local len
  if type(str) == "string" then
    len = unicode.len(str)
  elseif type(str) == "number" then
    len = str
  else
    error("Number excepted")
  end
  local whereW, _ = math.modf(w / 2)
  local whereT, _ = math.modf(len / 2)
  local where = whereW - whereT + 1
  return where
end

local function centerY(lines)
  local whereH, _ = math.modf(h / 2)
  local whereT, _ = math.modf(lines / 2)
  local where = whereH - whereT + 1
  return where
end

local function sn(num)
  -- SplitNumber
  local n1, n2
  if num >= 10 then
    n1, n2 = tostring(num):match("(%d)(%d)")
    n1, n2 = tonumber(n1), tonumber(n2)
  else
    n1, n2 = 0, num
  end
  return n1, n2
end

local function drawNumbers(hh, mm, ss)
  local firstLine = centerY(5)
  local n1, n2, n3, n4, n5, n6
  n1, n2 = sn(hh)
  n3, n4 = sn(mm)
  if ss ~= nil then
    n5, n6 = sn(ss)
  end
--print(n1, n2, n3, n4, n5, n6, type(n1))
  for i = 1, 5, 1 do
    local sep
    if i == 2 or i == 4 then
      sep = " . "
    else
      sep = "   "
    end
    local lineToDraw = ""
    if ss ~= nil then
      lineToDraw = nums[n1][i] .. "  " .. nums[n2][i] .. sep .. nums[n3][i] .. "  " .. nums[n4][i] .. sep .. nums[n5][i] .. "  " .. nums[n6][i]
    else
      lineToDraw = nums[n1][i] .. "  " .. nums[n2][i] .. sep .. nums[n3][i] .. "  " .. nums[n4][i]
    end
    gpu.set(centerX(lineToDraw), firstLine + i - 1, lineToDraw)
  end
end

local function setDaytimeColor(hh, mm)
  local daytime
  if (hh == 19 and mm >= 30) or (hh > 19 and hh < 22) then
    daytime = 4
    gpu.setForeground(EVENING)
  elseif hh >= 22 or hh < 6 then
    daytime = 1
    gpu.setForeground(NIGHT)
  elseif hh >= 6 and hh < 12 then
    daytime = 2
    gpu.setForeground(MORNING)
  elseif (hh >= 12 and hh < 19) or (hh == 19 and mm < 30) then
    daytime = 3
    gpu.setForeground(DAY)
  end
end

local function drawRT()
  local year, month, day, wd, hh, mm, ss = Time.year, Time.month,Time.day, Time.dayName, Time.hour, Time.minute, Time.second
  gpu.fill(1, 1, w, h, " ")
  --hh, mm, ss = tonumber(hh), tonumber(mm), tonumber(ss)
  if not SHOWSECS then
    ss = nil
  end
  drawNumbers(hh, mm, ss)
  if SWDTMRT then
    local dtm = setDaytimeColor(hh, mm)
    gpu.set(centerX(dts[dtm]), centerY(5) - 1, dts[dtm])
  end
  gpu.setForeground(RT_FG)
  local infoLine = wd .. ", " .. year .. "/" .. month .. "/" .. day .. "::GMT" .. TIMEZONE
  if SWDATERT then
  gpu.set(centerX(infoLine), centerY(1) + 3, infoLine)
  end
end

while true do
  drawRT()
  os.sleep(0.5)
end



--[[
function drawPixel(x, y)
  gpu.fill(1, 1, x, y, "█")
end

function show()
  
  local w, h = gpu.getResolution()
  gpu.fill(1, 1, w, h, " ") -- clears the screen
  gpu.setForeground(0x000000)
  gpu.setBackground(0xFFFFFF)
--  gpu.fill(1, 1, w/2, h/2, "X") -- fill top left quarter of screen
--  gpu.copy(1, 1, w/2, h/2, w/2, h/2)

  gpu.fill(1, 1, 10, 10, "█")

--  gpu.setBackground(colors.green, true)
end

show()]]--
