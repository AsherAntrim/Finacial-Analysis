//
//  ContentView.swift
//  Finacial Analysis
//
//  Created by Asher Antrim on 12/20/24.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var viewModel = FinancialViewModel()
    @EnvironmentObject var watchlist: WatchlistManager
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter ticker (e.g. AAPL)", text: $viewModel.symbol)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                if viewModel.isLoading {
                    ProgressView("Analyzing...")
                } else if let metrics = viewModel.metrics {
                    ScrollView {
                        FinancialMetricsView(metrics: metrics)
                            .environmentObject(settings)
                        
                        // Revenue Chart
                        if !viewModel.historicalData.isEmpty {
                            ChartSection(title: "Revenue Over Time",
                                         dataPoints: viewModel.historicalData,
                                         formatter: formatNumberShort)
                        }

                        // EPS Chart
                        if !viewModel.epsData.isEmpty {
                            ChartSection(title: "EPS Over Time",
                                         dataPoints: viewModel.epsData,
                                         formatter: { val in String(format: "%.2f", val) })
                        }
                        
                        // Net Income Chart (new)
                        if !viewModel.netIncomeData.isEmpty {
                            ChartSection(title: "Net Income Over Time",
                                         dataPoints: viewModel.netIncomeData,
                                         formatter: formatNumberShort)
                        }

                        // Operating Income Chart (new)
                        if !viewModel.operatingIncomeData.isEmpty {
                            ChartSection(title: "Operating Income Over Time",
                                         dataPoints: viewModel.operatingIncomeData,
                                         formatter: formatNumberShort)
                        }
                        
                        // Link to detailed data
                        NavigationLink("View Detailed Financial Data") {
                            FinancialDataDetailView(
                                incomeStatements: viewModel.incomeStatements,
                                balanceSheets: viewModel.balanceSheets
                            )
                        }
                        .padding()

                        NavigationLink("View News", destination: NewsView(articles: viewModel.news))
                        NavigationLink("View Peer Comparison", destination: PeerComparisonView(peers: viewModel.peerComparisons))
                        NavigationLink("Scenario Analysis", destination: ScenarioAnalysisView().environmentObject(viewModel))
                    }
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }

                Spacer()

                Button("Analyze") {
                    Task {
                        await viewModel.analyze()
                    }
                }
                .padding()
            }
            .navigationTitle("Quarterly Earnings Analyzer")
        }
    }
}

struct ChartSection: View {
    let title: String
    let dataPoints: [(Date, Double)]
    let formatter: (Double) -> String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.leading)
            Chart {
                ForEach(dataPoints, id: \.0) { (date, value) in
                    LineMark(
                        x: .value("Date", date),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(.blue)
                    PointMark(
                        x: .value("Date", date),
                        y: .value("Value", value)
                    )
                    .annotation(position: .top) {
                        Text(formatter(value))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 250)
            .padding()
        }
    }
}


struct FinancialMetricsView: View {
    let metrics: FinancialMetrics
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        List {
            Section(header: Text("Growth Metrics").font(.headline)) {
                metricRow(label: "Revenue Growth QoQ:", value: formatPercentage(metrics.revenueGrowth))
                metricRow(label: "EPS Growth QoQ:", value: formatPercentage(metrics.epsGrowth))
            }
            
            Section(header: Text("Profitability & Ratios").font(.headline)) {
                metricRow(label: "Operating Margin:", value: formatPercentage(metrics.operatingMargin))
                metricRow(label: "Current Ratio:", value: String(format: "%.2f", metrics.currentRatio))
                metricRow(label: "Debt/Equity:", value: String(format: "%.2f", metrics.debtToEquity))
            }
            
            Section(header: Text("Cash Flow & Score").font(.headline)) {
                metricRow(label: "Free Cash Flow Growth:", value: formatPercentage(metrics.freeCashFlowGrowth))
                metricRow(label: "Overall Score:", value: "\(metrics.overallScore)/100")
            }
            
            if settings.showAdvancedMetrics {
                Section(header: Text("Valuation Metrics").font(.headline)) {
                    metricRow(label: "P/E Ratio:", value: formattedOptional(metrics.peRatio))
                    metricRow(label: "P/S Ratio:", value: formattedOptional(metrics.psRatio))
                    metricRow(label: "P/B Ratio:", value: formattedOptional(metrics.pbRatio))
                    metricRow(label: "Dividend Yield:", value: metrics.dividendYield != nil ? formatPercentage(metrics.dividendYield!) : "N/A")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.body)
        }
    }
    
    func formattedOptional(_ val: Double?) -> String {
        if let v = val {
            return String(format: "%.2f", v)
        } else {
            return "N/A"
        }
    }
}

struct TrendChartView: View {
    let dataPoints: [(Date, Double)]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)
            Chart {
                ForEach(dataPoints, id: \.0) { (date, value) in
                    LineMark(
                        x: .value("Date", date),
                        y: .value("Value", value)
                    )
                }
            }
            .frame(height: 200)
        }
        .padding()
    }
}

