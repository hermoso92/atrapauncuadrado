//
//  SceneDelegate.swift
//  Atrapa un cuadrado
//
//  Created by Antonio Hermoso on 20/3/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }

        ArtificialWorldPersistence.bootstrapIfNeeded()

        let window = UIWindow(windowScene: windowScene)
        let viewController = GameViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        self.window = window
    }
}
