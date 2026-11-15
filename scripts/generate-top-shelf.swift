#!/usr/bin/env swift
// generate-top-shelf.swift
//
// Renders the tvOS Top Shelf images (standard 1920x720 and wide 2320x720,
// @1x and @2x) per DESIGN.md: Library Charcoal canvas, white SF Pro type,
// no accent color. Uses AppKit so the real system font is used.
//
// Usage (from the repo root):
//   swift scripts/generate-top-shelf.swift
// Writes directly into the brandassets Top Shelf imagesets.
import AppKit

let brand = "Internet Archive/Asses.xcassets/App Icon & Top Shelf Image.brandassets"
let logoPath = "\(brand)/App Icon - Large.imagestack/Front.imagestacklayer/Content.imageset/app_icon_large_front@1x.png"
guard let logo = NSImage(contentsOfFile: logoPath) else {
    fatalError("Logo not found at \(logoPath); run from the repo root")
}
let outDirs = ["top_shelf_wide": "\(brand)/Top Shelf Image Wide.imageset",
               "top_shelf": "\(brand)/Top Shelf Image.imageset"]

// Logo artwork bounds inside the 1280x768 front layer (top-left origin)
let logoSrc = NSRect(x: 330, y: 768 - 80 - 605, width: 625, height: 605)

func render(width: CGFloat, height: CGFloat = 720, scale: CGFloat, name: String) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(width * scale), pixelsHigh: Int(height * scale),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Canvas: Library Charcoal with a neutral "reading lamp" glow (lightness only)
    NSColor(srgbRed: 0.133, green: 0.133, blue: 0.133, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    let logoH: CGFloat = 400
    let logoW = logoH * logoSrc.width / logoSrc.height
    let gap: CGFloat = 96
    let headline = "Films, television, music\nand live concerts"
    let headFont = NSFont.systemFont(ofSize: 92, weight: .bold)
    let subFont = NSFont.systemFont(ofSize: 40, weight: .medium)
    let headPara = NSMutableParagraphStyle(); headPara.lineHeightMultiple = 0.95
    let headAttrs: [NSAttributedString.Key: Any] = [
        .font: headFont, .foregroundColor: NSColor.white, .paragraphStyle: headPara, .kern: -1.0]
    let subAttrs: [NSAttributedString.Key: Any] = [
        .font: subFont, .foregroundColor: NSColor.white.withAlphaComponent(0.6)]
    let head = NSAttributedString(string: headline, attributes: headAttrs)
    let sub = NSAttributedString(string: "Free from the public library of the internet", attributes: subAttrs)
    let headSize = head.size(), subSize = sub.size()
    let textW = max(headSize.width, subSize.width)
    let textH = headSize.height + 28 + subSize.height

    let x0 = (width - (logoW + gap + textW)) / 2
    let logoY = (height - logoH) / 2
    let center = NSPoint(x: x0 + logoW / 2, y: height / 2)

    let glow = NSGradient(colors: [
        NSColor(white: 0.24, alpha: 1), NSColor(white: 0.15, alpha: 1), NSColor(white: 0.11, alpha: 1)],
        atLocations: [0, 0.5, 1], colorSpace: .deviceGray)!
    glow.draw(fromCenter: center, radius: 0, toCenter: center, radius: width * 0.55, options: [.drawsAfterEndingLocation])

    logo.draw(in: NSRect(x: x0, y: logoY, width: logoW, height: logoH),
              from: logoSrc, operation: .sourceOver, fraction: 1)

    // Hairline divider (chromeOutline weight, quieter)
    NSColor.white.withAlphaComponent(0.18).setFill()
    NSRect(x: x0 + logoW + gap / 2 - 1, y: logoY + 40, width: 2, height: logoH - 80).fill()

    let tx = x0 + logoW + gap
    let ty = (height - textH) / 2
    sub.draw(at: NSPoint(x: tx + 3, y: ty))
    head.draw(at: NSPoint(x: tx, y: ty + subSize.height + 28))

    NSGraphicsContext.restoreGraphicsState()
    let png = rep.representation(using: .png, properties: [:])!
    let outDir = outDirs[name] ?? "."
    do {
        try png.write(to: URL(fileURLWithPath: "\(outDir)/\(name)@\(Int(scale))x.png"))
    } catch {
        fatalError("Failed to write \(name): \(error)")
    }
    print("\(name)@\(Int(scale))x.png", rep.pixelsWide, "x", rep.pixelsHigh)
}

for (name, w) in [("top_shelf_wide", CGFloat(2320)), ("top_shelf", CGFloat(1920))] {
    for s in [CGFloat(1), CGFloat(2)] { render(width: w, scale: s, name: name) }
}
