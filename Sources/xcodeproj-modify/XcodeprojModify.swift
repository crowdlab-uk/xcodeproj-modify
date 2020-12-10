import Foundation
import PathKit
import XcodeProj

struct XcodeprojModify {
    enum Error: LocalizedError {
        case unknownTarget(String)
        case invalidPosition(Int)
        
        var errorDescription: String? {
            switch self {
            case .unknownTarget(let string):
                return "Couldn't find target named \(string)"
            case .invalidPosition(let int):
                return "Unable to place build script at position \(int)"
            }
        }
    }
    
    private let arguments: [String]

    init(arguments: [String]) {
        self.arguments = arguments
    }
    
    public func run() -> Int32 {
        do {
            let arguments = try Arguments(self.arguments)
            try run(with: arguments)
        } catch {
            print(error.localizedDescription)
            return 1
        }
        return 0
    }
    
    private func run(with arguments: Arguments) throws {
        for command in arguments.commands {
            try runCommand(command, with: arguments)
        }
    }
    
    private func runCommand(_ command: Command, with arguments: Arguments) throws {
        switch command {
        case .addRunScriptPhase(let target, let position, let name, let contents):
            try addRunScriptPhase(target: target, position: position, name: name, contents: contents, xcodeprojPath: arguments.xcodeprojPath)
        }
    }
    
    private func addRunScriptPhase(target: String, position: Int, name: String, contents: String, xcodeprojPath: String) throws {
        let path = Path(xcodeprojPath)
        let xcodeproj = try XcodeProj(path: path)
        let targets = xcodeproj.pbxproj.targets(named: target)
        guard !targets.isEmpty else {
            throw Error.unknownTarget(target)
        }

        let phase = PBXShellScriptBuildPhase(name: name, shellScript: contents)
        for target in targets {
            var buildPhases = target.buildPhases.filter {
                ($0 as? PBXShellScriptBuildPhase)?.name != phase.name
            }

            if position < 0 {
                buildPhases.append(phase)
            } else {
                guard position <= buildPhases.count else {
                    throw Error.invalidPosition(position)
                }
                buildPhases.insert(phase, at: position)
            }
            target.buildPhases = buildPhases
            print("Added build phase")
        }
        xcodeproj.pbxproj.add(object: phase)
        try xcodeproj.writePBXProj(
            path: path,
            override: true,
            outputSettings: PBXOutputSettings()
        )
        print("Successfully wrote data")
    }
}
