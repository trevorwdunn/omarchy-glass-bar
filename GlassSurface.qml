import QtQuick

// A piece of liquid glass over the wallpaper. Nothing can read the pixels
// behind a layer surface, so this draws its own copy of the wallpaper, lined
// up with the real one, and bends that (the "backdrop copy" pattern from
// https://github.com/gentpan/liquidglass). It only looks right where the
// wallpaper really is what sits behind it, which is true for the bar.
Item {
  id: root

  // Wallpaper file, and the screen it is drawn on (logical size and scale).
  property string wallpaper: ""
  property real screenWidth: 1920
  property real screenHeight: 1080
  property real pixelRatio: 1
  // Where this item's top-left corner sits on that screen.
  property real screenX: 0
  property real screenY: 0

  // Lens rectangle in item coordinates. It may overhang the item: a
  // full-width bar hangs its ends off-screen so only the long edges bend.
  property rect lens: Qt.rect(0, 0, width, height)
  property real radius: 0

  // Optics, as in liquidglass' references/optics.md.
  property real refraction: 10
  property real bezel: 1
  property real curvature: 2.5
  property real ior: 1.5
  property real chroma: 0.2
  property real specular: 0.9
  property real specularWidth: 1.5
  property real lightAngleDeg: -120
  property color tintColor: "black"
  property real tint: 0

  readonly property bool ready: backdrop.status === Image.Ready

  Image {
    id: backdrop
    visible: false
    source: root.wallpaper ? "file://" + root.wallpaper : ""
    sourceSize.width: Math.round(root.screenWidth * root.pixelRatio)
    sourceSize.height: Math.round(root.screenHeight * root.pixelRatio)
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: true
    smooth: true
  }

  ShaderEffect {
    anchors.fill: parent
    fragmentShader: Qt.resolvedUrl("shaders/glass.frag.qsb")

    property var source: backdrop
    property real refraction: root.refraction
    property real bezel: root.bezel
    property real curvature: root.curvature
    property real ior: root.ior
    property real chroma: root.chroma
    property real specular: root.specular
    property real specularWidth: root.specularWidth
    property real lightAngle: root.lightAngleDeg * Math.PI / 180
    property real radius: root.radius
    property real tint: root.tint
    property vector2d itemSize: Qt.vector2d(width, height)
    property vector4d lens: Qt.vector4d(root.lens.x, root.lens.y, root.lens.width, root.lens.height)
    property color tintColor: root.tintColor
    // The wallpaper is shown scaled to cover the screen and centred, the same
    // way the shell's own background draws it.
    property vector4d uvMap: {
      var iw = Math.max(1, backdrop.implicitWidth), ih = Math.max(1, backdrop.implicitHeight)
      var s = Math.max(root.screenWidth / iw, root.screenHeight / ih)
      var dw = iw * s, dh = ih * s
      var ox = (root.screenWidth - dw) / 2, oy = (root.screenHeight - dh) / 2
      return Qt.vector4d((root.screenX - ox) / dw, (root.screenY - oy) / dh, 1 / dw, 1 / dh)
    }
  }
}
