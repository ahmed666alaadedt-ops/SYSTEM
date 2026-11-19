import argparse
import math
import os
import bpy
from mathutils import Vector, Matrix

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

def uv_sphere(name, loc, scale, mat, segments=16, rings=12):
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
            start=(sign*0.31+spread*sign,0.82,-0.015)
            mid=(sign*0.31+spread*sign,0.77,-0.02)
            end=(sign*0.31+spread*sign,0.73,-0.025)
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
    body.data.remesh_voxel_size=0.022
    bpy.ops.object.voxel_remesh()
    smooth=body.modifiers.new("Anatomical smoothing","SMOOTH")
    smooth.factor=1.25; smooth.iterations=4
    sub=body.modifiers.new("Surface polish","SUBSURF")
    sub.levels=1; sub.render_levels=1
    decimate=body.modifiers.new("Mobile polygon optimization","DECIMATE")
    decimate.ratio=0.88
    for poly in body.data.polygons: poly.use_smooth=True
    return body

def add_face_and_hair(name, female=False):
    objs=[]
    for s in (-1,1):
        objs.append(uv_sphere(name+"_Eye",(s*0.054,1.84,-0.123),(0.021,0.018,0.012),EYES,16,12))
        objs.append(uv_sphere(name+"_EyeGlint",(s*0.058,1.847,-0.133),(0.006,0.006,0.004),WHITE,12,8))
        objs.append(uv_sphere(name+"_Ear",(s*0.145,1.81,0),(0.027,0.055,0.035),SKIN,16,12))
        objs.append(capsule(name+"_Eyebrow",(s*0.025,1.885,-0.116),(s*0.085,1.89,-0.112),0.010,HAIR,12))
    objs.append(uv_sphere(name+"_Nose",(0,1.80,-0.143),(0.025,0.043,0.035),SKIN,16,12))
    objs.append(capsule(name+"_Mouth",( -0.034,1.718,-0.132),(0.034,1.718,-0.132),0.006,HAIR,12))
    objs.append(uv_sphere(name+"_HairCap",(0,1.965,0.015),(0.15,0.085,0.14),HAIR,20,12))
    # Layered hair silhouette; longer side locks distinguish the female base mesh.
    for i in range(7):
        x=-0.12+i*0.04
        objs.append(capsule(name+"_HairLock",(x,1.99,0.0),(x+0.018,1.91,-0.07),0.025,HAIR,12))
    if female:
        for s in (-1,1):
            objs.append(capsule(name+"_LongHairSide",(s*0.125,1.91,0.025),(s*0.145,1.64,0.025),0.035,HAIR,16))
        objs.append(uv_sphere(name+"_HairBun",(0,1.91,0.115),(0.09,0.10,0.085),HAIR,20,12))
    return objs

def add_finger_geometry(name):
    fingers=[]
    for side,sign in (("L",-1),("R",1)):
        for finger,spread in (("thumb",0.055),("index",0.025),("middle",0.0),("ring",-0.025),("pinky",-0.05)):
            x=sign*0.31+spread*sign
            first=capsule(name+"_"+finger+"_01_"+side,(x,0.82,-0.015),(x,0.77,-0.02),0.010,SKIN,12)
            second=capsule(name+"_"+finger+"_02_"+side,(x,0.77,-0.02),(x,0.73,-0.025),0.008,SKIN,12)
            fingers.append((first,finger+"_01."+side))
            fingers.append((second,finger+"_02."+side))
    return fingers

def add_clothes(name):
    objs=[]
    # tailored jacket and trousers, separate fitted pieces to permit outfit swaps
    objs.append(uv_sphere(name+"_Jacket",(0,1.31,0),(0.265,0.39,0.16),CLOTH,20,12))
    objs.append(uv_sphere(name+"_Belt",(0,1.00,-0.005),(0.205,0.045,0.145),TRIM,20,12))
    objs.append(capsule(name+"_CollarLeft",(-0.09,1.63,-0.105),(0.0,1.51,-0.16),0.035,TRIM,12))
    objs.append(capsule(name+"_CollarRight",(0.09,1.63,-0.105),(0.0,1.51,-0.16),0.035,TRIM,12))
    for button_y in (1.43,1.33,1.23):
        objs.append(uv_sphere(name+"_JacketButton",(0,button_y,-0.158),(0.012,0.016,0.008),TRIM,12,8))
    objs.append(uv_sphere(name+"_BeltBuckle",(0,1.00,-0.15),(0.055,0.038,0.014),TRIM,16,10))
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

