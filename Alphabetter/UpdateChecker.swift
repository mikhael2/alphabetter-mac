import Foundation
import AppKit
import Combine

class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    
    @Published var updateStatus: String = ""
    @Published var isChecking: Bool = false
    @Published var newVersionURL: URL? = nil
    

    let repoURL = "https://api.github.com/repos/mikhael2/alphabetter-mac/releases"
    
    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    func checkForUpdates() {
        isChecking = true
        updateStatus = "Checking..."
        
        guard let url = URL(string: repoURL) else {
            fail("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isChecking = false
                
                if let _ = error {
                    self?.fail("Network error")
                    return
                }
                
              
                guard let data = data,
                      let releases = try? JSONDecoder().decode([GitHubRelease].self, from: data),
                      let latestRelease = releases.first else {
                    self?.fail("No releases found")
                    return
                }
 
                let cleanServerVersion = latestRelease.tag_name
                    .replacingOccurrences(of: "v", with: "")
                    .components(separatedBy: "-").first ?? ""
                
                if self?.isUpdateAvailable(server: cleanServerVersion, local: self?.currentVersion ?? "1.0") == true {
                    self?.updateStatus = "New version available: \(latestRelease.tag_name)"
                    self?.newVersionURL = URL(string: latestRelease.html_url)
                } else {
                    self?.updateStatus = "You are up to date! (\(self?.currentVersion ?? "?"))"
                    self?.newVersionURL = nil
                }
            }
        }
        task.resume()
    }
    
    
        func downloadAndQuit() {
            if let url = newVersionURL {
                NSWorkspace.shared.open(url)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    
    private func fail(_ message: String) {
        updateStatus = "Error: \(message)"
    }
    
    private func isUpdateAvailable(server: String, local: String) -> Bool {
        return server.compare(local, options: .numeric) == .orderedDescending
    }
}

struct GitHubRelease: Decodable {
    let tag_name: String
    let html_url: String
}
