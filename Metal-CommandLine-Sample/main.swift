//
//  main.swift
//  Metal-CommandLine-Sample
//
//  Created by Safx Developer on 2015/06/19.
//  Copyright © 2015 Safx Developers. All rights reserved.
//

import Cocoa
import Metal
import MetalKit

func saveImage(image: CGImage, path: String) {
    let rep = NSBitmapImageRep(CGImage: image)
    rep.size = CGSize(width: CGImageGetWidth(image), height: CGImageGetHeight(image))

    guard let data = rep.representationUsingType(.NSPNGFileType, properties: [:]) else {
        fatalError()
    }
    data.writeToFile(path, atomically: true)
}

func createImage(texture: MTLTexture) -> CGImage? {
    let width = texture.width
    let height = texture.height
    let rowBytes = width * 4

    var buf = Array<UInt8>(count: rowBytes * height, repeatedValue: 0)
    let region = MTLRegionMake2D(0, 0, width, height)
    texture.getBytes(&buf, bytesPerRow: rowBytes, fromRegion: region, mipmapLevel: 0)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGBitmapContextCreate(&buf, width, height, 8, rowBytes, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)

    return CGBitmapContextCreateImage(context)
}

func createEmptyTexture(device: MTLDevice, width: Int, height: Int) -> MTLTexture {
    let desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, width: width, height: height, mipmapped: false)
    return device.newTextureWithDescriptor(desc)
}

func grayScale(url: NSURL) throws -> MTLTexture {
    let device = MTLCreateSystemDefaultDevice()!
    let library = device.newDefaultLibrary()!
    let queue = device.newCommandQueue()

    let kernel = library.newFunctionWithName("grayscale")!
    let pipelineState = try! device.newComputePipelineStateWithFunction(kernel)

    let loader = MTKTextureLoader(device: device)
    let inTexture = try! loader.newTextureWithContentsOfURL(url, options: nil)
    let width  = inTexture.width
    let height = inTexture.height
    let outTexture = createEmptyTexture(device, width: width, height: height)

    let commandBuf = queue.commandBuffer()

    do {
        let encoder = commandBuf.computeCommandEncoder()
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(inTexture, atIndex: 0)
        encoder.setTexture(outTexture, atIndex: 1)

        let threadsPerThreadgroup = MTLSize(width: 32, height: 16, depth: 1)
        let numGroups = MTLSize(width: 1 + width / threadsPerThreadgroup.width,
                               height: 1 + height / threadsPerThreadgroup.height, depth: 1)
        encoder.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
    }

    do {
        let encoder = commandBuf.blitCommandEncoder()
        encoder.synchronizeResource(outTexture)
        encoder.endEncoding()
    }

    commandBuf.commit()
    commandBuf.waitUntilCompleted()

    if let err = commandBuf.error {
        fatalError("MetalExecutionError: " + err.description)
    }

    return outTexture
}

if Process.arguments.count >= 2 {
    let outTexture = try! grayScale(NSURL(fileURLWithPath: Process.arguments[1]))
    if let image = createImage(outTexture) {
        saveImage(image, path: "out.png")
    } else {
        print("Image creation failed")
    }
}
