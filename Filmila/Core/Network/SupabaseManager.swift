import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: Supabase.SupabaseClient

    private init() {
        let url = Env.supabaseURL
        let anonKey = Env.supabaseAnonKey
        let options = SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                storage: KeychainLocalStorage()
            )
        )
        client = Supabase.SupabaseClient(supabaseURL: url, supabaseKey: anonKey, options: options)
    }
}
