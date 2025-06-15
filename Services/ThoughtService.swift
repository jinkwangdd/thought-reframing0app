import Foundation

class ThoughtService {
    private let thoughtsKey = "savedThoughts"
    
    func loadThoughts() async throws -> [Thought] {
        guard let data = UserDefaults.standard.data(forKey: thoughtsKey) else {
            return []
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([Thought].self, from: data)
    }
    
    func saveThoughts(_ thoughts: [Thought]) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(thoughts)
        UserDefaults.standard.set(data, forKey: thoughtsKey)
    }
} 