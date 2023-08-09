//
//  Error.swift
//  aBicycle
//
//  Created by 1 on 8/8/23.
//

import Foundation

enum AppError: Error {
    case PathNotFound
    case PathValid
    case CustomPathVaild
    case ExecutionFailed
    
    case NotFoundEmulator
    case NotFoundActiveEmulator
    case AvdDataParsingFailed
    
    case FailedToDeleteAvd
    
    case FailedToGetProcessInfo
    case FailedToGetProcessID
    case FailedToKillProcess
}


func getErrorMessage(etype: AppError) -> String {
    switch(etype) {
    case .PathNotFound:
        return "Path Not Found."
    case .PathValid:
        return "PATH is Vaild."
    case .CustomPathVaild:
        return "In the application settings, the custom path is invalid"
    case .ExecutionFailed:
        return "command execution failed"
    case .AvdDataParsingFailed:
        return "avdmanager list avd: data parsing failed"
    case .NotFoundEmulator:
        return "not found avd"
    case .NotFoundActiveEmulator:
        return "Not Found Active Emulator"
    case .FailedToDeleteAvd:
        return "Description Failed to delete the avd."
    case .FailedToGetProcessInfo:
        return "Failed to get process information."
    case .FailedToGetProcessID:
        return "Failed to get process ID."
    case .FailedToKillProcess:
        return "Failed to kill process"
    }
}
