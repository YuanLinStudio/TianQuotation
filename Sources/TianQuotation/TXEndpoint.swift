//
//  TXEndpoint.swift
//  
//
//  Created by 袁林 on 2021/6/19.
//

import Foundation

public struct TXEndpoint: Codable, Equatable {
    /// Token
    public var token: String! = nil
    
    /// 根据 `CYEndpoint` 设置获得的 `URLComponents` 对象
    var components: URLComponents { return getComponents() }
    
    /// 根据 `CYEndpoint` 设置得到的请求 URL
    public var url: URL! { return components.url }
}

extension TXEndpoint {
    
    func getComponents() -> URLComponents {
        // Credit: https://www.swiftbysundell.com/articles/constructing-urls-in-swift/
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.tianapi.com"
        components.path = ["", "txapi", "zaoan", "index"].joined(separator: "/")
        components.queryItems = [
            URLQueryItem(name: "key", value: token),
        ]
        return components
    }
}