struct NewsView: View {
    let articles: [NewsArticle]
    
    var body: some View {
        List(articles) { article in
            VStack(alignment: .leading, spacing: 8) {
                Text(article.headline)
                    .font(.headline)
                Text(article.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Source: \(article.source)")
                    Spacer()
                    Text(article.sentiment)
                        .foregroundColor(article.sentiment == "Positive" ? .green : (article.sentiment == "Negative" ? .red : .gray))
                }
                .font(.footnote)
            }
            .onTapGesture {
                if let url = URL(string: article.url) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .navigationTitle("News")
    }
}

struct PeerComparisonView: View {
    let peers: [PeerComparison]
    
    var body: some View {
        List(peers) { peer in
            VStack(alignment: .leading) {
                Text(peer.symbol)
                    .font(.headline)
                HStack {
                    Text("P/E: \(peer.peRatio, specifier: "%.2f")")
                    Spacer()
                    Text("EPS Growth: \(peer.epsGrowth, specifier: "%.2f")%")
                    Spacer()
                    Text("Revenue Growth: \(peer.revenueGrowth, specifier: "%.2f")%")
                }
                .font(.subheadline)
            }
        }
        .navigationTitle("Peer Comparison")
    }
}

struct ScenarioAnalysisView: View {
    @EnvironmentObject var viewModel: FinancialViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Adjust Assumptions")) {
                Stepper("Revenue Growth: \(viewModel.scenarioRevenueGrowth, specifier: "%.1f")%", value: $viewModel.scenarioRevenueGrowth, in: 0...50, step: 0.5)
                Stepper("Operating Margin: \(viewModel.scenarioOperatingMargin, specifier: "%.1f")%", value: $viewModel.scenarioOperatingMargin, in: 0...50, step: 0.5)
            }
            
            if let scenarioMetrics = viewModel.applyScenarioAnalysis() {
                Section(header: Text("Scenario Metrics")) {
                    Text("Overall Score: \(scenarioMetrics.overallScore)")
                    Text("Revenue Growth: \(scenarioMetrics.revenueGrowth, specifier: "%.2f")%")
                    Text("Operating Margin: \(scenarioMetrics.operatingMargin, specifier: "%.2f")%")
                }
            } else {
                Text("Run analysis first.")
            }
        }
        .navigationTitle("Scenario Analysis")
    }
}

struct WatchlistView: View {
    @EnvironmentObject var watchlist: WatchlistManager
    @State private var newTicker: String = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("Add Ticker", text: $newTicker)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Add") {
                    if !newTicker.isEmpty {
                        watchlist.addTicker(newTicker)
                        newTicker = ""
                    }
                }
            }
            .padding()
            
            List {
                ForEach(watchlist.watchlist, id: \.self) { ticker in
                    Text(ticker)
                }
                .onDelete { indices in
                    indices.forEach { idx in
                        watchlist.removeTicker(watchlist.watchlist[idx])
                    }
                }
            }
        }
        .navigationTitle("Watchlist")
    }
}

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        Form {
            Toggle("Show Advanced Metrics", isOn: $settings.showAdvancedMetrics)
            
            Picker("Theme", selection: $settings.preferredTheme) {
                Text("System").tag("System")
                Text("Light").tag("Light")
                Text("Dark").tag("Dark")
            }
        }
        .navigationTitle("Settings")
    }
}

struct FinancialDataDetailView: View {
    let incomeStatements: [IncomeStatement]
    let balanceSheets: [BalanceSheet]

    var body: some View {
        List {
            Section(header: Text("Income Statements (Last 5 Quarters)").font(.headline)) {
                ForEach(incomeStatements.prefix(5), id: \.date) { stmt in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date: \(stmt.date)").font(.subheadline).bold()
                        Text("Revenue: \(formatCurrency(stmt.revenue))")
                        Text("Net Income: \(formatCurrency(stmt.netIncome))")
                        Text("EPS: \(String(format: "%.2f", stmt.eps))")
                        Text("Operating Income: \(formatCurrency(stmt.operatingIncome))")
                        Text("Cost of Revenue: \(formatCurrency(stmt.costOfRevenue))")
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section(header: Text("Balance Sheets (Last 5 Quarters)").font(.headline)) {
                ForEach(balanceSheets.prefix(5), id: \.date) { bs in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date: \(bs.date)").font(.subheadline).bold()
                        Text("Total Assets: \(formatCurrency(bs.totalAssets))")
                        Text("Total Liabilities: \(formatCurrency(bs.totalLiabilities))")
                        Text("Cash & Equivalents: \(formatCurrency(bs.cashAndCashEquivalents))")
                        Text("Short Term Debt: \(formatCurrency(bs.shortTermDebt))")
                        Text("Long Term Debt: \(formatCurrency(bs.longTermDebt))")
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Detailed Financial Data")
    }
}
