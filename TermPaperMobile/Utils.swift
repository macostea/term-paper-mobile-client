//
//  Utils.swift
//  catwalk15
//
//  Created by Mihai Costea on 10/10/14.
//  Copyright (c) 2014 mcostea. All rights reserved.
//

import Foundation
import Box

enum Either<T, U> {
    case Result(Box<T>)
    case Error(Box<U>)
}
