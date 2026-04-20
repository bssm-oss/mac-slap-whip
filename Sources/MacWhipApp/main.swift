import Foundation
import MacWhipCore

Task { @MainActor in
    await MacWhipEntrypoint.run(arguments: CommandLine.arguments)
}

dispatchMain()
