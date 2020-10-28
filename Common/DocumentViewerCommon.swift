//
//  DocumentViewerCommon.swift
//  iCryptr
//
//  Created by Reuben Eggar on 28/10/2020.
//  Copyright © 2020 Reuben. All rights reserved.
//

import Foundation

import QuickLook


class QLPreviewControllerSingleDataSource: QLPreviewControllerDataSource {
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    func numberOfPreviewItems(in: QLPreviewController) -> Int {return 1}
    func previewController(_: QLPreviewController, previewItemAt: Int) -> QLPreviewItem {
        print(self.fileURL)
        return self.fileURL as QLPreviewItem
    }
    
    var fileURL: URL
}
