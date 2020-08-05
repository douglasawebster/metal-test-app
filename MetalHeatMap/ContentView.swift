//
//  ContentView.swift
//  MetalHeatMap
//
//  Created by Douglas Webster on 7/31/20.
//  Copyright © 2020 Douglas Webster. All rights reserved.
//  https://donaldpinckney.com/metal/2018/07/05/metal-intro-1.html

import UIKit
import Metal
import MetalKit
import QuartzCore

class ContentViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        device = MTLCreateSystemDefaultDevice()
        
        metalLayer = CAMetalLayer()
        metalLayer?.device = device
        metalLayer?.pixelFormat = .bgra8Unorm
        metalLayer?.framebufferOnly = true
        metalLayer?.frame = view.layer.frame
        
        if let layer = metalLayer {
            view.layer.addSublayer(layer)
        }
        
        let dataSize = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device?.makeBuffer(bytes: vertexData, length: dataSize, options: .storageModeShared)
        
        let defaultLibrary = device?.makeDefaultLibrary()
        let fragmentProgram = defaultLibrary?.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary?.makeFunction(name: "basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            try pipelineState = device?.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            print("Failed to create pipeline state, erroe \(error)")
        }
        
        commandQueue = device?.makeCommandQueue()
        
        timer = CADisplayLink(target: self, selector: #selector(ContentViewController.loop))
        timer?.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
        
    }
    
    private var mtkView: MTKView? = nil
    
    /**
     To interact with the GPU, you need to create a software interface for it
     This interface is the MTLDevice protocol
    */
    private var device: MTLDevice? = nil
    
    private var metalLayer: CAMetalLayer? = nil
    
    private var vertexBuffer: MTLBuffer? = nil
    
    private var pipelineState: MTLRenderPipelineState? = nil
    
    private var commandQueue: MTLCommandQueue? = nil
    
    /*private let vertexData: [Float] = [0.0, 0.5, 0.0,
                                       -0.5, -0.5, 0.0,
                                       0.5, -0.5, 0.0]*/
    
    private let vertexData: [Float] = [-0.5, 0.5, 0.0,
                                       -0.5, -0.5, 0.0,
                                       0.5, -0.5, 0.0,
                                       0.0, 0.5, 0.0,
                                       0.5, 0.5, 0.0,
                                       0.5, -0.3, 0.0]
    
    var timer: CADisplayLink? = nil
    
    private func render() {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        guard let drawable = metalLayer?.nextDrawable() else { return }
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 221.0/255.0, green: 160.0/255.0, blue: 221.0/255.0, alpha: 1.0)
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(pipelineState!)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexData.count)
        renderEncoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    
    @objc func loop() {
        autoreleasepool {
            self.render()
        }
    }
    
}

class ContentViewController2: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        
        metalView = MTKView()
        metalView.device = device
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.framebufferOnly = true
        metalView.frame = view.frame
        
        renderer = Renderer(mtkView: metalView)
        metalView?.delegate = renderer
        
        self.view.addSubview(metalView)
    
    }
    
    private var metalView: MTKView!
    private var device: MTLDevice!
    private var renderer: Renderer!
    
}

class Renderer: NSObject, MTKViewDelegate {
    
    init?(mtkView: MTKView) {
        device = mtkView.device!
        commandQueue = device.makeCommandQueue()!
        
        do {
            pipelineState = try Renderer.buildRenderPipelineWith(device: device, metalKitView: mtkView)
        } catch {
            print("Unable to compile render pipeline state: \(error)")
            return nil
        }
        
        let xSpace: Float = 2
        let ySpace: Float = 2
        for row in 0..<100 {

            for col in 0..<200 {
                let v1: vector_float2 = [(xSpace/200)*Float(col) - 1, (-1*(ySpace/100)*Float(row)) + 1]
                let v2: vector_float2 = [(xSpace/200)*Float(col) - 1, (-1*(((ySpace/100)*Float(row)) + (ySpace/100))) + 1]
                let v3: vector_float2 = [((xSpace/200)*Float(col)) + (xSpace/200) - 1, (-1*(ySpace/100)*Float(row)) + 1]
                
                let v4: vector_float2 = [(xSpace/200)*Float(col) - 1, (-1*(((ySpace/100)*Float(row)) + (ySpace/100))) + 1]
                let v5: vector_float2 = [((xSpace/200)*Float(col)) + (xSpace/200) - 1, (-1*(ySpace/100)*Float(row)) + 1]
                let v6: vector_float2 = [((xSpace/200)*Float(col)) + (xSpace/200) - 1, (-1*(((ySpace/100)*Float(row)) + (ySpace/100))) + 1]
                
                vertexData.append(Vertex(pos: v1, color: [0.5,0.3,0.5,1]))
                vertexData.append(Vertex(pos: v2, color: [0.5,0.3,0.5,1]))
                vertexData.append(Vertex(pos: v3, color: [0.5,0.3,0.5,1]))
                vertexData.append(Vertex(pos: v4, color: [0.5,0.3,0.5,1]))
                vertexData.append(Vertex(pos: v5, color: [0.5,0.3,0.5,1]))
                vertexData.append(Vertex(pos: v6, color: [0.5,0.3,0.5,1]))
                
            }

        }
        
        let dataSize = vertexData.count * MemoryLayout<Vertex>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: .storageModeShared)
    }
    
    class func buildRenderPipelineWith(device: MTLDevice, metalKitView: MTKView) throws -> MTLRenderPipelineState {
        let defaultLibrary = device.makeDefaultLibrary()
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertex_shader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragment_shader")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        // renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 0, blue: 0, alpha: 1)
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexData.count)
        renderEncoder?.endEncoding()
        
        commandBuffer?.present(view.currentDrawable!)
        commandBuffer?.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    private var device: MTLDevice
    private var commandQueue: MTLCommandQueue
    private var vertexBuffer: MTLBuffer? = nil
    private let pipelineState: MTLRenderPipelineState
    
    private var vertexData = [Vertex]()
}

