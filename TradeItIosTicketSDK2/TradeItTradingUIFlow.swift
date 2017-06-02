import UIKit

class TradeItTradingUIFlow: NSObject, TradeItAccountSelectionViewControllerDelegate, TradeItSymbolSearchViewControllerDelegate, TradeItTradingTicketViewControllerDelegate, TradeItTradePreviewViewControllerDelegate, TradeItTradingConfirmationViewControllerDelegate {

    let viewControllerProvider: TradeItViewControllerProvider = TradeItViewControllerProvider()
    var order = TradeItOrder()
    var previewOrderResult: TradeItPreviewOrderResult?

    func pushTradingFlow(onNavigationController navController: UINavigationController,
                                                asRootViewController: Bool,
                                                withOrder order: TradeItOrder = TradeItOrder()) {
        self.order = order

        let initialViewController = getInitialViewController(forOrder: order)

        if (asRootViewController) {
            navController.setViewControllers([initialViewController], animated: true)
        } else {
            navController.pushViewController(initialViewController, animated: true)
        }
    }

    func presentTradingFlow(fromViewController viewController: UIViewController,
                            withOrder order: TradeItOrder = TradeItOrder()) {
        self.order = order

        let initialViewController = getInitialViewController(forOrder: order)

        let navController = UINavigationController()
        navController.setViewControllers([initialViewController], animated: true)

        viewController.present(navController, animated: true, completion: nil)
    }

    // MARK: Private

    private func initializeLinkedAccount(forOrder order: TradeItOrder) {
        if order.linkedBrokerAccount == nil {
            let enabledAccounts = TradeItSDK.linkedBrokerManager.getAllEnabledAccounts()

            // If there is only one enabled account, auto-select it
            if enabledAccounts.count == 1 {
                order.linkedBrokerAccount = enabledAccounts.first
            }
        }
    }

    private func getInitialViewController(forOrder order: TradeItOrder) -> UIViewController {
        var initialStoryboardId: TradeItStoryboardID!

        self.initializeLinkedAccount(forOrder: order)

        if (order.linkedBrokerAccount == nil) {
            initialStoryboardId = TradeItStoryboardID.accountSelectionView
        } else if (order.symbol == nil) {
            initialStoryboardId = TradeItStoryboardID.symbolSearchView
        } else {
            initialStoryboardId = TradeItStoryboardID.tradingTicketView
        }

        let initialViewController = self.viewControllerProvider.provideViewController(forStoryboardId: initialStoryboardId)

        if let accountSelectionViewController = initialViewController as? TradeItAccountSelectionViewController {
            accountSelectionViewController.delegate = self
        } else if let symbolSearchViewController = initialViewController as? TradeItSymbolSearchViewController {
            symbolSearchViewController.delegate = self
        } else if let tradingTicketViewController = initialViewController as? TradeItTradingTicketViewController {
            tradingTicketViewController.delegate = self
            tradingTicketViewController.order = order
        }

        return initialViewController
    }

    // MARK: TradeItSymbolSearchViewControllerDelegate

    internal func symbolSearchViewController(_ symbolSearchViewController: TradeItSymbolSearchViewController,
                                             didSelectSymbol selectedSymbol: String) {
        self.order.symbol = selectedSymbol

        let tradingTicketViewController = self.viewControllerProvider.provideViewController(forStoryboardId: TradeItStoryboardID.tradingTicketView) as! TradeItTradingTicketViewController

        tradingTicketViewController.delegate = self
        tradingTicketViewController.order = self.order

        symbolSearchViewController.navigationController?.setViewControllers([tradingTicketViewController], animated: true)
    }

    // MARK: TradeItAccountSelectionViewControllerDelegate

    internal func accountSelectionViewController(_ accountSelectionViewController: TradeItAccountSelectionViewController,
                                                 didSelectLinkedBrokerAccount linkedBrokerAccount: TradeItLinkedBrokerAccount) {
        self.order.linkedBrokerAccount = linkedBrokerAccount

        var nextStoryboardId: TradeItStoryboardID!

        if (order.symbol == nil) {
            nextStoryboardId = TradeItStoryboardID.symbolSearchView
        } else {
            nextStoryboardId = TradeItStoryboardID.tradingTicketView
        }

        let nextViewController = self.viewControllerProvider.provideViewController(forStoryboardId: nextStoryboardId)

        if let symbolSearchViewController = nextViewController as? TradeItSymbolSearchViewController {
            symbolSearchViewController.delegate = self
        } else if let tradingTicketViewController = nextViewController as? TradeItTradingTicketViewController {
            tradingTicketViewController.delegate = self
            tradingTicketViewController.order = self.order
        }

        accountSelectionViewController.navigationController?.setViewControllers([nextViewController], animated: true)
    }

    // MARK: TradeItTradingTicketViewControllerDelegate

    internal func orderSuccessfullyPreviewed(
        onTradingTicketViewController tradingTicketViewController: TradeItTradingTicketViewController,
        withPreviewOrderResult previewOrderResult: TradeItPreviewOrderResult,
        placeOrderCallback: @escaping TradeItPlaceOrderHandlers) {
        self.previewOrderResult = previewOrderResult

        let nextViewController = self.viewControllerProvider.provideViewController(forStoryboardId: TradeItStoryboardID.tradingPreviewView)

        if let tradePreviewViewController = nextViewController as? TradeItTradePreviewViewController {
            tradePreviewViewController.delegate = self
            tradePreviewViewController.linkedBrokerAccount = tradingTicketViewController.order.linkedBrokerAccount
            tradePreviewViewController.previewOrderResult = previewOrderResult
            tradePreviewViewController.placeOrderCallback = placeOrderCallback
        }

        tradingTicketViewController.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    // MARK: TradeItTradePreviewViewControllerDelegate

    internal func orderSuccessfullyPlaced(onTradePreviewViewController tradePreviewViewController: TradeItTradePreviewViewController,
                                          withPlaceOrderResult placeOrderResult: TradeItPlaceOrderResult) {
        let nextViewController = self.viewControllerProvider.provideViewController(forStoryboardId: TradeItStoryboardID.tradingConfirmationView)

        if let tradingConfirmationViewController = nextViewController as? TradeItTradingConfirmationViewController {
            tradingConfirmationViewController.delegate = self
            tradingConfirmationViewController.previewOrderResult = self.previewOrderResult
            tradingConfirmationViewController.placeOrderResult = placeOrderResult
        }

        tradePreviewViewController.navigationController?.setViewControllers([nextViewController], animated: true)
    }

    // MARK: TradeItTradingConfirmationViewControllerDelegate

    internal func tradeButtonWasTapped(_ tradeItTradingConfirmationViewController: TradeItTradingConfirmationViewController) {
        if let navigationController = tradeItTradingConfirmationViewController.navigationController {
            self.pushTradingFlow(onNavigationController: navigationController, asRootViewController: true)
        } else if let presentingViewController = tradeItTradingConfirmationViewController.presentingViewController {
            self.presentTradingFlow(fromViewController: presentingViewController)
        }
    }
}
