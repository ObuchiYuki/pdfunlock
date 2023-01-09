//
//  main.swift
//  PDFCrack
//
//  Created by yuki on 2022/03/23.
//

import Foundation
import PDFKit
import ArgumentParser

enum PDFUnlockError: Error, CustomStringConvertible {
    case PDFFileRead(URL)
    case PDFFileWrite(URL)
    case deleteInputFile(URL)
    
    var description: String {
        switch self {
        case .PDFFileWrite(let url): return "Write PDF '\(url.path)' file failed."
        case .PDFFileRead(let url): return "Read PDF '\(url.path)' file failed."
        case .deleteInputFile(let url): return "Delete Input file '\(url.path)' failed."
        }
    }
}

struct PDFUnlock: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "pdfunlock", abstract: "Unlock PDF edit/copy lock.")

    @Argument
    var inputFiles: [String]
    
    @Option(name: [.customShort("f"), .customLong("format")], help: "Unlocked file name format.")
    var unlockFileFormat: String = "[name] (Unlocked).pdf"
    
    @Flag(name: [.customShort("d"), .customLong("delete")], help: "Should delete input files")
    var deleteFiles: Bool = false
    
    mutating func run() throws {
        for inputFile in inputFiles {
            let url = URL(fileURLWithPath: inputFile)
            do {
                try unlockPDF(url)
            } catch PDFUnlockError.PDFFileRead {
                print("Read PDF '\(url.lastPathComponent)' is failed.")
            } catch PDFUnlockError.PDFFileWrite {
                print("Write PDF '\(url.lastPathComponent)' is failed.")
            }
        }
    }
    
    private func unlockPDF(_ url: URL) throws {
        let originalFilename = url.deletingPathExtension().lastPathComponent
        let newFilename = unlockFileFormat.replacingOccurrences(of: "[name]", with: originalFilename)

        let destinationURL = url.deletingLastPathComponent().appendingPathComponent(newFilename)
        guard let document = PDFDocument(url: url) else {
            throw PDFUnlockError.PDFFileRead(url)
        }
        let pages = (0..<document.pageCount).compactMap{
            document.page(at: $0)
        }
        let ndocument = PDFDocument()
        for (i, page) in pages.enumerated() {
            ndocument.insert(page, at: i)
        }

        do {
            try ndocument.dataRepresentation()?.write(to: destinationURL)
        } catch {
            throw PDFUnlockError.PDFFileWrite(url)
        }
        
        if deleteFiles {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                throw PDFUnlockError.deleteInputFile(url)
            }
        }
    }
}

PDFUnlock.main()
