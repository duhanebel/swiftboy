//
//  Renderer.swift
//  oiuhygtfg
//
//  Created by Fabio Gallonetto on 18/12/2020.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

class Renderer: NSObject, MTKViewDelegate {

    public let device: MTLDevice
    var pipelineState: MTLRenderPipelineState
    let commandQueue: MTLCommandQueue
    var texture: MTLTexture? = nil
    var vertices: MTLBuffer?
    
    let numVertices: Int
    
    var viewPortSize: vector_uint2
    
    let width = 160
    let height = 144
    let originalRatio: Float = 160/144
    
    var ratio: Float = 4.0
    
    let buffer: UnsafeMutablePointer<UInt8>
    var bytes: UnsafeRawPointer { UnsafeRawPointer(buffer) }

    deinit {
        buffer.deallocate()
    }
    
    lazy var textureDescriptor: MTLTextureDescriptor = {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.width = width
        textureDescriptor.height = height
        return textureDescriptor
    }()
    
    lazy var textures: [MTLTexture] = {
        return [device.makeTexture(descriptor: textureDescriptor)!,
                device.makeTexture(descriptor: textureDescriptor)!,
                device.makeTexture(descriptor: textureDescriptor)!]
    }()
    
    lazy var region: MTLRegion = {
        MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                  size: MTLSize(width: width, height: height, depth: 1))
    }()
    
    func loadTexture() -> MTLTexture? {
        
        let texture = textures[0]
        
        texture.replace(region: region,
                        mipmapLevel: 0,
                        withBytes: bytes,
                        bytesPerRow: 4*width)
        return texture
    }
    
    func updateTexture(bytes: [UInt8]) {
        bytes.withUnsafeBytes { newBytes in
            textures[0].replace(region: region,
                                mipmapLevel: 0,
                                withBytes: newBytes.baseAddress!,
                                bytesPerRow: 4*width)
        }
    }
    
    init?(metalKitView: MTKView) {
        self.viewPortSize = vector_uint2(UInt32(width), UInt32(height))
        self.buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: width*height*4)
        
        self.device = metalKitView.device!
        self.commandQueue = self.device.makeCommandQueue()!
        let midPointX = ratio * Float(width) / 2.0
        let midPointY = ratio * Float(height) / 2.0

        let qVertices: [AAPLVertex] = [AAPLVertex(position: vector_float2([midPointX, -midPointY]),
                                                  textureCoordinate: vector_float2([1.0, 1.0])),
                                       AAPLVertex(position: vector_float2([-midPointX, -midPointY]),
                                                  textureCoordinate: vector_float2([0.0, 1.0])),
                                       AAPLVertex(position: vector_float2([-midPointX, midPointY]),
                                                  textureCoordinate: vector_float2([0.0, 0.0])),
                                       AAPLVertex(position: vector_float2([midPointX, -midPointY]),
                                                  textureCoordinate: vector_float2([1.0, 1.0])),
                                       AAPLVertex(position: vector_float2([-midPointX, midPointY]),
                                                  textureCoordinate: vector_float2([0.0, 0.0])),
                                       AAPLVertex(position: vector_float2([midPointX, midPointY]),
                                                  textureCoordinate: vector_float2([1.0, 0.0])),
        ]
        
        vertices = device.makeBuffer(bytes: qVertices,
                                     length: MemoryLayout<AAPLVertex>.size * qVertices.count,
                                     options: .storageModeShared)
        
        numVertices = qVertices.count
        
        let library = device.makeDefaultLibrary()
        let vertexFunc = library?.makeFunction(name: "vertexShader")
        let fragmentFunc = library?.makeFunction(name: "samplingShader")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "Texturing pipeline"
        pipelineStateDescriptor.vertexFunction = vertexFunc!
        pipelineStateDescriptor.fragmentFunction = fragmentFunc!
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            print("Unable to compile render pipeline state.  Error info: \(error)")
            return nil
        }
        
        super.init()
        self.texture = loadTexture()
    }
    
    func updateVertices() {
        let midPointX = ratio * Float(width) / 2.0
        let midPointY = ratio * Float(height) / 2.0
        
        let qVertices: [AAPLVertex] = [AAPLVertex(position: vector_float2([midPointX, -midPointY]),
                                                  textureCoordinate: vector_float2([1.0, 1.0])),
                                       AAPLVertex(position: vector_float2([-midPointX, -midPointY]),
                                                  textureCoordinate: vector_float2([0.0, 1.0])),
                                       AAPLVertex(position: vector_float2([-midPointX, midPointY]),
                                                  textureCoordinate: vector_float2([0.0, 0.0])),
                                       AAPLVertex(position: vector_float2([midPointX, -midPointY]),
                                                  textureCoordinate: vector_float2([1.0, 1.0])),
                                       AAPLVertex(position: vector_float2([-midPointX, midPointY]),
                                                  textureCoordinate: vector_float2([0.0, 0.0])),
                                       AAPLVertex(position: vector_float2([midPointX, midPointY]),
                                                  textureCoordinate: vector_float2([1.0, 0.0])),
        ]
        
        vertices = device.makeBuffer(bytes: qVertices,
                                     length: MemoryLayout<AAPLVertex>.size * qVertices.count,
                                     options: .storageModeShared)
    }

 
