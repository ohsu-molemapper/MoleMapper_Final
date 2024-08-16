//
// MoleMapper
//
// Copyright (c) 2017-2022 OHSU. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit
import WebKit

enum WebViewControllerTypes {
    case local
    case external
}

// Straight from https://developer.apple.com/documentation/webkit/wkwebview  (minus the delegates)
class WebViewController: UIViewController {
    var webView: WKWebView!
    var destination: String?
    var contentType: WebViewControllerTypes = .external
    var showDoneButton: Bool = false


    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        view = webView
        webView.navigationDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (self.navigationController != nil) && (self.showDoneButton) {
            let doneButton = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(myDone))
            self.navigationItem.rightBarButtonItem = doneButton
        }

        if destination != nil {
            if contentType == .external {
                if Reachability.isConnectedToNetwork() {
                    let myRequest = URLRequest(url: URL(string: destination!)!)  // go ahead and crash if fail -- find failures before shipping!
                    webView.load(myRequest)
                }
                else {
                    let url = Bundle.main.url(forResource: "unreachable", withExtension: "html")!
                    webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
                }
            } else {
                let url = Bundle.main.url(forResource: destination!, withExtension: "html")!
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
        }
    }
    
    func setup(destination: String, contentType: WebViewControllerTypes, showDoneButton: Bool = false) {
        self.destination = destination
        self.contentType = contentType
        self.showDoneButton = showDoneButton
    }

    @objc func myDone() {
        print("my done (webviewcontroller)")
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.showBodyMap()
    }
}

extension WebViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("web call failed: \(error), \(error.localizedDescription)")
        let url = Bundle.main.url(forResource: "unreachable", withExtension: "html")!
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("webView:didCommit")
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print(#function)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(#function)
    }
    
}
