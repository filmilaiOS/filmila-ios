import Supabase
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task {
            await Self.persistApnsToken(hex: hex)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("APNs registration failed: \(error.localizedDescription)")
        #endif
    }

    private static func persistApnsToken(hex: String) async {
        do {
            let client = SupabaseManager.shared.client
            let userId = try await client.auth.session.user.id
            struct ProfileApnsUpdate: Encodable {
                let apnsToken: String
                enum CodingKeys: String, CodingKey {
                    case apnsToken = "apns_token"
                }
            }
            try await client.from("profiles")
                .update(ProfileApnsUpdate(apnsToken: hex))
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            // No session or offline; token will be refreshed on next launch after sign-in.
        }
    }
}
