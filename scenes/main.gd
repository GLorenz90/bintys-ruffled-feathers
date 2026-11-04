extends Node3D
class_name Main

func _init() -> void:
  Global.main = self;
#/_init

func _ready() -> void:
  Global.camera = $SubViewportContainer/SubViewport/CameraTarget/Camera;
  Global.ui_layer = $SubViewportContainer/SubViewport/UiLayer;
  Global.current_scene = $SubViewportContainer/SubViewport/Scene;
#/_ready
