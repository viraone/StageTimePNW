import Foundation
import Supabase

/// Shared Supabase client, configured from `AppConfig` so the backend can be
/// swapped per build configuration or per process environment.
let supabase = SupabaseClient(
    supabaseURL: AppConfig.current.supabaseURL,
    supabaseKey: AppConfig.current.supabaseAnonKey
)
