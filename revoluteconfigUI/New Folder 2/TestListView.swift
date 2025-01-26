
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
    @Published var isEditing: Bool = false
    
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

struct ReportListView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @StateObject private var viewModel = ReportViewModel()
    
    var body: some View {
        
       
            VStack {
                SearchBar(searchText: $viewModel.searchText, selectedScope: $viewModel.selectedScope, isEditing: $viewModel.isEditing)
                
                List(viewModel.filteredReports) { report in
                    HStack {
                        Text(report.name)
                        Spacer()
                        
                        
//                        Button(action: {
//                            print("Action 1 for \(report.reportID)")
//                            
//                        }) {
//                            Image(systemName: "digitalcrown.horizontal.arrow.clockwise")
//                                .foregroundColor(.white)
//                                .padding([.top, .leading, .trailing,.bottom])
//                            
////                                .frame(maxWidth: .infinity)
//                                .background(Color.black.opacity(0.3))
//                                .cornerRadius(16)
//                        }
                        
//                        Button(action: {
//                            print("Action 2 for \(report.reportID)")
//                            
//                        }) {
//                            Image(systemName: "digitalcrown.horizontal.arrow.counterclockwise")
//                                .foregroundColor(.white)
//                                .padding([.top, .leading, .trailing,.bottom])
////                                .frame(maxWidth: .infinity)
//                                .background(Color.black.opacity(0.3))
//                                .cornerRadius(16)
//                        }
                        
//                        Button {
//                            print("Action 1 for \(report.reportID)")
//                        } label: {
//                            Image(systemName: "digitalcrown.horizontal.arrow.counterclockwise")
//                        }
                        
                        
                        Button {
                            // Perform action 1 with report.reportID
                            
                            print("Up report written \(report.reportID)")
                            
                            if report.scope == "keyboard"{
                                bluetoothManager.writeModeReport(byteArray: [0x05] )
                                
                            }else if report.scope == "mouse"{
                                bluetoothManager.writeModeReport(byteArray: [0xD] )
                                
                                
                            }else if report.scope == "consumer" {
                                bluetoothManager.writeModeReport(byteArray: [0x09] )
                                
                                
                                
                                
                            }
                            
                            bluetoothManager.writeUpReport(byteArray: report.reportID)
                            HapticFeedbackManager.shared.playImpactFeedback()
                            
                            
                            
                            
                            
                            
                        }label: {
                            Image(systemName: "digitalcrown.horizontal.arrow.clockwise")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding([.top, .leading, .trailing,.bottom],(20))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(16)
                        .onPressGesture(
                            minimumDuration: 0.0,
                            perform: {
                                HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback on press
                            },
                            onPressingChanged: { pressing in
                                if !pressing {
                                    HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback on release
                                }
                            }
                        )
//                        .border(.red)
                        
                        Button {
                            // Perform action 1 with report.reportID
                            print("Down report written \(report.reportID)")
                            
                            
                            
                            if report.scope == "keyboard"{
                                bluetoothManager.writeModeReport(byteArray: [0x05] )
                                
                            }else if report.scope == "mouse"{
                                bluetoothManager.writeModeReport(byteArray: [0xD] )
                                
                                
                            }else if report.scope == "consumer" {
                                bluetoothManager.writeModeReport(byteArray: [0x09] )
                                
                                
                                
                                
                            }
                            
                            bluetoothManager.writeDownReport(byteArray: report.reportID)
                            
                            
                            
                            
                            HapticFeedbackManager.shared.playImpactFeedback()
                        }label: {
                            Image(systemName: "digitalcrown.horizontal.arrow.counterclockwise")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding([.top, .leading, .trailing,.bottom],(20))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(16)
                        .onPressGesture(
                            minimumDuration: 0.0,
                            perform: {
                                HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback on press
                            },
                            onPressingChanged: { pressing in
                                if !pressing {
                                    HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback on release
                                }
                            }
                        )
//                        .border(.red)
                        
                        
                        
                    
//                        Button("Action 2") {
//                            // Perform action 2 with report.reportID
//                            print("Action 2 for \(report.reportID)")
//                        }
//                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .contextMenu {
                        Text(report.description)
                    }
                }
                .listStyle(PlainListStyle())
                .cornerRadius(16)
         
        }
    }
}

struct ReportListView_Previews: PreviewProvider {
    static var previews: some View {
        ReportListView(bluetoothManager: BluetoothManager())
    }
}

struct WhiteBorder: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            
            .padding(9)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray, lineWidth:1)
            )
            
    }
}


struct SearchBar: View {
    @Binding var searchText: String
    @Binding var selectedScope: String?
    @Binding var isEditing: Bool
    
    let scopes = ["All", "keyboard", "consumer", "mouse"]
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding([.leading, .trailing],(0.7))
                
                TextField("Search...", text: $searchText, onEditingChanged: { isEditing in
                    withAnimation {
                        self.isEditing = isEditing
                    }
                })
                
                
                .textFieldStyle(WhiteBorder())
//                .padding([.top, .leading, .trailing,.bottom],(0))
//                .background(Color.black.opacity(0.3))
//                .cornerRadius(16)
                
                
//                .padding(.leading)
                
                
                if isEditing {
                    Button("Clear") {
                        withAnimation {
                            searchText = ""
                            selectedScope = "All"
                            isEditing = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                    .padding(.trailing)
                    .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale(0.3, anchor: UnitPoint(x: 0, y: 0))))
                }
            }
            .padding()
            
            if isEditing {
                Picker("Scope", selection: $selectedScope) {
                    ForEach(scopes, id: \.self) { scope in
                        Text(scope.capitalized).tag(scope as String?)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(0.8, anchor: UnitPoint(x: 0, y: 0))))
            }
        }
    }
}
