//
//  TXRequest.swift
//  
//
//  Created by 袁林 on 2021/6/19.
//

import Foundation

public class TXRequest {
    
    /// The `TXEndpoint` object to which the request is sent to.
    public lazy var endpoint = TXEndpoint()
    
    /// The URL that saves API response cache.
    public lazy var localContentUrl: URL = getDefaultLocalContentUrl()
    
    /// The expiration, that is, the minimum time interval for URL request for the same condinate. In second.
    public var expiration: TimeInterval = 5 * 60
    
    /// The queue on which the request is performed
    public var queue: DispatchQueue = .global(qos: .background)
    
    public init(token: String? = nil) {
        self.endpoint = TXEndpoint(token: token)
    }
    
    public enum DataSource: Equatable {
        case local
        case remote
    }
}


// MARK: - Default generator for Local Content URL

/// A default generator for `CYRequest.localContentUrl`. The URL will be `cachesDirectory`.
fileprivate func getDefaultLocalContentUrl() -> URL {
    let destination: URL = Bundle.module.bundleURL
    let cacheUrl: URL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: destination, create: true)
    return cacheUrl
    // Credit: https://nshipster.com/temporary-files/
}
