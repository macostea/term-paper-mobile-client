//
//  Utils.swift
//  catwalk15
//
//  Created by Mihai Costea on 10/10/14.
//  Copyright (c) 2014 mcostea. All rights reserved.
//

import Foundation

enum Either<T, U> {
    case Result(@autoclosure() -> T)
    case Error(@autoclosure() -> U)
}
