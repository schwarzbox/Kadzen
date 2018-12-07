-- Mon Jul 16 23:34:53 2018
-- (c) Alexander Veledzimovich
-- view KADZEN

local ui = require('lib/lovui')
local imd = require('lib/lovimd')
local obj = require('game/obj')
local set = require('game/set')

local View = {}
function View:new()
    self.ui = ui
    self.screen = nil
    self.uibg = love.graphics.newImage(set.IMG['uibg'])
end

function View:get_screen() return self.screen end
function View:get_ui() return self.ui end

function View:set_start_scr()
    self.screen = 'ui_scr'
    ui.Manager.clear()
    ui.Label{x=set.MIDWID, y=set.MIDHEI-20, anchor='s',angle=3,
            text=set.APPNAME:upper(), frm=0, fnt=set.TITLEFNT}

    ui.Button{x=set.MIDWID-114, y=set.MIDHEI+40,
                image=set.IMG['znet'], frm=0, fnt=set.MENUFNT,
                com=function() Model:market() end}

    ui.Button{x=set.MIDWID+182, y=set.MIDHEI+366, anchor='s',
            image=set.IMG['start'], frm=0, fnt=set.TITLEFNT,
            com=function() Model:startgame() end}

    local copyright = ui.HBox{x=set.MIDWID, y=set.HEI-4, anchor='s', sep=16}
    copyright:add(
        ui.Label{
            text='© LÖVE Development Team https://love2d.org',
            fnt={nil,12}},
        ui.Label{
            text='© Game by Alexander Veledzimovich veledz@gmail.com',
            fnt={nil,12}},
        ui.Label{
            text='© Music by Eric Matyas www.soundimage.org',
            fnt={nil,12}})
end

function View.buy(item,price)
    if tonumber(item.display.text)>item.var.val then
        item.var.val = tonumber(item.display.text)
        Model.stat.chip.val=Model.stat.chip.val+price
        item.var.val=item.var.val-1
    elseif tonumber(item.display.text)<item.var.val then
        item.var.val = tonumber(item.display.text)
        if Model.stat.chip.val>=price then
            Model.stat.chip.val=Model.stat.chip.val-price
            item.var.val=item.var.val+1
        end
    end
end

function View:set_market_scr()
    self.screen = 'market_scr'
    ui.Manager.clear()
    local menu = ui.VBox{x=set.MIDWID, y=set.MIDHEI,
                    mode='fill',frm=20,sep=20}

    local top = ui.HBox{sep=50}
    top:add(ui.Label{text='Z.NET', fnt=set.TITLEFNT},
            ui.Label{image=obj.Chip.img_lab,fntclr=set.WHITE},
            ui.Label{text='    ',var=Model.stat.chip,fnt=set.TITLEFNT})

    local products = ui.VBox{sep=20}
    local r1 = ui.HBox{sep=60}
    local r2 = ui.HBox{sep=60}
    local r3 = ui.HBox{sep=60}

    r1:add(ui.Label{image=obj.Hp.img_lab,fntclr=set.WHITE},
           ui.Counter{var=Model.stat.hp,fnt={nil,32},min=1,max=10,
           com=function(counter) self.buy(counter,3) end},
           ui.Label{text='3',fnt=set.TITLEFNT})
    r2:add(ui.Label{image=obj.Ammo.img_lab,fntclr=set.WHITE},
           ui.Counter{var=Model.stat.ammo,fnt={nil,32},max=13,
            com=function(counter) self.buy(counter,2) end},
           ui.Label{text='2',fnt=set.TITLEFNT})
    r3:add(ui.Label{image=obj.Upgrade.imgdata,fntclr=set.WHITE},
           ui.Counter{var=Model.stat.dist,fnt={nil,32},min=1,max=10,
           com=function(counter) self.buy(counter,4) end},
           ui.Label{text='4',fnt=set.TITLEFNT})
    r1.items[2].max=set.MAXHP
    r2.items[2].max=set.MAXAMMO
    r3.items[2].max=set.MAXDIST

    products:add(r1,r2,r3)
    menu:add(top,ui.Sep(),products,ui.Sep(),
            ui.Button{text='OK', fnt=set.TITLEFNT, frm=0,
            com=function()
                local hp,ammo,dist,chip = Model:get_stat()
                Model.save_gamestat(hp,ammo,dist,chip)
                Model:restart()
            end})
end

function View:set_level_scr(level)
    self.screen = 'level_scr'
    ui.Manager.clear()
    local leveltext = 'LEVEL '..level
    if level == 4 then leveltext = 'KILL THEM ALL!' end
    ui.LabelExe{x=set.MIDWID,y=set.MIDHEI,text=leveltext,time=60,
            fnt=set.TITLEFNT,com=function() Model:nextlevel() end}
