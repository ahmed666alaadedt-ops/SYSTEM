import argparse
import math
import os
import bpy
from mathutils import Vector

def parse_args():
    argv = __import__("sys").argv
    argv = argv[argv.index("--") + 1:] if "--" in argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--output", default="SYSTEM-WORLD-3D/assets/characters")
    return p.parse_args(argv)

def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.actions):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)

def material(name, color, roughness=0.72, metallic=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1.0)
    m.use_nodes = True
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1.0)
    bs.inputs["Roughness"].default_value = roughness
    bs.inputs["Metallic"].default_value = metallic
    return m

SKIN = material("Skin - warm natural", (0.48, 0.285, 0.19), 0.62)
HAIR = material("Hair - deep brown", (0.025, 0.012, 0.009), 0.78)
CLOTH = material("Cloth - midnight blue", (0.025, 0.075, 0.14), 0.86)
TRIM = material("Trim - brushed gold", (0.52, 0.29, 0.075), 0.38, 0.55)
PANTS = material("Trousers - charcoal", (0.035, 0.045, 0.06), 0.88)
SHOES = material("Boot leather", (0.018, 0.014, 0.012), 0.48)
EYES = material("Eyes", (0.012, 0.009, 0.008), 0.22)
WHITE = material("Eye highlights", (0.8, 0.72, 0.58), 0.3)

