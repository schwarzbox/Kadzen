-- Thu Sep  6 23:35:59 2018
-- (c) Alexander Veledzimovich
-- proto KADZEN

local fc = require('lib/fct')
local cls = require('lib/cls')
local tmr = require('lib/tmr')
local wrld = require('lib/lovwrld')
local cmp = require('lib/lovcmp')
local imd = require('lib/lovimd')
local set = require('game/set')

local unpack = table.unpack or unpack

local O={}
O.Floor = {}
O.Floor.setSprite = cmp.setSprite
O.Floor:setSprite(set.IMG['floor'],128,128,6,1)
O.Floor.sprite.table=love.graphics.newSpriteBatch(O.Floor.sprite.atlas,512)

function O.Floor:add_explode(x,y)
    self.sprite.table:add(self.sprite.quads[6],x,y,0,set.SCALE,set.SCALE)
end

function O.Floor:clear()
    self.sprite.table:clear()
end

local Proto = cls.Class({tag='proto', x=nil, y=nil, dx=0, dy=0,
                      angle=0,da=0, scale=set.SCALE})
-- const
Proto.all_data = {imd.fromMatrix({{1}}, set.GRAY, 1)}
Proto.imgdata = Proto.all_data[1]
-- cmp
Proto.setObject = cmp.setObject
Proto.move = cmp.move
Proto.rotate = cmp.rotate
Proto.collision = cmp.matrixCollision
-- particle
Proto.destroyParticle = cmp.destroyParticle
Proto.boom = cmp.nodeParticle
Proto.objectParticle = cmp.objectParticle

function Proto:new(o)
    Proto.total = Proto.total + 1
    self:setObject(self.imgdata)
    self.node = Model
    self.tmr = tmr:new()
    self.dstaud = set.AUD['destroy']:clone()
    self.dstaud:setEffect('echo')
    self:spawn()
end

function Proto:spawn() Model:spawn(self) end

function Proto:__tostring() return self.tag end

function Proto:draw()
    love.graphics.draw(self.image,self.quad,self.x,self.y, self.angle,
                        self.scale, self.scale, self.pivx, self.pivy)
    for particle in pairs(self.particles) do
        love.graphics.draw(particle)
    end
end

function Proto:explosion_wave(dx,dy,maxdist,func)
    local boomfunc = func or function() self:boom(self.x, self.y, 30,
                        {10,8,4},{set.WHITEHF,set.GRAY,set.WHITEF},
                        'circle', {2,5}, {0,1}, 2) end

    self.step = self.step or set.TILESIZE/64
    self.angle = self.angle or 0
    self.scale = self.scale or set.SCALE
    local signx,signy = 0,0
    if dx<0 then signx=-1 elseif dx>0 then signx=1 end
    if dy<0 then signy=-1 elseif dy>0 then signy=1 end
    local powerx=signx*(maxdist-math.abs(dx))
    local powery=signy*(maxdist-math.abs(dy))
    local gx = (powerx*set.TILESIZE)/2
    local gy = (powery*set.TILESIZE)/2

    self.tmr:tween(self.step, self,{x=self.x+gx,y=self.y+gy,
            angle=self.angle+love.math.random()*love.math.random(-2,2),
            scale=self.scale-0.04},'outCubic',
            boomfunc)
end

function Proto:explode_animation(firex,firey,size)
    firex = firex or self.x
    firey = firey or self.y
    size = size or 1
    -- fire cloud
    self:boom(firex, firey, 20, {1},
              {set.WHITEHF,set.WHITE,set.GRAYF}, set.IMG['fire'],nil,{size,0})
    -- dust
    self:boom(self.x, self.y, 10, {1},
              {set.WHITEF,set.WHITEHHF,set.GRAYF}, set.IMG['cloud'],
                                                    {1,3},{3,0},40,{-1.5,1.5})
    -- fire
    self:boom(firex, firey, 20, {6}, nil, nil, nil, nil, 6000)
end

function Proto:explode_cells(size)
    local xx,yy = math.floor(self.tilex*set.TILESIZE),
                    math.floor(self.tiley*set.TILESIZE)
    for i=-self.distance.val,self.distance.val do
        local dx = self.tilex+i
        local dy = self.tiley+i
        size = size or 2
        if i~=0 then size=1 end

        if dx>0 and dx<=set.TILEWID then
            if dx>1 and dx<set.TILEWID-1 then
                -- safe remove wall tag
                Model:set_mazetile(dx,self.tiley,wrld.FLOOR)
            end
            local objectx=Model:get_object(self,dx,self.tiley)
            for ox=1,#objectx do
                objectx[ox]:explode(self.damage,i,0,self.distance.val)
            end
            self:explode_animation(dx*set.TILESIZE,yy,size)
        end

        if dy>0 and dy<=set.TILEHEI then
            if dy>1 and dy<set.TILEHEI-1 then
                -- safe remove wall tag
                Model:set_mazetile(self.tilex,dy,wrld.FLOOR)
            end
            local objecty=Model:get_object(self,self.tilex,dy)
            for oy=1,#objecty do
                objecty[oy]:explode(self.damage,0,i,self.distance.val)
            end
            self:explode_animation(xx,dy*set.TILESIZE,size)
        end
        local tsize = set.TILESIZE/2
        local fdx = love.math.random(-tsize,tsize)
        local fdy = love.math.random(-tsize,tsize)
        O.Floor:add_explode(self.x+fdx-tsize,self.y+fdy-tsize)
    end
