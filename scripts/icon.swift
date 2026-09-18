import AppKit
let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        let context = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = context
        let cg = context.cgContext
        cg.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
        cg.setFillColor(NSColor(calibratedRed: 0.09, green: 0.13, blue: 0.14, alpha: 1).cgColor)
        cg.addPath(CGPath(roundedRect: CGRect(x: 60, y: 60, width: 904, height: 904), cornerWidth: 210, cornerHeight: 210, transform: nil)); cg.fillPath()
        cg.setStrokeColor(NSColor(calibratedRed: 0.6, green: 0.87, blue: 0.73, alpha: 0.45).cgColor); cg.setLineWidth(43)
        cg.addPath(CGPath(roundedRect: CGRect(x: 264, y: 354, width: 385, height: 385), cornerWidth: 72, cornerHeight: 72, transform: nil)); cg.strokePath()
        cg.setFillColor(NSColor(calibratedRed: 0.09, green: 0.13, blue: 0.14, alpha: 1).cgColor)
        cg.setStrokeColor(NSColor(calibratedRed: 0.6, green: 0.87, blue: 0.73, alpha: 1).cgColor)
        cg.addPath(CGPath(roundedRect: CGRect(x: 384, y: 239, width: 385, height: 385), cornerWidth: 72, cornerHeight: 72, transform: nil)); cg.drawPath(using: .fillStroke)
        NSGraphicsContext.restoreGraphicsState()
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try rep.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(name))
    }
}
