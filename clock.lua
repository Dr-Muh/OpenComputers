local inet = require("internet")
local os = require("os")
local term = require("term")
local thread = require("thread")

local colors = require("colors")
local component = require("component")
local gpu = component.gpu


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

