-- Some handy variables for spacing and width, etc. on different devices
screenW = display.contentWidth
screenH = display.contentHeight
centerX  = display.contentWidth/2
centerY = display.contentHeight/2

local widget = require("widget")
-- We'll maek a GUI group to insert our debug
-- stuff into....
GUILayer = display.newGroup()
-- Make a background rectangle to put the debugText over
-- for easy viewing
local tempRect = display.newRect(0,0,screenW,100)
tempRect:setFillColor(0,0,0)

-- Our offsets for when faking our hex map...
local yOffset = 115
local xOffset = 98

-- For some path tracing stuff we're doing later
local oldX = 1 -- For our puroses, set the oldX and 
local oldY = 1 -- oldY values to 1,1 on our map...

-- Mapstyle for if we're doing hex or tile based map
local hexMapStyle = false

-- The fabulous Jumper library for pathfinding on our grid. 
-- http://developer.coronalabs.com/code/Jumper-fast-2d-pathfinder-grid-based-games
-- or
-- https://github.com/Yonaba/Jumper
-- Note, the Jumper lib doesnt know our map is a hex map,
-- that's the beauty of faking our hexes by using the offsets
-- above. However, it can lead to some wonky results like
-- not QUITE taking the shortest route, etc. Your results may
-- vary
local Jumper = require("Jumper")

-- Create a container to put all our graphics in; a 'display group'.
local gameBoard = display.newGroup()
gameBoard.xScale = 0.5
gameBoard.yScale = 0.5

-- Create a temporary blue circle to represent
-- our player....just for fun...you could make it
-- a graphic too.
local tempPlayer = display.newCircle( 0, 0, 50)
tempPlayer:setFillColor(0,0,255)

-- Insert the tempPlayer circle into our
-- display group: gameBoard
gameBoard:insert(tempPlayer)

