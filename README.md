
* Build the framework, and add it to your project as an Embedded Framework
  (if modifying SceneKrift, you can add the SceneKrift.xcodeproj to your own and add it as a Build Dependency)

* Make your view controller's main view an OVRView.

* Set the OVRView's scene to your SCNScene

* Optionally, add OVRView's headNode to any node in your scene. It will be added automatically to the rootNode otherwise.

* _/~Enter the Rift~\_