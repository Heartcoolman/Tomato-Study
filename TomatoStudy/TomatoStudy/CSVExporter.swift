import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct CSVDocument: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { document in
            Data(document.csv.utf8)
        }
    }

    var csv: String
}
