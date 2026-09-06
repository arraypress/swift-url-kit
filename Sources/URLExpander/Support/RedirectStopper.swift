//
//  RedirectStopper.swift
//  URLExpander
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Stops URLSession following redirects itself, so each hop comes back to us.
///
/// Without it URLSession swallows the chain and reports only the destination,
/// which is exactly the part a trace needs to show.
final class RedirectStopper: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
