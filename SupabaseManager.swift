//
//  SupabaseManager.swift
//  StageTimePNW
//
//  Created by viradeth on 8/24/26.
//

import Foundation
import Supabase

// MARK: - Supabase Shared Client
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://ldodkbdzljfpbnzrpxpu.supabase.co")!,
    supabaseKey:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxkb2RrYmR6bGpmcGJuenJweHB1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY1OTEyMDMsImV4cCI6MjEwMjE2NzIwM30.QMlA_hQ-FazldCZGQ11lvXRNS77nnwHy26RSBR6rS5Q"
)
