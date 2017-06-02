import Quick
import Nimble
@testable import TradeItIosTicketSDK2

class TradeItLoginViewControllerSpec: QuickSpec {
    override func spec() {
        var controller: TradeItLoginViewController!
        var linkedBrokerManager: FakeTradeItLinkedBrokerManager!
        var window: UIWindow!
        var nav: UINavigationController!
        var alertManager: FakeTradeItAlertManager!
        
        describe("initialization") {
            beforeEach {
                window = UIWindow()
                let bundle = Bundle(identifier: "TradeIt.TradeItIosTicketSDK2")
                let storyboard: UIStoryboard = UIStoryboard(name: "TradeIt", bundle: bundle)

                linkedBrokerManager = FakeTradeItLinkedBrokerManager()
                TradeItSDK._linkedBrokerManager = linkedBrokerManager

                controller = storyboard.instantiateViewController(withIdentifier: "TRADE_IT_LOGIN_VIEW") as! TradeItLoginViewController
                controller.selectedBroker = TradeItBroker(shortName: "B5", longName: "Broker #5")
                alertManager = FakeTradeItAlertManager()
                controller.alertManager = alertManager
                controller.delegate = FakeTradeItLoginViewControllerDelegate()
                nav = UINavigationController(rootViewController: controller)

                window.addSubview(nav.view)

                flushAsyncEvents()
            }

            it("sets the broker longName in the instruction label the and text field placeholders") {
                let brokerName = controller.selectedBroker!.brokerLongName!

                expect(controller.loginLabel.text).to(equal("Log in to \(brokerName)"))
                expect(controller.userNameInput.placeholder).to(equal("\(brokerName) Username"))
                expect(controller.passwordInput.placeholder).to(equal("\(brokerName) Password"))
            }

            it("focuses the userName text field") {
                expect(controller.userNameInput.isFirstResponder).to(equal(true))
            }

            it("disables the link button") {
                expect(controller.linkButton.isEnabled).to(beFalse())
            }

            describe("filling in the login fields") {
                context("when username and password are filled") {
                    beforeEach {
                        controller.userNameInput.text = "dummy"
                        controller.userNameOnEditingChanged(controller.userNameInput)
                        controller.passwordInput.text = "dummy"
                        controller.passwordOnEditingChanged(controller.passwordInput)
                    }

                    it("enables the link button") {
                        expect(controller.linkButton.isEnabled).to(beTrue())
                    }
                }

                context("when at least one field is empty") {
                    beforeEach {
                        controller.userNameInput.text = ""
                        controller.userNameOnEditingChanged(controller.userNameInput)
                        controller.passwordInput.text = "my special password"
                        controller.passwordOnEditingChanged(controller.passwordInput)

                    }

                    it("disables the link button") {
                        expect(controller.linkButton.isEnabled).to(beFalse())
                    }
                }

                context("when both fields are empty") {
                    beforeEach {
                        controller.userNameInput.text = ""
                        controller.userNameOnEditingChanged(controller.userNameInput)
                        controller.passwordInput.text = ""
                        controller.passwordOnEditingChanged(controller.passwordInput)
                    }

                    it("disables the link button") {
                        expect(controller.linkButton.isEnabled).to(beFalse())
                    }
                }

            }
            describe("relinking the account") {
                var relinkedBroker: FakeTradeItLinkedBroker!
                beforeEach {
                    relinkedBroker = FakeTradeItLinkedBroker(session: FakeTradeItSession(),
                                                             linkedLogin: TradeItLinkedLogin(label: "my label",
                                                                                             broker: "my broker",
                                                                                             userId: "my userId",
                                                                                             andKeyChainId: "my keychain id"))
                    controller.userNameInput.text = "My Special Username"
                    controller.userNameOnEditingChanged(controller.userNameInput)
                    controller.passwordInput.text = "My Special Password"
                    controller.passwordOnEditingChanged(controller.passwordInput)
                    controller.linkedBrokerToRelink = relinkedBroker
                    controller.linkButtonWasTapped(controller.linkButton)
                }
                
                it("uses the linkedBrokerManager to relink the account") {
                    let relinkCalls = linkedBrokerManager.calls.forMethod("relinkBroker(_:authInfo:onSuccess:onSecurityQuestion:onFailure:)")
                    
                    expect(relinkCalls.count).to(equal(1))
                    expect(linkedBrokerManager.calls.count).to(equal(1))
                    
                    let linkCallAuthInfo = relinkCalls[0].args["authInfo"] as! TradeItAuthenticationInfo
                    
                    expect(linkCallAuthInfo.broker).to(equal("B5"))
                    expect(linkCallAuthInfo.id).to(equal("My Special Username"))
                    expect(linkCallAuthInfo.password).to(equal("My Special Password"))
                }
                
                it("disables the link button") {
                    expect(controller.linkButton.isEnabled).to(beFalse())
                }
                
                it("shows a spinner") {
                    expect(controller.activityIndicator.isAnimating).to(beTrue())
                }
                
                context("when linking is successful") {
                    beforeEach {
                        let relinkCalls = linkedBrokerManager.calls.forMethod("relinkBroker(_:authInfo:onSuccess:onSecurityQuestion:onFailure:)")

                        let onSuccess = relinkCalls[0].args["onSuccess"] as! ((TradeItLinkedBroker) -> Void)
                        
                        onSuccess(relinkedBroker)
                    }
                    
                    // FIX: itBehavesLike("authenticating the broker") {["controller": controller, "linkedBroker": relinkedBroker, "nav": nav]}
                    
                }
                
                context("when relinking fails") {
                    beforeEach {
                        let errorResult = TradeItErrorResult()
                        errorResult.status = "ERROR"
                        errorResult.token = "My Special Token"
                        errorResult.shortMessage = "My Special Error Title"
                        errorResult.longMessages = ["My Special Error Message"]
                        
                        let onFailure = linkedBrokerManager.calls.forMethod("relinkBroker(_:authInfo:onSuccess:onFailure:)")[0].args["onFailure"] as! ((TradeItErrorResult) -> Void)
                        
                        linkedBrokerManager.calls.reset()
                        
                        onFailure(errorResult)
                    }
                    
                    // FIX: itBehavesLike("linking/relinking fails") {["controller": controller, "nav": nav]}
                    
                }


            }
            
            describe("linking the account") {
                beforeEach {
                    controller.userNameInput.text = "My Special Username"
                    controller.userNameOnEditingChanged(controller.userNameInput)
                    controller.passwordInput.text = "My Special Password"
                    controller.passwordOnEditingChanged(controller.passwordInput)

                    controller.linkButtonWasTapped(controller.linkButton)
                }

                it("uses the linkedBrokerManager to link the account") {
                    let linkCalls = linkedBrokerManager.calls.forMethod("linkBroker(authInfo:onSuccess:onSecurityQuestion:onFailure:)")

                    expect(linkCalls.count).to(equal(1))
                    expect(linkedBrokerManager.calls.count).to(equal(1))

                    let linkCallAuthInfo = linkCalls[0].args["authInfo"] as! TradeItAuthenticationInfo

                    expect(linkCallAuthInfo.broker).to(equal("B5"))
                    expect(linkCallAuthInfo.id).to(equal("My Special Username"))
                    expect(linkCallAuthInfo.password).to(equal("My Special Password"))
                }

                it("disables the link button") {
                    expect(controller.linkButton.isEnabled).to(beFalse())
                }

                it("shows a spinner") {
                    expect(controller.activityIndicator.isAnimating).to(beTrue())
                }

                context("when linking is successful") {
                    var linkedBroker: FakeTradeItLinkedBroker!

                    beforeEach {
                        let onSuccess = linkedBrokerManager.calls.forMethod("linkBroker(authInfo:onSuccess:onSecurityQuestion:onFailure:)")[0].args["onSuccess"] as! ((TradeItLinkedBroker) -> Void)
                        
                        linkedBroker = FakeTradeItLinkedBroker(session: FakeTradeItSession(),
                                                           linkedLogin: TradeItLinkedLogin(label: "",
                                                                                           broker: "",
                                                                                           userId: "",
                                                                                           andKeyChainId: ""))
                        onSuccess(linkedBroker)
                    }

                    // FIX: itBehavesLike("authenticating the broker") {["controller": controller, "linkedBroker": linkedBroker, "nav": nav]}
                    
                    
                }

                context("when linking fails") {
                    beforeEach {
                        let errorResult = TradeItErrorResult()
                        errorResult.status = "ERROR"
                        errorResult.token = "My Special Token"
                        errorResult.shortMessage = "My Special Error Title"
                        errorResult.longMessages = ["My Special Error Message"]

                        let onFailure = linkedBrokerManager.calls.forMethod("linkBroker(authInfo:onSuccess:onFailure:)")[0].args["onFailure"] as! ((TradeItErrorResult) -> Void)

                        linkedBrokerManager.calls.reset()

                        onFailure(errorResult)
                    }
                    
                    // FIX: itBehavesLike("linking/relinking fails") {["controller": controller, "nav": nav]}
                }
            }
        }
    }
}

