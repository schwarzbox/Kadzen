-- Mon Jul 16 23:34:53 2018
-- (c) Alexander Veledzimovich
-- model KADZEN

local Tmr = require('lib/tmr')
local cmp = require('lib/lovcmp')
local fc = require('lib/fct')

local fl = require('lib/lovfl')
local imd = require('lib/lovimd')
local wrld = require('lib/lovwrld')
local obj = require('game/obj')
local set = require('game/set')

local unpack = table.unpack or unpack

local Model = {}
-- static cmp
Model.getRandOffsetXY = cmp.getRandOffsetXY
Model.getEmptyTile = cmp.getEmptyTile
-- particle
Model.objectParticle=cmp.objectParticle

function Model:new()
    cmp.GRAVITY = {x=0,y=0}
    cmp.TILESIZE = set.TILESIZE
    self.tmr = Tmr:new()

    self.levels = {{maze='sidewinder',mons={star=9,tank=0,hunter=0},
            key={set.MIDTILEWID-2,set.MIDTILEWID+2,
                    set.MIDTILEHEI,set.TILEHEI-1,num=1},
            ammo={set.MIDTILEWID-4,set.MIDTILEWID+4,
                    2,set.TILEHEI-1,num=3},
            hp={2,set.MIDTILEWID-4,
                2,set.TILEHEI-1,num=1},
            upgrade={set.MIDTILEWID+4,set.TILEWID-4,
                    2,set.TILEHEI-1,num=1}},

            {maze='backtracking',mons={star=7,tank=2,hunter=0},
            key={set.MIDTILEWID-4,set.MIDTILEWID+4,
                    set.MIDTILEHEI+6,set.TILEHEI-1,num=1},
            ammo={2,set.MIDTILEWID-4,
                    2,set.TILEHEI-1,num=4},
            hp={set.MIDTILEWID+4,set.TILEWID-1,
                    2,set.MIDTILEHEI-2,num=1},
            upgrade={set.MIDTILEWID+4,set.TILEWID-1,
                    set.MIDTILEHEI+2,set.TILEHEI-1,num=1}},

            {maze='eller',mons={star=4,tank=3,hunter=2},
            key={set.MIDTILEWID-2,set.MIDTILEWID+2,
                    set.MIDTILEHEI+4,set.TILEHEI-1,num=1},
            ammo={set.MIDTILEWID-4,set.MIDTILEWID+4,
                    2,set.MIDTILEHEI,num=4},
            hp={2,set.MIDTILEWID-2,
                set.MIDTILEHEI+2,set.TILEHEI-1,num=1},
            upgrade={set.MIDTILEWID+2,set.TILEWID-1,
                    set.MIDTILEHEI+2,set.TILEHEI-1,num=1}},

            {maze='hall',mons={star=3,tank=3,hunter=3},
            key={2,set.TILEWID-1,
                    2,set.MIDTILEHEI-4,num=1},
            ammo={2,set.TILEWID-1,
                    set.MIDTILEHEI+4,set.TILEHEI-1,num=5},
            hp={2,set.MIDTILEWID-4,
                2,set.MIDTILEHEI,num=1},
            upgrade={set.MIDTILEWID+4,set.TILEWID-1,
                   2,set.MIDTILEHEI,num=1}},
            }
    self.gameaud = set.AUD['game']
    self.gameaud:setVolume(0)
    self.gameaud:setLooping(true)
    self.gameaud:play()
    self:restart()
end

function Model:restart()
    self.avatar = nil
    self.pause = false
    self.level = 0
    self:reset()
    local olddata = fl.loadLove(set.SAVE) or {hp={val=1},ammo={val=1},
                                        dist={val=1},chip={val=0}}
    self.stat = olddata

    self.score = {['star']={val=0},['tank']={val=0},['hunter']={val=0}}
    Ctrl:unbind('space')
    Ctrl:bind('space','start',function() self:startgame() end)

    self.startfire = false
    self.sfirex = set.MIDWID+156
    self.sfirey = set.MIDHEI+264
    self.sfire = self:objectParticle(10, {set.WHITEF,set.ORANGE,set.WHITEHF},
                                     'circle', {0.05,0.8},{0,0.4},256)
    View:set_start_scr()
end