end

function Proto:explode(damage,dx,dy,maxdist)
    if self.dead then return end
    if self.opendoor and not self.open then self:opendoor() end
    self.dead=true
    if (self.tag~=O.Fin.tag and self.tag~=O.Start.tag and
        self.tag~=O.Key.tag) then self:explosion_wave(dx,dy,maxdist) end

    self.image=love.graphics.newImage(self.dstdata)
    if self.tag~=wrld.FIN and self.tag~=wrld.START then
        Model:set_itemstile(self.tilex,self.tiley,wrld.FLOOR)
    end
    O.Monster.remove_oldgoal(O.Hunter,{self.tilex,self.tiley})
end

function Proto:empty()
    if self.dead then return end
    self.clean = true
    self.image = love.graphics.newImage(self.img_empty)
    Model:set_itemstile(self.tilex,self.tiley,wrld.FLOOR)
    O.Monster.remove_oldgoal(O.Hunter,{self.tilex,self.tiley})
end


O.Wall = cls.Class(Proto,{tag=wrld.WALL})
O.Wall.setSprite = cmp.setSprite
O.Wall:setSprite(set.IMG['wall'],128,128,5,4)
O.Wall.sprite.table=love.graphics.newSpriteBatch(O.Wall.sprite.atlas,386)
O.Wall.all_data = imd.slice(set.IMG['wall'], 128,128, 5,4)
function O.Wall:explode()
    local dstdata=self.sprite.quads[love.math.random(18,19)]
    self.angle=self.angle+love.math.random()*0.6-0.3
    if Model:get_mazetile(self.tilex,self.tiley)==wrld.WALL then
        dstdata=self.sprite.quads[17]
        self.angle=self.angle+love.math.random()*0.1-0.05
    end
    -- self.sprite.table:set(self.sid, 0, 0, 0, 0, 0)
    self.sprite.table:set(self.sid, dstdata,
                          self.x-set.TILESIZE/2,
                          self.y-set.TILESIZE/2, self.angle,
                          set.SCALE,set.SCALE)
    -- dust
    self:boom(self.x, self.y, 10, {1},
              {set.WHITEF,set.WHITEHHF,set.GRAYF}, set.IMG['cloud'],
                                                    {1,6},{2,0},10,{-0.8,0.8})
    -- gray dots
    self:boom(self.x, self.y, 10, {6},{set.GRAY,set.DARKGRAY,set.GRAYF},
                        nil, nil, nil, 2000)
    self.dstaud:play()

    local tsize = set.TILESIZE/2
    local fdx = love.math.random(-tsize,tsize)
    local fdy = love.math.random(-tsize,tsize)
    O.Floor:add_explode(self.x+fdx-tsize,self.y+fdy-tsize)
end

function O.Wall:clear()
    self.sprite.table:clear()
end

function O.Wall:draw()
    for particle in pairs(self.particles) do love.graphics.draw(particle) end
end

O.Fin = cls.Class(Proto,{tag='F',open=false})
O.Fin.all_data = imd.slice(set.IMG['door'], 128,128, 3,1)
function O.Fin:opendoor()
    self.open=true
    self.image = love.graphics.newImage(self.img_open)
end

O.Start = cls.Class(Proto,{tag='S'})
O.Start.imgdata = O.Fin.all_data[3]
O.Start.dstdata = imd.splash(O.Start.imgdata,20,set.TILESIZE)

O.Key = cls.Class(Proto,{tag='K',door=nil,open=false})
O.Key.all_data = imd.slice(set.IMG['key'], 128,128, 2,1)
O.Key.imgdata = O.Key.all_data[1]
O.Key.img_open = O.Key.all_data[2]
O.Key.dstdata = imd.splash(O.Key.img_open,20,set.TILESIZE)
O.Key.dooraud = set.AUD['opendoor']:clone()
function O.Key:opendoor()
    self.open=true
    self.tmr:after(1,function()
        local door = Model:get_object(self,self.door[1],self.door[2])[1]
            door:opendoor()
        end)
    self.image = love.graphics.newImage(self.img_open)
    self.dooraud:play()
    O.Monster.alarm(self,'tank')
