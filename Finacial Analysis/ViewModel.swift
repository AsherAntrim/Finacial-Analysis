import Foundation

@MainActor
class FinancialViewModel: ObservableObject {
    @Published var symbol: String = ""
    @Published var metrics: FinancialMetrics?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var news: [NewsArticle] = []
    @Published var peerComparisons: [PeerComparison] = []
    
    @Published var historicalData: [(Date, Double)] = [] // revenue
    @Published var epsData: [(Date, Double)] = []
    @Published var netIncomeData: [(Date, Double)] = []
    @Published var operatingIncomeData: [(Date, Double)] = []
    
    @Published var incomeStatements: [IncomeStatement] = []
    @Published var balanceSheets: [BalanceSheet] = []
    
    // Scenario analysis variables
    @Published var scenarioRevenueGrowth: Double = 10.0
    @Published var scenarioOperatingMargin: Double = 15.0

    private let service = FinancialDataService()
    
    func analyze() async {
        guard !symbol.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedIncome = try await service.fetchIncomeStatements(symbol: symbol)
            let fetchedBalance = try await service.fetchBalanceSheets(symbol: symbol)
            
            // Store the raw data
            incomeStatements = fetchedIncome.sorted { $0.date > $1.date }
            balanceSheets = fetchedBalance.sorted { $0.date > $1.date }
            
            guard incomeStatements.count >= 2 else {
                errorMessage = "Not enough data to analyze"
                return
            }
            
            let recent = incomeStatements[0]
            let previous = incomeStatements[1]

            // Prepare historical data for charts
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            historicalData = incomeStatements.prefix(8).compactMap { stmt in
                if let d = formatter.date(from: stmt.date) {
                    return (d, stmt.revenue)
                }
                return nil
            }.sorted { $0.0 < $1.0 }
            
            epsData = incomeStatements.prefix(8).compactMap { stmt in
                if let d = formatter.date(from: stmt.date) {
                    return (d, stmt.eps)
                }
                return nil
            }.sorted { $0.0 < $1.0 }
            
            netIncomeData = incomeStatements.prefix(8).compactMap { stmt in
                if let d = formatter.date(from: stmt.date) {
                    return (d, stmt.netIncome)
                }
                return nil
            }.sorted { $0.0 < $1.0 }
            
            operatingIncomeData = incomeStatements.prefix(8).compactMap { stmt in
                if let d = formatter.date(from: stmt.date) {
                    return (d, stmt.operatingIncome)
                }
                return nil
            }.sorted { $0.0 < $1.0 }
            
            // Calculate growth and margins
            let revenueGrowth = ((recent.revenue - previous.revenue) / previous.revenue) * 100.0
            let epsGrowth = ((recent.eps - previous.eps) / previous.eps) * 100.0
            let operatingMargin = (recent.operatingIncome / recent.revenue) * 100.0
            
            let recentBS = balanceSheets[0]
            
            let currentRatio = 1.2 // Placeholder
            let debtToEquity = (recentBS.shortTermDebt + recentBS.longTermDebt) / max((recentBS.totalAssets - recentBS.totalLiabilities), 1.0)
            let freeCashFlowGrowth = 5.0 // placeholder
            
            let currentPrice = try await service.fetchStockPrice(symbol: symbol)
            let annualizedEPS = recent.eps * 4
            let peRatio = annualizedEPS > 0 ? currentPrice / annualizedEPS : nil
            let psRatio: Double? = nil
            let pbRatio: Double? = nil
            let dividendYield: Double? = nil

            var score = 0
            if revenueGrowth > 10 { score += 20 }
            if epsGrowth > 10 { score += 20 }
            if operatingMargin > 15 { score += 20 }
            if currentRatio > 1.5 { score += 20 }
            if debtToEquity < 0.5 { score += 20 }

            let computedMetrics = FinancialMetrics(
                revenueGrowth: revenueGrowth,
                epsGrowth: epsGrowth,
                operatingMargin: operatingMargin,
                currentRatio: currentRatio,
                debtToEquity: debtToEquity,
                freeCashFlowGrowth: freeCashFlowGrowth,
                overallScore: score,
                peRatio: peRatio,
                psRatio: psRatio,
                pbRatio: pbRatio,
                dividendYield: dividendYield
            )
            
            metrics = computedMetrics
            news = try await service.fetchNews(for: symbol)
            let peers = await service.fetchPeerSymbols(for: symbol)
            peerComparisons = await service.fetchPeerComparisons(symbols: peers)
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func applyScenarioAnalysis() -> FinancialMetrics? {
        guard let m = metrics else { return nil }
        let adjustedRevenueGrowth = scenarioRevenueGrowth
        let adjustedOperatingMargin = scenarioOperatingMargin
        
        var scenarioScore = m.overallScore
        if adjustedRevenueGrowth > 10 { scenarioScore += 10 }
        if adjustedOperatingMargin > 15 { scenarioScore += 10 }
        
        return FinancialMetrics(
            revenueGrowth: adjustedRevenueGrowth,
            epsGrowth: m.epsGrowth,
            operatingMargin: adjustedOperatingMargin,
            currentRatio: m.currentRatio,
            debtToEquity: m.debtToEquity,
            freeCashFlowGrowth: m.freeCashFlowGrowth,
            overallScore: scenarioScore,
            peRatio: m.peRatio,
            psRatio: m.psRatio,
            pbRatio: m.pbRatio,
            dividendYield: m.dividendYield
        )
    }
}
