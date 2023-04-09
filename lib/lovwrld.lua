#!/usr/bin/env love
-- LOVWRLD
-- 1.0
-- World Generators (love2d)
-- lovwrld.lua

-- MIT License
-- Copyright (c) 2018 Aliaksandr Veledzimovich veledz@gmail.com

-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

-- 2.0
-- add new brain lab or diagonal maze

if arg[1] then print('1.0 LOVWRLD World Generators (lua+love2d)', arg[1]) end

-- lua<5.3
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local btmaze, swmaze, elmaze

local WRLD = {FLOOR=0,WALL=-1,FIN='F',START='S',MARK='.'}

btmaze = {}
function btmaze.setGrid(wid,hei,tilesize)
    tilesize = tilesize or 1
    local mazewid = math.floor(wid/tilesize)
    local mazehei = math.floor(hei/tilesize)
    mazewid = mazewid + (mazewid+1)%2
    mazehei = mazehei + (mazehei+1)%2
    local mat = {}
    local empty = {}
    for y=1,mazehei do
        mat[y] = {}
        for x=1,mazewid do
            if x % 2==0 and y%2==0 then
                mat[y][x] = WRLD.MARK
                empty[#empty+1] = {x,y}
            else
                mat[y][x] = WRLD.WALL end
        end
    end
    return mat, empty, mazewid, mazehei
end

function btmaze.getRandomDot(data,empty)
    local dot = data[math.random(#data)]
    for i=1,#empty do
        if empty[i][1]==dot[1] and empty[i][2]==dot[2] then
            table.remove(empty,i)
            break
        end
    end
    return dot
end

function btmaze.getClosest(wid,hei,mat,dot,sign,see)
    sign = sign or WRLD.MARK
    see = see or 2

    local close = {}
    local x,y = dot[1],dot[2]
    local cells = {{-1*see, 0}, {1*see, 0}, {0, 1*see}, {0, -1*see}}
    for i=1, #cells do
        local xx = x+cells[i][1]
        local yy = y+cells[i][2]
        if (xx>0 and xx<=wid) and (yy>0 and yy<=hei) then
            if (mat[yy][xx]==sign or
                mat[yy][xx]==WRLD.START or
                mat[yy][xx]==WRLD.FIN) then
                close[#close+1] = {xx, yy}
            end
        end
    end
    return close
end

function btmaze.setStep(mat,dot,path,sign)
    sign = sign or WRLD.FLOOR
    mat[dot[2]][dot[1]] = sign
    path[#path+1] = dot
end

function WRLD.backtracking(wid,hei,tilesize)
    local mat,empty,mazewid,mazehei = btmaze.setGrid(wid,hei,tilesize)

    local startdot = {math.ceil(mazewid/2),math.ceil(mazehei/2)}
    local finaldots = {{2,2},{2,mazehei-1},{mazewid-1,mazehei-1},{mazewid-1,2}}
    local finaldot = finaldots[math.random(#finaldots)]

    local path = {}
    local start = btmaze.getRandomDot(empty, empty)

    btmaze.setStep(mat,start,path)
    while #empty>0 do
        local close = btmaze.getClosest(mazewid,mazehei,mat,start)
        if #close>0 then
            btmaze.setStep(mat,start,path)
            local nextdot = btmaze.getRandomDot(close,empty)
            btmaze.setStep(mat,nextdot,path)
            -- remove wall
            local wall = {math.floor((start[1]+nextdot[1])/2),
                            math.floor((start[2]+nextdot[2])/2)}
            btmaze.setStep(mat,wall,path)

            start = nextdot
        elseif #path>0 then
            start = path[#path]
            table.remove(path,#path)
        else
            start = btmaze.getRandomDot(empty,empty)
        end
    end
    btmaze.setStep(mat,finaldot,path,WRLD.FIN)
    btmaze.setStep(mat,startdot,path,WRLD.START)
    return mat
end

-- sidewinder
swmaze = {setGrid=btmaze.setGrid}
function WRLD.sidewinder(wid,hei,tilesize)
    local mat,_,mazewid,mazehei = swmaze.setGrid(wid,hei,tilesize)

    for y=2,mazehei,2 do
        local start = 2
        for x=2,mazewid,2 do
            mat[y][x]=WRLD.FLOOR
            if y~=2 then
                if math.random(0,1)==0 and x~=mazewid then
                    if x+1~=mazewid then mat[y][x+1] = WRLD.FLOOR
                    else mat[y-1][x] = WRLD.FLOOR end
                else
                    local cell = math.random(start,x)
                    mat[y-1][cell+cell%2]=WRLD.FLOOR
                    start = x+2
                end
            else
                if x+1~=mazewid then mat[y][x+1] = WRLD.FLOOR end
            end
        end
    end

    local finaldots = {{2,mazehei-1},{mazewid-1,mazehei-1}}
    local index = math.random(#finaldots)
    local finaldot = finaldots[index]
    table.remove(finaldots,index)
    mat[finaldot[2]][finaldot[1]] = WRLD.FIN
    mat[finaldots[1][2]][finaldots[1][1]] = WRLD.START
    return mat
end

-- eller
elmaze = {getClosest=btmaze.getClosest}
function elmaze.setGrid(wid,hei,tilesize)
    tilesize = tilesize or 1
    local mazewid = math.floor(wid/tilesize)
    local mazehei = math.floor(hei/tilesize)
    mazewid = mazewid + (mazewid+1)%2
    mazehei = mazehei + (mazehei+1)%2
    local mat = {}
    for y=1,mazehei do
        mat[y] = {}
        for x=1,mazewid do
            if (x>1 and x<mazewid) and (y>1 and y<mazehei) then
                mat[y][x] = WRLD.FLOOR
            else
                mat[y][x] = WRLD.WALL
            end
        end
    end
    return mat,mazewid,mazehei
end

function WRLD.eller(wid,hei,tilesize)
    local mat,mazewid,mazehei = elmaze.setGrid(wid,hei,tilesize)
    for y=2, mazehei, 2 do
        local start = 2
        for x=2, mazewid, 2 do
            mat[y][x]=WRLD.FLOOR
            if math.random(0,1)==0 then
                if x+1~=mazewid then mat[y][x+1] = WRLD.WALL end
            end
            if math.random(0,1)==0 then
                if y+1~=mazehei then mat[y+1][x] = WRLD.WALL end
            end

            if mat[y][x+1]==WRLD.WALL then
                if y+1~=mazehei then
                    local cell = math.random(start,x)
                    mat[y+1][cell+cell%2] = WRLD.FLOOR
                end
                start = x+2
            end
        end

        if y+1~=mazehei then
            local copy = {}
            local copy1 = {}
            for i=1,#mat[y] do copy[i]=mat[y][i] end
            for i=1,#mat[y+1] do copy1[i]=mat[y+1][i] end
            mat[y+2]=copy
            if y+3~=mazehei then mat[y+3]=copy1 end

            for x=2,mazewid,2 do
                if mat[y+3][x]==WRLD.WALL then
                    mat[y+2][x-1]=WRLD.WALL
                    mat[y+2][x+1]=WRLD.WALL
                    mat[y+1][x-1]=WRLD.WALL
                    mat[y+1][x+1]=WRLD.WALL
                end
            end
            for x=2,mazewid,2 do
                local cl
                cl = #elmaze.getClosest(mazewid,mazehei,mat,
                                          {x,y+1},WRLD.WALL,1)
                if cl<2 then
                    mat[y+1][x-1]=WRLD.WALL
                    mat[y+1][x+1]=WRLD.WALL
                end
                -- clear walls and bottoms for next iter
                if x+1~=mazewid then mat[y+2][x+1] = WRLD.FLOOR end
                if y+3~=mazehei then mat[y+3][x]=WRLD.FLOOR end
            end
        else
            -- last row
            for x=2, mazewid,2 do
                local cl
                if x+1~=mazewid then mat[y][x+1] = WRLD.FLOOR end
                cl = #elmaze.getClosest(mazewid,mazehei,mat,
                                          {x+1,y-1},WRLD.WALL,1)
                if cl==0 then mat[y][x+1]=WRLD.WALL end
            end
        end
    end
    local finaldots = {{2,2},{mazewid-1,2}}
    local index = math.random(#finaldots)
    local finaldot = finaldots[index]
    table.remove(finaldots,index)
    mat[finaldot[2]][finaldot[1]] = WRLD.FIN
    mat[finaldots[1][2]][finaldots[1][1]] = WRLD.START
    return mat
end

function WRLD.hall(wid,hei,tilesize)
    local mat,mazewid,mazehei = elmaze.setGrid(wid,hei,tilesize)
    for y=3,mazehei,2 do
        for x=3,mazewid,2 do
            mat[y][x] = WRLD.WALL
        end
    end
    local startdot = {math.ceil(mazewid/2),math.ceil(mazehei/2)}
    local finaldots = {{2,2},{2,mazehei-1},{mazewid-1,mazehei-1},{mazewid-1,2}}
    local finaldot = finaldots[math.random(#finaldots)]
    mat[finaldot[2]][finaldot[1]] = WRLD.FIN
    mat[startdot[2]][startdot[1]] = WRLD.START
    return mat
end


function WRLD.solve(startdot,finaldot,matrix)
    local clonematrix = {}
    local wid = #matrix[1]
    local hei = #matrix
    for row=1,hei do
        local clonerow = {}
        for col=1,wid do
            clonerow[#clonerow+1]=matrix[row][col]
        end
        clonematrix[#clonematrix+1]=clonerow
    end

    local mazewid = #clonematrix[1]
    local mazehei = #clonematrix
    local empty = {}

    for y=1,mazehei do
        for x=1, mazewid do
            if clonematrix[y][x]==WRLD.FLOOR then empty[#empty+1]={x,y} end
        end
    end
    local path = {}

    repeat
        local close = btmaze.getClosest(mazewid,mazehei,clonematrix,
                                             startdot,WRLD.FLOOR,1)
        if #close>0 then
            startdot = btmaze.getRandomDot(close,empty)
            btmaze.setStep(clonematrix,startdot,path,WRLD.MARK)
        elseif path then
            startdot = path[#path]
            table.remove(path,#path)
        else
            return path
        end
    until startdot[1]==finaldot[1] and startdot[2]==finaldot[2]
    return path
end

function WRLD.print(matrix)
    local wid = #matrix[1]
    local hei = #matrix
    for y=1,hei do
        for x=1, wid do
            local cell = matrix[y][x]
            if cell==-1 then
                io.write(matrix[y][x],' ')
            else
                io.write(' ',matrix[y][x],' ')
            end
        end
        io.write('\n')
    end
end

return WRLD
