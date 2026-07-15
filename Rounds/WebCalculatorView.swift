//
//  WebCalculatorView.swift
//  Rounds
//
//  A hyper-minimal in-app browser for embedding an official external calculator
//  (e.g. the AHA PREVENT tool) without shipping our own risk equations.
//

import SwiftUI
import WebKit

// MARK: - Locked web view

struct LockedWebView: UIViewRepresentable {
    let url: URL
    /// Hosts (substring match) the user is allowed to stay on. Link taps to other
    /// hosts open in Safari instead, keeping the browser "stuck" on the tool.
    let allowedHostFragment: String
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let parent: LockedWebView
        init(_ parent: LockedWebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.isLoading = true }
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.isLoading = false }
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.parent.isLoading = false }
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.parent.isLoading = false }
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Let all resource/subframe loads and same-site navigation proceed.
            // Intercept only user link taps that would leave the tool's site.
            if navigationAction.navigationType == .linkActivated,
               let host = navigationAction.request.url?.host,
               !host.contains(parent.allowedHostFragment),
               let external = navigationAction.request.url {
                UIApplication.shared.open(external)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - External calculator screen

struct ExternalCalculatorView: View {
    let calculator: ClinicalCalculator
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            if let url = calculator.externalURL {
                ZStack(alignment: .top) {
                    LockedWebView(url: url, allowedHostFragment: "heart.org", isLoading: $isLoading)
                        .ignoresSafeArea(edges: .bottom)
                    if isLoading {
                        ProgressView()
                            .padding(8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.top, 10)
                    }
                }
            }

            Text("Official AHA calculator, shown in-app. \(CalculatorLibrary.disclaimer)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
        }
        .navigationTitle(calculator.abbreviation)
        .navigationBarTitleDisplayMode(.inline)
    }
}
