////
////  SpatialNode.swift
////  CyberSight
////
////  Created by Alfonso Tarallo on 01/04/24.
////
//
//import RealityKit
//import Foundation
//
//class SpatialNode {
//    
//    enum SpatialNodeType: String {
//        case person = "heartBeat"
//        case other = "godsPlan"
//    }
//    
//    static let name = String(describing: SpatialNode.self)
//    
//    var type: SpatialNodeType = .other
//    
//    let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
//    let material = SimpleMaterial(color: .red, roughness: 0.15, isMetallic: true)
//    
//    var model: ModelEntity {
//        ModelEntity(mesh: mesh, materials: [material])
//    }
//    
//    var audioController: AudioPlaybackController? = nil
//    
//    init(type: SpatialNodeType) {
//        self.type = type
//    }
//    
//    func playAudio() {
//        do {
//            if let audioUrl = Bundle.main.url(forResource: self.type.rawValue, withExtension: "mp3") {
//                let resource = try AudioFileResource.load(contentsOf: audioUrl, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: true)
//                audioController = model.prepareAudio(resource)
//            } else {
//                print("Audio URL is nil")
//            }
//        } catch {
//            print("Error loading audio file")
//        }
//        if audioController != nil {
//            audioController?.play()
//        }
//    }
//    
//    deinit {
//        audioController?.pause()
//        audioController = nil
//    }
//}