end

O.Hp = cls.Class(Proto,{tag='H'})
O.Hp.all_data = imd.slice(set.IMG['hp'], 128,128, 4,1)
O.Hp.imgdata = O.Hp.all_data[2]
O.Hp.img_empty = O.Hp.all_data[3]
O.Hp.img_lab = O.Hp.all_data[1]
O.Hp.img_bar = O.Hp.all_data[4]
O.Hp.dstdata = imd.splash(O.Hp.img_empty,40,set.TILESIZE)
O.Hp.bonus = 1

O.Ammo = cls.Class(Proto,{tag='A'})
O.Ammo.all_data = imd.slice(set.IMG['ammo'], 128,128, 3,1)
O.Ammo.imgdata = O.Ammo.all_data[3]
O.Ammo.img_empty = O.Ammo.all_data[1]
O.Ammo.img_lab = O.Ammo.all_data[2]
O.Ammo.dstdata = imd.splash(O.Ammo.img_empty,40,set.TILESIZE)
O.Ammo.bonus = 1
function O.Ammo:explode(damage,dx,dy,maxdist)
    if self.dead then return end
    self.dead=true
    self:explosion_wave(dx,dy,maxdist)

    self:destroyParticle({4,4},{1,2},2000)
    if not self.clean then
        self.tmr=tmr:new()
        self.image=love.graphics.newImage(self.dstdata)

        local bomb=O.Bomb{x=self.x,y=self.y,angle=self.angle,
                            dx=self.dx,dy=self.dy,da=self.da,
                            scale=self.scale}
        bomb:set_tmpdistance(love.math.random(4))

    else
        self.image=love.graphics.newImage(self.dstdata)
    end
    Model:set_itemstile(self.tilex,self.tiley,wrld.FLOOR)
    O.Monster.remove_oldgoal(O.Hunter,{self.tilex,self.tiley})
end

O.Upgrade = cls.Class(Proto,{tag='U'})
O.Upgrade.all_data = imd.slice(set.IMG['upgrade'], 128,128, 2,1)
O.Upgrade.imgdata = O.Upgrade.all_data[1]
O.Upgrade.img_empty = O.Upgrade.all_data[2]
O.Upgrade.dstdata = imd.splash(O.Upgrade.img_empty,40,set.TILESIZE)
O.Upgrade.bonus = 1

O.Chip = cls.Class(Proto,{tag='C'})
O.Chip.all_data = imd.slice(set.IMG['chip'], 128,128, 3,1)
O.Chip.imgdata = O.Chip.all_data[1]
O.Chip.img_empty = O.Chip.all_data[2]
O.Chip.img_lab = O.Chip.all_data[3]
O.Chip.dstdata =  imd.splash(O.Chip.all_data[2],20,set.TILESIZE)
O.Chip.bonus = 1
function O.Chip:spawn() Model:spawn(self,1) end


