//
//  PlayerEntity.swift
//  Gouken
//
//  Created by Sepehr Mansouri on 2024-02-18.
//

import GameplayKit
import Foundation

// Character List
enum CharacterName {
    case Ninja
}

let characterNameString = [
    CharacterName.Ninja : "Ninja"
]

// Character player side
enum PlayerType {
    case P1
    case P2
    case AI // stretch goal for Fatal Fury / Golden Axe mode
}

// States that characters can go into
enum CharacterState : String, Codable {
    case Stunned
    case Running
    case Attacking
    case Idle
    case Jumping
    case Blocking
    case Downed
}

class Character {
    
    var entity            : GKEntity = GKEntity() // composition over inheritance :^)
    var characterNode     : SCNNode
    var characterName     : CharacterName
    var characterMesh     : SCNNode
    var playerSide        : PlayerType
    var state             : CharacterState
    var animator          : AnimatorComponent
    var stateMachine      : CharacterStateMachine?
    var health            : HealthComponent
    
    init(withName name : CharacterName, underParentNode parentNode: SCNNode, onPSide side: PlayerType, components : [GKComponent] = [], withManager : EntityManager) {
           characterMesh = SCNScene(named: characterModels[name]!)!.rootNode.childNode(withName: characterNameString[name]!, recursively: true)!
           playerSide = side
        characterMesh = SCNScene(named: characterModels[name]!)!.rootNode.childNode(withName: characterNameString[name]!, recursively: true)!
        playerSide = side
        
        parentNode.addChildNode(characterMesh)
        characterNode = parentNode.childNodes[parentNode.childNodes.count - 1]
        characterName = name
        
        // The following code adds individual Components for our Character Entity
        let movementComponent = MovementComponent(onSide: side)
        entity.addComponent(movementComponent)
        
        // Add Animator Component
        animator = AnimatorComponent(character: characterNode, defaultAnimName: characterAnimations[CharacterName.Ninja]![CharacterState.Idle]!, loop: true)
        entity.addComponent(animator)
        
        // Add Health Component
        health = HealthComponent(maxHealth: 100)
        entity.addComponent(health)
        
        for component in components {
            entity.addComponent(component)
        }

        state = CharacterState.Idle
        
        withManager.addEntity(entity)
    }
    
    func update(deltaTime seconds : TimeInterval) {
        entity.update(deltaTime: seconds)
    }
    
    func setState(withState: CharacterState) {
        state = withState
    }
    
    func setupStateMachine(withStateMachine: CharacterStateMachine) {
        if (stateMachine == nil) {
            stateMachine = withStateMachine
            entity.addComponent(stateMachine!)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
