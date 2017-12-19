#!/usr/bin/env/swift
/*                                OBs                            [Dec 18 2017]
  sOBOB                           bOs        OB     bOB
 BBBOBOBOB  OBOBOBBBO  BOBOBOBBB  SB   sOBOs BOs BBBs   sBOBOBOBBs
 OB     BO  BO      s  OB     BO  pO  BOssBO pBOB       BOs     BO       .
 BO     OB   BOsss     BO     OB  SB      Op OO    pBBs pB .... Op ......::.
 OB     BB    ss PBs   OB     BO  pOs     BS pBoBOBsoOO bO  ..: Bk .:::::::::.
 BO sO  OB        oBs  Bb     OB  PB      OO OBB     Bo bB      OO ..:::::::`
 BB  SBOBO  BOBOBOBBB  BBOBOBBBO  pOBOBBBBBo OB     sOB bOBOBOBOBS       :`
 BB         ssssss       s s s       s s s           s     sss s
 ss
 */
import Foundation

@discardableResult func bashRun(_ cmd: String) -> String? {
    let pipe = Pipe()
    let process = Process()
    process.launchPath = "/bin/sh"
    process.arguments = ["-c", String(format:"%@", cmd)]
    process.standardOutput = pipe
    let fileHandle = pipe.fileHandleForReading
    process.launch()
    return String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)
}

extension FileManager {
    func firstFileWhere(path: String, suffix:String) -> String? {
        do {
            let contents = try contentsOfDirectory(atPath:path)
            if let index = contents.index(where: { $0.hasSuffix(suffix) }) {
                return contents[index]
            }
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
}

func getInput() -> String {
    let keyboard = FileHandle.standardInput
    let inputData = keyboard.availableData
    let strData = String(data: inputData, encoding: String.Encoding.utf8)!
    return strData.trimmingCharacters(in: CharacterSet.newlines)
}

////

let fm = FileManager.default
let path = fm.currentDirectoryPath


if CommandLine.argc < 2 {
    print("No arguments are passed.")
    let firstArgument = CommandLine.arguments[0]
    print(firstArgument)
} else {
    print("Arguments are passed.")
    let arguments = CommandLine.arguments
    for argument in arguments {
        print(argument)
    }
}

print(path)

guard let project = fm.firstFileWhere(path:path, suffix:".xcodeproj") else {
    print("No project file (.xcodeproj) found, run this command from project root.")
    exit(EXIT_FAILURE)
}

if !fm.fileExists(atPath:"Podfile") {
    print("No Podfile detected, run pod init? [y/n]")
    while true {
        let inputString: String = getInput()
        if(inputString == "y") {
            bashRun("pod init") //test
        } else if(inputString == "n"){
            print("Podfile doesn't exist, run 'pod init'")
            exit(EXIT_FAILURE)
        }
    }
}

func readPodfile() -> [String.SubSequence]? {
    do {
        return try String(contentsOfFile: path+"/Podfile", encoding: .utf8).split(separator: "\n", omittingEmptySubsequences:true)
    }
    catch let error as NSError {
        print("Error: \(error)")
        return nil
    }
}

guard var podfileLines = readPodfile() else {
    print("Can't read Podfile contents")
    exit(EXIT_FAILURE)
}

let targetName :String? = nil
let podName :String? = "MessageKit"


let regex = try NSRegularExpression(pattern: "target\\s*[\\'\\\"]\(targetName ?? ".*")[\\'\\\"]", options: [])
if let targetIndex = podfileLines.index(where: { regex.firstMatch(in:String($0),
                                                                  options: [],
                                                                  range: NSMakeRange(0, $0.count))?.range != nil}) {
    podfileLines[targetIndex].append(contentsOf:"\n    pod '\(podName ?? "")'")
}

@discardableResult func writeToPodfile(_ content:String) -> Bool{
    do {
        try content.write(toFile: path+"/Podfile", atomically: false, encoding: .utf8)
        return true
    }
    catch let error as NSError {
        print("Error: \(error)")
        return false
    }
}

if writeToPodfile(podfileLines.joined(separator:"\n")) {
    if let output = bashRun("pod install") {
        print(output)
    }
    // check podfile.lock
    // update podfile
} else {
    print("Can't write to Podfile")
    exit(EXIT_FAILURE)
}