//
//    class func buildRenderPipelineWithDevice(device: MTLDevice,
//                                             metalKitView: MTKView,
//                                             mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
//        /// Build a render state pipeline object
//
//        let library = device.makeDefaultLibrary()
//
//        let vertexFunction = library?.makeFunction(name: "vertexShader")
//        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
//
//        let pipelineDescriptor = MTLRenderPipelineDescriptor()
//        pipelineDescriptor.label = "RenderPipeline"
//        pipelineDescriptor.sampleCount = metalKitView.sampleCount
//        pipelineDescriptor.vertexFunction = vertexFunction
//        pipelineDescriptor.fragmentFunction = fragmentFunction
//        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
//
//        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
//        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
//        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
//
//        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
//    }

//
//    class func loadTexture(device: MTLDevice,
//                           textureName: String) throws -> MTLTexture {
//        /// Load texture data with optimal parameters for sampling
//
//        let textureLoader = MTKTextureLoader(device: device)
//
//        let textureLoaderOptions = [
//            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
//            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
//        ]
//
//        return try textureLoader.newTexture(name: textureName,
//                                            scaleFactor: 1.0,
//                                            bundle: nil,
//                                            options: textureLoaderOptions)
//
//    }

    func draw(in view: MTKView) {
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer?.label = "ScreenDraw"
        
        if let renderPassDescriptor = view.currentRenderPassDescriptor {
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            renderEncoder?.label = "ScreenDrawEncoder"
            
            renderEncoder?.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewPortSize.x), height: Double(viewPortSize.y), znear: -1.0, zfar: 1.0))

            renderEncoder?.setRenderPipelineState(pipelineState)
            renderEncoder?.setVertexBuffer(vertices, offset: 0, index: Int(VertexInputTypeVertices.rawValue))
            
            renderEncoder?.setVertexBytes(&viewPortSize, length: MemoryLayout.size(ofValue: viewPortSize), index: Int(VertexInputTypeViewportSize.rawValue))
            
            renderEncoder?.setFragmentTexture(texture, index: Int(TextureIndexTypeBaseColor.rawValue))
            
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVertices)
            renderEncoder?.endEncoding()
            commandBuffer?.present(view.currentDrawable!)
        }
        
        commandBuffer?.commit()
    }
     
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewPortSize.x = UInt32(size.width)
        viewPortSize.y = UInt32(size.height)
        
        if Float(size.width) / Float(size.height) > originalRatio {
            ratio = Float(size.height) / Float(height)
        } else {
            ratio = Float(size.width) / Float(width)
        }
        
        updateVertices()
    }
}