def combine_bone_parts(name, parts, arm):
    if not parts:
        return None
    vertices=[]
    faces=[]
    face_material_indices=[]
    materials=[]
    material_lookup={}
    bone_vertex_indices={}
    for source_obj,bone_name in parts:
        source_mesh=source_obj.data
        offset=len(vertices)
        world_matrix=source_obj.matrix_world.copy()
        for vertex in source_mesh.vertices:
            point=world_matrix @ vertex.co
            vertices.append((point.x,point.y,point.z))
        bone_vertex_indices.setdefault(bone_name,[]).extend(
            range(offset,offset+len(source_mesh.vertices))
        )
        for polygon in source_mesh.polygons:
            faces.append([offset+index for index in polygon.vertices])
            material=None
            if polygon.material_index < len(source_mesh.materials):
                material=source_mesh.materials[polygon.material_index]
            if material is None:
                raise RuntimeError("Character accessory has no material: "+source_obj.name)
            material_key=material.name
            if material_key not in material_lookup:
                material_lookup[material_key]=len(materials)
                materials.append(material)
            face_material_indices.append(material_lookup[material_key])

    mesh=bpy.data.meshes.new(name+"_Mesh")
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    for material in materials:
        mesh.materials.append(material)
    for polygon,material_index in zip(mesh.polygons,face_material_indices):
        polygon.material_index=material_index
        polygon.use_smooth=True

    combined=bpy.data.objects.new(name,mesh)
    bpy.context.scene.collection.objects.link(combined)
    combined.parent=arm
    combined.matrix_world=Matrix.Identity(4)
    for bone_name,vertex_indices in bone_vertex_indices.items():
        group=combined.vertex_groups.new(name=bone_name)
        group.add(vertex_indices,1.0,"REPLACE")
    modifier=combined.modifiers.new("Accessory Armature Skin","ARMATURE")
    modifier.object=arm

    for source_obj,bone_name in parts:
        bpy.data.objects.remove(source_obj,do_unlink=True)
    return combined

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
    walk_action=arm.animation_data.action
    walk_action.name="Walk_Cycle"
    for fc in walk_action.fcurves:
        for kp in fc.keyframe_points:
            kp.interpolation="BEZIER"
        fc.modifiers.new("CYCLES")
    # Idle clip: subtle chest breathing, exported as its own NLA strip.
    idle_action=bpy.data.actions.new("Idle_Breathing")
    arm.animation_data.action=idle_action
    for frame in (1,13,25):
        spine=arm.pose.bones.get("spine")
        if spine:
            spine.rotation_mode="XYZ"
            spine.rotation_euler.x=math.sin((frame-1)/24*math.tau)*0.012
            spine.keyframe_insert(data_path="rotation_euler",frame=frame,group="Body")
    for fc in idle_action.fcurves:
        fc.modifiers.new("CYCLES")
    # Run cycle: stronger stride and arm drive for sprinting.
    run_action=bpy.data.actions.new("Run_Cycle")
    arm.animation_data.action=run_action
    for frame in (1,7,13,19,25):
        phase=(frame-1)/24.0*math.tau
        for side,sign in (("L",1),("R",-1)):
            thigh=arm.pose.bones.get("thigh."+side)
            calf=arm.pose.bones.get("calf."+side)
            upper=arm.pose.bones.get("upper_arm."+side)
            fore=arm.pose.bones.get("forearm."+side)
            if thigh:
                thigh.rotation_mode="XYZ"; thigh.rotation_euler.x=math.sin(phase)*0.62*sign
                thigh.keyframe_insert(data_path="rotation_euler",frame=frame,group="Legs")
            if calf:
                calf.rotation_mode="XYZ"; calf.rotation_euler.x=max(0,math.sin(phase+math.pi))*0.78
                calf.keyframe_insert(data_path="rotation_euler",frame=frame,group="Legs")
            if upper:
                upper.rotation_mode="XYZ"; upper.rotation_euler.x=-math.sin(phase)*0.48*sign
                upper.keyframe_insert(data_path="rotation_euler",frame=frame,group="Arms")
            if fore:
                fore.rotation_mode="XYZ"; fore.rotation_euler.x=-0.22
                fore.keyframe_insert(data_path="rotation_euler",frame=frame,group="Arms")
        spine=arm.pose.bones.get("spine")
        if spine:
            spine.rotation_mode="XYZ"; spine.rotation_euler.x=0.10
            spine.keyframe_insert(data_path="rotation_euler",frame=frame,group="Body")
    for fc in run_action.fcurves:
        fc.modifiers.new("CYCLES")

    # Jump: anticipation, airborne tuck, landing recovery.
    jump_action=bpy.data.actions.new("Jump_Animation")
    arm.animation_data.action=jump_action
    for frame, torso, thigh_angle, calf_angle in (
        (1,0.0,0.0,0.0),(6,-0.12,-0.38,0.18),(13,0.10,0.52,-0.22),
        (19,0.04,0.25,0.42),(25,0.0,0.0,0.0)
    ):
        spine=arm.pose.bones.get("spine")
        if spine:
            spine.rotation_mode="XYZ"; spine.rotation_euler.x=torso
            spine.keyframe_insert(data_path="rotation_euler",frame=frame,group="Body")
        for side in ("L","R"):
            thigh=arm.pose.bones.get("thigh."+side)
            calf=arm.pose.bones.get("calf."+side)
            if thigh:
                thigh.rotation_mode="XYZ"; thigh.rotation_euler.x=thigh_angle
                thigh.keyframe_insert(data_path="rotation_euler",frame=frame,group="Legs")
            if calf:
                calf.rotation_mode="XYZ"; calf.rotation_euler.x=calf_angle
                calf.keyframe_insert(data_path="rotation_euler",frame=frame,group="Legs")
    for fc in jump_action.fcurves:
        fc.modifiers.new("CYCLES")

    # Unarmed strike: shoulder drive and opposing arm balance.
    attack_action=bpy.data.actions.new("Attack_Animation")
    arm.animation_data.action=attack_action
    for frame, lead, support in ((1,0.0,0.0),(5,-0.25,0.12),(10,0.72,-0.30),(15,0.20,0.10),(21,0.0,0.0)):
        for side, sign in (("R",1),("L",-1)):
            upper=arm.pose.bones.get("upper_arm."+side)
            fore=arm.pose.bones.get("forearm."+side)
            if upper:
                upper.rotation_mode="XYZ"
                upper.rotation_euler.z=lead if sign==1 else support
                upper.keyframe_insert(data_path="rotation_euler",frame=frame,group="Arms")
            if fore:
                fore.rotation_mode="XYZ"
                fore.rotation_euler.z=-0.42 if sign==1 and frame==10 else 0.0
                fore.keyframe_insert(data_path="rotation_euler",frame=frame,group="Arms")
    for fc in attack_action.fcurves:
        for kp in fc.keyframe_points: kp.interpolation="BEZIER"

    arm.animation_data.action=None
    for clip_name, clip_action in (
        ("Walk_Cycle",walk_action),("Run_Cycle",run_action),
        ("Idle_Breathing",idle_action),("Jump_Animation",jump_action),
        ("Attack_Animation",attack_action)
    ):
        track=arm.animation_data.nla_tracks.new()
        track.name=clip_name
        track.strips.new(clip_name,1,clip_action)

