import UIKit
import TradeItIosTicketSDK2

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, TradeItAuthenticationDelegate {
    static let API_KEY = "tradeit-fx-test-api-key" //"tradeit-test-api-key"
    static let ENVIRONMENT = TradeItEmsTestEnv
    var window: UIWindow?

    override init() {
        TradeItSDK.configure(apiKey: AppDelegate.API_KEY, environment: AppDelegate.ENVIRONMENT)
        super.init()
        TradeItSDK.linkedBrokerManager.authenticationDelegate = self
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if ProcessInfo.processInfo.arguments.contains("isUITesting") {
            UIView.setAnimationsEnabled(false)
        }

        return true
    }

    func clearUserDefaults() {
        let appDomain = Bundle.main.bundleIdentifier;
        UserDefaults.standard.removePersistentDomain(forName: appDomain!);
    }

    func application(_ application: UIApplication,
                     open url: URL,
                     sourceApplication: String?,
                     annotation: Any) -> Bool {
        // Check for the intended url.scheme, url.host, and url.path before proceeding
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            urlComponents.scheme == "tradeitexamplescheme",
            urlComponents.host == "completeOAuth",
            let queryItems = urlComponents.queryItems,
            let oAuthVerifier = queryItems.filter({ $0.name == "oAuthVerifier" }).first?.value {
            TradeItSDK.linkedBrokerManager.completeOAuth(
                withOAuthVerifier: oAuthVerifier,
                onSuccess: { linkedBroker in
                    print("=====> OAuth successful for \(linkedBroker.brokerName)!")

                    if var topViewController = UIApplication.shared.keyWindow?.rootViewController {
                        while let presentedViewController = topViewController.presentedViewController {
                            topViewController = presentedViewController
                        }

                        if let navController = topViewController as? UINavigationController,
                            let exampleViewController = navController.topViewController as? ExampleViewController {
                            exampleViewController.oAuthFlowCompleted(withLinkedBroker: linkedBroker)
                        }
                    }
                }, onFailure: { errorResult in
                    print("=====> ERROR: OAuth failed! \(errorResult.errorCode()): \(errorResult.shortMessage): \(errorResult.longMessages?.first)")
                }
            )
        } else {
            print("=====> ERROR: Received invalid deep link URL: \(url)")
            return false
        }

        return true
    }

    func didLink(linkedBroker: TradeItLinkedBroker, userId: String, userToken: String) {
        linkedBroker.authenticateIfNeeded(onSuccess: {
            for account in linkedBroker.accounts {
                account.getPositions(onSuccess: { positions in
                    print(positions)
                }, onFailure: { error in
                    print(error)
                })
            }
            print("SUCCESS")
        }, onSecurityQuestion: { _, _, _ in
            print("SECURITY QUESTION")
        }, onFailure: { error in
            print(error)
        })
    }

    func didUnlink(linkedBroker: TradeItLinkedBroker) {

    }
}
