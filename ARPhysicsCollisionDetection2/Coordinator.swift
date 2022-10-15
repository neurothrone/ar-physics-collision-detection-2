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
  
  let boxGroup = CollisionGroup(rawValue: 1 << 0)
  let sphereGroup = CollisionGroup(rawValue: 1 << 1)
  
  var movableEntities: [ModelEntity] = []

  func buildEnvironment() {
    guard let view = view else { return }
    
    let anchor = AnchorEntity(plane: .horizontal)
    
    // Create a floor
    let floor = ModelEntity(mesh: .generatePlane(width: 2, depth: 2), materials: [SimpleMaterial(color: .brown, isMetallic: true)])
    floor.generateCollisionShapes(recursive: true)
    floor.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
    
    // Create masks
    let boxMask = CollisionGroup.all.subtracting(sphereGroup)
    let sphereMask = CollisionGroup.all.subtracting(boxGroup)
    
    // Boxes will only collide with spheres and vice versa
//    let boxMask = CollisionGroup.all.subtracting(boxGroup)
//    let sphereMask = CollisionGroup.all.subtracting(sphereGroup)
    
    let box1 = ModelEntity(mesh: .generateBox(size: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: true)])
    box1.generateCollisionShapes(recursive: true)
    box1.collision = CollisionComponent(
      shapes: [.generateBox(size: [0.2, 0.2, 0.2])],
      mode: .trigger,
      filter: .sensor
//      filter: .init(group: boxGroup, mask: boxMask)
    )
    box1.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
    box1.position.y = 0.3
    
    let box2 = ModelEntity(mesh: .generateBox(size: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: true)])
    box2.generateCollisionShapes(recursive: true)
    box2.collision = CollisionComponent(
      shapes: [.generateBox(size: [0.2, 0.2, 0.2])],
      mode: .trigger,
      filter: .sensor
//      filter: .init(group: boxGroup, mask: boxMask)
    )
    box2.position.z = 0.3
    box2.position.y = 0.3
    box2.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
    
    let sphere1 = ModelEntity(mesh: .generateSphere(radius: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: true)])
    sphere1.generateCollisionShapes(recursive: true)
    sphere1.collision = CollisionComponent(
      shapes: [.generateSphere(radius: 0.2)],
      mode: .trigger,
      filter: .sensor
//      filter: .init(group: sphereGroup, mask: sphereMask)
    )
    sphere1.position.x += 0.3
    sphere1.position.y = 0.3
    sphere1.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
    
    let sphere2 = ModelEntity(mesh: .generateSphere(radius: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: true)])
    sphere2.generateCollisionShapes(recursive: true)
    sphere2.collision = CollisionComponent(
      shapes: [.generateSphere(radius: 0.2)],
      mode: .trigger,
      filter: .sensor
//      filter: .init(group: sphereGroup, mask: sphereMask)
    )
    sphere2.position.x -= 0.3
    sphere2.position.y = 0.3
    sphere2.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
    
    /* Change color on collisions
     
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
     */
    
    // Physics on collisions
    movableEntities.append(box1)
    movableEntities.append(box2)
    movableEntities.append(sphere1)
    movableEntities.append(sphere2)
    
    movableEntities.forEach { entity in
      view.installGestures(.all, for: entity).forEach { entityGestureDelegate in
        entityGestureDelegate.delegate = self
      }
    }
    
    anchor.addChild(box1)
    anchor.addChild(box2)
    anchor.addChild(sphere1)
    anchor.addChild(sphere2)
    anchor.addChild(floor)
    view.scene.addAnchor(anchor)
    
    setUpGestures()
  }
  
  fileprivate func setUpGestures() {
    guard let view = view else { return }
    
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panned))
    panGesture.delegate = self
    view.addGestureRecognizer(panGesture)
  }
  
  @objc func panned(_ sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .ended, .cancelled, .failed:
      // Change the physics mode to dynamic
      // First get all non-null entities
      movableEntities.compactMap { $0 }.forEach { entity in
        entity.physicsBody?.mode = .dynamic
      }
    default:
      return
    }
  }
}

extension Coordinator: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let translationGesture = gestureRecognizer as? EntityTranslationGestureRecognizer,
          let entity = translationGesture.entity as? ModelEntity else {
      return true
    }
    
    entity.physicsBody?.mode = .kinematic
    return true
  }
}