def generate_character(name, female, output):
    clear_scene()
    arm=make_armature(name,female)
    body=build_body(name,female)
    weight_body(body,arm)
    # Build detailed face, fingers and swappable outfit pieces, then combine
    # each semantic group into a weighted mesh to keep mobile draw calls low.
    face=add_face_and_hair(name,female)
    fingers=add_finger_geometry(name)
    clothes=add_clothes(name)
    groups={
        "FaceSkin":[],
        "Eyes":[],
        "Hair":[],
        "Hands":[],
        "Jacket":[],
        "Trim":[],
        "Trousers":[],
        "Belt":[],
        "Boots":[]
    }
    for obj in face:
        part_name=obj.name.lower()
        if "hair" in part_name or "eyebrow" in part_name or "mouth" in part_name:
            groups["Hair"].append((obj,"head"))
        elif "eye" in part_name:
            groups["Eyes"].append((obj,"head"))
        else:
            groups["FaceSkin"].append((obj,"head"))
    for obj,bone_name in fingers:
        groups["Hands"].append((obj,bone_name))
    for obj in clothes:
        part_name=obj.name.lower()
        if "sleeve" in part_name:
            bone_name="upper_arm.L" if obj.location.x<0 else "upper_arm.R"
            groups["Jacket"].append((obj,bone_name))
        elif "trousers" in part_name:
            bone_name="thigh.L" if obj.location.x<0 else "thigh.R"
            groups["Trousers"].append((obj,bone_name))
        elif "glove" in part_name:
            bone_name="hand.L" if obj.location.x<0 else "hand.R"
            groups["Boots"].append((obj,bone_name))
        elif "boot" in part_name:
            bone_name="foot.L" if obj.location.x<0 else "foot.R"
            groups["Boots"].append((obj,bone_name))
        elif "belt" in part_name:
            groups["Belt"].append((obj,"pelvis"))
        elif "collar" in part_name or "button" in part_name:
            groups["Trim"].append((obj,"chest"))
        else:
            groups["Jacket"].append((obj,"chest"))

    detail_meshes=[]
    for group_name,parts in groups.items():
        combined=combine_bone_parts(name+"_"+group_name,parts,arm)
        if combined is not None:
            detail_meshes.append(combined)

    add_walk_animation(arm)
    # Set clean rest pose before export; animations retain their own keyed poses.
    for pb in arm.pose.bones:
        pb.rotation_euler=(0,0,0)

    # Modeling coordinates use Y as the human height axis. Rotate the full
    # assembly in-place while preserving the armature/body/bone-parent links.
    rotation=Matrix.Rotation(math.radians(90.0),4,"X")
    world_matrices=[(obj,obj.matrix_world.copy()) for obj in assembly]
    for obj,world_matrix in world_matrices:
        obj.matrix_world=rotation @ world_matrix

    # Keep the armature as the true root for both skinned body and bone-attached parts.
    arm["system_character_type"]="humanoid"
    arm["system_rig"]="deform_armature"
    arm["system_gender"]="female" if female else "male"
    arm["system_animation_set"]="idle,walk,run,jump,attack"
    arm["system_joint_count"]=len(arm.data.bones)
    body["system_weighted_to_armature"]=True

    bpy.ops.object.select_all(action="DESELECT")
    for obj in assembly: obj.select_set(True)
    bpy.context.view_layer.objects.active=arm
    os.makedirs(output,exist_ok=True)
    blend=os.path.join(output,name+".blend")
    glb=os.path.join(output,name+".glb")
    bpy.ops.wm.save_as_mainfile(filepath=blend)
    bpy.ops.export_scene.gltf(filepath=glb,export_format="GLB",use_selection=True,export_animations=True,export_nla_strips=True,export_skins=True,export_apply=True)
    print("GENERATED_CHARACTER",name,glb)

def main():
    args=parse_args()
    out=os.path.abspath(args.output)
    generate_character("SYSTEM_Humanoid_Male",False,out)
    generate_character("SYSTEM_Humanoid_Female",True,out)

if __name__=="__main__":
    main()
