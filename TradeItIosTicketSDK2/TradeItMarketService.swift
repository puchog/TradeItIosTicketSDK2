@objc public protocol MarketDataService {
    @objc func getQuote(
        symbol: String,
        onSuccess: @escaping (TradeItQuote) -> Void,
        onFailure: @escaping (TradeItErrorResult) -> Void
    )

    @objc optional func getFxQuote(
        symbol: String,
        broker: String,
        onSuccess: @escaping (TradeItQuote) -> Void,
        onFailure: @escaping (TradeItErrorResult) -> Void
    )
}

@objc public class TradeItSymbolService: NSObject {
    let marketDataService: TradeItMarketDataService

    init(apiKey: String, environment: TradeitEmsEnvironments) {
        let connector = TradeItConnector(apiKey: apiKey, environment: environment, version: TradeItEmsApiVersion_2)
        self.marketDataService = TradeItMarketDataService(connector: connector)
    }

    public func symbolLookup(_ searchText: String, onSuccess: @escaping ([TradeItSymbolLookupCompany]) -> Void, onFailure: @escaping (TradeItErrorResult) -> Void) {
        let symbolLookupRequest = TradeItSymbolLookupRequest(query: searchText)

        self.marketDataService.symbolLookup(
            symbolLookupRequest,
            withCompletionBlock: { tradeItResult in
                if let symbolLookupResult = tradeItResult as? TradeItSymbolLookupResult,
                    let results = symbolLookupResult.results as? [TradeItSymbolLookupCompany] {
                    onSuccess(results)
                } else if let errorResult = tradeItResult as? TradeItErrorResult {
                    onFailure(errorResult)
                } else {
                    onFailure(TradeItErrorResult(title: "Market Data failed", message: "Fetching data for symbol lookup failed. Please try again later."))
                }
            }
        )
    }
}

@objc public class TradeItMarketService: NSObject, MarketDataService {
    let marketDataService: TradeItMarketDataService

    init(apiKey: String, environment: TradeitEmsEnvironments) {
        let connector = TradeItConnector(apiKey: apiKey, environment: environment, version: TradeItEmsApiVersion_2)
        self.marketDataService = TradeItMarketDataService(connector: connector)
    }

    public func getQuote(
        symbol: String,
        onSuccess: @escaping (TradeItQuote) -> Void,
        onFailure: @escaping (TradeItErrorResult) -> Void
    ) {
        let quotesRequest = TradeItQuotesRequest(symbol: symbol)

        self.getQuote(quoteRequest: quotesRequest, onSuccess: onSuccess, onFailure: onFailure)
    }

    public func getFxQuote(
        symbol: String,
        broker: String,
        onSuccess: @escaping (TradeItQuote) -> Void,
        onFailure: @escaping (TradeItErrorResult) -> Void
    ) {
        let quotesRequest = TradeItQuotesRequest(fxSymbol: symbol, andBroker: broker)

        self.getQuote(quoteRequest: quotesRequest, onSuccess: onSuccess, onFailure: onFailure)
    }

    private func getQuote(
        quoteRequest: TradeItQuotesRequest,
        onSuccess: @escaping (TradeItQuote) -> Void,
        onFailure: @escaping (TradeItErrorResult) -> Void
    ) {
        self.marketDataService.getQuoteData(
            quoteRequest,
            withCompletionBlock: { result in
                if let quotesResult = result as? TradeItQuotesResult,
                    let quote = quotesResult.quotes?.first as? TradeItQuote {
                    onSuccess(quote)
                } else if let errorResult = result as? TradeItErrorResult {
                    onFailure(errorResult)
                } else {
                    onFailure(TradeItErrorResult(title: "Market Data failed", message: "Fetching the quote failed. Please try again later."))
                }
            }
        )
    }
}
