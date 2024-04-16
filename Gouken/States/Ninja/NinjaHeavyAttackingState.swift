//
//  NinjaHeavyAttackingState.swift
//  Gouken
//
//  Created by Nathan Dong on 2024-04-01.
//

import Foundation
import GameplayKit

class NinjaHeavyAttackingState: NinjaBaseState {
    var stateMachine: NinjaStateMachine!
    
    let damage: Int = 40
    
    required init(_ stateMachine: NinjaStateMachine) {
        self.stateMachine = stateMachine
    }
    
    func enter() {
        print("enter NinjaHeavyAttackingState")
        stateMachine.character.setState(withState: CharacterState.HeavyAttacking)
        stateMachine.character.animator.changeAnimation(animName: characterAnimations[CharacterName.Ninja]![CharacterState.HeavyAttacking]!, loop: false)
        stateMachine.character.animator.setSpeed(1.5)
        
        // Hardcoded retrieval of move
        let move: CharacterMove = NinjaMoveSet[CharacterState.HeavyAttacking]!
        stateMachine.character.hitbox.damage = self.damage
        move.addAttackKeyFramesAsAnimationEvents(stateMachine: stateMachine)
        
        // Sound effect for attack
        stateMachine.character.animator.addAnimationEvent(keyTime: CGFloat(0.5)) { node, eventData, playingBackward in
            AudioManager.Instance().playEffectSound(audio: AudioDict.HeavyAttack)
        }
    }
    
    // TODO: Turn on hitboxes at certain points
    func tick(_ deltaTime: TimeInterval) {
        if (stateMachine.character.animator.currentTimeNormalized >= 1.0) {
            stateMachine.switchState(stateMachine.stateInstances[CharacterState.Idle]!)
        }
    }
    
    func exit() {
        print("exit NinjaHeavyAttackingState")
        stateMachine.character?.hitbox.deactivateHitboxes()    // Clears hitboxes if attack state disrupted
        stateMachine.character?.hitbox.activateHurtboxes()    // Clears hurtboxes if attack state disrupted
    }
}

