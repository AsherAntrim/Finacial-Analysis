import Foundation

class FinancialDataService {
    private let apiKey = "7OsG6cYHuDJsvDEXECtkGBVPpZ40tMyo"
    private let baseURL = "https://financialmodelingprep.com/api/v3"
    
    func fetchIncomeStatements(symbol: String) async throws -> [IncomeStatement] {
        guard let url = URL(string: "\(baseURL)/income-statement/\(symbol)?apikey=\(apiKey)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let statements = try JSONDecoder().decode([IncomeStatement].self, from: data)
        return statements
    }
    
    func fetchBalanceSheets(symbol: String) async throws -> [BalanceSheet] {
        guard let url = URL(string: "\(baseURL)/balance-sheet-statement/\(symbol)?apikey=\(apiKey)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let statements = try JSONDecoder().decode([BalanceSheet].self, from: data)
        return statements
    }
    
    // Fetch current stock price, needed for valuation ratios
    func fetchStockPrice(symbol: String) async throws -> Double {
        // Placeholder implementation. Use an endpoint like:
        // GET /quote/<symbol>?apikey=...
        // Parse JSON and return price.
        return 150.0 // Dummy value
    }
    
    // Fetch peer tickers (just a placeholder; in real scenario fetch from an API)
    func fetchPeerSymbols(for symbol: String) async -> [String] {
        // TODO: Implement real API call. For now, return static peers.
        return ["MSFT", "GOOGL", "AMZN"]
    }
    
    // Fetch news articles for the symbol
    func fetchNews(for symbol: String) async throws -> [NewsArticle] {
        // Placeholder: In production, call a news API endpoint.
        // Return some dummy data:
        return [
            NewsArticle(headline: "Company Announces New Product",
                        source: "Bloomberg",
                        url: "https://www.example.com/news1",
                        summary: "The company unveiled a new product line expected to boost revenue.",
                        sentiment: "Positive",
                        publishedDate: Date())
        ]
    }
    
    // Fetch metrics for peers (placeholder)
    func fetchPeerComparisons(symbols: [String]) async -> [PeerComparison] {
        // In a real scenario, fetch data and compute metrics. Here we provide dummy data.
        return symbols.map { sym in
            PeerComparison(symbol: sym, peRatio: Double.random(in: 10...30), epsGrowth: Double.random(in: -5...20), revenueGrowth: Double.random(in: -5...20))
        }
    }
}

class WatchlistManager: ObservableObject {
    @Published var watchlist: [String] = {
        UserDefaults.standard.stringArray(forKey: "Watchlist") ?? []
    }() {
        didSet {
            UserDefaults.standard.set(watchlist, forKey: "Watchlist")
        }
    }

    func addTicker(_ symbol: String) {
        let s = symbol.uppercased()
        guard !watchlist.contains(s) else { return }
        watchlist.append(s)
    }

    func removeTicker(_ symbol: String) {
        watchlist.removeAll { $0 == symbol.uppercased() }
    }
}

class SettingsManager: ObservableObject {
    @Published var showAdvancedMetrics: Bool {
        didSet { UserDefaults.standard.set(showAdvancedMetrics, forKey: "showAdvancedMetrics") }
    }
    @Published var preferredTheme: String {
        didSet { UserDefaults.standard.set(preferredTheme, forKey: "preferredTheme") }
    }
    
    init() {
        showAdvancedMetrics = UserDefaults.standard.bool(forKey: "showAdvancedMetrics")
        preferredTheme = UserDefaults.standard.string(forKey: "preferredTheme") ?? "System"
    }
}