-- Different from our previous hex map examples
-- we're using a table of just numbers for our 
-- map.
local map = {
     {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
     {1,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1,0,0,0,1},
     {1,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1,0,0,0,1},
     {1,0,0,1,1,1,1,0,0,1,1,0,0,1,1,1,1,0,0,1},
     {1,1,1,1,0,0,1,0,0,1,1,1,1,1,0,0,1,0,0,1},
     {1,0,0,1,0,0,1,0,0,1,1,0,0,1,0,0,1,0,0,1},
     {1,0,0,1,1,1,1,0,0,1,1,0,0,1,1,1,1,0,0,1},
     {1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1},
     {1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1},
     {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
     {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
     {1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1},
     {1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1},
     {1,0,0,1,1,1,1,0,0,1,1,0,0,1,1,1,1,0,0,1},
     {1,1,1,1,0,0,1,0,0,1,1,1,1,1,0,0,1,0,0,1},
     {1,0,0,1,0,0,1,0,0,1,1,0,0,1,0,0,1,0,0,1},
     {1,0,0,1,1,1,1,0,0,1,1,0,0,1,1,1,1,0,0,1},
     {1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,1},
     {1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,1},
     {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
}

local walkable = 1
local allowDiagonal = false
local pather = Jumper(map,walkable,allowDiagonal)

-- OK we're going to dynamically assign the width depending on the
-- width of each element in the array above...we'll pick 'textMap[1]'.
-- We are assuming that they are ALL the same width.
-- Getting the width of the first row...
local mapWidth = #map[1]
-- And now, let's dynamically assign the height of the map by doing
-- the same thing for the number of elements to equal the height.
-- Getting the number of rows...
local mapHeight = #map

-- create huge rectangle
local movingRectangle = display.newRect( 0, 0, 2048, 2048 )
-- OK below is a simple setFillColor to make the rectangle
-- all black...but notice the last entry for the alpha!
-- We're gonna fade the alpha out for effect so you can see
-- the actual rectangle first and get a feel for it, but
-- we'll bring it down to one so it shouldn't be too
-- perceptible.
movingRectangle:setFillColor( 0,0,0,255 )

-- For effect, let's transition the alpha...
transition.to(movingRectangle, {time = 2000, alpha = 0.01})
-- We're also setting the reference to be the upper left
-- of the rectangle.
movingRectangle:setReferencePoint(display.TopLeftReferencePoint)


-- We'll do a small transition so you can see where the 
-- rectangle is. It should be solid black and then the 
-- alpha will fade to 

-- touch listener function
function movingRectangle:touch( event )
     if event.phase == "began" then
          self.markX = self.x    -- store x location of object
          self.markY = self.y    -- store y location of object
     elseif event.phase == "moved" then
          local x = (event.x - event.xStart) + self.markX
          local y = (event.y - event.yStart) + self.markY
          self.x, self.y = x, y    -- move object based on calculations above
          -- OK, we've moved our little shite rectangle, so
          -- let's move our group too.
          gameBoard.x = self.x
          gameBoard.y = self.y
     end
     
     -- Check this out, normally you'd leave the
     -- 'return true' in there to prevent 'click through';
     -- where you can click two objects at the same 
     -- time, which usually ISN'T what you want...but
     -- in this case, we DO want it so you can drag the
     -- rectangle around (which in turn we'll use to set
     -- the gameBoard group's x and y coordinate with)
     
     --return true
end

-- make 'movingRectangle' listen for touch events
movingRectangle:addEventListener( "touch", movingRectangle )

local function SolvePath(sourceX,sourceY,targetX,targetY)
     -- Let's make all the tiles normal color now
     -- This is a strictly graphical change and not
     -- needed for the actual path solution.
     for y=1,mapHeight do
          for x=1,mapWidth do
               -- Make all tiles full alpha
               -- and no colors...
               myMap[y][x].graphic:setFillColor(255,255,255)
          end
     end
     
     -- Call the jumper lib and request a solution from the source to the target...
     local results = pather:getPath(sourceX,sourceY,targetX,targetY)
     -- If results aren't nil....
     if(results)then
          local tempPath = {}
          local iteration = 1
          
          for k,v in pairs(results) do
               local tempPoint = {}
               tempPoint.x,tempPoint.y = v.x,v.y
               -- Insert our x and y values into the table 'tempPath'
               table.insert(tempPath,tempPoint)
          end
          
          for i=1,#tempPath do
               local x = tempPath[i].x
               local y = tempPath[i].y
               tempPlayer.x,tempPlayer.y = myMap[y][x].graphic.x,myMap[y][x].graphic.y
               myMap[y][x].graphic:setFillColor(0,200,0)
               if(i==#tempPath)then
                    -- OK since i==#tempPath we know
                    -- we've reached the end of our path
                    -- so set that as our 'oldX' and 'oldY'
                    -- values so when the next time we click,
                    -- the path solution will START at the LAST
                    -- location we solved for. 
                    oldX = x
                    oldY = y
               end
          end
          
          print("tempPath "..#tempPath)
          -- print out our path's solution coordinates
          -- for i=1,#tempPath do
          -- 	print("Finished steps "..tempPath[i].x,tempPath[i].y)
          -- end
     else
          -- OK we didn't get a solution so do whatever...
          print("No solution for path "..sourceX..","..sourceY.." "..targetX..","..targetY)
     end
     return results
end

-- Our event handler for clicking our tiles...
local function ClickHandler(event) 
     if(event.phase=="ended")then
          print("Clicked on "..event.target.name)
          local tempResults = SolvePath(oldX,oldY,event.target.col,event.target.row)
          if(tempResults)then
               print("Success?")
               tempPlayer.x = oldX * xOffset
               tempPlayer.y = oldY * yOffset
               tempPlayer:toFront()          
          else
               -- Seems this is needed if we click on an invalid
               -- target piece of the map.
               local tempResults = SolvePath(oldX,oldY,oldX,oldY)
          end
     end
     return true 
end 

function CreateGraphicMap(passedMap)
     print("Creating graphic map!")
     local myMap = {}
     for y=1,mapHeight do
          myMap[y] = {}     -- create a new row
          for x=1,mapWidth do
               -- OK, we're making our actual object a table that we 
               -- can throw goodies in later on...
               myMap[y][x] = {}
               -- We'll assign the variable 'value' a text value so we can parse
               -- it later on
               
               local scale = 6.50
               
               local fileName = ""
               local tempValue = passedMap[y][x] -- This will go to the 'xth' place in the string and give us the character at 'x'
               if(tempValue==0)then
                    myMap[y][x].value = "0"
                    if(hexMapStyle)then
                         fileName = "ocean.png"
                    else
                         fileName="wall.jpg"
                    end
                    myMap[y][x].graphic = display.newImage(fileName)
               elseif(tempValue==1) then
                    myMap[y][x].value = "1"	
                    if(hexMapStyle)then
                         fileName = "grass.png"
                    else
                         fileName="floor.jpg"
                    end
                    myMap[y][x].graphic = display.newImage(fileName)
               end		
               -- We'll assign the variable 'graphic' a newImage value
               -- and we're loading from the fileName selected above
               -- depending on which random number we picked
               
               -- Let's name the graphic to return a name when
               -- it's clicked!
               myMap[y][x].graphic.name = x..","..y
               -- Let's add some new values to make life
               -- easier when doing pathfinding:
               myMap[y][x].graphic.col = x
               myMap[y][x].graphic.row = y
               -- Add event handler to the graphic
               myMap[y][x].graphic:addEventListener("touch", ClickHandler )
               -- NEW! We're inserting the tiles in our parent display group
               -- called 'gameBoard'
               gameBoard:insert(myMap[y][x].graphic)
               -- Handle the offset by using modulo to determine
               -- if we're on an even or odd column, and adjust the
               -- spacing accordingly
               if(hexMapStyle==true)then
                    if math.mod(x, 2) == 0 then
                         --print("even")
                         myMap[y][x].graphic.x = x*xOffset
                         myMap[y][x].graphic.y = (y * yOffset)
                    else
                         --print("odd")
                         myMap[y][x].graphic.x = x*xOffset
                         myMap[y][x].graphic.y = (y * yOffset) - (yOffset / 2)
                    end
               else
                    myMap[y][x].graphic.x = x*xOffset
                    myMap[y][x].graphic.y = (y * yOffset)
               end
          end
     end
     return myMap
end
-- Make the 'myMap' table so we can
-- Duplicate the existing map into it,
-- but also add bonus stuff like graphics
-- touch events, other values, etc.
myMap = CreateGraphicMap(map)

GUILayer:toFront()

local function ClearMap(passedMap)
     for y=1,mapHeight do
          for x=1,mapWidth do
               passedMap[y][x].graphic:removeEventListener("touch", ClickHandler )
               display.remove(passedMap[y][x].graphic)
               passedMap[y][x].graphic = nil
          end
     end
end

local function testButtonHandler(event) 
     -- 	event.phase is a string identifying where in the touch sequence the event occurred:
     -- "began" a finger touched the screen.
     -- "moved" a finger moved on the screen.
     -- "ended" a finger was lifted from the screen.
     -- "cancelled" the system cancelled tracking of the touch.
     print(event.name.." occurred") 
     if hexMapStyle then
          hexMapStyle = false
          ClearMap(myMap)
          myMap = CreateGraphicMap(map)
          oldX = 1
          oldY = 1
          tempPlayer.x = myMap[1][1].graphic.x
          tempPlayer.y = myMap[1][1].graphic.y
     else
          hexMapStyle = true
          ClearMap(myMap)
          myMap = CreateGraphicMap(map)
          oldX = 1
          oldY = 1
          tempPlayer.x = myMap[1][1].graphic.x
          tempPlayer.y = myMap[1][1].graphic.y
     end
     return true 
end

local testButton = widget.newButton{
	id = "id",
	label = "Switch Hex/2D",
	font = nil,
	onRelease = testButtonHandler,
	emboss = true,
	offset = offset,
     	default = "buttonNormal2.png",
     	over =  "buttonOver2.png",
	buttonTheme = "blue",
}

testButton.x = centerX
testButton.y = screenH - testButton.contentHeight*2

