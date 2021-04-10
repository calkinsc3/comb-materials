/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import UIKit
import Photos
import Combine

typealias urlSessionResponse = (Data, URLResponse, Error) -> Void

class PhotoWriter {
    enum Error: Swift.Error {
        case couldNotSavePhoto
        case generic(Swift.Error)
    }
    
    static func save(_ image: UIImage) -> Future<String, PhotoWriter.Error> {
        return Future { resolve in
            do {
                try PHPhotoLibrary.shared().performChangesAndWait {
                    let request = PHAssetChangeRequest.creationRequestForAsset(from: image) //1
                    guard let savedAssetID = request.placeholderForCreatedAsset?.localIdentifier else { //2
                        return resolve(.failure(.couldNotSavePhoto))
                    }
                    resolve(.success(savedAssetID)) //3
                }
            } catch {
                resolve(.failure(.generic(error)))
            }
        }
    }
    
    func getNetworkData<D:Decodable>(url: URLRequest) -> Future<D, PublisherError> {
        
        return Future { resolve in
            
            let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
                do {
                    guard let data = data,
                          let response = response as? HTTPURLResponse else {
                        return resolve(.failure(.network(description: "Could not unwrap data or response")))
                    }
                    if response.statusCode == 200 {
                        let decoder = JSONDecoder()
                        let decoded = try decoder.decode(D.self, from: data)
                        
                        resolve(.success(decoded))
                        
                    } else {
                        return resolve(.failure(.network(description: "Non 200 response code: \(response) \(error?.localizedDescription ?? "")")))
                    }
                    
                } catch {
                    resolve(.failure(.parsing(description: "Could not decode given type: Error: \(error)")))
                }
            }
            dataTask.resume()
            
        }
        
    }
    
}

enum PublisherError: Swift.Error, CustomStringConvertible {
    
    case network(description: String)
    case parsing(description: String)
    case unknown
    
    var description: String {
        switch self {
        case .network: return "A network error occured."
        case .parsing: return "A parsing error occured."
        case .unknown: return "An unknown error occured."
        }
    }
    
    init(_ error: Swift.Error) {
        switch error {
        case is URLError: self = .network(description: error.localizedDescription)
        case is DecodingError: self = .parsing(description: error.localizedDescription)
        default:
            self = error as? PublisherError ?? .unknown
        }
    }
    
}
