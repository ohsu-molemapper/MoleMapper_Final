//
//  TestViewModelItem.swift
//  MoleMapper
//
//  Created by Alejandro Cárdenas on 3/14/18.
//  Copyright © 2018 OHSU. All rights reserved.
//

import UIKit

extension TestViewModel {
    struct TestItem{
        var rowTitle: String
        var completion: (()->Void)?
    }
}

