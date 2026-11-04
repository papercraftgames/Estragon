extends Node
const Entry2D = preload("res://addons/estragon/layout_proof/entry_2d.gd")
const Entry3D = preload("res://addons/estragon/layout_proof/entry_3d.gd")

func make_2d() -> Node2D:
    return _GogoFactories_0._gogo_build_0(
        (Vector2(0, 50)),
        (70.0),
        (20.0),
        (true),
        (1.0),
        (Color.TRANSPARENT),
        (100.0),
        (70.0),
        (10.0),
        (Color.TRANSPARENT),
        (50.0),
        (45.0),
        (Color(0.6, 0.3, 0.9)),
        (50.0),
        (70.0),
        (Color(0.3, 0.55, 0.95)),
        (Vector2(30, 180)),
        (8.0),
        (Color.TRANSPARENT),
        (80.0),
        (35.0),
        (Color(1, 0.65, 0.2))
    )

func make_3d() -> Node3D:
    return _GogoFactories_0._gogo_build_1(
        (Vector3(-4, 0, 0)),
        (1.4),
        (1.0),
        (0.4),
        (true),
        (0.0125),
        (Color.TRANSPARENT),
        (1.5),
        (1.4),
        (1.0),
        (0.2),
        (Color.TRANSPARENT),
        (0.8),
        (0.8),
        (0.8),
        (Color(0.6, 0.3, 0.9)),
        (0.8),
        (1.4),
        (1.0),
        (Color(0.3, 0.55, 0.95)),
        (Vector3(0.6, -2, 0)),
        (Color.TRANSPARENT),
        (1.2),
        (0.5),
        (0.6),
        (Color(1, 0.65, 0.2))
    )



