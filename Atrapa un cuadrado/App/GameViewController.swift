//
//  GameViewController.swift
//  Atrapa un cuadrado
//
//  Created by Antonio Hermoso on 20/3/26.
//

import os
import SpriteKit
import UIKit

final class GameViewController: UIViewController {

    private let skView = SKView(frame: .zero)
    private var hasPresented = false

    override func loadView() {
        view = skView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        skView.ignoresSiblingOrder = true

        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasPresented && !view.bounds.isEmpty {
            hasPresented = true
            presentMainMenu()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    private func presentMainMenu() {
        guard !view.bounds.isEmpty else {
            return
        }

        let scene = ModeSelectScene(sceneSize: view.bounds.size)
        scene.scaleMode = .resizeFill
        let b = view.bounds
        AppLog.scene.info("present ModeSelectScene w=\(b.width, privacy: .public) h=\(b.height, privacy: .public)")
        skView.presentScene(scene)
    }
}
