//
//  ViewController.swift
//  CyberSight
//
//  Created by Alfonso Tarallo on 01/04/24.
//

import UIKit
import SceneKit
import ARKit
import RealityKit
import Vision

class ViewController: UIViewController {
    
    var objectDetectionService = ObjectDetectionService()
    let throttler = Throttler(minimumDelay: 1, queue: .global(qos: .userInteractive))
    var isLoopShouldContinue = true
    var lastLocation: SCNVector3?
    var audioController: AudioPlaybackController? = nil
    var audioControllerTwo: AudioPlaybackController? = nil
    var counter: Int = 0
    
    @IBOutlet weak var arView: ARView!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arView.session.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startSession()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopSession()
    }
    
    
    //MARK: FUNCTIONS
    private func startSession(resetTracking: Bool = false) {
        guard ARWorldTrackingConfiguration.isSupported else {
            assertionFailure("ARKit is not supported")
            return
        }
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        if resetTracking {
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        } else {
            arView.session.run(configuration)
        }
    }
    
    func stopSession() {
        arView.session.pause()
    }
    
    func loopObjectDetection() {
        throttler.throttle { [weak self] in
            guard let self = self else { return }
            
            if self.isLoopShouldContinue {
                self.performDetection()
            }
            self.loopObjectDetection()
        }
    }
    
    func performDetection() {
        guard let pixelBuffer = arView.session.currentFrame?.capturedImage else { return }
        
        objectDetectionService.detect(on: .init(pixelBuffer: pixelBuffer)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                let rectOfInterest = VNImageRectForNormalizedRect(
                    response.boundingBox,
                    Int(self.arView.bounds.width),
                    Int(self.arView.bounds.height))
                print(response.classification)
                if response.classification == "person" && counter == 0 {
                    self.addAnnotation(rectOfInterest: rectOfInterest, text: response.classification)
                    counter += 1
                }
                
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    func addAnnotation(rectOfInterest rect: CGRect, text: String) {
        let point = CGPoint(x: rect.midX, y: rect.midY)
        
        let arHitTestResults = arView.hitTest(point)
        
        guard !arHitTestResults.contains(where: { $0.entity.name == "obstacle" }) else { return }
        
        guard let raycastQuery = arView.makeRaycastQuery(from: point, allowing: .existingPlaneInfinite, alignment: .any),
              let raycastResult = arView.session.raycast(raycastQuery).first else { return }
        
        
        let position = SIMD3(raycastResult.worldTransform.columns.3.x,
                                  raycastResult.worldTransform.columns.3.y,
                                  raycastResult.worldTransform.columns.3.z)
        
        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        let material = SimpleMaterial(color: .red, roughness: 0.15, isMetallic: true)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.name = "obstacle"
        model.transform.translation.y = 0.05
        model.generateCollisionShapes(recursive: true)
        arView.installGestures(for: model)
        
        let anchor = AnchorEntity()
        anchor.children.append(model)
        
        arView.scene.anchors.append(anchor)
        anchor.position = position
        
        do {
            if let audioUrl = Bundle.main.url(forResource: "heartBeat", withExtension: "mp3") {
                let resource = try AudioFileResource.load(contentsOf: audioUrl, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: true)
                audioController = model.prepareAudio(resource)
                audioController?.play()
            } else {
                print("Audio URL is nil")
            }
        } catch {
            print("Error loading audio file")
        }
        
    }
    
    private func onSessionUpdate(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        isLoopShouldContinue = false
        
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal and vertical surfaces."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            message = ""
            isLoopShouldContinue = true
            loopObjectDetection()
        }
        
        self.messageLabel.text = message
        self.messageLabel.textColor = .white
        self.messageLabel.backgroundColor = .black.withAlphaComponent(0.6)
        self.messageLabel.isHidden = message.isEmpty
        
    }
}

extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        guard let frame = session.currentFrame else { return }
        onSessionUpdate(for: frame, trackingState: camera.trackingState)
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        onSessionUpdate(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        onSessionUpdate(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let transform = SCNMatrix4(frame.camera.transform)
        let orientation = SCNVector3(-transform.m31, -transform.m32, transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = orientation + location
        
        if let lastLocation = lastLocation {
            let speed = (lastLocation - currentPositionOfCamera).length()
            isLoopShouldContinue = speed < 0.1
        }
        lastLocation = currentPositionOfCamera
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
