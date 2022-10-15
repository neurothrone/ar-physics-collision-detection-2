//
//  Coordinator.swift
//  ARGravity
//
//  Created by Zaid Neurothrone on 2022-10-15.
//

import ARKit
import Combine
import Foundation
import RealityKit

final class Coordinator: NSObject, ARSessionDelegate {
  weak var view: ARView?
  var collisionSubscriptions: [Cancellable] = []

  func buildEnvironment() {
    guard let view = view else { return }
    
    let anchor = AnchorEntity(plane: .horizontal)
    
    let box1 = ModelEntity(mesh: .generateBox(size: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: true)])
    box1.generateCollisionShapes(recursive: true)
    box1.collision = CollisionComponent(shapes: [.generateBox(size: [0.2, 0.2, 0.2])], mode: .trigger, filter: .sensor)
    
    let box2 = ModelEntity(mesh: .generateBox(size: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: true)])
    box2.generateCollisionShapes(recursive: true)
    box2.collision = CollisionComponent(shapes: [.generateBox(size: [0.2, 0.2, 0.2])], mode: .trigger, filter: .sensor)
    box2.position.z = 0.3
    
    let sphere1 = ModelEntity(mesh: .generateSphere(radius: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: true)])
    sphere1.generateCollisionShapes(recursive: true)
    sphere1.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.2)], mode: .trigger, filter: .sensor)
    sphere1.position.x += 0.3
    
    let sphere2 = ModelEntity(mesh: .generateSphere(radius: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: true)])
    sphere2.generateCollisionShapes(recursive: true)
    sphere2.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.2)], mode: .trigger, filter: .sensor)
    sphere2.position.x -= 0.3
    
    anchor.addChild(box1)
    anchor.addChild(box2)
    anchor.addChild(sphere1)
    anchor.addChild(sphere2)
    
    view.scene.addAnchor(anchor)
    
    view.installGestures(.all, for: box1)
    view.installGestures(.all, for: box2)
    view.installGestures(.all, for: sphere1)
    view.installGestures(.all, for: sphere2)
    
    collisionSubscriptions.append(view.scene.subscribe(to: CollisionEvents.Began.self) { event in
      guard let entity1 = event.entityA as? ModelEntity,
            let entity2 = event.entityB as? ModelEntity else { return }
      
      entity1.model?.materials = [SimpleMaterial(color: .purple, isMetallic: true)]
      entity2.model?.materials = [SimpleMaterial(color: .purple, isMetallic: true)]
    })
    
    collisionSubscriptions.append(view.scene.subscribe(to: CollisionEvents.Ended.self) { event in
      guard let entity1 = event.entityA as? ModelEntity,
            let entity2 = event.entityB as? ModelEntity else { return }
      
      entity1.model?.materials = [SimpleMaterial(color: .red, isMetallic: true)]
      entity2.model?.materials = [SimpleMaterial(color: .red, isMetallic: true)]
    })
  }
}
