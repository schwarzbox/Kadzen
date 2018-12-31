#!/usr/bin/env love
-- KADZEN
-- 1.0
-- Game (love2d)
-- main.lua

-- MIT License
-- Copyright (c) 2018 Alexander Veledzimovich veledz@gmail.com

-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this softwarwe and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANbTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER INb AN ACTION OF CONTRACT, TORT OR OTHE RWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

-- Music by Eric Matyas
-- www.soundimage.org

-- v2.0
-- show hero
-- tutorial

-- old lua version
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local fc = require('lib/fct')
local ui = require('lib/lovui')

Model = love.filesystem.load('game/model.lua')()
View = love.filesystem.load('game/view.lua')()
Ctrl = love.filesystem.load('lib/lovctrl.lua')()
local set = require('game/set')

io.stdout:setvbuf('no')
function love.load()
    if arg[1] then print(set.VER, set.APPNAME, 'Game (love2d)', arg[1]) end

    love.window.setTitle(string.format('%s %s', set.APPNAME, set.VER))
    love.window.setFullscreen(set.FULLSCR, 'desktop')
    love.graphics.setBackgroundColor(set.BGCLR)
    -- make icon
    love.window.setIcon(set.IMG['kadzen'])
    -- set controller view model
    Ctrl.load()
    ui.load()
    View:new()
    Model:new()
    -- avatar
    Ctrl:bind('w','up')
    Ctrl:bind('s','down')
    Ctrl:bind('d','right')
    Ctrl:bind('a','left')
    Ctrl:bind('w','stop_up')
    Ctrl:bind('s','stop_down')
    Ctrl:bind('d','stop_right')
    Ctrl:bind('a','stop_left')

    Ctrl:bind('up','arrUp')
    Ctrl:bind('down','arrDown')
    Ctrl:bind('right','arrRight')
    Ctrl:bind('left','arrLeft')
    Ctrl:bind('up','arrUpStop')
    Ctrl:bind('down','arrDownStop')
    Ctrl:bind('right','arrRightStop')
    Ctrl:bind('left','arrLeftStop')
    -- game
    Ctrl:bind('space','start',function() Model:startgame() end)
    Ctrl:bind('escape','pause', function() Model:set_pause() end)
    Ctrl:bind('lgui+r','cmdr', function() love.event.quit('restart') end)
    Ctrl:bind('lgui+q','cmdq',function() love.event.quit(1) end)
end

function love.update(dt)
    local upd_title = string.format('%s %s',set.APPNAME, set.VER)
    love.window.setTitle(upd_title)

    -- update model
    Model:update(dt)
    --  ctrl avatar
    local kadzen = Model:get_avatar()
    if kadzen and not kadzen.dead then
        if Ctrl:down('up') or Ctrl:down('arrUp') then
            kadzen:move_side('up')
        elseif Ctrl:down('down') or Ctrl:down('arrDown') then
            kadzen:move_side('down')
        elseif Ctrl:down('right') or Ctrl:down('arrRight') then
            kadzen:move_side('right')
        elseif Ctrl:down('left') or Ctrl:down('arrLeft') then
            kadzen:move_side('left')
        end
        if Ctrl:press('fire') then
            kadzen:shot()
        end
        if Ctrl:release('stop_up') or Ctrl:release('arrUpStop') then
            kadzen:setDX(0) kadzen:setDY(0)
        elseif Ctrl:release('stop_down') or Ctrl:release('arrDownStop') then
            kadzen:setDX(0) kadzen:setDY(0)
        elseif Ctrl:release('stop_right') or Ctrl:release('arrRightStop') then
            kadzen:setDX(0) kadzen:setDY(0)
        elseif Ctrl:release('stop_left') or Ctrl:release('arrLeftStop') then
            kadzen:setDX(0) kadzen:setDY(0)
        end
    end
    -- ctrl gamed
    Ctrl:press('start')
    Ctrl:press('pause')
    Ctrl:press('cmdr')
    Ctrl:press('cmdq')
end

function love.draw()
    -- view
    View:draw()
end

function love.focus(focus)
    if not focus then Model:set_pause(true) else Model:set_pause(false) end
end

function love.keypressed(key,unicode,isrepeat) end
function love.keyreleased(key,unicode) end
function love.mousepressed(x,y,button,istouch) end
function love.mousereleased(x,y,button,istouch) end
function love.mousemoved(x,y,dx,dy,istouch) end
function love.wheelmoved(x, y) end
