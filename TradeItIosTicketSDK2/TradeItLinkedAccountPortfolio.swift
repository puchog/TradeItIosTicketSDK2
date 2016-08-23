class TradeItLinkedAccountPortfolio: NSObject {
    
    var tradeItSession: TradeItSession
    var broker: String = ""
    var accountName: String = ""
    var accountNumber: String = ""
    var balance: TradeItAccountOverviewResult!
    var positions: [TradeItPositionPortfolio] = []
    var isBalanceError: Bool = false
    var isPositionsError: Bool = false
    
    init(tradeItSession: TradeItSession, broker: String, accountName: String, accountNumber: String, balance: TradeItAccountOverviewResult!, positions: [TradeItPositionPortfolio]) {
        self.tradeItSession = tradeItSession
        self.broker = broker
        self.accountName = accountName
        self.accountNumber = accountNumber
        self.balance = balance
        self.positions = positions
    }
    
}
