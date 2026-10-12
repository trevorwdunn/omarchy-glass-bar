import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Glass Bar: paints liquid glass behind the whole bar.
//
// The widget itself takes no room. It reaches up to the bar's window and puts
// a GlassSurface underneath everything else in it. The bar reserves its own
// strip of the screen, so the only thing ever behind it is the wallpaper, and
// a lined-up copy of the wallpaper can stand in for "what is behind".
//
// Controlled from Hypr Controls > Liquid Glass (or: omabar-glass on|off).
BarWidget {
  id: root
  moduleName: "trevor.glass"

  implicitWidth: 0
  implicitHeight: 0

  property string wallpaper: ""
  property var surface: null

  readonly property var win: root.QsWindow.window
  readonly property string position: bar && bar.position ? String(bar.position) : "top"

  Process {
    id: readlinkProc
    command: ["readlink", "-f", Quickshell.env("HOME") + "/.local/state/omarchy/current/background"]
    stdout: StdioCollector {
      onStreamFinished: {
        var path = String(text || "").trim()
        if (path && path !== root.wallpaper) root.wallpaper = path
      }
    }
  }

  // The shell switches wallpaper by re-pointing a symlink; there is nothing
  // to subscribe to from here, so look again every few seconds.
  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!readlinkProc.running) readlinkProc.running = true
  }

  Component {
    id: surfaceComponent

    GlassSurface {
      readonly property var scr: root.win ? root.win.screen : null

      anchors.fill: parent
      z: -1
      // Off leaves the bar to the shell's own background (the frosted look).
      visible: root.setting("glass", true) === true && ready
      wallpaper: root.wallpaper
      screenWidth: scr ? scr.width : 1920
      screenHeight: scr ? scr.height : 1080
      pixelRatio: scr ? scr.devicePixelRatio : 1
      screenX: root.position === "right" ? screenWidth - width : 0
      screenY: root.position === "bottom" ? screenHeight - height : 0
      // Hang the ends off-screen so only the long edges bend, like a rod.
      lens: root.vertical ? Qt.rect(0, -80, width, height + 160) : Qt.rect(-80, 0, width + 160, height)
      bezel: 1
      curvature: 2.5
      refraction: Number(root.setting("refraction", 0))
      chroma: Number(root.setting("chroma", 0.2))
      specular: Number(root.setting("specular", 0))
      specularWidth: 1.5
      tintColor: "black"
      tint: Number(root.setting("tint", 0))
    }
  }

  // Bold bar text. The shell has no font-weight setting and every widget
  // styles its own labels, so this walks the bar's items (and the drop-downs
  // that hang off them) and switches their text to bold. Icon glyphs are left
  // alone. Widgets load lazily and drop-downs are built on first open, hence
  // the repeat.
  readonly property bool boldText: setting("boldText", true) === true

  function isIconText(str) {
    if (!str.length) return true
    for (var i = 0; i < str.length; i++) {
      var c = str.charCodeAt(i)
      if (c > 0x20 && c < 0x2000) return false
    }
    return true
  }

  function embolden(item, depth) {
    if (!item || depth > 40) return
    try {
      if (item.font !== undefined && typeof item.text === "string" && !item.font.bold && !isIconText(item.text))
        item.font.bold = true
    } catch (e) {}
    var kids = item.data
    if (!kids) return
    for (var i = 0; i < kids.length; i++) {
      var k = kids[i]
      if (!k) continue
      // Drop-downs are windows owned by a widget, not child items.
      if (k.contentItem !== undefined && k.contentItem) embolden(k.contentItem, depth + 1)
      else if (k.data !== undefined) embolden(k, depth + 1)
    }
  }

  Timer {
    interval: 1200
    running: root.boldText && root.win !== null
    repeat: true
    triggeredOnStart: true
    onTriggered: if (root.win && root.win.contentItem) root.embolden(root.win.contentItem, 0)
  }

  function attach() {
    if (surface || !win || !win.contentItem) return
    surface = surfaceComponent.createObject(win.contentItem)
  }

  onWinChanged: attach()
  Component.onCompleted: Qt.callLater(attach)
  Component.onDestruction: if (surface) surface.destroy()
}