def uv_sphere(name, loc, scale, mat, segments=24, rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(mat)
    for p in o.data.polygons: p.use_smooth = True
    return o

def capsule(name, a, b, radius, mat, vertices=16):
    av, bv = Vector(a), Vector(b)
    direction = bv - av
    mid = (av + bv) * 0.5
    bpy.ops.mesh.primitive_uv_sphere_add(segments=vertices, ring_count=12, location=mid)
    o = bpy.context.object
    o.name = name
    o.scale = (radius, direction.length * 0.5 + radius * 0.35, radius)
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = direction.to_track_quat("Y", "Z")
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(mat)
    for p in o.data.polygons: p.use_smooth = True
    return o

def make_armature(name, female=False):
    bpy.ops.object.select_all(action="DESELECT")
    bpy.ops.object.armature_add(enter_editmode=True, location=(0,0,0))
    arm = bpy.context.object
    arm.name = name + "_Rig"
    arm.data.name = name + "_Skeleton"
    root = arm.data.edit_bones[0]
    root.name = "root"
    root.head = (0,0,0); root.tail = (0,0,0.12)
    bones = {}
    def bone(n, head, tail, parent="root", connected=False):
        b = arm.data.edit_bones.new(n)
        b.head = head; b.tail = tail
        b.parent = bones.get(parent, root)
        b.use_connect = connected
        bones[n] = b
    hip = 0.94
    shoulder = 1.48 if not female else 1.45
    bone("pelvis",(0,hip,0),(0,1.12,0))
    bone("spine",(0,1.12,0),(0,1.40,0),"pelvis",True)
    bone("chest",(0,1.40,0),(0,shoulder,0),"spine",True)
    bone("neck",(0,shoulder,0),(0,1.65,0),"chest",True)
    bone("head",(0,1.65,0),(0,1.91,0),"neck",True)
    for side, sign in (("L",-1),("R",1)):
        bone("clavicle."+side,(0,shoulder-0.02,0),(sign*0.25,shoulder-0.01,0),"chest")
        bone("upper_arm."+side,(sign*0.25,shoulder-0.01,0),(sign*0.29,1.17,0),"clavicle."+side,True)
        bone("forearm."+side,(sign*0.29,1.17,0),(sign*0.31,0.91,0),"upper_arm."+side,True)
        bone("hand."+side,(sign*0.31,0.91,0),(sign*0.31,0.79,-0.015),"forearm."+side,True)
        bone("thigh."+side,(sign*0.12,hip,0),(sign*0.13,0.53,0),"pelvis")
        bone("calf."+side,(sign*0.13,0.53,0),(sign*0.13,0.13,0),"thigh."+side,True)
        bone("foot."+side,(sign*0.13,0.13,0),(sign*0.13,0.07,-0.19),"calf."+side,True)
        for finger, spread in (("thumb",0.055),("index",0.025),("middle",0.0),("ring",-0.025),("pinky",-0.05)):
            start=(sign*0.31,0.82,spread)
            mid=(sign*0.31,0.77,spread*1.2)
            end=(sign*0.31,0.73,spread*1.4)
            bone(f"{finger}_01.{side}",start,mid,"hand."+side)
            bone(f"{finger}_02.{side}",mid,end,f"{finger}_01.{side}",True)
    bpy.ops.object.mode_set(mode="OBJECT")
    arm.show_in_front = True
    arm.data.display_type = "OCTAHEDRAL"
    return arm

def build_body(name, female=False):
    parts=[]
    # continuous-looking anatomy, remeshed into a single deforming body surface
    parts.append(uv_sphere("TorsoCore",(0,1.29,0),(0.235 if female else 0.255,0.43,0.145),SKIN))
    parts.append(uv_sphere("Pelvis",(0,0.98,0),(0.19,0.19,0.13),SKIN))
    parts.append(uv_sphere("Chest",(0,1.52,0),(0.31 if not female else 0.285,0.22,0.17),SKIN))
    parts.append(uv_sphere("Neck",(0,1.66,0),(0.075,0.14,0.075),SKIN))
    parts.append(uv_sphere("Head",(0,1.82,0),(0.145,0.205,0.135),SKIN,32,24))
    # jaw/chin and cheek volume
    parts.append(uv_sphere("Jaw",(0,1.735,-0.012),(0.12,0.105,0.125),SKIN))
    for s in (-1,1):
        parts.append(uv_sphere("Cheek",(s*0.09,1.79,-0.075),(0.055,0.065,0.05),SKIN))
        parts.append(capsule("UpperArm",(s*0.27,1.51,0),(s*0.30,1.19,0),0.072,SKIN))
        parts.append(capsule("Forearm",(s*0.30,1.19,0),(s*0.31,0.92,0),0.055,SKIN))
        parts.append(uv_sphere("Palm",(s*0.31,0.86,-0.01),(0.055,0.085,0.035),SKIN))
        parts.append(capsule("Thigh",(s*0.12,0.99,0),(s*0.13,0.55,0),0.09 if not female else 0.085,SKIN))
        parts.append(capsule("Calf",(s*0.13,0.55,0),(s*0.13,0.14,0),0.062,SKIN))
        parts.append(uv_sphere("Foot",(s*0.13,0.105,-0.075),(0.07,0.055,0.15),SKIN))
    # join and voxel-remesh all body masses into a unified organic mesh
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    body=bpy.context.object
    body.name=name+"_Body"
    body.data.remesh_voxel_size=0.018
    bpy.ops.object.voxel_remesh()
    smooth=body.modifiers.new("Anatomical smoothing","SMOOTH")
    smooth.factor=1.25; smooth.iterations=4
    sub=body.modifiers.new("Surface polish","SUBSURF")
    sub.levels=1; sub.render_levels=1
    for poly in body.data.polygons: poly.use_smooth=True
    return body

def add_face_and_hair(name):
    objs=[]
    for s in (-1,1):
        objs.append(uv_sphere(name+"_Eye",(s*0.054,1.84,-0.123),(0.021,0.018,0.012),EYES,16,12))
        objs.append(uv_sphere(name+"_EyeGlint",(s*0.058,1.847,-0.133),(0.006,0.006,0.004),WHITE,12,8))
        objs.append(uv_sphere(name+"_Ear",(s*0.145,1.81,0),(0.027,0.055,0.035),SKIN,16,12))
    objs.append(uv_sphere(name+"_Nose",(0,1.80,-0.143),(0.025,0.043,0.035),SKIN,16,12))
    objs.append(uv_sphere(name+"_HairCap",(0,1.965,0.015),(0.15,0.085,0.14),HAIR,24,16))
    # layered swept hair locks
    for i in range(7):
        x=-0.12+i*0.04
        objs.append(capsule(name+"_HairLock",(x,1.99,0.0),(x+0.018,1.91,-0.07),0.025,HAIR,12))
    return objs

def add_clothes(name):
    objs=[]
    # tailored jacket and trousers, separate fitted pieces to permit outfit swaps
    objs.append(uv_sphere(name+"_Jacket",(0,1.31,0),(0.265,0.39,0.16),CLOTH,24,16))
    objs.append(uv_sphere(name+"_Belt",(0,1.00,-0.005),(0.205,0.045,0.145),TRIM,20,12))
    for s in (-1,1):
        objs.append(capsule(name+"_Sleeve",(s*0.27,1.51,0),(s*0.30,1.20,0),0.082,CLOTH))
        objs.append(capsule(name+"_Glove",(s*0.31,0.90,0),(s*0.31,0.82,0),0.056,SHOES))
        objs.append(capsule(name+"_Trousers",(s*0.12,0.99,0),(s*0.13,0.15,0),0.095,PANTS))
        objs.append(uv_sphere(name+"_Boot",(s*0.13,0.11,-0.075),(0.078,0.07,0.16),SHOES))
    return objs

def parent_rigid_to_bone(obj, arm, bone_name):
    world_matrix = obj.matrix_world.copy()
    obj.parent = arm
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name
    obj.matrix_world = world_matrix

def weight_body(body, arm):
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True); arm.select_set(True)
    bpy.context.view_layer.objects.active=arm
    try:
        bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    except Exception:
        body.parent=arm
        mod=body.modifiers.new("Humanoid Armature","ARMATURE")
        mod.object=arm
        # deterministic nearest-bone fallback weights
        bones=[b for b in arm.data.bones if b.name!="root"]
        groups={b.name:body.vertex_groups.new(name=b.name) for b in bones}
        for v in body.data.vertices:
            co=body.matrix_world @ v.co
            nearest=sorted(bones,key=lambda b:(co-(arm.matrix_world @ b.head_local)).length)[:2]
            if nearest:
                groups[nearest[0].name].add([v.index],0.78,"REPLACE")
                if len(nearest)>1:
                    groups[nearest[1].name].add([v.index],0.22,"ADD")
    # Ensure armature modifier and deform
    if not any(m.type=="ARMATURE" for m in body.modifiers):
        mod=body.modifiers.new("Humanoid Armature","ARMATURE"); mod.object=arm

