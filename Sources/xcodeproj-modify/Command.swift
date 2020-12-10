import Foundation

enum Command {
    case addRunScriptPhase(target: String, position: Int, name: String, contents: String)
}
