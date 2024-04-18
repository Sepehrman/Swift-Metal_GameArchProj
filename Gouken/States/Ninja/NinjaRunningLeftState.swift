import Foundation
import GameplayKit

// Handles animations and logic related to ninja's running left state
class NinjaRunningLeftState: NinjaBaseState {
    var stateMachine: NinjaStateMachine!
    var player1Node: SCNNode
    var player2Node: SCNNode
    var cameraNode: SCNNode
    
    
    required init(_ stateMachine: NinjaStateMachine) {
        self.stateMachine = stateMachine
        self.player1Node = stateMachine.character.parentNode
        self.player2Node = GameManager.Instance().otherCharacter(character:stateMachine.character).parentNode
        
        self.cameraNode = GameManager.Instance().cameraNode!
    }
    
    func enter() {        
        stateMachine.character.setState(withState: CharacterState.RunningLeft)
        stateMachine.character.animator.changeAnimation(animName: characterAnimations[CharacterName.Ninja]![CharacterState.RunningLeft]!, loop: true)
        
        if(stateMachine.character.parentNode.eulerAngles.y == Float.pi){
            stateMachine.character.animator.setSpeed(0.8)
        }else if(stateMachine.character.parentNode.eulerAngles.y == 0){
            stateMachine.character.parentNode.eulerAngles.x -= 0.25
            stateMachine.character.animator.setSpeed(-0.8)
        }
    }
    
    func tick(_ deltaTime: TimeInterval) {
        player1Node.position.z = boundCheckAll(player1Node: player1Node, player2Node: player2Node, newPos: player1Node.position.z - Float(runSpeed), cameraPos: cameraNode.position.z)

    }
    
    func exit() {
        stateMachine.character.parentNode.eulerAngles.x = 0.0
        stateMachine.character.animator.setSpeed(1)
        
    }
    
}