end
function View:set_game_scr()
    self.screen = 'game_scr'
    ui.Manager.clear()
    local avatar = Model:get_avatar()
    local bars = ui.HBox{x=0,y=0,anchor='nw',sep=12}
    local hplab = ui.Label{image=imd.resize(obj.Hp.img_lab,
                                set.SCALE),fntclr=set.WHITE}
    local hpbar = ui.ProgBar{image=imd.resize(obj.Hp.img_bar,
                                set.SCALE),frmclr=set.WHITE,
                                var=avatar.hp,frm=0,max=set.MAXHP}
    local ammolab = ui.Label{image=imd.resize(obj.Ammo.img_lab,
                                            set.SCALE),fntclr=set.WHITE}
    local ammobar = ui.ProgBar{image=imd.resize(
                            obj.Bomb.imgdata,set.SCALE),frmclr=set.WHITE,
                                var=avatar.ammo,frm=0,max=set.MAXAMMO}
    local chiplab = ui.Label{image=imd.resize(obj.Chip.img_lab,
                                                set.SCALE),fntclr=set.WHITE}

    local chipcount = ui.Label{text='',var=avatar.chip,fnt=set.MENUFNT,
                                fntclr=set.WHITE}

    bars:add(hplab,hpbar,ammolab,ammobar,chiplab,chipcount)
    avatar.ammobar = ammobar
end

function View:set_fin_scr(fintext)
    self.screen = 'fin_scr'
    ui.Manager.clear()

    local modelscore = Model:get_score()
    local score = ui.VBox{x=set.MIDWID, y=set.MIDHEI,mode='fill',frm=20,sep=20}
    local table = ui.HBox{sep=60}

    local chipbox = ui.VBox{sep=20}
    local cb1 = ui.HBox{sep=60}

    cb1:add(ui.Label{image=obj.Chip.imgdata,fntclr=set.WHITE},
            ui.Label{text=Model.stat.chip.val,fnt=set.TITLEFNT})
    chipbox:add(cb1)

    local scorebox = ui.VBox{sep=20}
    local r1 = ui.HBox{sep=60}
    local r2 = ui.HBox{sep=60}
    local r3 = ui.HBox{sep=60}
    local r4 = ui.HBox{sep=60}

    r1:add(ui.Label{image=obj.Star.imgdata,fntclr=set.WHITE},
           ui.Label{text=modelscore['star'].val,fnt=set.TITLEFNT})
    r2:add(ui.Label{image=obj.Tank.imgdata,fntclr=set.WHITE},
           ui.Label{text=modelscore['tank'].val,fnt=set.TITLEFNT})
    r3:add(ui.Label{image=obj.Hunter.imgdata,fntclr=set.WHITE},
           ui.Label{text=modelscore['hunter'].val,fnt=set.TITLEFNT})
    scorebox:add(r1,r2,r3)

    table:add(scorebox,chipbox)

    score:add(ui.Label{text=fintext,fnt=set.TITLEFNT},
            ui.Sep(),table, r4, ui.Sep(),
            ui.Button{text='RESTART',fnt=set.TITLEFNT,frm=0,
              com=function() Model:restart() end})
end

function View:set_label(text,bool)
    local x = set.MIDWID
    local y = set.MIDHEI
    if self.label then self.label:remove() end
    if bool then
        self.label=ui.Label{x=x,y=y,text=text, fnt=set.MENUFNT,
                                    fntclr=set.DARKRED, anchor='s'}
    end
end

local Canvas = love.graphics.newCanvas(set.WID+set.TILESIZE/2,
                                       set.HEI+set.TILESIZE/2)
function View:draw()
    love.graphics.setColor(set.WHITE)
    if self.screen=='ui_scr' then
        love.graphics.draw(self.uibg)
    end

    if self.screen=='game_scr' then
        love.graphics.setCanvas(Canvas)
        love.graphics.clear()
        -- fade
        local fade = Model:get_fade()
        love.graphics.setColor({fade,fade,fade,fade})
        -- sprite batch floor
        love.graphics.draw(obj.Floor:getSprite().table)
        -- sprite batch wall
        love.graphics.draw(obj.Wall:getSprite().table)
        -- items
        local items = Model:get_objects()
        for i=1,#items do
            if items[i].draw then items[i]:draw() end
        end
        -- particle
        for particle in pairs(Model:get_particles()) do
            love.graphics.draw(particle)
        end

        love.graphics.setCanvas()
        love.graphics.draw(Canvas,-set.TILESIZE/2,-set.TILESIZE/2)
    end

    ui.Manager.draw()

    if self.screen=='ui_scr' then
        -- particle
        for particle in pairs(Model:get_particles()) do
            love.graphics.draw(particle)
        end
    end
end

return View
