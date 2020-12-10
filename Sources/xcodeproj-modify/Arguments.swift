import Foundation

struct Arguments {
    let xcodeprojPath: String
    let commands: [Command]

    enum Error: LocalizedError {
        case missingXcodeprojPath
        case missingCommand
        case unknownCommand(String)
        case missingTarget
        case missingName
        case missingPosition
        case missingContents
        
        var errorDescription: String? {
            switch self {
            case .missingXcodeprojPath:
                return "Please give path to xcodeproj as first argument"
            case .missingCommand:
                return "Please give a command (add-run-script-phase)"
            case .unknownCommand(let command):
                return "Unknown command: \(command)"
            case .missingTarget:
                return "Please specify a target as the first argument after add-run-script-phase"
            case .missingPosition:
                return "Please specify the position the build script shall be injected at"
            case .missingName:
                return "Please specify a build phase name"
            case .missingContents:
                return "Please specify shell script contents as the second argument after add-run-script-phase"
            }
        }
    }

    private typealias TokenIterator = IndexingIterator<ArraySlice<String>>

    init(_ arguments: [String]) throws {
        var iterator = arguments.dropFirst().makeIterator()
        
        guard let path = iterator.next() else {
            throw Error.missingXcodeprojPath
        }
        xcodeprojPath = path
        
        guard let commandName = iterator.next() else {
            throw Error.missingCommand
        }
        let command = try Arguments.parseCommand(named: commandName, from: &iterator)
        commands = [command]
    }
    
    private static func parseCommand(named commandName: String, from iterator: inout TokenIterator) throws -> Command {
        switch commandName {
        case "add-run-script-phase":
            guard let target = iterator.next() else {
                throw Error.missingTarget
            }
            guard let position = Int(iterator.next() ?? "-1") else {
                throw Error.missingPosition
            }
            guard let name = iterator.next() else {
                throw Error.missingName
            }
            guard let contents = iterator.next() else {
                throw Error.missingContents
            }
            return Command.addRunScriptPhase(target: target, position: position, name: name, contents: contents)
        
        default:
            throw Error.unknownCommand(commandName)
        }
    }

}