class TradeItLoginViewControllerSpecConfiguration: QuickConfiguration {
    override class func configure(_ configuration: Configuration) {
        sharedExamples("authenticating the broker"){ (sharedExampleContext: @escaping SharedExampleContext) in
            var controller: TradeItLoginViewController!
            var nav: UINavigationController!
            var linkedBroker: FakeTradeItLinkedBroker!
            beforeEach {
                controller = sharedExampleContext()["controller"] as! TradeItLoginViewController
                nav = sharedExampleContext()["nav"] as! UINavigationController!
                linkedBroker = sharedExampleContext()["linkedBroker"] as! FakeTradeItLinkedBroker
            }
            
            it("keeps the link button disabled") {
                expect(controller.linkButton.isEnabled).to(beFalse())
            }
            
            it("keeps the spinner spinning") {
                expect(controller.activityIndicator.isAnimating).to(beTrue())
            }
            describe("authentication") {
                context("when authentication succeeds") {
                    beforeEach {
                        let onSuccess = linkedBroker.calls.forMethod("authenticate(onSuccess:onSecurityQuestion:onFailure:)")[0].args["onSuccess"] as! (() -> Void)
                        
                        onSuccess()
                    }
                    it("hides the spinner") {
                        expect(controller.activityIndicator.isAnimating).to(beFalse())
                    }
                    
                    it("enables the link button") {
                        expect(controller.linkButton.isEnabled).to(beTrue())
                    }
                    
                    xit("calls brokerLinked on  the delegate") {
                        let delegate = controller.delegate as! FakeTradeItLoginViewControllerDelegate
                        let calls = delegate.calls.forMethod("brokerLinked(_:withLinkedBroker:)")
                        let arg1 = calls[0].args["fromTradeItLoginViewController"] as! TradeItLoginViewController
                        let arg2 = calls[0].args["withLinkedBroker"] as! TradeItLinkedBroker
                        expect(calls.count).to(equal(1))
                        expect(arg1).to(equal(controller))
                        expect(arg2).to(equal(linkedBroker))
                        
                    }
                }
                
                context("when authentication fails") {
                    var alertManager: FakeTradeItAlertManager!
                    beforeEach {
                        alertManager = controller.alertManager as! FakeTradeItAlertManager
                        let errorResult = TradeItErrorResult()
                        errorResult.status = "ERROR"
                        errorResult.token = "My Special Token"
                        errorResult.shortMessage = "My Special Error Title"
                        errorResult.longMessages = ["My Special Error Message"]
                        
                        let onFailure = linkedBroker.calls.forMethod("authenticate(onSuccess:onSecurityQuestion:onFailure:)")[0].args["onFailure"] as! ((TradeItErrorResult) -> Void)
                        onFailure(errorResult)
                    }
                    
                    it("hides the spinner") {
                        expect(controller.activityIndicator.isAnimating).to(beFalse())
                    }
                    
                    it("enables the link button") {
                        expect(controller.linkButton.isEnabled).to(beTrue())
                    }
                    
                    it("calls the showTradeItErrorResultAlert to show a modal") {
                        let calls = alertManager.calls.forMethod("showTradeItErrorResultAlert(onViewController:errorResult:onAlertDismissed:)")
                        expect(calls.count).to(equal(1))
                    }
                    
                    it("remains on the login screen") {
                        expect(nav.topViewController).toEventually(beAnInstanceOf(TradeItLoginViewController.self))
                    }
                    
                    xdescribe("dismissing the alert") {
                        beforeEach {
                            let calls = alertManager.calls.forMethod("showTradeItErrorResultAlert(onViewController:errorResult:onAlertDismissed:)")
                            let onCompletion = calls[0].args["onAlertDismissed"] as! () -> Void
                            onCompletion()
                        }
                        
                        it("remains on the login screen") {
                            expect(nav.topViewController).toEventually(beAnInstanceOf(TradeItLoginViewController.self))
                        }
                    }
                }
                
                context("when security question is needed") {
                    // TODO
                    //                            beforeEach {
                    //                                let tradeItSecurityQuestionResult = TradeItSecurityQuestionResult()
                    //                                let onSecurityQuestion = linkedBroker.calls.forMethod("authenticate(onSuccess:onSecurityQuestion:onFailure:)")[0].args["onSecurityQuestion"] as! ((tradeItSecurityQuestionResult: TradeItSecurityQuestionResult) -> String)
                    //
                    //                                onSecurityQuestion(tradeItSecurityQuestionResult: tradeItSecurityQuestionResult)
                    //                            }
                }
            }
            
        }
        
        sharedExamples("linking/relinking fails") { (sharedExampleContext: @escaping SharedExampleContext) in
            var controller: TradeItLoginViewController!
            var alertManager: FakeTradeItAlertManager!
            var nav: UINavigationController!
            beforeEach {
                controller = sharedExampleContext()["controller"] as! TradeItLoginViewController
                alertManager = controller.alertManager as! FakeTradeItAlertManager
                nav = sharedExampleContext()["nav"] as! UINavigationController

            }
            it("hides the spinner") {
                expect(controller.activityIndicator.isAnimating).to(beFalse())
            }
            
            it("enables the link button") {
                expect(controller.linkButton.isEnabled).to(equal(true))
            }
            
            it("calls the showTradeItErrorResultAlert to show a modal") {
                let calls = alertManager.calls.forMethod("showTradeItErrorResultAlert(onViewController:errorResult:onAlertDismissed:)")
                expect(calls.count).to(equal(1))
            }
            
            it("remains on the login screen") {
                expect(nav.topViewController).toEventually(beAnInstanceOf(TradeItLoginViewController.self))
            }
            
            xdescribe("dismissing the alert") {
                beforeEach {
                        let calls = alertManager.calls.forMethod("showTradeItErrorResultAlert(onViewController:errorResult:onAlertDismissed:)")
                        let onCompletion = calls[0].args["onAlertDismissed"] as! () -> Void
                        onCompletion()
                }
                
                it("remains on the login screen") {
                    expect(nav.topViewController).toEventually(beAnInstanceOf(TradeItLoginViewController.self))
                }
            }
            
            
        }
    }
    
}

