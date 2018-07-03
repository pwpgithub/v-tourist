//
//  GCDBlackBox.swift
//  VirtualTourist
//
//  Created by Ping Wu on 3/5/18.
//  Copyright © 2018 SHDR. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping() -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