class _GogoFactories_0:

    static func _gogo_build_0(
        _gogo_value_0: Vector2,
        _gogo_value_1: float,
        _gogo_value_2: float,
        _gogo_value_3: bool,
        _gogo_value_4: float,
        _gogo_value_5: Color,
        _gogo_value_6: float,
        _gogo_value_7: float,
        _gogo_value_8: float,
        _gogo_value_9: Color,
        _gogo_value_10: float,
        _gogo_value_11: float,
        _gogo_value_12: Color,
        _gogo_value_13: float,
        _gogo_value_14: float,
        _gogo_value_15: Color,
        _gogo_value_16: Vector2,
        _gogo_value_17: float,
        _gogo_value_18: Color,
        _gogo_value_19: float,
        _gogo_value_20: float,
        _gogo_value_21: Color
    ) -> Entry2D:
        var component_0: Entry2D = Entry2D.new()
        component_0.name = "Layout2D"
        component_0.position = _gogo_value_0
        component_0.height = _gogo_value_1
        component_0.gap = _gogo_value_2
        component_0.center = _gogo_value_3
        component_0.viewport_width_scale = _gogo_value_4
        component_0.tint = _gogo_value_5
        var component_1: Entry2D = Entry2D.new()
        component_1.name = "Left"
        component_1.width = _gogo_value_6
        component_1.height = _gogo_value_7
        component_0.add_child(component_1)
        var component_2: Entry2D = Entry2D.new()
        component_2.name = "Branch"
        component_2.gap = _gogo_value_8
        component_2.tint = _gogo_value_9
        var component_3: Entry2D = Entry2D.new()
        component_3.name = "InnerA"
        component_3.width = _gogo_value_10
        component_3.height = _gogo_value_11
        component_3.tint = _gogo_value_12
        component_2.add_child(component_3)
        var component_4: Entry2D = Entry2D.new()
        component_4.name = "InnerB"
        component_4.width = _gogo_value_13
        component_4.height = _gogo_value_14
        component_4.tint = _gogo_value_15
        component_2.add_child(component_4)
        component_0.add_child(component_2)
        var component_5: Node2D = Node2D.new()
        component_5.name = "NativeBoundary"
        component_5.position = _gogo_value_16
        var component_6: Entry2D = Entry2D.new()
        component_6.name = "Reentry"
        component_6.gap = _gogo_value_17
        component_6.tint = _gogo_value_18
        var component_7: Entry2D = Entry2D.new()
        component_7.name = "Independent"
        component_7.width = _gogo_value_19
        component_7.height = _gogo_value_20
        component_7.tint = _gogo_value_21
        component_6.add_child(component_7)
        component_5.add_child(component_6)
        component_0.add_child(component_5)
        component_1.owner = component_0
        component_3.owner = component_0
        component_4.owner = component_0
        component_2.owner = component_0
        component_7.owner = component_0
        component_6.owner = component_0
        component_5.owner = component_0
        return component_0


    static func _gogo_build_1(
        _gogo_value_0: Vector3,
        _gogo_value_1: float,
        _gogo_value_2: float,
        _gogo_value_3: float,
        _gogo_value_4: bool,
        _gogo_value_5: float,
        _gogo_value_6: Color,
        _gogo_value_7: float,
        _gogo_value_8: float,
        _gogo_value_9: float,
        _gogo_value_10: float,
        _gogo_value_11: Color,
        _gogo_value_12: float,
        _gogo_value_13: float,
        _gogo_value_14: float,
        _gogo_value_15: Color,
        _gogo_value_16: float,
        _gogo_value_17: float,
        _gogo_value_18: float,
        _gogo_value_19: Color,
        _gogo_value_20: Vector3,
        _gogo_value_21: Color,
        _gogo_value_22: float,
        _gogo_value_23: float,
        _gogo_value_24: float,
        _gogo_value_25: Color
    ) -> Entry3D:
        var component_0: Entry3D = Entry3D.new()
        component_0.name = "Layout3D"
        component_0.position = _gogo_value_0
        component_0.height = _gogo_value_1
        component_0.depth = _gogo_value_2
        component_0.gap = _gogo_value_3
        component_0.center = _gogo_value_4
        component_0.viewport_width_scale = _gogo_value_5
        component_0.tint = _gogo_value_6
        var component_1: Entry3D = Entry3D.new()
        component_1.name = "Left"
        component_1.width = _gogo_value_7
        component_1.height = _gogo_value_8
        component_1.depth = _gogo_value_9
        component_0.add_child(component_1)
        var component_2: Entry3D = Entry3D.new()
        component_2.name = "Branch"
        component_2.gap = _gogo_value_10
        component_2.tint = _gogo_value_11
        var component_3: Entry3D = Entry3D.new()
        component_3.name = "InnerA"
        component_3.width = _gogo_value_12
        component_3.height = _gogo_value_13
        component_3.depth = _gogo_value_14
        component_3.tint = _gogo_value_15
        component_2.add_child(component_3)
        var component_4: Entry3D = Entry3D.new()
        component_4.name = "InnerB"
        component_4.width = _gogo_value_16
        component_4.height = _gogo_value_17
        component_4.depth = _gogo_value_18
        component_4.tint = _gogo_value_19
        component_2.add_child(component_4)
        component_0.add_child(component_2)
        var component_5: Node3D = Node3D.new()
        component_5.name = "NativeBoundary"
        component_5.position = _gogo_value_20
        var component_6: Entry3D = Entry3D.new()
        component_6.name = "Reentry"
        component_6.tint = _gogo_value_21
        var component_7: Entry3D = Entry3D.new()
        component_7.name = "Independent"
        component_7.width = _gogo_value_22
        component_7.height = _gogo_value_23
        component_7.depth = _gogo_value_24
        component_7.tint = _gogo_value_25
        component_6.add_child(component_7)
        component_5.add_child(component_6)
        component_0.add_child(component_5)
        component_1.owner = component_0
        component_3.owner = component_0
        component_4.owner = component_0
        component_2.owner = component_0
        component_7.owner = component_0
        component_6.owner = component_0
        component_5.owner = component_0
        return component_0
