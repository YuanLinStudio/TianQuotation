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

// MARK: - Work with request for TXResponse

extension TXRequest {
    
    /// Perform an action to request weather content.
    ///
    /// If the data from local cache will be used if:
    /// 1. the local cached file exists with no decoding errors; and
    /// 2. it is for the coordinate you are requiring (rounded to `%.4f`, about 100 meters in distance); and
    /// 3. it is not expired.
    ///
    /// Elsewise, a new data will be requested from remote API.
    open func perform(completionHandler: @escaping (TXResponse?, DataSource, Error?) -> Void) {
        NSLog("Trying to request new content...", -1)
        perform(from: .remote) { request, source, error in
            completionHandler(request, source, error)
        }
    }
    
    /// Perform an action to request weather content. Explicitly defines from which dataSource that you want to request weather content.
    public func perform(from dataSource: DataSource, completionHandler: @escaping (TXResponse?, DataSource, Error?) -> Void) {
        let actuator: (@escaping (Data?, Error?) -> Void) -> Void = {
            switch dataSource {
            case .remote:
                return fetchDataFromRemote
            case .local:
                return fetchDataFromLocal
            }
        }()
        
        queue.async { [self] in
            actuator { data, error in
                guard let data = data else {
                    completionHandler(nil, dataSource, error)
                    return
                }
                decode(data) { response, error in
                    completionHandler(response, dataSource, error)
                }
            }
        }
    }
}

// MARK: - Work with data

extension TXRequest {
    
    /// Explicitly fetch data.
    public func fetchData(from dataSource: DataSource, completionHandler: @escaping (Data?, Error?) -> Void) {
        switch dataSource {
        case .remote:
            fetchDataFromRemote(completionHandler: completionHandler)
        case .local:
            fetchDataFromLocal(completionHandler: completionHandler)
        }
    }
    
    /// Explicitly fetch data from API.
    func fetchDataFromRemote(completionHandler: @escaping (Data?, Error?) -> Void) {
        queue.async { [self] in
            guard endpoint.token != nil else {
                completionHandler(nil, TXError.tokenIsNil)
                return
            }
            
            URLSession.shared.dataTask(with: endpoint.url) { (data, _, error) in
                completionHandler(data, error)
                NSLog("Performed a remote data fatching. URL: %@", endpoint.url.absoluteString)
                
                if let data = data {
                    // save a copy to local
                    try? saveDataToLocal(data)
                }
            }
            .resume()
        }
    }
    
    /// Explicitly fetch data from local caches.
    func fetchDataFromLocal(completionHandler: @escaping (Data?, Error?) -> Void) {
        queue.async { [self] in
            do {
                let data = try readDataFromLocal()
                completionHandler(data, nil)
            }
            catch let error {
                completionHandler(nil, error)
            }
        }
    }
    
    /// Explicitly fetch data from example file.
    public func fetchExampleData(completionHandler: @escaping (Data?, Error?) -> Void) {
        queue.async {
            guard let url = Bundle.module.url(forResource: "MorningQuotation", withExtension: "json") else {
                completionHandler(nil, TXError.fileDontExist)
                return
            }
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                completionHandler(data, nil)
                NSLog("Reading example data. URL: %@", url.absoluteString)
            }
            catch let error {
                completionHandler(nil, error)
                NSLog("Error exists when reading example data. Error: %@", error.localizedDescription)
            }
        }
    }
}

// MARK: - Local data caches management

extension TXRequest {
    
    /// URL for local data cache, as `<CYRequest.localContentUrl>/<CYRequest.endpoint.coordinate.urlString>`
    public var localFileUrl: URL { return getFileUrl() }
    
    /// Save some content to local, URL of `<CYRequest.localContentUrl>/<CYCoordinate.urlString>`.
    func saveDataToLocal(_ data: Data) throws {
        do {
            try data.write(to: localFileUrl, options: .atomic)
            NSLog("Successfully saved data to local. URL: %@", localFileUrl.absoluteString)
        }
        catch let error {
            NSLog("Error exists when saving data to local. Error: %@", error.localizedDescription)
            throw error
        }
        
    }
    
    /// Read some content from local, URL of `<CYRequest.localContentUrl>/<CYCoordinate.urlString>`.
    func readDataFromLocal() throws -> Data {
        do {
            let data = try Data(contentsOf: localFileUrl)
            NSLog("Successfully read data from local. URL: %@", localFileUrl.absoluteString)
            return data
        }
        catch let error {
            NSLog("Error exists when reading data from local. Error: %@", error.localizedDescription)
            throw error
        }
    }
    
    /// get URL as `<CYRequest.localContentUrl>/<CYCoordinate.urlString>`.
    func getFileUrl() -> URL {
        let filename: String = "MorningQuotation"
        let fileUrl = localContentUrl.appendingPathComponent(filename)
        return fileUrl
    }
}

// MARK: - Decoding

extension TXRequest {
    
    /// Decode the data. May result in `CYResponse`, `CYInvalidResponse`, or cannot decode.
    /// Resulting in `CYInvalidResponse` means there's some error with your token, so the `error` return will be `CYError.invalidResponse(description: invalidResponse.error)`.
    public func decode(_ data: Data, completionHandler: @escaping (TXResponse?, TXError?) -> Void) {
        queue.async {
            let decoder = JSONDecoder()
            if let response = try? decoder.decode(TXResponse.self, from: data) {
                completionHandler(response, nil)
                NSLog("Successfully decode content.", 0)
            }
            else {
                completionHandler(nil, .invalidResponse(description: "unexpected result"))
                NSLog("API return unexpected result", -1)
            }
        }
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
