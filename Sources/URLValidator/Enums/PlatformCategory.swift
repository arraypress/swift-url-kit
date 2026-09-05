//
//  PlatformCategory.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

/// The family a platform belongs to.
public enum PlatformCategory: String, CaseIterable, Sendable, Codable {
    case video = "Video"
    case audio = "Audio"
    case social = "Social Media"
    case messaging = "Messaging"
    case developer = "Developer"
    case ecommerce = "E-commerce"
    case cloud = "Cloud Storage"
    case streaming = "Live Streaming"
    case productivity = "Productivity"
    case maps = "Maps"
    case news = "News & Publishing"
    case learning = "E-Learning"
    case web3 = "Web3 & Crypto"
    case gaming = "Gaming"
    case financial = "Financial"
    case dating = "Dating"
    case food = "Food Delivery"
    case travel = "Travel & Booking"
    case subscription = "Subscription Platforms"
    case alternative = "Alternative Tech"
    case regional = "Regional"
    case ai = "AI Assistants"
    case entertainment = "Film, TV & Books"
    case reference = "Reference & Research"
    case fitness = "Health & Fitness"
    case events = "Events & Tickets"
    case crowdfunding = "Crowdfunding"
    case images = "Images & Design"
    case apps = "App Stores"
    case unknown = "Unknown"
}
