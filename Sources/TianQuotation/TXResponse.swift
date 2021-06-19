//
//  TXResponse.swift
//  
//
//  Created by 袁林 on 2021/6/19.
//

import Foundation

public struct TXResponse: Codable, Equatable {
    /// 响应状态
    public let responseStatus: String
    /// API 版本
    public let responseCode: Int
    /// 返回结果对象
    public let result: [TXResult]
    
    private enum CodingKeys: String, CodingKey {
        case responseStatus = "msg"
        case responseCode = "code"
        case result = "newslist"
    }
}
