//
//  ImageOperation.swift
//  DemoAf
//
//  Created by Raheel Rehman on 22/08/2021.
//

import UIKit
import Alamofire

class NetworkManager {
    
    static let sharedInstance = NetworkManager()
    
    let manager: Session = {
        let configuration: URLSessionConfiguration = {
          
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 5
            configuration.httpMaximumConnectionsPerHost = 2
            return configuration
        }()
        return Session(configuration: configuration)
    }()
    
}
class ImageOperation: AsynchronousOperation {
    
    // define properties to hold everything that you'll supply when you instantiate
    // this object and will be used when the request finally starts
    //
    // Keep track of (a) URL; and (b) closure to call when request is done
    
    private let urlConvertible: URLRequestConvertible
    private var networkOperationCompletionHandler: ((_ responseObject: AFDataResponse<Any>?) -> Void)?
    
    // we'll also keep track of the resulting request operation in case we need to cancel it later
    
    weak var request: Alamofire.Request?
    
    // define init method that captures all of the properties to be used when issuing the request
    
    init(urlConvertible: URLRequestConvertible, networkOperationCompletionHandler: ((_ responseObject: AFDataResponse<Any>?) -> Void)? = nil) {
        self.urlConvertible = urlConvertible
        self.networkOperationCompletionHandler = networkOperationCompletionHandler
        super.init()
        self.name = urlConvertible.urlRequest?.url?.path
    }
    
    // when the operation actually starts, this is the method that will be called
    
    override func main() {
        request = NetworkManager.sharedInstance.manager.request(urlConvertible)
            .responseJSON { response in
                // do whatever you want here; personally, I'll just all the completion handler that was passed to me in `init`
                
                self.networkOperationCompletionHandler?(response)
                self.networkOperationCompletionHandler = nil
                
                // now that I'm done, complete this operation
                self.completeOperation()
        }
    }
    
    // we'll also support canceling the request, in case we need it
    
    override func cancel() {
        request?.cancel()
        super.cancel()
    }
}
