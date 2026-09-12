#!/usr/bin/env swift
import AppKit
import CoreGraphics

let width: CGFloat = 760
let height: CGFloat = 440

func readVersion() -> String {
    let path = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("version.json").path
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let version = json["version"] as? String else { return "?" }
    return version
}

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width),
    pixelsHigh: Int(height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

let background = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        NSColor(calibratedRed: 0.97, green: 0.99, blue: 1.00, alpha: 1).cgColor,
        NSColor(calibratedRed: 0.91, green: 0.97, blue: 0.99, alpha: 1).cgColor,
        NSColor(calibratedRed: 0.96, green: 1.00, blue: 0.98, alpha: 1).cgColor,
    ] as CFArray,
    locations: [0, 0.55, 1]
)!
ctx.drawLinearGradient(
    background,
    start: CGPoint(x: 0, y: height),
    end: CGPoint(x: width, y: 0),
    options: []
)

func fillCircle(center: CGPoint, radius: CGFloat, color: NSColor) {
    ctx.setFillColor(color.cgColor)
    ctx.fillEllipse(in: CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
    ))
}

// Very soft atmosphere, kept away from labels and instructional text.
fillCircle(center: CGPoint(x: 88, y: 372), radius: 130,
           color: NSColor(calibratedRed: 0.55, green: 0.86, blue: 1, alpha: 0.09))
fillCircle(center: CGPoint(x: 700, y: 355), radius: 150,
           color: NSColor(calibratedRed: 0.50, green: 1, blue: 0.82, alpha: 0.08))

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 27, weight: .semibold),
    .foregroundColor: NSColor(calibratedRed: 0.09, green: 0.16, blue: 0.22, alpha: 1),
]
let title = "Установка в два шага" as NSString
let titleSize = title.size(withAttributes: titleAttributes)
title.draw(at: CGPoint(x: (width - titleSize.width) / 2, y: 382), withAttributes: titleAttributes)

let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
    .foregroundColor: NSColor(calibratedRed: 0.31, green: 0.42, blue: 0.49, alpha: 1),
]
let subtitle = "Install in two steps" as NSString
let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
subtitle.draw(at: CGPoint(x: (width - subtitleSize.width) / 2, y: 357), withAttributes: subtitleAttributes)

// Arrow sits between Finder icons. No text is placed near either icon label.
let arrowColor = NSColor(calibratedRed: 0.19, green: 0.62, blue: 0.86, alpha: 0.9)
ctx.setStrokeColor(arrowColor.cgColor)
ctx.setLineWidth(4)
ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: 303, y: 220))
ctx.addCurve(
    to: CGPoint(x: 457, y: 220),
    control1: CGPoint(x: 350, y: 245),
    control2: CGPoint(x: 410, y: 195)
)
ctx.strokePath()
ctx.setFillColor(arrowColor.cgColor)
ctx.move(to: CGPoint(x: 465, y: 220))
ctx.addLine(to: CGPoint(x: 444, y: 235))
ctx.addLine(to: CGPoint(x: 449, y: 210))
ctx.closePath()
ctx.fillPath()

let dragAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
    .foregroundColor: NSColor(calibratedRed: 0.16, green: 0.49, blue: 0.67, alpha: 1),
    .kern: 1.0,
]
let drag = "ПЕРЕТАЩИТЕ  ·  DRAG" as NSString
let dragSize = drag.size(withAttributes: dragAttributes)
drag.draw(at: CGPoint(x: (width - dragSize.width) / 2, y: 173), withAttributes: dragAttributes)

// Dedicated instruction panel below the Finder labels. This closes the user path:
// copying an app does not launch it, so the second action must be explicit.
let cardRect = CGRect(x: 42, y: 12, width: width - 84, height: 96)
let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 18, yRadius: 18)
NSColor(calibratedWhite: 1, alpha: 0.86).setFill()
cardPath.fill()
NSColor(calibratedRed: 0.68, green: 0.84, blue: 0.90, alpha: 0.75).setStroke()
cardPath.lineWidth = 1
cardPath.stroke()

let instructionAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .medium),
    .foregroundColor: NSColor(calibratedRed: 0.10, green: 0.18, blue: 0.23, alpha: 1),
]
let mutedAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 11, weight: .regular),
    .foregroundColor: NSColor(calibratedRed: 0.36, green: 0.45, blue: 0.50, alpha: 1),
]
("1. Перетащите LocalSwitcher в Applications" as NSString)
    .draw(at: CGPoint(x: 66, y: 72), withAttributes: instructionAttributes)
("2. Затем откройте LocalSwitcher из папки «Программы»" as NSString)
    .draw(at: CGPoint(x: 66, y: 47), withAttributes: instructionAttributes)
("Если macOS предупредит: Control-клик по приложению → «Открыть»" as NSString)
    .draw(at: CGPoint(x: 66, y: 24), withAttributes: mutedAttributes)
let version = "v\(readVersion())  ·  macOS 13+  ·  Apple Silicon" as NSString
let versionSize = version.size(withAttributes: mutedAttributes)
version.draw(at: CGPoint(x: width - versionSize.width - 18, y: 414), withAttributes: mutedAttributes)

NSGraphicsContext.current = nil
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg_background.png"
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outputPath))
print("Generated: \(outputPath) (\(Int(width))x\(Int(height)))")
