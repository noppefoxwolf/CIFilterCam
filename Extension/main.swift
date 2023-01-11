//
//  main.swift
//  Extension
//
//  Created by noppe on 2023/01/12.
//

import Foundation
import CoreMediaIO

let providerSource = ExtensionProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()
