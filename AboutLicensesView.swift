import SwiftUI

struct AboutLicensesView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Third-party Licenses")) {
                    NavigationLink("Alamofire - MIT") {
                        ScrollView { Text(try! String(contentsOfFile: Bundle.main.path(forResource: "LICENSES/ALAMOFIRE_LICENSE", ofType: "md")!)) }
                    }
                    NavigationLink("Kingfisher - MIT") {
                        ScrollView { Text(try! String(contentsOfFile: Bundle.main.path(forResource: "LICENSES/KINGFISHER_LICENSE", ofType: "md")!)) }
                    }
                }
                Section(header: Text("Policies")) {
                    NavigationLink("Privacy Policy") {
                        ScrollView { Text(try! String(contentsOfFile: Bundle.main.path(forResource: "PRIVACY_POLICY", ofType: "md")!)) }
                    }
                    NavigationLink("AI Disclaimer") {
                        ScrollView { Text(try! String(contentsOfFile: Bundle.main.path(forResource: "AI_DISCLAIMER", ofType: "md")!)) }
                    }
                }
            }
            .navigationTitle("About & Licenses")
        }
    }
}

#if DEBUG
struct AboutLicensesView_Previews: PreviewProvider {
    static var previews: some View {
        AboutLicensesView()
    }
}
#endif
