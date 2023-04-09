-- Mon Jul 16 23:34:53 2018
-- (c) Aliaksandr Veledzimovich
-- set KADZEN

local fc = require('lib/fct')
local fl = require('lib/lovfl')

local set = {
    APPNAME = love.window.getTitle(),
    VER = '1.0',
    SAVE = 'kadzensave.lua',
    SAVEDEF = 'kadzendef.lua',
    FULLSCR = love.window.getFullscreen(),
    WID = love.graphics.getWidth(),
    HEI = love.graphics.getHeight(),
    MIDWID = love.graphics.getWidth() / 2,
    MIDHEI = love.graphics.getHeight() / 2,
    SCALE = 0.375,

    EMPTY = {0,0,0,0},
    WHITE = {1,1,1,1},
    BLACK = {0,0,0,1},
    RED = {1,0,0,1},
    YELLOW = {1,1,0,1},
    GREEN = {0,1,0,1},
    BLUE = {0,0,1,1},

    DARKGRAY = {32/255,32/255,32/255,1},
    DARKGRAYF = {32/255,32/255,32/255,0},
    GRAY = {0.5,0.5,0.5,1},
    GRAYHHHF = {0.5,0.5,0.5,64/255},
    GRAYHHF = {0.5,0.5,0.5,32/255},
    GRAYHF = {0.5,0.5,0.5,16/255},
    GRAYF = {0.5,0.5,0.5,0},
    LIGHTGRAY = {192/255,192/255,192/255,1},
    LIGHTGRAYF = {192/255,192/255,192/255,0},

    WHITEHHHF = {1,1,1,64/255},
    WHITEHHF = {1,1,1,32/255},
    WHITEHF = {1,1,1,16/255},
    WHITEF = {1,1,1,0},

    BLACKBLUE = {16/255,16/255,64/255,1},
    DARKRED = {128/255,0,0,1},
    ORANGE = {1, 164/255, 32/255, 200/255},

    -- Vera Sans
    MAINFNT = 'res/fnt/StencilStd.otf',

    IMG=fc.map(love.image.newImageData, fl.loadAll('res/img','png')),
    AUD=fc.map(function(path)
                       if path:match('[^.]+$')=='wav' then
                           return love.audio.newSource(path,'static')
                       else
                           return love.audio.newSource(path,'stream') end
                        end, fl.loadAll('res/aud','wav','mp3')),

    love.audio.setEffect('echo',{type='echo',delay=0.7,spread=0.8}),

    TILESIZE = 48,
    MAXHP = 4,
    MAXAMMO = 13,
    MAXDIST = 4
}

set.TILEWID = math.floor(set.WID/set.TILESIZE)
set.TILEHEI = math.floor(set.HEI/set.TILESIZE)

set.MIDTILEWID = math.ceil(set.TILEWID/2)
set.MIDTILEHEI = math.ceil(set.TILEHEI/2)

set.TITLEFNT = {set.MAINFNT,64}
set.MENUFNT = {set.MAINFNT,32}
set.GAMEFNT = {set.MAINFNT,16}
set.UIFNT = {set.MAINFNT,8}

set.BGCLR =  set.DARKGRAY
set.TXTCLR = set.WHITE
return set