function Model:reset()
    if self.objects then
        for i=#self.objects,1,-1 do
            if self.objects[i].tmr then self.objects[i].tmr:clear() end
        end
    end
    self.objects = {}
    self.particles = {}
    obj.Monster.pool = {}
    -- clear batch sprites tables
    obj.Floor:clear()
    obj.Wall:clear()
    self.fade = 32/255
    self.maze = nil
    self.items = nil
end

function Model:set_pause(pause)
    if View:get_screen()=='game_scr' then
        self.pause = pause or not self.pause
        View:set_label('PAUSE',self.pause)
    end
end

function Model:spawn(object,index)
    if index then table.insert(self.objects,index,object)
    else self.objects[#self.objects+1] = object end
end
function Model:destroy(object)
    for i=#self.objects,1,-1 do
        if self.objects[i]==object then table.remove(self.objects,i) break end
    end
end
function Model:get_objects() return self.objects end
function Model:get_object(object,x,y)
    local objects = {}
    for i=1,#self.objects do
        if self.objects[i].tilex==x and self.objects[i].tiley==y then
            if self.objects[i]~=object then
                objects[#objects+1]=self.objects[i]
            end
        end
    end
    return objects
end

function Model:get_particles() return self.particles end

function Model:set_avatar(avatar) self.avatar=avatar end
function Model:get_avatar() return self.avatar end
function Model:get_fade() return self.fade end

function Model:get_maze() return self.maze end
function Model:get_mazetile(x,y) return self.maze[y][x] end
function Model:set_mazetile(x,y,tag) self.maze[y][x]=tag end
function Model:get_itemstile(x,y) return self.items[y][x] end
function Model:set_itemstile(x,y,tag) self.items[y][x]=tag end

function Model:set_score(type)
    self.score[type].val = self.score[type].val + 1
end

function Model:get_level() return self.level end

function Model:get_score() return self.score end

function Model.save_gamestat(hp,ammo,dist,chip)
    fl.saveLove(set.SAVE,string.format('return {hp={val=%i},ammo={val=%i},dist={val=%i},chip={val=%i}}',hp,ammo,dist,chip))
end

function Model:get_stat()
    return self.stat.hp.val,self.stat.ammo.val,
            self.stat.dist.val,self.stat.chip.val
end

function Model:set_stat()
    self.avatar:set_hp(self.stat.hp.val)
    self.avatar:set_ammo(self.stat.ammo.val)
    self.avatar:set_weapon(self.stat.dist.val)
    self.avatar:set_chip(self.stat.chip.val)
end

function Model:save_stat()
    self.stat.hp.val = self.avatar:get_hp()
    self.stat.ammo.val = self.avatar:get_ammo()
    self.stat.dist.val = self.avatar:get_weapondist()
    self.stat.chip.val = self.avatar:get_chip()
end

function Model:nextmaze()
    self.level=self.level+1
    self:reset()
    self:set_maze(self.levels[self.level].maze,
                  self.levels[self.level].mons,
                  self.levels[self.level].key,
                  self.levels[self.level].ammo,
                  self.levels[self.level].hp,
                  self.levels[self.level].upgrade)
    View:set_level_scr(self.level)
end

function Model:nextlevel()
    self.tmr:tween(1, self, {fade=1})
    View:set_game_scr()
end

function Model:set_bonus(bonus,val,tag,type,door)
    local xval, yval
    for _=1,val.num do
        repeat
            xval=love.math.random(val[1],val[2])
            yval=love.math.random(val[3],val[4])

        until self.items[yval][xval]==wrld.FLOOR
        if type~='hall' then
            self.items[yval][xval] = tag
            bonus{x=math.floor(xval*set.TILESIZE),
                    y=math.floor(yval*set.TILESIZE),door=door}
        end
    end
    return {xval,yval}
end

function Model:doorside(tile,wall)
    local empty = self.getEmptyTile(self.maze,tile,wall)
    local side
    if fc.isval('left',empty) then side='CW' end
    if fc.isval('up',empty) then side='VFLIP' end
    if fc.isval('right',empty) then side='CCW' end
    if fc.isval('down',empty) then side='HFLIP' end
    return side
end

function Model:wallside(tile,wall)
    local wall_sprite=obj.Wall:getSprite()
    local empty = self.getEmptyTile(self.maze,tile,wall)
    local image
    if #empty==0 then
        image = wall_sprite.quads[1]
    elseif #empty==1 then
        if empty[1]=='down' then
            image = wall_sprite.quads[5]
        elseif  empty[1]=='right' then
            image = wall_sprite.quads[4]
        elseif  empty[1]=='up' then
            image = wall_sprite.quads[3]
        else
            image = wall_sprite.quads[2]
        end
    elseif #empty==2 then
        if ((empty[1]=='up' and empty[2]=='down') or
            (empty[2]=='up' and empty[1]=='down')) then
            image = wall_sprite.quads[11]
        elseif ((empty[1]=='left' and empty[2]=='up') or
            (empty[2]=='left' and empty[1]=='up')) then
            image = wall_sprite.quads[8]
        elseif ((empty[1]=='right' and empty[2]=='up') or
            (empty[2]=='right' and empty[1]=='up'))then
            image = wall_sprite.quads[9]
        elseif ((empty[1]=='right' and empty[2]=='down') or
            (empty[2]=='right' and empty[1]=='down')) then
            image = wall_sprite.quads[6]
        elseif ((empty[1]=='left' and empty[2]=='down') or
            (empty[2]=='left' and empty[1]=='down'))then
            image = wall_sprite.quads[7]
        else
            image = wall_sprite.quads[10]
        end
    elseif #empty==3 then
        if not fc.isval('up',empty) then
            image = wall_sprite.quads[14]
        elseif not fc.isval('left',empty) then
            image = wall_sprite.quads[13]
        elseif not fc.isval('right',empty) then
            image = wall_sprite.quads[15]
        else
            image = wall_sprite.quads[12]
        end
    else
        image = wall_sprite.quads[16]
    end
    return image
end

function Model:set_maze(type,mons,keynum,ammonum,hpnum,upgradenum)
    if type=='sidewinder' then
        self.maze = wrld.sidewinder(set.WID,set.HEI, set.TILESIZE)
    elseif type=='eller' then
        self.maze = wrld.eller(set.WID,set.HEI, set.TILESIZE)
    elseif type=='backtracking' then
        self.maze = wrld.backtracking(set.WID,set.HEI, set.TILESIZE)
    elseif type=='hall' then
        self.maze=wrld.hall(set.WID,set.HEI, set.TILESIZE)
    else
        return
    end

    local exittile
    local starttile

    local floor_sprite=obj.Floor:getSprite()
    local wall_sprite=obj.Wall:getSprite()

    for tiley=1,#self.maze do
        for tilex=1,#self.maze[1] do
            local x = math.floor((tilex)*set.TILESIZE)
            local y = math.floor((tiley)*set.TILESIZE)

            local randfloor=love.math.random(#floor_sprite.quads-1)
            floor_sprite.table:add(floor_sprite.quads[randfloor],
                                  x-set.TILESIZE/2, y-set.TILESIZE/2,0,
                                  set.SCALE,set.SCALE)

            if self.maze[tiley][tilex]==wrld.WALL then
                local image
                local empty = self.getEmptyTile(self.maze,
                                                 {tilex,tiley},wrld.WALL)

                if ((tilex==1 or tilex==set.TILEWID) or
                    (tiley==1 or tiley==set.TILEHEI)) then
                    image = wall_sprite.quads[16]
                elseif tilex==2 then
                    if #empty==3 then
                        image = wall_sprite.quads[16]
                    else
                        image = wall_sprite.quads[15]
                    end
                elseif tilex==set.TILEWID-1 then
                    image = wall_sprite.quads[13]
                elseif tiley==set.TILEHEI-1 then
                    image = wall_sprite.quads[14]
                elseif tiley==2  then
                    image = wall_sprite.quads[12]
                else
                    image=self:wallside({tilex,tiley},wrld.WALL)
                end
                local id = wall_sprite.table:add(image,
                                      x-set.TILESIZE/2, y-set.TILESIZE/2,0,
                                      set.SCALE,set.SCALE)
                obj.Wall{x=x, y=y,sid=id}
            elseif self.maze[tiley][tilex]==wrld.START then
                obj.Start{x=x,y=y}
                starttile={tilex,tiley}
            elseif self.maze[tiley][tilex]==wrld.FIN then
                local side = self:doorside({tilex,tiley},wrld.WALL)
                obj.Fin.imgdata = imd.rotate(obj.Fin.all_data[1],side)
                obj.Fin.img_open = imd.rotate(obj.Fin.all_data[2],side)
                obj.Fin.dstdata = imd.splash(obj.Fin.img_open,
                                                        20,set.TILESIZE)
                if type~='hall' then
                    obj.Fin{x=x,y=y}
                end
                exittile = {tilex,tiley}
            end
        end
    end
    self.items=fc.copy(self.maze)
    local keytile = self:set_bonus(obj.Key,keynum,'K',type,exittile)
    local ammotile = self:set_bonus(obj.Ammo,ammonum,'A')
    local hptile = self:set_bonus(obj.Hp,hpnum,'H')
    local upgradetile = self:set_bonus(obj.Upgrade,upgradenum,'U')
    -- create monsters
    for _=1, mons.star do
        obj.Star{x=math.floor(exittile[1]*set.TILESIZE),
                y=math.floor(exittile[2]*set.TILESIZE)}
    end
    for _=1, mons.tank do
        obj.Tank{x=math.floor(keytile[1]*set.TILESIZE),
                y=math.floor(keytile[2]*set.TILESIZE)}
    end
    for _=1, mons.hunter do
        obj.Hunter{x=math.floor(ammotile[1]*set.TILESIZE),
                y=math.floor(ammotile[2]*set.TILESIZE),
                oldgoal={hptile,upgradetile,ammotile,exittile,
                {set.MIDTILEWID,2},{set.MIDTILEWID,set.TILEHEI-1},
                {2,set.MIDTILEHEI},{set.TILEWID-1,set.MIDTILEHEI}}}
    end

    self:set_avatar(obj.Kadzen{
                x=math.floor(starttile[1]*set.TILESIZE),
                    y=math.floor(starttile[2]*set.TILESIZE)})
    self:set_stat()
end

function Model:startgame()
    Ctrl:unbind('space')
    Ctrl:bind('space','fire')
    self.startfire = true
    local ifire = self:objectParticle(1, {set.BLACK,set.ORANGE,set.WHITEHF},
                            set.IMG['fire'], {0.05,0.5},{0,0.15},128)
    ifire.particle:setPosition(self.sfirex,self.sfirey+10)
    ifire.particle:setSpeed(0,300)
    ifire.particle:setDirection(-1.5)
    ifire.particle:emit(50)
    set.AUD['start']:play()
    set.AUD['tnt']:setVolume(0.2)
    set.AUD['tnt']:play()
    self.tmr:tween(2, self, {sfirex=self.sfirex-15,sfirey=self.sfirey+10},
                   'linear',function() self:nextmaze() end)
end

function Model:market()
    love.mouse.setVisible(true)
    View:set_market_scr()
end

function Model:update(dt)
    if View:get_screen()=='ui_scr' then
        if self.startfire then
            self.sfire.particle:setPosition(self.sfirex,self.sfirey)
            self.sfire.particle:emit(30)
        end
        for particle in pairs(self.particles) do
            particle:update(dt)
        end
    end
    if View:get_screen()=='game_scr' then
        if self.pause then return end

        -- particle
        for particle in pairs(self.particles) do
            particle:update(dt)
            if particle:getCount()==0 then
                particle:reset()
            end
        end
        -- collision
        for i=1,#self.objects do
            if self.objects[i].tag~=wrld.WALL and not self.objects[i].dead then
                self.objects[i].lastcoll = {}
                self.objects[i]:collision(self.maze)
                if #self.objects[i].lastcoll == 0 then
                    self.objects[i].collide=nil
                end
            end
        end
        -- objects
        for i=1,#self.objects do
            local object=self.objects[i]
            if object and not object.dead and object.update then
                object:update(dt)
            end
        end
    end
    self.gameaud:setVolume(self.fade)
    View:get_ui().Manager.update(dt)
end

function Model:endgame(dead)
    love.audio.stop()
    love.audio.play(set.AUD['game'])

    self:save_stat()
    self.fade = 32/255
    if dead then
        View:set_fin_scr('GAME OVER')
        self.save_gamestat(1,1,1,self.stat.chip.val)
    else
        View:set_fin_scr('KADZEN WIN')
        local hp,ammo,dist,chip = Model:get_stat()
        self.save_gamestat(hp,ammo,dist,chip)
    end
    Ctrl:unbind('space')
    Ctrl:bind('space','start',function() self:restart() end)
end

return Model
