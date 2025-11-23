//
//  EMOMApp.swift
//  EMOMTimer
//
//  Created on November 22, 2025.
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//

import SwiftUI
import WebKit

// MARK: - Configuration
private let EMOM_TIMER_URL = "http://localhost:8084"
// Production URL: "http://emom-timer-us-east-2-504242000181.s3-website.us-east-2.amazonaws.com"

class NavigationDelegate: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        let urlString = url.absoluteString.lowercased()
        
        // Allow localhost for debugging
        if urlString.contains("localhost") {
            decisionHandler(.allow)
            return
        }
        
        // Block navigation to GitHub and other external sites
        if (!urlString.contains("emom-timer-us-east-2-504242000181.s3") && 
            !urlString.contains("s3.amazonaws.com")) {
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}

struct EMOMWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Disable zoom via viewport meta tag injection
        let script = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no';
        document.getElementsByTagName('head')[0].appendChild(meta);
        
        // Add CSS to prevent touch zoom
        var style = document.createElement('style');
        style.innerHTML = 'body { touch-action: none; -ms-touch-action: none; }';
        document.getElementsByTagName('head')[0].appendChild(style);
        
        // Prevent default touch behaviors
        document.addEventListener('touchmove', function(e) {
            if (e.scale !== 1) { e.preventDefault(); }
        }, { passive: false });
        
        document.addEventListener('gesturestart', function(e) {
            e.preventDefault();
        });
        """
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        // Make webView background transparent for glass effect
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        // Disable all scrolling, zooming, and gestures
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        
        // Remove all gesture recognizers to prevent double-tap zoom
        webView.scrollView.gestureRecognizers?.forEach { gesture in
            webView.scrollView.removeGestureRecognizer(gesture)
        }
        
        // Load the EMOM timer from S3
        if let url = URL(string: EMOM_TIMER_URL) {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> NavigationDelegate {
        NavigationDelegate()
    }
}

@main
struct EMOMApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Frosted glass background
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Small spacing to avoid Dynamic Island
                    Spacer()
                        .frame(height: 0)
                    
                    EMOMWebView()
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}
