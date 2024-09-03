import Foundation
import SwiftData

@Model
final class StoredData {
    var value: Bool
    
    init(value: Bool) {
        self.value = value
    }
}

@MainActor
class Store: NSObject, ObservableObject {
    static let shared = Store()
    @Published var local: [Bool] = []
    
    var modelContext: ModelContext? = nil

    // Initialize with a SwiftData context
    override init() {
        super.init()
        
        Task { @MainActor in
            do {
                // Setup SwiftData model context on the main actor
                let container = try ModelContainer(for: StoredData.self)
                self.modelContext = container.mainContext
                self.local = retrieve(forKey: "PersistedDataKey")
            } catch {
                print("Failed to initialize SwiftData context: \(error)")
            }
        }
    }

    func persist(data: [Bool], forKey: String) {
        guard let context = modelContext else { return }
        
        Task { @MainActor in
            do {
                // Clear existing data
                let fetchDescriptor = FetchDescriptor<StoredData>()
                let results = try context.fetch(fetchDescriptor)
                results.forEach { context.delete($0) }
                
                // Save new data
                data.forEach { value in
                    let newData = StoredData(value: value)
                    context.insert(newData)
                }
                
                // Save context
                try context.save()
                
                // Update local published property
                self.local = data
            } catch {
                print("Failed to persist data: \(error)")
            }
        }
    }
    
    func retrieve(forKey: String) -> [Bool] {
        guard let context = modelContext else { return [] }
        
        do {
            // Fetch all stored data
            let fetchDescriptor = FetchDescriptor<StoredData>()
            let results = try context.fetch(fetchDescriptor)
            return results.map { $0.value }
        } catch {
            print("Failed to retrieve data: \(error)")
            return []
        }
    }
}
