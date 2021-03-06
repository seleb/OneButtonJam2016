pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--one button duel
--made by sean for #onebuttonjam


function rpin(i)
 return peek(0x5f80+i)
end

function wpin(i,v)
 return poke(0x5f80+i,v)
end

function entity(_x,_y,_c)
 local e={}
 e.p={}
 e.p[1]=_x
 e.p[2]=_y
 e.a=0
 e.s={1,1}
 e.c=_c
 e.children={}
 e.add=function(_c)
  add(e.children,_c)
 end
 return e
end

function vectorize(_e)
 _e.points={}
 _e.draw=draw_vector
 return _e
end

function ease(t)
 if t < 0.5 then
  return 4*t*t*t
 end
	return (t-1)*(2*t-2)*(2*t-2)+1
end

function remap(v,oa,ob,na,nb)
 return na + (v - oa) * (nb - na) / (ob - oa)
end

function lerp(_from,_to,_t)
 return _from+_t*(_to-_from)
end

function rotate(_p,_a)
 local ca=cos(_a)
 local sa=sin(_a)
 local p={}
 p[1] = ca*_p[1]-sa*_p[2]
 p[2] = sa*_p[1]+ca*_p[2]
 return p
end

function v_add(_a,_b)
 return {_a[1]+_b[1],_a[2]+_b[2]}
end
function v_sub(_a,_b)
 return {_a[1]-_b[1],_a[2]-_b[2]}
end
function v_mul(_v,_s)
 return {_v[1]*_s[1],_v[2]*_s[2]}
end
function v_lerp(_a,_b,_t)
 return{lerp(_a[1],_b[1],_t),lerp(_a[2],_b[2],_t)}
end


function remove(table,idx)
 for i=idx,#table do
  table[i]=table[i+1]
 end
end

function sfx2(v,c)
 if options.sfx then
  sfx(v,c)
 end
end

