import Foundation

struct IncomeStatement: Decodable {
    let date: String
    let symbol: String
    let reportedCurrency: String
    let revenue: Double
    let netIncome: Double
    let eps: Double
    let operatingIncome: Double
    let costOfRevenue: Double
    // Add more fields as needed
}

struct BalanceSheet: Decodable {
    let date: String
    let symbol: String
    let totalAssets: Double
    let totalLiabilities: Double
    let cashAndCashEquivalents: Double
    let shortTermDebt: Double
    let longTermDebt: Double
    // Add more fields as needed
}

struct FinancialMetrics {
    let revenueGrowth: Double         // percentage QoQ
    let epsGrowth: Double             // percentage QoQ
    let operatingMargin: Double       // operatingIncome/revenue * 100
    let currentRatio: Double
    let debtToEquity: Double
    let freeCashFlowGrowth: Double
    let overallScore: Int
    // Add additional computed metrics as needed
    let peRatio: Double?
    let psRatio: Double?
    let pbRatio: Double?
    let dividendYield: Double?
}

struct NewsArticle: Decodable, Identifiable {
    let id = UUID()
    let headline: String
    let source: String
    let url: String
    let summary: String
    let sentiment: String
    let publishedDate: Date
}

struct PeerComparison: Identifiable {
    let id = UUID()
    let symbol: String
    let peRatio: Double
    let epsGrowth: Double
    let revenueGrowth: Double
}
