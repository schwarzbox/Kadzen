-- Mon Jul 16 23:34:53 2018
-- (c) Aliaksandr Veledzimovich
-- obj KADZEN

local cls = require('lib/cls')
local wrld = require('lib/lovwrld')
local cmp = require('lib/lovcmp')
local imd = require('lib/lovimd')
local set = require('game/set')

local unpack = table.unpack or unpack

local Proto, O = love.filesystem.load('game/proto.lua')()

O.Star = cls.Class(O.Monster)
O.Star.all_data = imd.slice(set.IMG['star'], 128,128, 5,2)
O.Star.imgdata = O.Star.all_data[1]
O.Star.dstdata = imd.splash(O.Star.imgdata,20,set.TILESIZE)

O.Star.distance = {val=3}
O.Star.viewrange = 240
O.Star.torque = math.rad(180)
O.Star.step = set.TILESIZE/64
O.Star.type = 'star'
function O.Star:new(o)
    self.Super.new(self)
    O.Monster.pool[#O.Monster.pool+1]=self
    self.smoke = self:objectParticle(10, {set.WHITEHHHF,set.WHITEHHF,
                            set.DARKGRAYF},'circle',{0.1,0.5})
    self.findaud = set.AUD['star']:clone()
    self.findaud:setVolume(0.3)
end

function O.Star:update(dt)
    local move=self:matrix_collide(dt)
    self:move_animation(dt)
    self:updateRect()

    self.smoke.update(dt,'center',{-10,0},-set.TILESIZE/4)
    self.smoke.particle:emit(1)

    if move then self:set_angles() end

    if self:overlap() and not self.moving then
        self:random_move()
        self.path = {}
        self.goal = nil
    else
        local avatar = Model:get_avatar()
        if self:circleView(avatar.x,avatar.y) then
            self.findaud:play()
            self.goal = {avatar.tilex,avatar.tiley}
        end

        if #self.path==0 or self.goal then
            self.path = self:matrixPathfinder(Model:get_maze(),
                                {{self.tilex,self.tiley}},
                                self.goal,wrld.FLOOR,{O.Kadzen.tag})
        end
        if #self.path>0 and not self.moving then
            self:set_dxdy()
            table.remove(self.path)
        end
        if not self.goal then self:random_move() end
    end
end

function O.Star:explore(catch)
    if catch and not self.destruction then
        self.destruction = true
        O.Monster.alarm(self,'tank','hunter')
        self.tmr:during(0.7,function() self:rotate(1) self:updateAngle() end,
                            function()
                                self:explode(self.damage,0,0,0)
                                self:explode_cells(self.distance.val)
                            end)
    end
end

O.Fireball = cls.Class(O.Monster,{tag='M'})
O.Fireball.all_data = imd.slice(set.IMG['fire'], 128,128, 1,1)
O.Fireball.imgdata = O.Fireball.all_data[1]
O.Fireball.dstdata = O.Fireball.imgdata

O.Fireball.damage = 200
O.Fireball.distance = {val=1}
O.Fireball.torque = math.rad(180)
O.Fireball.step = set.TILESIZE/256
O.Fireball.type = 'fireball'
function O.Fireball:new(o)
    self.Super.new(self)

    self.fireball = self:objectParticle(10, {set.WHITEF,set.ORANGE,
                            set.DARKGRAYF},'circle',{0.1,0.3})
    self.pdx = self.dx
    self.pdy = self.dy
    self:init_animation()
    self.notmove=false
end

function O.Fireball:init_animation()
    self.scale=self.scale-0.4
    self.tmr:tween(self.step*8,self,{scale=self.scale+0.3})
end

function O.Fireball:update(dt)
    self:matrix_collide(dt)

    self:rotate(1)
    self:updateAngle(dt)
    self:updateRect()

    self.fireball.update(dt,'center',{0,0},set.TILESIZE/8)
    self.fireball.particle:emit(40)
    self.fireball.particle:setEmissionArea('uniform', 6, 6, self.angle)

    self.dx=self.pdx
    self.dy=self.pdy

    if self.moving then self.notmove=false end
    if self.notmove then self:timetoexplode() end
    if not self.moving then self.notmove=true end
end

function O.Fireball:explode() self:random_move() end

function O.Fireball:timetoexplode()
    self.dead = true
    self:explode_cells(1)
    self.image = love.graphics.newImage(self.dstdata)
    O.Monster.alarm(self,'tank','hunter')
    for particle in pairs(self.particles) do particle:reset() end
    Model:destroy(self)
end

function O.Fireball:explore(catch)
    if catch and not self.dead then
        self:timetoexplode()
    end
end

O.Tank = cls.Class(O.Monster)
O.Tank.all_data = imd.slice(set.IMG['tank'], 128,128, 5,3)
O.Tank.imgdata = O.Tank.all_data[1]
O.Tank.dstdata = imd.splash(O.Tank.imgdata,10,set.TILESIZE)

O.Tank.viewrange = 384
O.Tank.torque = math.rad(90)
O.Tank.step = set.TILESIZE/96
O.Tank.type = 'tank'
function O.Tank:new(o)
    self.Super.new(self)
    O.Monster.pool[#O.Monster.pool+1]=self
    self.smoke = self:objectParticle(8, {set.GRAY,set.DARKGRAY,
                            set.GRAYF},'circle',{0.1,0.4})
    self.shotaud = set.AUD['tankshot']:clone()
    self.shotaud:setVolume(0.5)
    self.findaud = set.AUD['tank']:clone()
    self.findaud:setVolume(0.3)

    self.oldgoal = {}

    self.weapon = {type=O.Fireball,side='center',offset = {set.TILESIZE,-10}}
end

function O.Tank:update(dt)
    local move=self:matrix_collide(dt)
    self:move_animation(dt)
    self:updateRect()

    self.smoke.update(dt,'center',{-16,-8},-set.TILESIZE/8)
    self.smoke.particle:emit(1)

    if move then self:set_angles() end

    if self:overlap() and not self.moving then
        self:random_move()
        self.path = {}
        self.oldgoal={}
        self.goal=nil
    elseif (self.goal and
            Model:get_mazetile(self.goal[1],self.goal[2])==self.tag) then
        self.path = {}
        self.oldgoal = {}
        self.goal = nil
    else
        local goal,tar = self:look(O.Kadzen.tag)
        local avatar = Model:get_avatar()
        local see_kadzen = false
        if tar and (tar[1]==avatar.tilex and tar[2]==avatar.tiley) then
            self.goal = tar
            see_kadzen = true
            self.findaud:play()
        end
        if not self.goal then self.goal=goal end

        if not self.goal and #self.oldgoal>0 then
            self.goal = self.oldgoal[#self.oldgoal]
            table.remove(self.oldgoal)
        end

        if #self.path==0 and self.goal or see_kadzen then
            self.path = self:matrixPathfinder(Model:get_maze(),
                                {{self.tilex,self.tiley}},
                                self.goal,wrld.FLOOR,{O.Kadzen.tag})
        end

        if #self.path>0 and not self.moving then
            self:set_dxdy()
            self.oldgoal[#self.oldgoal+1] = self.path[#self.path]
            table.remove(self.path)
        end

        if #self.oldgoal>set.TILEWID+set.TILEHEI then
            local lenold = #self.oldgoal
            self.oldgoal = {unpack(self.oldgoal,1,lenold-set.TILEWID)}
        end

        local dirx=(self.tilex>avatar.tilex and self.dx<0) or
                        (self.tilex<avatar.tilex and self.dx>0)
        local diry=(self.tiley>avatar.tiley and self.dy<0) or
              (self.tiley<avatar.tiley and self.dy>0)

        local fireline=((self.tiley==avatar.tiley and dirx) or
                        (self.tilex==avatar.tilex and diry))
        if move and see_kadzen and fireline and not self.fire and
            (self.dx~=0 or self.dy~=0) then
            self.shotaud:play()
            self:shot()
        end
    end
end

function O.Tank:explore(catch)
    if catch and not self.dead then
       for _=1,4 do
           self.angle=self.angle+self.torque
           self:updateRect()
           self:shot()
       end
    end
end

O.Hunter = cls.Class(O.Monster)
O.Hunter.all_data = imd.slice(set.IMG['hunter'], 128,128, 5,2)
O.Hunter.imgdata = O.Hunter.all_data[1]
O.Hunter.dstdata = imd.splash(O.Hunter.imgdata,10,set.TILESIZE)
O.Hunter.damage = 1
O.Hunter.viewrange = 480
O.Hunter.step = set.TILESIZE/144
O.Hunter.type = 'hunter'
function O.Hunter:new(o)
    self.Super.new(self)

    self.smokel = self:objectParticle(8, {set.DARKGRAY,set.GRAY,
                            set.WHITEHF},'circle',{0.1,0.4})
    self.smoker = self:objectParticle(8, {set.DARKGRAY,set.GRAY,
                            set.WHITEHF},'circle',{0.1,0.4})
    self.findaud = set.AUD['hunter']:clone()
    self.findaud:setVolume(0.2)
    O.Monster.pool[#O.Monster.pool+1]=self
end

function O.Hunter:update(dt)
    local move = self:matrix_collide(dt)
    self:move_animation(dt)
    self:updateRect()

    self.smokel.update(dt,'center',{-16,-6},-set.TILESIZE/8)
    self.smoker.update(dt,'center',{-16,6},-set.TILESIZE/8)
    self.smokel.particle:emit(1)
    self.smoker.particle:emit(1)

    if move then self:set_angles() end

    if self:overlap() and not self.moving then
        self:random_move()
        self.path = {}
        self.goal = nil
    elseif (self.goal and
            Model:get_mazetile(self.goal[1],self.goal[2])==self.tag) then
        self.path = {}
        self.goal = nil
    else
        local goal,tar = self:look(O.Kadzen.tag)
        local avatar = Model:get_avatar()
        local see_kadzen = false
        if tar and (tar[1]==avatar.tilex and tar[2]==avatar.tiley) then
            self.goal=tar
            see_kadzen=true
            self.findaud:play()
        end
        if not self.goal then
            self.goal = self.oldgoal[love.math.random(#self.oldgoal)]
        end
        if not self.goal then self.goal=goal end

        if #self.path==0 and self.goal or see_kadzen then
            self.path = self:matrixPathfinder(Model:get_maze(),
                                {{self.tilex,self.tiley}},
                                self.goal,wrld.FLOOR,{O.Kadzen.tag})
        end

        if #self.path>0 and not self.moving then
            self:set_dxdy()
            table.remove(self.path)
        end

        if self.goal and self.dx==0 and self.dy==0 then self.goal = nil end
    end
end

function O.Hunter:explore(catch)
    if catch and not self.dead then
        Model:get_avatar():explode(self.damage,0,0,0)
    end
end


O.Kadzen = cls.Class(O.Monster,{tag='Z'})
-- const
O.Kadzen.all_data = imd.slice(set.IMG['hero'], 128,128, 4,7)
O.Kadzen.imgdata = O.Kadzen.all_data[1]
O.Kadzen.dstdata = imd.splash(O.Kadzen.all_data[5],20,
                                       set.TILESIZE,set.RED)
O.Kadzen.step = set.TILESIZE/192
O.Kadzen.type = 'hero'
function O.Kadzen:new(o)
    Proto.new(self)
    self.moving = false
    self.img_index=1
    self.idle_img = self:set_tiles(1,4)
    self.ammo0_img = self:set_tiles(5,8)
    self.ammo1_img = self:set_tiles(9,12)
    self.ammo2_img = self:set_tiles(13,16)
    self.ammo3_img = self:set_tiles(17,20)
    self.ammo4_img = self:set_tiles(21,24)
    self.fire_img = self:set_tiles(25,28)

    self.weapon = {type=O.Bomb,side='center',offset = {20,8}}

    self.blood = self:objectParticle(4, {set.DARKRED,set.RED,set.GRAYF},
                                  'circle',{0.1,2},{1,0},1)
    self.blood.particle:setEmissionArea('uniform',set.TILESIZE/2,
                                                    set.TILESIZE/2,1)

    self.hp = {val=1}
    self.ammo = {val=1}
    self.chip = {val=0}

    self.walkaud=set.AUD['walk']:clone()
    self.walkaud:setVolume(0.2)
    self.throwaud = set.AUD['throw']:clone()
    set.AUD['hp']:setVolume(0.5)
    set.AUD['ammo']:setVolume(0.5)
    set.AUD['upgrade']:setVolume(0.3)
    set.AUD['dead']:setVolume(0.3)
end

function O.Kadzen:set_hp(hp) self.hp.val = hp end
function O.Kadzen:set_ammo(ammo) self.ammo.val = ammo end
function O.Kadzen:set_weapon(distance)
    self.weapon.type.set_distance(distance)
end
function O.Kadzen:set_chip(chip) self.chip.val = chip end
function O.Kadzen:get_hp() return self.hp.val end
function O.Kadzen:get_ammo() return self.ammo.val end
function O.Kadzen:get_weapondist() return self.weapon.type.get_distance() end
function O.Kadzen:get_chip() return self.chip.val end

function O.Kadzen:shot(...)
    if self.ammo.val>0 and not self.dead then
        cmp.shot(self,...)
        self:set_ammo(self.ammo.val-1)
        self.fire = true
        self.tmr:after(0.5, function() self.fire=false end)
        self.throwaud:play()
    end
end

function O.Kadzen:update(dt)
    self:matrix_collide(dt)
    self:move_animation(dt)
    self.blood.update(dt,'center',{0,0})

    if self.moving and (self.dx~=0 or self.dy~=0) then self.walkaud:play() end
end

function O.Kadzen:move_animation(dt)
    local index_img = math.floor(self.img_index+0.5)
    if not self.moving and self.ammo.val==0 then
        self.img_index = self.img_index+dt
        index_img = math.floor(self.img_index+0.5)
        if index_img>#self.idle_img then self.img_index=1 index_img=1 end

        self.image = self.idle_img[index_img]
    elseif self.ammo.val>0 then
        if self.weapon.type.get_distance()==1 then
            self.image = self.ammo1_img[index_img]
        elseif self.weapon.type.get_distance()==2 then
            self.image = self.ammo2_img[index_img]
        elseif self.weapon.type.get_distance()==3 then
            self.image = self.ammo3_img[index_img]
        elseif self.weapon.type.get_distance()==4 then
            self.image = self.ammo4_img[index_img]
        end
        if self.fire then
            self.image = self.fire_img[index_img]
        end
    else
        self.image = self.ammo0_img[index_img]
    end

end

function O.Kadzen:move_side(side)
    if side=='up' then self.angle=math.rad(270)
    elseif side=='down' then self.angle=math.rad(90)
    elseif side=='right' then self.angle=math.rad(0)
    elseif side=='left' then self.angle=math.rad(180)
    else self.angle=self.angle end
    self:move()
end

function O.Kadzen:explore(catch)
    local itemstile = Model:get_itemstile(self.tilex,self.tiley)
    local objects = Model:get_object(self,self.tilex,self.tiley)

    for i=1,#objects do
        local object = objects[i]
        if object.tag==O.Monster.tag or object.tag==wrld.WALL then
            if catch and object.tag==O.Monster.tag then
                object:explore(catch)
            end
            goto continue
        end

        if itemstile==O.Hp.tag and self.hp.val<set.MAXHP then
            self:set_hp(self.hp.val+object.bonus)
            set.AUD['hp']:play()
            object:empty()
        elseif itemstile==O.Ammo.tag and self.ammo.val<set.MAXAMMO then
            self:set_ammo(self.ammo.val+object.bonus)
            set.AUD['ammo']:play()
            object:empty()
        elseif (itemstile==O.Upgrade.tag and
            self.weapon.type.get_distance()<set.MAXDIST) then
            self:set_weapon(self.weapon.type.get_distance()+object.bonus)
            if self.ammobar then
                self.ammobar:setImage(imd.resize(O.Bomb.imgdata,set.SCALE))
                set.AUD['upgrade']:play()
            end
            object:empty()
        elseif itemstile==O.Key.tag then
            object:opendoor()
            Model:set_itemstile(self.tilex,self.tiley,wrld.FLOOR)
        elseif itemstile==O.Chip.tag then
            self:set_chip(self.chip.val+object.bonus)
            object:empty()
        end

        if itemstile==wrld.FIN and object.open then
            Model:save_stat()
            Model:nextmaze()
            return
        end
        ::continue::
    end
end

function O.Kadzen:explode(damage,dx,dy,maxdist)
    if not self.dead then
        self.blood.particle:emit(100)
        self:boom(self.x, self.y, 200, {10,8,4},
                  {set.WHITEF,set.RED,set.GRAYF}, nil,nil, {0.1,1},2000)
    end
    -- animation
    if self:hit(damage) and not self.dead then
        self.dead = true
        local func = function() self:boom(self.x, self.y, 40,
                        {8,4},{set.WHITEF,set.DARKRED,set.RED},
                        'circle', {1,3}, {0.1,1}, 3000) end
        self:explosion_wave(dx,dy,maxdist,func)
        self.image=love.graphics.newImage(self.dstdata)
        self:destroyParticle({8,8},{2,6},4000)
        self:boom(self.x, self.y, 50, {8,4},
                  {set.WHITEF,set.RED,set.GRAYF}, nil, nil, nil, 4000)
        set.AUD['dead']:play()

        local obj=self
        Model:destroy(self)
        Model:set_avatar(obj,1)

        -- put in lower level
        Model:spawn(obj,1)
        -- dead animation
        self.tmr:after(4, function() Model:endgame(self.dead) end)
    end
end


O.Bomb = cls.Class(O.Monster,{tag='B'})
O.Bomb.all_data = imd.slice(set.IMG['bomb'], 128,128, 4,1)
O.Bomb.distance = {val=1}
O.Bomb.imgdata = O.Bomb.all_data[O.Bomb.distance.val]
O.Bomb.dstdata = imd.splash(O.Bomb.imgdata,10,set.TILESIZE)
O.Bomb.idle_img = O.Bomb.set_tiles(O.Bomb,1,#O.Bomb.all_data)

O.Bomb.lifetime = 2.4
O.Bomb.step = set.TILESIZE/set.TILESIZE
O.Bomb.type = 'bomb'

function O.Bomb:new(o)
    self.Super.new(self)

    self.ifire = self:objectParticle(20, {set.ORANGE,set.DARKGRAYF,
                                   set.DARKGRAYF})
    self.ifire_offset = 0
    self.fireaud=set.AUD['tnt']:clone()
    self.fireaud:setVolume(0.5)
    self.dstaud = set.AUD['bomb']:clone()
    self.dstaud:setVolume(0.3)
    -- fly backward
    self.dx = math.floor(self.dx*-1)
    self.dy = math.floor(self.dy*-1)
    self:init_animation()
end

function O.Bomb.set_distance(distance)
    O.Bomb.distance.val=distance
    if O.Bomb.distance.val>set.MAXDIST then
        O.Bomb.distance.val=set.MAXDIST
    end
    O.Bomb.imgdata=O.Bomb.all_data[(O.Bomb.distance.val)]
end

function O.Bomb.get_distance()
    return O.Bomb.distance.val
end

function O.Bomb:set_tmpdistance(distance)
    self.distance = {unpack(self.distance)}
    self.distance.val = distance
    self.image = self.idle_img[self.distance.val]
end

function O.Bomb:init_animation()
    self.scale = 0
    self.fireaud:play()
    self.tmr:tween(self.step/2,self,
                {scale=self.scale+0.575,
                angle=self.angle+love.math.random(2),
                ifire_offset=-6},
                'outCubic',function() self.tmr:tween(self.step*1.5,self,
                                    {x=self.tilex*set.TILESIZE,
                                     y=self.tiley*set.TILESIZE,
                                    scale=self.scale-0.35,
                                    angle=self.angle+love.math.random(2),
                                    ifire_offset=6},
                                    'outBounce')
                                    end)
end

function O.Bomb:update(dt)
    self:matrix_collide(dt)
    self:updateAngle(dt)
    self:updateRect()

    self.ifire.update(dt, 'right',{0, self.ifire_offset-set.TILESIZE/2})
    self.ifire.particle:emit(1)

    self.lifetime = self.lifetime-dt
    if self.lifetime<0 then self:timetoexplode() end
end

function O.Bomb:explode(damage)
    self.lifetime = self.lifetime-damage/200
    self:random_move()
end

function O.Bomb:timetoexplode()
    self.dead = true
    self:explode_cells()
    O.Monster.alarm(self,'tank','hunter')
    for particle in pairs(self.particles) do particle:reset() end
    self.dstaud:play()
    Model:destroy(self)
end

return O