function _init()
 cartdata("sean_onebuttonjam_data")
 
 options={}
 if dget(10)!=1 then
  dset(10,1)
  dset(1,1)
  dset(2,1)
  dset(3,1)
  dset(4,1)
 else
 end
 
 
 options.palettes={
  {0,2,8,15},
  {1,7,13,6},
  {0,15,7,8},
  {8,9,10,7},
  {1,15,14,13},
  {0,4,4,5},
  {8,7,15,12},
  {7,6,0,5},
  {11,0,1,3},
  {15,7,2,14},
  {7,7,0,0},
  {0,0,7,7},
  {10,10,0,0},
  {0,1,10,2}
 }
 
 options.sun=dget(1)==1
 options.music=dget(2)==1
 options.sfx=dget(3)==1
 options.palette=dget(4)
 options.palette=(options.palette-1)%#options.palettes+1
 
 options.set_palette=function()
  for i=1,4 do
   pal(options.palettes[1][i],options.palettes[options.palette][i])
  end
 end
 
 palt(0,false)
 palt(11,true)
 
 if options.music then
  music(2,1600,1+2+3)
 end
 options.set_palette()

 ratio=0

 pins={}
 pins.online=0
 pins.p1_btn=1
 pins.p2_btn=2
 pins.p1_stat=3
 pins.p2_stat=4
 pins.p1_winner=5
 pins.p2_winner=6
 
 connection={}
 connection.offline=0
 connection.connecting=1
 connection.online=2
 connection.disabled=3
 
 online=false
 
 -- start with online disabled
 -- btns invalid
 -- and not moving
 wpin(pins.online,connection.disabled)
 wpin(pins.p1_btn,6)
 wpin(pins.p2_btn,6)
 wpin(pins.p1_stat,0)
 wpin(pins.p2_stat,0)
 wpin(pins.p1_winner,3)
 wpin(pins.p2_winner,3)
 
 -- camera
 cam=entity(0,0)
 cam.p_stack={}
 cam.a_stack={}
 cam.s_stack={}
 cam.sp={}
 cam.sp[1]=0
 cam.sp[2]=0
 cam.n_stack=1
 add(cam.p_stack,cam.sp)
 add(cam.a_stack,cam.a)
 add(cam.s_stack,cam.s)
 
 cam.push = function(_p)
  add(cam.p_stack,cam.sp)
  add(cam.a_stack,cam.a)
  add(cam.s_stack,cam.s)
  local p = cam.point(_p.p)
  cam.sp=v_sub(cam.sp,p)
  cam.a+=_p.a
  cam.s=v_mul(cam.s,_p.s)
  camera(cam.p[1]+cam.sp[1],cam.p[2]+cam.sp[2])
 
  cam.n_stack+=1
 end
 
 cam.pop = function()
  local p=cam.p_stack[cam.n_stack]
  local a=cam.a_stack[cam.n_stack]
  local s=cam.s_stack[cam.n_stack]
  cam.a=a
  cam.s=s
  cam.sp=p
  camera(cam.p[1]+cam.sp[1],cam.p[2]+cam.sp[2])
  cam.a_stack[cam.n_stack]=nil
  cam.p_stack[cam.n_stack]=nil
  cam.s_stack[cam.n_stack]=nil

  cam.n_stack-=1
 end
 
 cam.point=function(_p)
  return v_mul(rotate(_p,cam.a),cam.s)
 end
 
 btns={}
 for i=0,5 do
  btns[i]={}
  btns[i].face=vectorize(entity(0,0))
 end
 btns[0].s="\139"
 btns[1].s="\145"
 btns[2].s="\148"
 btns[3].s="\131"
 btns[4].s="\142"
 btns[5].s="\151"
 
 btns[0].face.points={
  {-1.5,-0.5},
  {-0.5,-0.5},
  {-0.5,-1.5},
  {1.5,-1.5},
  {1.5,1.5},
  {-0.5,1.5},
  {-0.5,0.5},
  {-1.5,0.5},
  {-1.5,-0.5}
 }
 for p in all(btns[0].face.points) do
  add(btns[1].face.points,rotate(p,0.5))
  add(btns[2].face.points,rotate(p,0.75))
  add(btns[3].face.points,rotate(p,0.25))
 end
 
 btns[4].face.points={
  {-1.5,-1.5},
  {-1.5,1.5},
  {1.5,1.5},
  {1.5,-1.5},
  {-1.5,-1.5}
 }
 btns[4].face.child=vectorize(entity(0,0))
 btns[4].face.child.points={
  {-.5,-.5},
  {-.5,.5},
  {.5,.5},
  {.5,-.5},
  {-.5,-.5}
 }
 btns[4].face.add(btns[4].face.child)
 
 btns[5].face.points={
  {-1.5,-1.5},
  {-0.5,-1.5},
  {-0.5,1.5},
  {-1.5,1.5},
  {-1.5,0.5},
  {1.5,0.5},
  {1.5,1.5},
  {0.5,1.5},
  {0.5,-1.5},
  {1.5,-1.5},
  {1.5,-0.5},
  {-1.5,-0.5},
  {-1.5,-1.5}
 }
 
 parts={}
 
 -- player 1
 p1=entity(-256,0,7)
 p1.btn=nil
 p1.dir=1
 p1.id=1
 p1.draw=function(_c)
  cam.push(_c)
  
  draw_children(_c)
  
  cam.pop()
 end
 
 p1.body=vectorize(entity(0,-4.5))
 p1.body.points={
  {-2,0.1},
  {2,0.5},
  {0.75,-4},
  {1,-5.5},
  {-0.5,-6},
  {-1.5,-3.5},
  {-2,0.1}
 }
 add(p1.body.points,p1.body.points[1])
 
 p1.head=vectorize(entity(1,-9))
 p1.head.points={
  {-2.5,2.5},
  {-2.5,1.5},
  {-3.5,1.5},
  {-3.5,-1.5},
  {-2.5,-1.5},
  {-2.5,-2.5},
  {2.5,-2.5},
  {2.5,-1.5},
  {3.5,-1.5},
  {3.5,1.5},
  {2.5,1.5},
  {2.5,2.5},
  {-2.5,2.5}
 }
 
 p1.lleg=vectorize(entity(-2,0.1))
 p1.lleg.points={
  {0,0},
  {0,2}
 }
 p1.lshin=vectorize(entity(0,2))
 p1.lshin.points={
  {0,0},
  {0,2},
  {0.5,2}
 }
 p1.rleg=vectorize(entity(2,0.5))
 p1.rleg.points={
  {0,0},
  {0,2}
 }
 p1.rshin=vectorize(entity(0,2))
 p1.rshin.points={
  {0,0},
  {0,2},
  {0.5,2}
 }
 
 p1.larm=vectorize(entity(-0.5,-6))
 p1.larm.points={
  {0,0},
  {0,2}
 }
 p1.lelb=vectorize(entity(0,2))
 p1.lelb.points={
  {0,0},
  {0,2}
 }
 p1.sword=vectorize(entity(0,1.5))
 p1.sword.points={
  {-1,0},
  {1,0},
  {1,-1},
  {4,0},
  {1,1},
  {1,0}
 }
 p1.rarm=vectorize(entity(1,-5.5))
 p1.rarm.points={
  {0,0},
  {0,1.5}
 }
 p1.relb=vectorize(entity(0,1.5))
 p1.relb.points={
  {0,0},
  {0,1.5}
 }
 
 
 
 p1.add(p1.body)
 p1.body.add(p1.head)
 
 p1.body.add(p1.lleg)
 p1.lleg.add(p1.lshin)
 p1.body.add(p1.rleg)
 p1.rleg.add(p1.rshin)
 
 p1.body.add(p1.rarm)
 p1.rarm.add(p1.relb)
 
 p1.body.add(p1.larm)
 p1.larm.add(p1.lelb)
 p1.lelb.add(p1.sword)
 
 -- player 2
 p2=entity(-p1.p[1],p1.p[2])
 p2.s = {-p1.s[1],p1.s[2]}
 p2.btn=nil
 p2.draw=p1.draw
 p2.dir=-1
 p2.id=2
 
 --duplicate p1's parts to p2
 p2.body=clone(p1.body)
 p2.head=clone(p1.head)
 p2.rleg=clone(p1.rleg)
 p2.rshin=clone(p1.rshin)
 p2.lleg=clone(p1.lleg)
 p2.lshin=clone(p1.lshin)
 p2.rarm=clone(p1.rarm)
 p2.relb=clone(p1.relb)
 p2.larm=clone(p1.larm)
 p2.lelb=clone(p1.lelb)
 p2.sword=clone(p1.sword)
 
 p2.add(p2.body)
 p2.body.add(p2.head)
 p2.body.add(p2.rarm)
 p2.body.add(p2.larm)
 p2.body.add(p2.rleg)
 p2.body.add(p2.lleg)
 p2.rleg.add(p2.rshin)
 p2.lleg.add(p2.lshin)
 p2.rarm.add(p2.relb)
 p2.larm.add(p2.lelb)
 p2.lelb.add(p2.sword)
 
 
 
 reset()
 
 menu={}
 menu.step=1
 menu.step_i=1
 menu.opt=1
 menu.start=10
 menu.gap=6
 menu.bar=32
 
 menu.select={}
 menu.u=function()
  menu.step_i=lerp(menu.step_i,menu.step,0.25)
  if abs(menu.step_i-menu.step) > 0.05 then
   for i=0,2 do
    local p={}
    p.c=0
    p.p={rnd(256),rnd(30)+90}
    p.v={(rnd(25)+25)*(menu.step-menu.step_i),0}
    add(parts,p)
   end
  end
  if menu.step==1 then
   if btnp(2) then
    menu.opt-=1
    if menu.opt==2 and rpin(pins.online) == connection.disabled then menu.opt -=1 end
    sfx2(0,3)
   end
   if btnp(3) then
    menu.opt+=1
    if menu.opt==2 and rpin(pins.online) == connection.disabled then menu.opt +=1 end
    sfx2(0,3)
   end
   menu.opt=(menu.opt-1)%4+1
   
   if btnp(1) then
    menu.step+=1
    sfx2(1,3)
   end
  end
  
  if menu.step==2 then
   menu.select[menu.opt]()
  end
 end
 
 menu.select[3]=function()
  if btnp(0) then
   menu.step-=1
   sfx2(1,3)
  end
 end
 menu.select[1]=function()
  local p=nil
  if p1.face == nil then
   p=p1
  elseif p2.face==nil then
   p=p2
  elseif onreset==nil then
   start()
  end
  
  -- pick characters
  if p!=nil and menu.step_i > 1.5 and btnp() != 0 then
   for i=0,5 do
    if btnp(i) then
     if not (p==p2 and i==p1.btn) then
      set_player(p,i)
      break
     end
    end
   end
  end
  
 end
 menu.select[2]=function()
  online=true
  
  local p=nil
  if p1.face == nil then
   p=p1
  elseif p2.face==nil then
   p=p2
  elseif onreset==nil then
   start()
  end
  
  -- pick characters
  if p==p1 and menu.step_i > 1.5 and btnp() != 0 then
   for i=0,5 do
    if btnp(i) then
     set_player(p,i)
     wpin(pins.online,connection.connecting)
     break
    end
   end
  elseif p==p2 then
   
   local i = rpin(pins.p2_btn)
   if i<6 then
    set_player(p2,i)
   end
  end
 end
 
 menu.select[4]=function()
  if btnp(2) then
   menu.opt2-=1
   sfx2(0,3)
  end
  if btnp(3) then
   menu.opt2+=1
  sfx2(0,3)
  end
  menu.opt2=(menu.opt2-1)%5+1
   
  if menu.opt2 == 1 then
   if btnp(0) then
    menu.step-=1
    sfx2(1,3)
   end
  elseif menu.opt2 == 2 then
   if btnp(0) or btnp(1) then
    options.sun=not options.sun
    if options.sun then
     dset(1,1)
    else
     dset(1,0)
    end
    sfx2(0,3)
   end
  elseif menu.opt2 == 3 then
   if btnp(0) or btnp(1) then
    options.music=not options.music
    if options.music then
     music(2,1600,1+2+3)
				 dset(2,1)
    else
				 music(-1,1+2+3)
				 dset(2,0)
    end
    sfx2(0,3)
   end
  elseif menu.opt2 == 4 then
   if btnp(0) or btnp(1) then
    options.sfx=not options.sfx
    if options.sfx then
     dset(3,1)
    else
     dset(3,0)
    end
    dset(1,options.sfx)
    sfx2(0,3)
   end
  elseif menu.opt2 == 5 then
   if btnp(0) then
    options.palette-=1
    sfx2(0,3)
   end
   if btnp(1) then
    options.palette+=1
    sfx2(0,3)
   end
   
   
   if btnp(0) or btnp(1) then
    options.palette=(options.palette-1)%#options.palettes+1
    dset(4,options.palette)
    options.set_palette()
   end
   
  end
 end
 
 
 menu.draw={}
 menu.draw[3]=function(y)
  local s="instructions"
  print_ol(s,128+64-#s/2*4,y+6,0,8)
  
  s="1. select a button"
  print_ol(s,156,y+menu.start+menu.gap*1,0,8)
  s="2. hold to run"
  print_ol(s,156,y+menu.start+menu.gap*2,0,8)
  s="3. release to attack"
  print_ol(s,156,y+menu.start+menu.gap*3,0,8)
  
  color(0)
  rectfill(128+64-menu.bar,y+menu.start-1+menu.gap*4,128+64+menu.bar,y+menu.start+menu.gap*5-1)
  print_ol(btns[0].s,128+64-menu.bar-4,y+menu.start+menu.gap*4,0,8)
  s="back"
  print_ol(s,128+64-#s/2*4,y+menu.start+menu.gap*4,0,8)
 end
 menu.draw[1]=function(y)
  
  local s="local vs."
  print_ol(s,128+64-#s/2*4,y+6,0,8)
  
  if p1.btn == nil then
   s="p1: select"
   print_ol(s,158,y+menu.start+menu.gap*1,0,8)
   s="p2: wait..."
   print_ol(s,158,y+menu.start+menu.gap*2,0,8)
  elseif p2.btn == nil then
   s="p1:   "..btns[p1.btn].s
   print_ol(s,158,y+menu.start+menu.gap*1,0,8)
   s="p2: select"
   print_ol(s,158,y+menu.start+menu.gap*2,0,8)
  else
   s="p1:   "..btns[p1.btn].s
   print_ol(s,158,y+menu.start+menu.gap*1,0,8)
   s="p2:   "..btns[p2.btn].s
   print_ol(s,158,y+menu.start+menu.gap*2,0,8)
  end
  
 end
 menu.draw[2]=function(y)
  local s="online vs."
  print_ol(s,128+64-#s/2*4,y+6,0,8)
  
  if p1.btn == nil then
   s="p1: select"
   print_ol(s,158,y+menu.start+menu.gap*1,0,8)
   s="p2: wait..."
   print_ol(s,158,y+menu.start+menu.gap*2,0,8)
  elseif p2.btn == nil then
   s="p1:   "..btns[p1.btn].s
   print_ol(s,158,y+menu.start+menu.gap*1,0,8)
   s="p2: connecting..."
   print_ol(s,158,y+menu.start+menu.gap*2,0,8)
  else
   s="p1:   "..btns[p1.btn].s
   print_ol(s,158,y+menu.start+menu.gap*1,0,8)
   s="p2:   "..btns[p2.btn].s
   print_ol(s,158,y+menu.start+menu.gap*2,0,8)
  end
 end
 menu.draw[4]=function(y)
  local s="options"
  print_ol(s,128+64-#s/2*4,y+6,0,8)
  
  color(0)
  rectfill(128+64-menu.bar,y+menu.start-1+menu.gap*menu.opt2,128+64+menu.bar,y+menu.start+menu.gap*(menu.opt2+1)-1)
  print_ol(btns[0].s,128+64-menu.bar-4,y+menu.start+menu.gap*menu.opt2,0,8)
  if menu.opt2 != 1 then
   print_ol(btns[1].s,128+64+menu.bar-4,y+menu.start+menu.gap*menu.opt2,0,8)
  end
  
  s="back"
  print_ol(s,128+64-#s/2*4,y+menu.start+menu.gap*1,0,8)
  
  s="sun: "
  if options.sun then
   s=s.."on "
  else 
   s=s.."off"
  end
  print_ol(s,128+64-#s/2*4,y+menu.start+menu.gap*2,0,8)
  s="music: "
  if options.music then
   s=s.."on "
  else 
   s=s.."off"
  end
  print_ol(s,128+64-#s/2*4,y+menu.start+menu.gap*3,0,8)
  s="sfx: "
  if options.sfx then
   s=s.."on "
  else 
   s=s.."off"
  end
  print_ol(s,128+64-#s/2*4,y+menu.start+menu.gap*4,0,8)
  s="palette: "
  s=s..options.palette
  print_ol(s,128+64-#s/2*4,y+menu.start+menu.gap*5,0,8)
 end
 menu.opt2=1
 
end

function set_player(p,i)
 sfx2(0,3)
 p.btn=i
 p.face=clone(btns[p.btn].face)
 p.head.add(p.face)
 if p.btn==4 then
  p.face.add(btns[4].face.child)
 end
 if p==p2 then
  -- flip p2's face
  for p in all(p2.face.points) do
   p[1]*=-1
  end
 end
 
 if p == p1 then
  wpin(pins.p1_btn,i)
 else
  wpin(pins.p2_btn,i)
 end
end

function clone(_p)
 local e=vectorize(entity(_p.p[1],_p.p[2],_p.c))
 for p in all(_p.points) do
  add(e.points,{p[1],p[2]})
 end
 return e
end

function _update()
 p1.press=btn(p1.btn)
 if p1.press then
  wpin(pins.p1_stat,1)
 else
  wpin(pins.p1_stat,0)
 end
 if online then 
  p2.press=rpin(pins.p2_stat)!=0
 else
  p2.press=btn(p2.btn)
  if p2.press then
   wpin(pins.p2_stat,1)
  else
   wpin(pins.p2_stat,0)
  end
 end
 
 
 
 player_update(p1)
 player_update(p2)
 
 if menu != nil then
  menu.u()
 end
 
 for p in all(parts) do
  --p.p=v_add(p.p,p.v)
  p.v=v_mul(p.v,{0.85,0.85})
  if abs(p.v[1])+abs(p.v[2]) < 0.5 then
   del(parts,p)
  end
 end
 
 flash=nil
 
 if not gameover then
  if p1.p[1] > p2.p[1] then
   gameover=true
   gameover_t=time()
   flash=15
   sfx2(2,3)
   
   if p1.dash and not p2.dash then
    winner=p1
    p2.dead=true
   elseif p2.dash and not p1.dash then
    winner=p2
    p1.dead=true
   elseif p1.dash and p2.dash then
    --decide who won based on speed
    if p1.b > p2.b then
     winner=p1
     p2.dead=true
    elseif p2.b > p1.b then
     winner=p2
     p1.dead=true
    else
     winner=nil
     p1.dead=true
     p2.dead=true
    end
   else
    winner=nil
   end
   
   
   -- force dash for misses
   if not p1.dash then
    p1.dash=true
    p1.b=max(1,p1.b*3)
    p1.dasht=time()+p1.b/2
   end
   
   if not p2.dash then  
    p2.dash=true
    p2.b=max(1,p2.b*3)
    p2.dasht=time()+p2.b/2
   end
  end
 end
 
 -- transition into game
 if paused then
  transition += 0.015
  if transition > 0.5 and onreset != nil then
   onreset()
   onreset=nil
  end
  if transition >= 1 then
   paused=false
   transition=0
  end
 end
 
 
 center=(p1.p[1]+p2.p[1])/2
 width=abs(p1.p[1]-p2.p[1])
 s=mid(0.01,64/width,5.5)
 ratio=mid(0,32/width,1)
 
 
 if gameover then
  
  
  if online and not online_over then
   local w1
   local w2
  
   if winner==nil then
    w1 = 0
   elseif winner==p1 then
    w1 = 1
   else
    w1 = 2
   end
   wpin(pins.p1_winner,w1)
   
   if rpin(pins.p2_winner) > 2 then
    --don't know who won yet
    gameover_t=time()
   else
    online_over=true
    w2=rpin(pins.p2_winner)
    --check if we agree on who won
    --if not, call it a draw
    --during draws, we kill both players
    --event if we only think one died
    if not(w1==1 and w2==2) and
       not(w1==2 and w1==2) then
     if p1.dead or p2.dead then
      p1.dead=true
      p2.dead=true
     else
      p1.dead=false
      p2.dead=false
     end
    end
   end
  end
  
  
  -- adjust cameras
  ratio=mid(0,1,gameover_t+3-time())
  
  -- transition out of game
  if time()-gameover_t-4 > 0 then
   transition+=0.015
   if transition >= 0.5 then
    reset()
    sfx2(1,3)
   end
  end
 end
 
 if ratio > 0 and ratio < 1 then
  ratio=ease(ratio)
 end
 
 
end

function start()
 onreset=function()
  menu=nil
  score={0,0}
 end
 reset()
 transition=0
end

function reset()
 if p1.dead != p2.dead then
  if p1.dead then
   score[2]+=1
  else
   score[1]+=1
  end
 end

 p1.b=0
 p1.bt=0
 p2.b=0
 p2.bt=0
 
 p1.press=false
 p2.press=false
 
 p1.run=false
 p2.run=false
 p1.dash=false
 p2.dash=false

 p1.p[1]=-256
 p2.p[1]=-p1.p[1]
 
 p1.dead=false
 p2.dead=false
  
 transition = 0.5
 paused=true
 
 wpin(pins.p1_winner,3)
 wpin(pins.p2_winner,3)
 
 gameover=false
 gameover_t=0
 online_over=false
end

function player_update(_p)
 if not gameover and not paused and menu==nil then
  if _p.btn != nil and _p.press then
   if not _p.dash then
    if not _p.run then
     _p.run = true
     sfx2(0,3)
    end
   else
    _p.run = false
   end
  else
   if _p.run then
    _p.b*=3
    _p.dash = true
    _p.dasht=time()+_p.b/2
    sfx2(0,3)
   end
   _p.run = false
  end
 else
  _p.run = false
 end
 
 if _p.dash then
  local t=time()-_p.dasht
  if t > 0 then
   _p.dash = false
   _p.bt=time()
   _p.b=0
  end 
  _p.b=mid(0,_p.b*0.95,1)
 elseif _p.run then
  if _p.b == 0 then
   _p.bt=time()*1.5+0.5
  end
  _p.b=mid(0,_p.b+0.025,1)
 else
  _p.b=mid(0,_p.b*0.95,1)
 end
 
 if _p.b < 0.01 then
  _p.b=0
 end

 --add speed lines 
 if _p.b > 0.5 then
  local p={}
  p.c=0
  p.p=v_add(_p.p,{-_p.dir*5+rnd(5)-rnd(5),-rnd(15)-2.5})
  p.v={_p.dir*(0.2+rnd(_p.b*10)),rnd()/5-0.1}
  add(parts,p)
 end
 
 _p.p[1]+=_p.b*_p.dir*4
 
 local t=time()*1.5-_p.bt
 
 if _p.dash then
 _p.larm.a=lerp(_p.larm.a,0.15,0.5)
 _p.lelb.a=lerp(_p.lelb.a,0.05,0.5)
 _p.sword.a=lerp(_p.sword.a,-0.2 ,0.5)
 else
 _p.rleg.a=lerp(_p.rleg.a,(sin(t)/4+0.08)*_p.b+0.02,0.5)
 _p.rshin.a=lerp(_p.rshin.a,(sin(t-0.2)/8-0.08)*_p.b-0.02,0.5)
 
 _p.lleg.a=lerp(_p.lleg.a,(sin(t+0.5)/4+0.08)*_p.b+0.02,0.5)
 _p.lshin.a=lerp(_p.lshin.a,(sin(t+0.3)/8-0.06)*_p.b-0.04,0.5)
 
 _p.rarm.a=lerp(_p.rarm.a,(sin(t+0.5)/8+0.08)*_p.b+0.15,0.5)
 _p.relb.a=lerp(_p.relb.a,(sin(t+0.3)/8-0.08)*_p.b-0.05,0.5)
 
 _p.larm.a=lerp(_p.larm.a,(-sin(t)/14+0.08)*_p.b-0.2,0.5)
 _p.lelb.a=lerp(_p.lelb.a,(sin(t-0.2)/16-0.08)*_p.b,0.5)
 _p.sword.a=lerp(_p.sword.a,0.5,0.5)
 
 _p.a=lerp(_p.a,abs(sin(t))/20*_p.b,0.5)
 _p.head.a=lerp(_p.head.a,abs(sin(t))/20*_p.b-0.025,0.5)
 _p.body.p[2]=lerp(_p.body.p[2],-4.5-abs(sin(t))*5*_p.b,0.5)
 _p.head.p[2]=lerp(_p.head.p[2],-9-sin(t-0.25)/3,0.5)
 end
 
 
 if _p.dead then
 --if _p.id==1 then
  local ratio=1-ratio
  _p.lshin.a=lerp(_p.lshin.a,-0.3,ratio)
  _p.rshin.a=lerp(_p.rshin.a,-0.3,ratio)
  
  _p.larm.a=lerp(_p.larm.a,0.,ratio)
  _p.rarm.a=lerp(_p.rarm.a,0.,ratio)
 
  _p.sword.a=lerp(_p.sword.a,-0.2,ratio)
 
  _p.head.a=lerp(_p.head.a,-0.1,ratio)
  
  _p.body.p[2]=lerp(_p.body.p[2],-2.5,ratio)
 end
 
 _p.s[2]=1+sin(t)/15
 
end


function _draw()
 local ratio=1-remap(ratio,0,1,0.38,1)
 
 --cls()
 clip(0,0,128,128)
 color(15)
 rectfill(0,0,127,127)
 
 
 if ratio > 0 then
  local y=flr(124*ratio)
  clip(2,2,61,y-1)
  o=entity(-p1.p[1]*3+32,70)
  if p1.dash and p1.b > 0 then
   o.p[1]+=rnd(p1.b*4)-rnd(p1.b*4)
   o.p[2]+=rnd(p1.b*4)-rnd(p1.b*4)
  end
  o.s={3,3}
  cam.push(o)
  draw_floor()
  p1.draw(p1)
  draw_fx()
  cam.pop()
  
  if score!=nil then
   local s=""
   if score[1] > 9 then
   s=""..score[1]
   else
   s="0"..score[1]
   end
   if gameover then
    s=s.."\n"
    if p1.dead==p2.dead then
     s=s.."tie!"
    elseif p1.dead then
     s=s.."loss!"
    else
     s=s.."win!"
    end
   end
   s=btns[p1.btn].s..":"..s
   print_ol(s,3,3,0,8)
  end
 
 
  draw_transition()
  rect(2,2,62,y)
  
  clip(65,2,61,y-1)
  o=entity(-p2.p[1]*3+32+64,70)
  if p2.dash and p2.b > 0 then
   o.p[1]+=rnd(p2.b*4)-rnd(p2.b*4)
   o.p[2]+=rnd(p2.b*4)-rnd(p2.b*4)
  end
  o.s={3,3}
  cam.push(o)
  draw_floor()
  p2.draw(p2)
  draw_fx()
  cam.pop()
  
  if score!=nil then
   local s=""
   if score[2] > 9 then
   s=""..score[2]
   else
   s="0"..score[2]
   end
   if gameover then
    s=s.."\n"
    if p2.dead==p1.dead then
     s=s.." tie!"
    elseif p2.dead then
     s=s.."loss!"
    else
     s=s.." win!"
    end
   end
   s=btns[p2.btn].s..":"..s
   print_ol(s,126-20,3,0,8)
  end
  
  draw_transition()
  rect(65,2,125,y)
 end
 
 local y=min(flr(124*ratio)+1,flr(126*ratio))
 clip(2,y+2,124,124-y)
 
 if menu then
  draw_menu(y)
 else
  o=entity(-(center)*s+64,110)
  if p1.dash and p1.b > 0 then
   o.p[1]+=rnd(p1.b*4)-rnd(p1.b*4)
   o.p[2]+=rnd(p1.b*4)-rnd(p1.b*4)
  end
  if p2.dash and p2.b > 0 then
   o.p[1]+=rnd(p2.b*4)-rnd(p2.b*4)
   o.p[2]+=rnd(p2.b*4)-rnd(p2.b*4)
  end
  o.s={s,s}
  cam.push(o)
  draw_floor()
  p1.draw(p1)
  p2.draw(p2)
  draw_fx()
  cam.pop()
 end
 draw_transition()
 color(0)
 rect(2,y+2,125,125)
 
 
 clip(0,0,128,128)
 camera(0,0)
end

function draw_floor()
 local p1=cam.point({-500,-2})
 local p2=cam.point({500,80})
 local r=cam.s[2]
 if gameover then
  r*=ratio
 end
 
 if options.sun and r > 0 then
  local c=center*cam.s[1]
  color(8)
  circ(c,p1[2],60*r)
  circfill(c,p1[2],60*r-2)
 end
 
 color(2)
 rectfill(p1[1],p1[2],p2[1],p2[2])
 color(15)
 line(p1[1],p1[2]+1,p2[1],p1[2]+1)
 line(p1[1],p2[2]-1,p2[1],p2[2]-1)
 line(p1[1],p2[2]-3,p2[1],p2[2]-3)
 
end

function draw_fx()
 for p in all(parts) do
  color(p.c)
  line_rotated(p.p,v_add(p.p,p.v))
 end
 
 if flash != nil then
  camera(0,0)
  color(flash)
  rectfill(0,0,127,127)
 end
end

function draw_menu(y)
 camera((menu.step_i-1)*128,0)
 draw_fx()
 --local s="one button duel"
 --print_ol(s,64-#s/2*4,y+6,0,8)
 sspr(0,0,72,14,64-72/2,y+5)
 
 color(0)
 rectfill(64-menu.bar,y+menu.start-1+menu.gap*(menu.opt+1),64+menu.bar,y+menu.start+menu.gap*(menu.opt+2)-1)
 print_ol(btns[1].s,64+menu.bar-4,y+menu.start+menu.gap*(menu.opt+1),0,8)
  
 s="local vs."
 print_ol(s,64-#s/2*4,y+menu.start+menu.gap*2,0,8)
  
 s="online vs."
 local c=8
 if rpin(pins.online) == connection.disabled then
  c=5
 end
 print_ol(s,64-#s/2*4,y+menu.start+menu.gap*3,0,c)
  
 s="instructions"
 print_ol(s,64-#s/2*4,y+menu.start+menu.gap*4,0,8)
 
 s="options"
 print_ol(s,64-#s/2*5,y+menu.start+menu.gap*5,0,8)
 
 menu.draw[menu.opt](y)
 
 camera(0,0)
end

function draw_transition()
 color(0)
 for i=0,127,1 do
  local t=(sin(i/256+time()/2)+1)/2
  
  for j=1,5 do
   if i%(j+1)==0 then
    t/=j
   end
  end
  
  if transition > 0.5 then
   
   t=mid(0,ease(remap(transition,0.5,1,0,1))*2+t-1,1)
   line(i,2+125*t,i,125)
  else
   t=mid(0,ease(remap(transition,0,0.5,0,1))*2+t-1,1)
   line(i,2,i,125*t)
  end
 end
end




function draw_children(_c)
 for c in all(_c.children) do
  c.draw(c)
 end
end

function line_rotated(_p1,_p2)
 _p1 = cam.point(_p1)
 _p2 = cam.point(_p2)
 
 line(
 _p1[1],
 _p1[2],
 _p2[1],
 _p2[2])
end

function draw_vector(_p)
 cam.push(_p)
 
 color(_p.c)
 local p1 = _p.points[1]
 for i=2,#_p.points do
  local p2 = _p.points[i]
  
  line_rotated(p1,p2)
  
  p1 = p2
 end
 
 draw_children(_p)
 
 cam.pop()
end

function print_ol(_s,_x,_y,_c1,_c2)
 color(_c1)
 for x=_x-1,_x+1 do
 for y=_y-1,_y+1 do
  print(_s,x,y)
 end
 end
 color(_c2)
 print(_s,_x,_y)
end
__gfx__
bbb00000bbbbbbbbbbbb00000bbbbbbbbbbbbbbbbbbbbbbbbbb000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000088800bbbbbbbbb00088800bbbbbbbbbbbbbbbbbbbbbbb000888800bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0888888800bbbbbbbb088888800bbbbbbbbbbbbbbbbbbbbbb0888888800bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0000008880bbbbbbbb000008880bbbbbbbbbbbbbbbbbbbbbb0000008880bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b008000880bbbbbbbbb00800880bbbbbbbbbbbbbbbbbbbbbbb008000880bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b0880b0880bbbbbbbbb08800880bbbbbbbbbbbbbbbbbbbbbbb0880b0880bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b0880b0880bbbbbbbbb08808800bbbbbbbbbbbbbbbbbbbbbbb0880b0880bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b0880b08800000000000888800000000000000000000b0000b0880b088000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b0880b088008800888008808800800808880888008800088000880b088080080888080bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b0880b088080080800008800880800800800080080080800800880b088080080800080bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b08800088080080880b0880088080080080b080080080800800880b088080080880080bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b0888088008008080000880088080080080b080080080800800880008808008080008000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b0088880008008088800888880008800080b080008800800800888888000880088808880bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb000000b00000000000000000b0000b000b000b000000000000000000b0000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01030000226141d63118641136310f6110f6110f6110f615006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603
01040000206111c6311a6411a6251b6141f6112a61135611386113a62139631256310761107611076110761500603006030060300603006030060300603006030060300603006030060300603006030060300603
0002000026270376702d27036670382702d6703f2601a650136400f6310c6210a6110561103615036150361500600006000060000600006000060000600006000060000600006000060000600006000060000600
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a000010621106251d6211d62510621106251d6211d62510621106251d6211d62510621106251d6211d62510625106051d625216051062510625216251d62510625106051d6252160523625216251f62521625
0114000010625106251d6251d62510625106251d6051d62510625106251d6251d62510605106251d6051d62510625106251d625216251062510625216051d62510625106251d6252162523625216251f62521625
012800001012410141101511011113121131411315113111101211014110151101111312113141151511514500101001010010100101001010010100101001010010100101001010010100101001010010100101
011400001022517245102551721510225172451025517215132251c245132551c215132251c245132551c2451022517245102551721510225172451025517215132251c2451a2551c215182251a2451725518215
0128000034524345412a5512c51134521345412a5512c51134521345412a5512b5112d5242f545305543254500501345223552234725005013452235725005010050134522395223472500501395223b5223c725
010a18203c50537505325053c5052855528505345253c505285553c505345253c5053c50537505325053c5052855532505345253c705285553c505347253c5052851534525285353452528515345252853534725
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 4a4b4c44
00 0a4b4c44
00 090b4d44
00 090c4d44
01 0a0b0c44
00 0a0b0c44
00 0a4c0d44
00 090b0e44
00 0a0c4d44
00 090c0b44
00 0a0c0d44
02 090c0f44
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

