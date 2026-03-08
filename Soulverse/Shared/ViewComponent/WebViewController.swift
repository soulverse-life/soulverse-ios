//
//  WebViewController.swift
//  KonoSummit
//
//  Created by mingshing on 2021/11/25.
//

import UIKit
import WebKit

class WebViewController: ViewController, WKUIDelegate, WKNavigationDelegate {

    private lazy var navigationBar: SoulverseNavigationView = {
        let navigationBar = SoulverseNavigationView(title: pageTitle)
        navigationBar.delegate = self
        return navigationBar
    }()
    
    private lazy var webView: WKWebView = { [weak self] in
        let webConfiguration = WKWebViewConfiguration()
        let view = WKWebView(frame: .zero, configuration: webConfiguration)
            
        view.uiDelegate = self
        view.navigationDelegate = self

        return view
    }()
    
    private let pageTitle: String
    private let pageUrl: URL?
    
    init(title: String, targetUrl: String) {
        pageTitle = title
        pageUrl = URL(string: targetUrl)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        // Do any additional setup after loading the view.
    }

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        view.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(ViewComponentConstants.navigationBarHeight)
        }
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        showLoadingView(below: navigationBar)
        guard let pageUrl = pageUrl else { return }
        let request = URLRequest(url: pageUrl)
        webView.load(request)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideLoadingView()
    }
}
