
import SwiftUI
import Foundation
import Combine


struct Report: Identifiable, Codable {
    let id = UUID()
    let name: String
    let reportID: [UInt8]
    let scope: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case name, reportID, scope, description
    }
}

class ReportViewModel: ObservableObject {
    @Published var reports: [Report] = []
    @Published var searchText: String = ""
    @Published var selectedScope: String? = "All"
    @Published var filteredReports: [Report] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadReports()
        setupSearch()
    }
    
    func loadReports() {
        if let url = Bundle.main.url(forResource: "reports", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            if let reports = try? decoder.decode([Report].self, from: data) {
                self.reports = reports
                self.filteredReports = reports // Initialize with all reports
            }
        }
    }
    
    func setupSearch() {
        Publishers.CombineLatest($searchText, $selectedScope)
            .map { [unowned self] (searchText, selectedScope) in
                self.reports.filter { report in
                    (searchText.isEmpty || report.name.lowercased().contains(searchText.lowercased())) &&
                    (selectedScope == "All" || report.scope == selectedScope)
                }
            }
            .assign(to: &$filteredReports)
    }
}




struct SearchBar: View {
    @Binding var searchText: String
    @Binding var selectedScope: String?
    @State private var isEditing = false
    
    let scopes = ["All", "keyboard", "consumer", "mouse"]
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search...", text: $searchText, onEditingChanged: { isEditing in
                    self.isEditing = isEditing
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading)
                
                if isEditing {
                    Button("Clear") {
                        searchText = ""
                        selectedScope = "All"
                        isEditing = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .padding(.trailing)
                }
            }
            .padding()
            
            if isEditing {
                Picker("Scope", selection: $selectedScope) {
                    ForEach(scopes, id: \.self) {
                        Text($0.capitalized)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
        }
    }
}


struct ReportListView: View {
    @StateObject private var viewModel = ReportViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(searchText: $viewModel.searchText, selectedScope: $viewModel.selectedScope)
                
                List(viewModel.filteredReports) { report in
                    HStack {
                        Text(report.name)
                        Spacer()
                        Button("Action 1") {
                            // Perform action 1 with report.reportID
                            print("Action 1 for \(report.reportID)")
                        }
                        .padding(.trailing, 8)
                        .border(.red)
                        Button("Action 2") {
                            // Perform action 2 with report.reportID
                            print("Action 2 for \(report.reportID)")
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Reports")
        }
    }
}

struct ReportListView_Previews: PreviewProvider {
    static var previews: some View {
        ReportListView()
    }
}