O.Monster = cls.Class(Proto,{tag='M'})
O.Monster.speed = set.TILESIZE
O.Monster.maxspeed = O.Monster.speed+1
O.Monster.pool = {}
O.Monster.hp = 1
O.Monster.damage = 1
O.Monster.step = set.TILESIZE/64
-- cmp
O.Monster.shot = cmp.shot
O.Monster.hit = cmp.hit
O.Monster.matrixPathfinder = cmp.matrixPathfinder
O.Monster.getMatrixGoal = cmp.getMatrixGoal
O.Monster.circleView = cmp.circleView
function O.Monster:new(o)
    Proto.new(self)
    self.goal = nil
    self.path = {}
    self.moving = false
    self.img_index = 1
    self.idle_img = self:set_tiles(1,#self.all_data)
    Model:set_mazetile(self.tilex,self.tiley,self.tag)
end

function O.Monster:set_tiles(st,fin)
    local arr={}
    for i=st,fin do
        local img=love.graphics.newImage(self.all_data[i])
        arr[#arr+1] = img
    end
    return arr
end

function O.Monster.alarm(obj,...)
    local fargs={...}
    for i=1,#O.Monster.pool do
        local mons = O.Monster.pool[i]
        if fc.isval(mons.type,fargs) then
            mons:set_goal(obj.tilex,obj.tiley)
        end
    end
end

function O.Monster.remove_oldgoal(obj,remove)
    for i=1,#O.Monster.pool do
        local mon = O.Monster.pool[i]
        if mon.type==obj.type then
            for g=#mon.oldgoal,1,-1 do
                if fc.equal(mon.oldgoal[g],remove) then
                    table.remove(mon.oldgoal,g)
                    break
                end
            end
        end
    end
end

function O.Monster:set_goal(tilex,tiley) self.goal={tilex,tiley} end

function O.Monster:get_viewrange()
    return love.math.random(set.TILESIZE,self.viewrange)
end

function O.Monster:set_dxdy()
    local dx = self.path[#self.path][1]-self.tilex
    local dy = self.path[#self.path][2]-self.tiley
    self.dx = dx*set.TILESIZE
    self.dy = dy*set.TILESIZE
end

function O.Monster:set_angles()
    if self.dx>0 then self:setAngle(math.rad(0))
    elseif self.dx<0 then self:setAngle(math.rad(180))
    elseif self.dy>0 then self:setAngle(math.rad(90))
    elseif self.dy<0 then self:setAngle(math.rad(270))
    else self.angle=self:setAngle(self.angle)
    end
end

function O.Monster:look(target)
    local viewrange=self:get_viewrange()
    local goal = self:getMatrixGoal(Model:get_maze(),self.oldgoal,
                    math.floor(viewrange/set.TILESIZE),wrld.FLOOR,
                    {target})

    local tar = self:getMatrixGoal(Model:get_maze(),self.oldgoal,
                    math.floor(self.viewrange/set.TILESIZE),wrld.FLOOR,
                    {target})
    return goal,tar
end

function O.Monster:matrix_collide(dt)
    for i=1, #self.lastcoll do
        local catch = ((self.tag==O.Monster.tag and
                       self.lastcoll[i].tile==O.Kadzen.tag) or
                        (self.tag==O.Kadzen.tag and
                       self.lastcoll[i].tile==O.Monster.tag))

        if (self.lastcoll[i].tile==wrld.FLOOR or
            self.lastcoll[i].tile==wrld.START or
            self.lastcoll[i].tile==wrld.FIN or
            catch) then

            if not self.moving then
                self.moving = true
                self.img_index = 1
                local oldx = self.x
                local oldy = self.y
                local dx = self.dx
                local dy = self.dy
                Model:set_mazetile(self.tilex,self.tiley,wrld.FLOOR)
                self.tilex=self.tilex+self.lastcoll[i].dx
                self.tiley=self.tiley+self.lastcoll[i].dy
                Model:set_mazetile(self.tilex,self.tiley,self.tag)
                self.tmr:tween(self.step,self,{x=self.x+self.dx,
                                        y=self.y+self.dy,
                                        img_index=#self.idle_img},'linear',
                                    function()
                                        self.x = oldx+dx self.y = oldy+dy
                                        self.dx = 0 self.dy = 0
                                        self:updateXY(dt)
                                        self:updateRect()
                                        self.img_index = 1
                                        self.moving = false
                                        self:explore(catch)
                                    end)
                return true
            end

        elseif self.lastcoll[i].tile==O.Monster.tag then
            self.path = {}
        elseif self.lastcoll[i].tile==O.Bomb.tag then
            self.path = {}
            self.goal = nil
        end
    end
end

function O.Monster:move_animation()
    local index_img = math.floor(self.img_index+0.5)
    self.image = self.idle_img[index_img]
end

function O.Monster:overlap()
    for i=1,#O.Monster.pool do
        local mon = O.Monster.pool[i]
        if mon~=self and mon.tilex==self.tilex and mon.tiley==self.tiley then
            return true
        end
    end
end

function O.Monster:random_move()
    local path = {{self.speed,0},{-self.speed,0},
                    {0,self.speed},{0,-self.speed}}
    self.dx,self.dy = unpack(path[love.math.random(#path)])
end

function O.Monster:explore(catch) end

function O.Monster:explode(damage,dx,dy,maxdist)
    self:destroyParticle({4,4},{1,2},2000)
    if self:hit(damage) and not self.dead then
        self.dead = true
        O.Chip{x=math.floor(self.tilex*set.TILESIZE),
                    y=math.floor(self.tiley*set.TILESIZE)}
        Model:set_itemstile(self.tilex,self.tiley,O.Chip.tag)

        self:explosion_wave(dx,dy,maxdist)
        self.image = love.graphics.newImage(self.dstdata)
        Model:set_mazetile(self.tilex,self.tiley,wrld.FLOOR)
        for particle in pairs(self.particles) do particle:reset() end

        self.dstaud:play()

        local obj=self
        Model:destroy(self)
        Model:spawn(obj,1)

        Model:set_score(self.type)
        -- end game at last level
        for i=#O.Monster.pool,1,-1 do
            if not O.Monster.pool[i].dead then goto continue end
        end

        if Model:get_level() == 4 then
            self.tmr:after(4,
                function() Model:endgame(Model:get_avatar().dead) end)
        end

    end
    :: continue ::
end

return Proto,O
