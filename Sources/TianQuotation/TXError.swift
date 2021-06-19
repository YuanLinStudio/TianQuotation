//
//  TXError.swift
//  
//
//  Created by 袁林 on 2021/6/19.
//

import Foundation

public enum TXError: Error, Equatable {
    case tokenIsNil
    case fileDontExist
    case invalidResponse(description: String)
}

