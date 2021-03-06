import bpy
from bpy.props import *
from bpy.types import Node, NodeSocket
from arm.logicnode.arm_nodes import *

class GateNode(Node, ArmLogicTreeNode):
    '''Gate node'''
    bl_idname = 'GateNodeType'
    bl_label = 'Gate'
    bl_icon = 'CURVE_PATH'
    property0 = EnumProperty(
        items = [('Equal', 'Equal', 'Equal'),
                 ('Not Equal', 'Not Equal', 'Not Equal'),
                 ('Greater', 'Greater', 'Greater'),
                 ('Greater Equal', 'Greater Equal', 'Greater Equal'),
                 ('Less', 'Less', 'Less'),
                 ('Less Equal', 'Less Equal', 'Less Equal')],
        name="", default='Equal')
    
    def init(self, context):
        self.inputs.new('NodeSocketShader', "In")
        self.inputs.new('NodeSocketShader', "Value")
        self.inputs.new('NodeSocketShader', "Value")
        self.outputs.new('NodeSocketFloat', "Out")

    def draw_buttons(self, context, layout):
        layout.prop(self, "property0")

add_node(GateNode, category='Logic')