def add_walk_animation(arm):
    arm.animation_data_create()
    scene=bpy.context.scene
    scene.frame_start=1; scene.frame_end=25
    for frame in (1,7,13,19,25):
        phase=(frame-1)/24.0*math.tau
        for side,sign in (("L",1),("R",-1)):
            thigh=arm.pose.bones.get("thigh."+side)
            calf=arm.pose.bones.get("calf."+side)
            upper=arm.pose.bones.get("upper_arm."+side)
            fore=arm.pose.bones.get("forearm."+side)
            if thigh:
                thigh.rotation_mode="XYZ"; thigh.rotation_euler.x=math.sin(phase)*0.38*sign
                thigh.keyframe_insert(data_path="rotation_euler",frame=frame,group="Legs")
            if calf:
                calf.rotation_mode="XYZ"; calf.rotation_euler.x=max(0,math.sin(phase+math.pi))*0.48
                calf.keyframe_insert(data_path="rotation_euler",frame=frame,group="Legs")
            if upper:
                upper.rotation_mode="XYZ"; upper.rotation_euler.x=-math.sin(phase)*0.28*sign
                upper.keyframe_insert(data_path="rotation_euler",frame=frame,group="Arms")
            if fore:
                fore.rotation_mode="XYZ"; fore.rotation_euler.x=-0.08
                fore.keyframe_insert(data_path="rotation_euler",frame=frame,group="Arms")
        spine=arm.pose.bones.get("spine")
        if spine:
            spine.rotation_mode="XYZ"; spine.rotation_euler.z=math.sin(phase)*0.025
            spine.keyframe_insert(data_path="rotation_euler",frame=frame,group="Body")
    action=arm.animation_data.action
    action.name="Walk_Cycle"
    for fc in action.fcurves:
        for kp in fc.keyframe_points:
            kp.interpolation="BEZIER"
    # loop modifier on all channels
    for fc in action.fcurves:
        fc.modifiers.new("CYCLES")
    # idle clip: subtle chest breathing on a separate action
    idle=bpy.data.actions.new("Idle_Breathing")
    arm.animation_data.action=idle
    for frame in (1,13,25):
        spine=arm.pose.bones.get("spine")
        if spine:
            spine.rotation_mode="XYZ"
            spine.rotation_euler.x=math.sin((frame-1)/24*math.tau)*0.012
            spine.keyframe_insert(data_path="rotation_euler",frame=frame,group="Body")
    for fc in idle.fcurves:
        fc.modifiers.new("CYCLES")
    arm.animation_data.action=action

def generate_character(name, female, output):
    clear_scene()
    arm=make_armature(name,female)
    body=build_body(name,female)
    weight_body(body,arm)
    # bone-attached accessories and fitted clothing: stable rigid weighting
    face=add_face_and_hair(name)
    clothes=add_clothes(name)
    for obj in face:
        parent_rigid_to_bone(obj,arm,"head")
    for obj in clothes:
        n=obj.name
        if "Sleeve" in n: b="upper_arm.L" if "_L" in n else "upper_arm.R"
        elif "Glove" in n: b="hand.L" if "_L" in n else "hand.R"
        elif "Trousers" in n: b="thigh.L" if "_L" in n else "thigh.R"
        elif "Boot" in n: b="foot.L" if "_L" in n else "foot.R"
        elif "Belt" in n: b="pelvis"
        else: b="chest"
        # Names do not encode side for generated parts; assign by object center.
        if any(k in n for k in ("Sleeve","Glove","Trousers","Boot")):
            b=b.rsplit(".",1)[0]+(".L" if obj.location.x<0 else ".R")
        parent_rigid_to_bone(obj,arm,b)
    add_walk_animation(arm)
    # Set clean rest pose before export; animations retain their own keyed poses.
    for pb in arm.pose.bones:
        pb.rotation_euler=(0,0,0)
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True); body.select_set(True)
    for obj in face+clothes: obj.select_set(True)
    bpy.context.view_layer.objects.active=arm
    os.makedirs(output,exist_ok=True)
    blend=os.path.join(output,name+".blend")
    glb=os.path.join(output,name+".glb")
    bpy.ops.wm.save_as_mainfile(filepath=blend)
    bpy.ops.export_scene.gltf(filepath=glb,export_format="GLB",use_selection=True,export_animations=True,export_skins=True,export_apply=True)
    print("GENERATED_CHARACTER",name,glb)

def main():
    args=parse_args()
    out=os.path.abspath(args.output)
    generate_character("SYSTEM_Humanoid_Male",False,out)
    generate_character("SYSTEM_Humanoid_Female",True,out)

if __name__=="__main__":
    main()
