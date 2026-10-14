"""Higher-quality, asset-only Cafeteria/Library pass for current assets.blend.

Run with Blender 5.2: --background assets.blend --python this_file.py
Export separately with the unchanged export_school_web.py.
Preserves all original objects, including the seven maze walls and old tables.
Table/counter finishes envelop existing cover visuals without changing collision.
Only this generator's tagged objects, collections and mesh data are replaced.
"""
import json
import math
import os
from collections import Counter, deque
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

TAG = "cafeteria_library_generator"
GROUPS = ("School Props - Cafeteria", "School Props - Library")
ROOMS = ("Cafe Floor", "Library Floor")


def bounds(obj):
    pts = [obj.matrix_world @ Vector(v) for v in obj.bound_box]
    return tuple((min(p[i] for p in pts), max(p[i] for p in pts)) for i in range(3))


class Builder:
    """Joined parts, baked 1-segment bevels; no persistent modifiers."""
    def __init__(self):
        self.vertices, self.faces, self.colors, self.smooth = [], [], [], []

    def solid(self, vertices, faces, material, bevel=0, smooth_sides=False):
        bm = bmesh.new()
        verts = [bm.verts.new(v) for v in vertices]
        for face in faces:
            bm.faces.new([verts[i] for i in face])
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        if bevel:
            bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=1,
                            affect="EDGES", clamp_overlap=True)
            bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.verts.ensure_lookup_table()
        indices = {v: len(self.vertices) + i for i, v in enumerate(bm.verts)}
        self.vertices += [tuple(v.co) for v in bm.verts]
        for face in bm.faces:
            self.faces.append(tuple(indices[v] for v in face.verts))
            self.colors.append(material)
            self.smooth.append(smooth_sides and len(face.verts) == 4)
        bm.free()

    def box(self, size, center, material, bevel=0.012):
        vertices = [tuple(Vector(center) + Vector((x * size[0]/2, y * size[1]/2, z * size[2]/2)))
                    for x, y, z in ((-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
                                    (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1))]
        faces = ((0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7))
        self.solid(vertices, faces, material, bevel)

    def cylinder(self, radius, depth, center, material, sides=8, wheel=False):
        rotation = Matrix.Rotation(math.pi/2, 3, "Y") if wheel else Matrix.Identity(3)
        vertices = [tuple(Vector(center) + rotation @ Vector((radius*math.cos(2*math.pi*i/sides),
                    radius*math.sin(2*math.pi*i/sides), h)))
                    for h in (-depth/2,depth/2) for i in range(sides)]
        faces = [tuple(reversed(range(sides))), tuple(range(sides,2*sides))]
        faces += [(i,(i+1)%sides,sides+(i+1)%sides,sides+i) for i in range(sides)]
        self.solid(vertices,faces,material,smooth_sides=True)

    def back(self, y, material):
        # Tapered chair back with clipped shoulders, rather than a rectangle.
        outline = ((-.245,.46),(.245,.46),(.225,.85),(.17,.92),(-.17,.92),(-.225,.85))
        vertices = [(x, yy, z) for yy in (y-.035,y+.035) for x,z in outline]
        n = len(outline)
        faces = [tuple(reversed(range(n))),tuple(range(n,2*n))]
        faces += [(i,(i+1)%n,n+(i+1)%n,n+i) for i in range(n)]
        self.solid(vertices,faces,material,.012)

    def mesh(self, name, materials):
        mesh = bpy.data.meshes.new("School Dining Reading Kit - " + name)
        mesh[TAG] = True
        mesh.from_pydata(self.vertices,[],self.faces)
        slots = list(dict.fromkeys(self.colors))
        for key in slots:
            mesh.materials.append(materials[key])
        for polygon,key,smooth in zip(mesh.polygons,self.colors,self.smooth):
            polygon.material_index = slots.index(key)
            polygon.use_smooth = smooth
        mesh.update()
        mesh.calc_loop_triangles()
        return mesh


def table(width, depth, height, cover=False):
    k = Builder()
    k.box((width,depth,.095),(0,0,height-.0475),"Laminate",.015)
    leg_x = width/2 - (.13 if cover else .12)
    leg_y = depth/2 - .112 if cover else depth/2-.08
    for x in (-leg_x,leg_x):
        for y in (-leg_y,leg_y):
            k.box((.16 if cover else .075,.14 if cover else .075,height-.095),
                  (x,y,(height-.095)/2),"Metal",.009)
    for y in (-depth*.30,depth*.30):
        k.box((width-.28,.075,.66 if cover else .12),(0,y,.41 if cover else height-.16),"Metal",.009)
    for x in (-leg_x,leg_x):
        k.box((.065,depth-.10,.07),(x,0,.23),"Metal",0)
    return k


def chair(arms=False):
    k = Builder()
    k.box((.50,.47,.065),(0,0,.4475),"Chair",.018)
    k.back(-.20,"Chair")
    for x in (-.19,.19):
        for y in (-.175,.175):
            k.box((.055,.055,.415),(x,y,.2075),"Laminate",.006)
        k.box((.045,.045,.35),(x,-.20,.57),"Laminate",0)
        k.box((.045,.34,.045),(x,0,.22),"Laminate",0)
    if arms:
        for x in (-.30,.30):
            k.box((.06,.34,.045),(x,0,.635),"Laminate",.010)
            k.box((.04,.045,.16),(x,.11,.535),"Metal",0)
    return k


def shelf(width, depth, height, books=False):
    k = Builder()
    for x in (-width/2+.032,width/2-.032):
        k.box((.064,depth,height),(x,0,height/2),"Laminate",.008)
    k.box((width,.035,height),(0,depth/2-.0175,height/2),"Cabinet",.005)
    levels = (.06,height*.33,height*.65,height-.04) if height>1.2 else (.055,height*.49,height-.04)
    for z in levels:
        k.box((width,depth,.055),(0,0,z),"Laminate",.008)
    if books:
        # Readable book groups, all in this mesh; no per-book objects/materials.
        for row,z in enumerate(levels[:-1]):
            for i,(w,color) in enumerate(((.22,"Art"),(.26,"Canvas"),(.18,"Chair"))):
                x = -width*.31 + i*width*.28
                h = min(.30,height*.30)-.025*(i%2)
                k.box((w,depth*.70,h),(x,-.015,z+.028+h/2),color,0)
    return k


def kit(materials):
    floor = bpy.data.objects["Cafe Floor"]
    width = bounds(floor)[0][1]-bounds(floor)[0][0]
    reading = table(1.55,.76,.76)
    reading.box((.45,.26,.045),(.24,.10,.7875),"Canvas",0)
    for z in (.763,.813):
        reading.box((.48,.28,.006),(.24,.10,z),"Art",.002)
    designs = {"Cafeteria Table Finish": table(width*.62+.04,.74,.94,True),
               "Reading Table": reading, "Reading Chair": chair(),
               "Librarian Chair": chair(True), "Perimeter Bookshelf": shelf(1.35,.32,1.65,True),
               "Low Window Bookshelf": shelf(1.30,.24,.90,True),
               "Serving Shelf": shelf(1.10,.35,.86)}
    k = Builder()
    k.box((2.35,.34,.07),(0,0,.485),"Laminate",.016)
    for x in (-.88,.88):
        for y in (-.10,.10):
            k.box((.065,.065,.45),(x,y,.225),"Metal",.006)
        k.box((.12,.32,.04),(x,0,.02),"Metal",.009)
    k.box((1.85,.055,.055),(0,0,.24),"Metal",0)
    designs["Cafeteria Bench"] = k
    for name,w,d in (("Serving Counter",1.80,.58),("Pass-through Counter Finish",1.80,.35)):
        k = Builder()
        k.box((w,d,.07),(0,0,.905),"Medical White",.012)
        k.box((w-.10,d-.05,.79),(0,.015,.465),"Cabinet",.014)
        k.box((w-.14,d-.12,.10),(0,.025,.05),"Metal",.007)
        for x in (-w*.25,w*.25):
            k.box((w*.45,.035,.62),(x,-d/2+.040,.50),"Laminate",.007)
            k.box((.16,.04,.025),(x,-d/2+.026,.64),"Metal",0)
        k.box((w,.035,.045),(0,-d/2+.022,.865),"Metal",0)
        designs[name] = k
    for name,color in (("Trash Bin","Cabinet"),("Recycling Bin","Chair")):
        k = Builder()
        k.box((.45,.45,.59),(0,0,.295),color,.028)
        k.box((.47,.47,.075),(0,0,.6175),"Metal",.018)
        k.box((.28,.17,.01),(0,-.015,.66),"Metal",0)
        k.box((.17,.012,.12),(0,-.229,.40),"Board",0)
        designs[name] = k
    k = Builder()
    for x in (-.34,.34):
        k.box((.06,.50,.95),(x,0,.475),"Cabinet",.010)
    k.box((.74,.045,.88),(0,.225,.44),"Cabinet",.009)
    for z in (.08,.47,.92):
        k.box((.74,.50,.055),(0,0,z),"Metal",.008)
    k.box((.66,.38,.06),(0,-.02,.54),"Medical White",.007)
    k.box((.50,.24,.025),(0,-.035,.9625),"Metal",.008)
    k.box((.33,.015,.10),(0,.248,.78),"Board",0)
    designs["Tray Return"] = k
    k = Builder()
    k.box((.82,.62,1.64),(0,0,.88),"Accent",.045)
    k.box((.72,.03,1.38),(0,-.319,.91),"Cabinet",.013)
    k.box((.46,.025,.85),(-.10,-.343,1.12),"Metal",.018)
    for z,color in ((.88,"Chair"),(1.12,"Canvas"),(1.36,"Art")):
        k.box((.37,.03,.10),(-.10,-.359,z),color,.010)
    k.box((.14,.05,.41),(.25,-.350,1.08),"Metal",.010)
    for z in (1.20,1.09,.98):
        k.box((.075,.012,.035),(.25,-.382,z),"Board",0)
    k.box((.48,.085,.16),(-.055,-.355,.44),"Metal",.012)
    k.box((.47,.10,.025),(-.055,-.375,.365),"Medical White",.006)
    k.box((.82,.53,.06),(0,0,.03),"Metal",.010)
    k.box((.60,.08,.05),(0,-.31,.20),"Metal",.009)
    designs["Vending Machine"] = k
    k = Builder()
    k.box((1.40,.64,.085),(0,0,.7575),"Laminate",.022)
    k.box((.35,.57,.71),(-.49,.015,.355),"Cabinet",.012)
    k.box((.085,.57,.71),(.59,.015,.355),"Laminate",.010)
    k.box((1.25,.065,.44),(0,.245,.49),"Laminate",.010)
    for z in (.20,.43,.66):
        k.box((.30,.035,.20),(-.49,-.285,z),"Cabinet",.008)
        k.box((.12,.04,.023),(-.49,-.31,z+.03),"Metal",0)
    k.box((.36,.28,.025),(.34,-.05,.8125),"Metal",.007)
    k.box((.26,.20,.02),(.34,-.05,.835),"Board",.005)
    k.box((.55,.04,.13),(.22,-.287,.66),"Cabinet",.008)
    k.box((.27,.012,.07),(.22,-.314,.66),"Board",.004)
    designs["Library Checkout Desk"] = k
    k = Builder()
    for z in (.18,.53):
        k.box((.70,.43,.065),(0,0,z),"Cabinet",.012)
    for x in (-.30,.30):
        for y in (-.17,.17):
            k.box((.045,.045,.59),(x,y,.385),"Metal",.007)
    for x in (-.30,.30):
        k.box((.045,.045,.28),(x,.27,.78),"Metal",.009)
    k.box((.64,.055,.055),(0,.27,.92),"Metal",.012)
    for x in (-.31,.31):
        for y in (-.17,.17):
            k.cylinder(.075,.05,(x,y,.075),"Metal",wheel=True)
    for x,color in ((-.21,"Art"),(0,"Canvas"),(.21,"Chair")):
        k.box((.16,.25,.22),(x,0,.675),color,0)
    designs["Book Cart"] = k
    return {name:builder.mesh(name,materials) for name,builder in designs.items()}


class Layout:
    def __init__(self,collections,meshes):
        self.collections,self.meshes = collections,meshes
        self.objects,self.reserved,self.targets = [],{},{}
        self.obstacles,self.allowed_legacy = {},{}
        self.route_paths = {}

    def place(self,room,design,x,y,angle=0,label=None,legacy=None):
        count = sum(o["room_floor"]==room and o["prop_type"]==design for o in self.objects)+1
        name = "%s - %s %02d" % ("Cafeteria" if room=="Cafe Floor" else "Library",label or design,count)
        if bpy.data.objects.get(name): raise RuntimeError("Unowned object conflict: "+name)
        obj = bpy.data.objects.new(name,self.meshes[design])
        self.collections[ROOMS.index(room)].objects.link(obj)
        obj[TAG],obj["room_floor"],obj["prop_type"] = True,room,design
        obj["collision_policy"] = "visual-only; original cover colliders/maze unchanged"
        obj.location = (x,y,bounds(bpy.data.objects[room])[2][1])
        obj.rotation_euler.z = angle
        bpy.context.view_layer.update()
        world = obj.matrix_world.copy()
        obj.parent = bpy.data.objects[room]
        obj.matrix_world = world
        self.objects.append(obj)
        if legacy: self.allowed_legacy[obj.name]=legacy
        return obj

    def reserve(self,room,u,v,radius,label):
        (x0,x1),(y0,y1),_ = bounds(bpy.data.objects[room])
        p = (x0+(x1-x0)*u,y1-(y1-y0)*v)
        self.reserved.setdefault(room,[]).append((*p,radius,label))
        self.targets.setdefault(room,[]).append((label,p))

    def furnish(self):
        cafe,library = ROOMS
        cb = bounds(bpy.data.objects[cafe])
        (x0,x1),(y0,y1),_ = cb
        wall = bounds(bpy.data.objects["Kitchen - South Wall"])
        table_y = [wall[1][0]-.85,wall[1][0]-2.95]
        for i,y in enumerate(table_y):
            self.place(cafe,"Cafeteria Table Finish",(x0+x1)/2,y,legacy="Cafeteria Table %02d"%(i+1))
        for dx in (-2.25,2.25):
            self.place(cafe,"Cafeteria Bench",(x0+x1)/2+dx,table_y[0]-.56)
        self.place(cafe,"Pass-through Counter Finish",sum(wall[0])/2,wall[1][0]-.175,legacy="KitchenServingCounter")
        self.place(cafe,"Serving Counter",x0+3.80,y1-.58)
        self.place(cafe,"Serving Shelf",x0+4.25,y1-2.30)
        self.place(cafe,"Vending Machine",x0+.55,y1-2.60,math.pi/2)
        self.place(cafe,"Tray Return",x0+.65,y0+2.40,math.pi/2)
        self.place(cafe,"Trash Bin",x0+.45,y0+.65)
        self.place(cafe,"Recycling Bin",x0+.45,y0+1.38)
        self.reserve(cafe,.10,.12,1.10,"Snack pickup")
        kitchen = bounds(bpy.data.objects["Kitchen Floor"])
        wait = (kitchen[0][0]+(kitchen[0][1]-kitchen[0][0])*.25,wall[1][1]+.75)
        peek = (sum(wall[0])/2+.90+.18,wall[1][0]-.35-.20)
        west_peek = (kitchen[0][0]-.65,sum(kitchen[1])/2)
        for p,r,label in ((wait,.75,"Kitchen watch"),(peek,.60,"South peek"),(west_peek,.75,"West peek")):
            self.reserved.setdefault(cafe,[]).append((*p,r,label))
            self.targets.setdefault(cafe,[]).append((label,p))
        # Existing table footprints and runtime kitchen cover remain obstacles.
        self.obstacles[cafe] = []
        for i in (1,2):
            self.obstacles[cafe].append(("Original cafeteria cover",bounds(bpy.data.objects["Cafeteria Table %02d Top"%i])))
        self.obstacles[cafe].append(("KitchenServingCounter",((sum(wall[0])/2-.90,sum(wall[0])/2+.90),
                                      (wall[1][0]-.35,wall[1][0]),cb[2])))
        # Kitchen wall side panels, derived from the current runtime opening.
        mid = sum(wall[0])/2
        opening = min(3.6,(wall[0][1]-wall[0][0])*.75)
        for xb in ((wall[0][0],mid-opening/2),(mid+opening/2,wall[0][1])):
            self.obstacles[cafe].append(("Kitchen opening side",(xb,wall[1],wall[2])))
        for name in ("Kitchen - West Opening North Panel","Kitchen - West Opening South Panel"):
            self.obstacles[cafe].append((name,bounds(bpy.data.objects[name])))

        (x0,x1),(y0,y1),_ = bounds(bpy.data.objects[library])
        # Reading nook in the southeast bay; keep the narrow maze U-turn free.
        self.place(library,"Reading Table",x0+9.60,y0+.70)
        self.place(library,"Reading Chair",x0+8.54,y0+.70,-math.pi/2)
        self.place(library,"Reading Chair",x0+10.66,y0+.70,math.pi/2)
        self.place(library,"Reading Table",x0+4.55,y0+3.25,label="Reference Reading Table")
        self.place(library,"Library Checkout Desk",x0+.55,y0+.91,math.pi/2)
        self.place(library,"Librarian Chair",x0+1.23,y0+.91,math.pi/2)
        self.place(library,"Perimeter Bookshelf",x1-.36,y0+4.15,-math.pi/2)
        for dx in (5.30,6.85):
            self.place(library,"Low Window Bookshelf",x0+dx,y1-.30)
        self.place(library,"Low Window Bookshelf",x0+5.40,y0+.35,math.pi)
        self.place(library,"Book Cart",x0+1.70,y0+4.45)
        self.reserve(library,.90,.10,1.0,"Book pickup")
        self.reserve(library,.10,.10,.80,"Library Monster northwest spawn")
        self.obstacles[library] = [(o.name,bounds(o)) for o in bpy.data.objects if o.name.startswith("Library Maze Wall")]

    def validate(self):
        bpy.context.view_layer.update()
        errors = []
        for obj in self.objects:
            room = obj["room_floor"]
            ob,fb = bounds(obj),bounds(bpy.data.objects[room])
            if any(ob[i][0]<fb[i][0]+.15 or ob[i][1]>fb[i][1]-.15 for i in (0,1)):
                errors.append("Wall margin: "+obj.name)
            if abs(ob[2][0]-fb[2][1])>.002: errors.append("Floor contact: "+obj.name)
            for x,y,r,label in self.reserved.get(room,[]):
                if self.allowed_legacy.get(obj.name)=="KitchenServingCounter" and label=="South peek":
                    # Existing waypoint is already close to its cover counter.
                    # Its fitted finish must stay INSIDE that exact footprint.
                    original=next(b for name,b in self.obstacles[room] if name=="KitchenServingCounter")
                    if any(ob[i][0]<original[i][0]-.001 or ob[i][1]>original[i][1]+.001 for i in (0,1)):
                        errors.append("Counter finish expands encounter footprint")
                    continue
                if math.hypot(max(ob[0][0]-x,0,x-ob[0][1]),max(ob[1][0]-y,0,y-ob[1][1]))<r:
                    errors.append(obj.name+" overlaps "+label)
            for label,bb in self.obstacles.get(room,[]):
                if obj.name in self.allowed_legacy and (label=="Original cafeteria cover" or label=="KitchenServingCounter"):
                    continue
                if all(ob[i][1]>bb[i][0]+.005 and bb[i][1]>ob[i][0]+.005 for i in range(3)):
                    errors.append(obj.name+" intersects "+label)
            for door in bpy.data.objects:
                if not door.name.startswith("Door Header"): continue
                db = bounds(door)
                if all(db[i][1]>=fb[i][0]-.22 and db[i][0]<=fb[i][1]+.22 for i in (0,1)):
                    margin = (.35,1.20) if db[0][1]-db[0][0]>db[1][1]-db[1][0] else (1.20,.35)
                    if all(ob[i][1]>db[i][0]-margin[i] and ob[i][0]<db[i][1]+margin[i] for i in (0,1)):
                        errors.append(obj.name+" blocks "+door.name)
        for i,obj in enumerate(self.objects):
            a=bounds(obj)
            for other in self.objects[i+1:]:
                if obj["room_floor"]!=other["room_floor"]: continue
                b=bounds(other)
                if all(a[k][1]>b[k][0]+.002 and b[k][1]>a[k][0]+.002 for k in range(3)):
                    errors.append("Prop overlap: "+obj.name+" / "+other.name)
        if errors: raise RuntimeError("Placement rejected:\n"+"\n".join(errors))
        self.routes()

    def routes(self):
        for room in ROOMS:
            fb=bounds(bpy.data.objects[room])
            (x0,x1),(y0,y1),_=fb
            obstacles=[b for _,b in self.obstacles[room]]+[bounds(o) for o in self.objects if o["room_floor"]==room]
            for radius in (.24,.45):
                inset,step=radius+.15,.05
                def point(cell): return (x0+inset+cell[0]*step,y0+inset+cell[1]*step)
                free=set()
                for i in range(int((x1-x0-2*inset)/step)+1):
                    for j in range(int((y1-y0-2*inset)/step)+1):
                        x,y=point((i,j))
                        if all(math.hypot(max(b[0][0]-x,0,x-b[0][1]),max(b[1][0]-y,0,y-b[1][1]))>=radius for b in obstacles):
                            free.add((i,j))
                targets=list(self.targets[room])
                for door in bpy.data.objects:
                    if not door.name.startswith("Door Header"): continue
                    db=bounds(door)
                    if all(db[i][1]>=fb[i][0]-.22 and db[i][0]<=fb[i][1]+.22 for i in (0,1)):
                        x,y=[sum(db[i])/2 for i in (0,1)]
                        targets.append((door.name,(min(x1-inset,max(x0+inset,x)),min(y1-inset,max(y0+inset,y)))))
                cells=[]
                for label,p in targets:
                    if not free: raise RuntimeError("No free route cells: "+room)
                    cell=min(free,key=lambda c:math.dist(point(c),p))
                    if math.dist(point(cell),p)>.25: raise RuntimeError("Route target blocked: "+label)
                    cells.append(cell)
                seen,queue={cells[0]},deque([cells[0]])
                parents={cells[0]:None}
                while queue:
                    i,j=queue.popleft()
                    for c in ((i-1,j),(i+1,j),(i,j-1),(i,j+1)):
                        if c in free and c not in seen:
                            seen.add(c);queue.append(c);parents[c]=(i,j)
                if not all(c in seen for c in cells):
                    unreachable=[label for (label,_),cell in zip(targets,cells) if cell not in seen]
                    raise RuntimeError("Routes disconnected: %s / %.2f m / %s"%(room,radius*2,unreachable))
                if radius==.24:
                    for (label,_),cell in zip(targets,cells):
                        if not label.startswith("Door Header"): continue
                        path=[]
                        while cell is not None:
                            path.append(point(cell));cell=parents[cell]
                        # Retain each turn in the furniture-aware path.
                        compact=[path[0]]
                        for j in range(1,len(path)-1):
                            a=(round(path[j][0]-path[j-1][0],3),round(path[j][1]-path[j-1][1],3))
                            b=(round(path[j+1][0]-path[j][0],3),round(path[j+1][1]-path[j][1],3))
                            if a!=b: compact.append(path[j])
                        compact.append(path[-1]);self.route_paths[room]=compact
                print("ROUTE_CLEAR",room,"body width",radius*2,"door/pickup/encounter targets",len(cells))


def main():
    school=bpy.data.collections.get("After School - School Blockout")
    if not school or not bpy.data.filepath: raise RuntimeError("Open current assets.blend")
    for name in ROOMS+("Kitchen Floor","Kitchen - South Wall"):
        if not bpy.data.objects.get(name): raise RuntimeError("Actual room geometry missing: "+name)
    for name in GROUPS:
        c=bpy.data.collections.get(name)
        if c and (not c.get(TAG) or c.children or any(not o.get(TAG) for o in c.objects)):
            raise RuntimeError("Refusing unowned collection: "+name)
    for name in GROUPS:
        c=bpy.data.collections.get(name)
        if c:
            for o in list(c.objects): bpy.data.objects.remove(o,do_unlink=True)
            bpy.data.collections.remove(c)
    for mesh in list(bpy.data.meshes):
        if mesh.get(TAG) and mesh.users==0: bpy.data.meshes.remove(mesh)
    collections=[]
    for name in GROUPS:
        c=bpy.data.collections.new(name);c[TAG]=True;school.children.link(c);collections.append(c)
    materials={}
    for key in ("Laminate","Metal","Chair","Cabinet","Board","Canvas","Art","Medical White"):
        materials[key]=bpy.data.materials.get("School Props - "+key)
        if not materials[key]: raise RuntimeError("Shared palette missing: "+key)
    mat=bpy.data.materials.get("School Props - Dining Accent")
    if mat and not mat.get(TAG): raise RuntimeError("Unowned accent material")
    mat=mat or bpy.data.materials.new("School Props - Dining Accent")
    mat[TAG]=True;mat.diffuse_color=(.28,.36,.35,1);mat.use_nodes=True
    node=mat.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value=mat.diffuse_color
    node.inputs["Roughness"].default_value=.72
    materials["Accent"]=mat
    meshes=kit(materials)
    layout=Layout(collections,meshes);layout.furnish();layout.validate()
    stats={"instances":len(layout.objects),"designs":len(meshes),"materials_added":1,"materials_reused":8,
           "rooms":dict(Counter(o["room_floor"] for o in layout.objects)),
           "types":dict(Counter(o["prop_type"] for o in layout.objects)),
           "triangles_per_design":{n:len(m.loop_triangles) for n,m in meshes.items()},
           "instanced_triangles":sum(len(o.data.loop_triangles) for o in layout.objects)}
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    folder=Path(os.environ.get("TEMP","/tmp"))/"after-school-cafeteria-library-review"
    folder.mkdir(exist_ok=True)
    report={"stats":stats,"reserved":layout.reserved,"targets":layout.targets,"routes":layout.route_paths,
            "objects":{o.name:{"room":o["room_floor"],"bounds":bounds(o),"type":o["prop_type"]} for o in layout.objects}}
    (folder/"props_report.json").write_text(json.dumps(report,indent=2))
    print("DINING_READING_PROPS",json.dumps(stats,sort_keys=True))


if __name__=="__main__": main()
