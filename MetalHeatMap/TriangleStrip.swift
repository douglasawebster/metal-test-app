//
//  TriangleStrip.swift
//  MetalHeatMap
//
//  Created by Douglas Webster on 8/4/20.
//  Copyright © 2020 Douglas Webster. All rights reserved.
//

import Foundation
import UIKit
import MetalKit

class TriangleStripViewController: UIViewController { 
    
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
            
            renderer = Renderer2(mtkView: metalView)
            metalView?.delegate = renderer
            
            self.view.addSubview(metalView)
        
        }
        
        private var metalView: MTKView!
        private var device: MTLDevice!
        private var renderer: Renderer2!
    
}


class Renderer2: NSObject, MTKViewDelegate {
    
    init?(mtkView: MTKView) {
        device = mtkView.device!
        commandQueue = device.makeCommandQueue()!
        
        do {
            pipelineState = try Renderer.buildRenderPipelineWith(device: device, metalKitView: mtkView)
        } catch {
            print("Unable to compile render pipeline state: \(error)")
            return nil
        }
        
        
        
        let rows: Int = 200
        let cols: Int = 100
        
        /*
         * Metal Coordinate Plane
         * (-1,1)--------------(1,1)
         *    |                  |
         *    |       (0,0)      |
         *    |                  |
         * (-1,-1)-------------(1,-1)
         */
        let width: Float = 2.0 / Float(cols)
        let height: Float = 2.0 / Float(rows)
        
        for row in 0..<(rows+1) {
            
            let y: Float = (-1 * (height * Float(row))) + 1
            
            for col in 0..<(cols+1) {
                let x: Float = (width * Float(col)) - 1
                
                let pos: vector_float2 = [x,y]
                
                let color: vector_float4 = [0, 0, 0, 1]
                
                let vertex: Vertex = Vertex(pos: pos, color: color)
                
                vertexData.append(vertex)
            }
        }
        
        let dataSize = vertexData.count * MemoryLayout<Vertex>.stride
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
        renderEncoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexData.count)
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
