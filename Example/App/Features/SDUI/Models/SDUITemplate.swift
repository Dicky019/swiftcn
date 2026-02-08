//
//  SDUITemplate.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import Foundation

struct SDUITemplate: Identifiable, Hashable {
  let id: String
  let name: String
  let category: TemplateCategory
  let description: String
  let json: String
  
  enum TemplateCategory: String, CaseIterable {
    case basic = "Basic"
    case forms = "Forms"
    case layouts = "Layouts"
    case cards = "Cards"
  }
}

extension SDUITemplate {
  static let all: [SDUITemplate] = [
    // Basic Examples
    SDUITemplate(
      id: "hello-world",
      name: "Hello World",
      category: .basic,
      description: "Simple text and button",
      json: """
            [
              {
                "id": "1",
                "type": "vstack",
                "props": {"spacing": 16},
                "children": [
                  {"id": "2", "type": "text", "props": {"content": "Hello, SDUI!", "style": "title"}},
                  {"id": "3", "type": "text", "props": {"content": "This UI is rendered from JSON.", "style": "body"}},
                  {"id": "4", "type": "button", "props": {"label": "Get Started", "variant": "default", "actionId": "get_started"}}
                ]
              }
            ]
            """
    ),
    SDUITemplate(
      id: "button-variants",
      name: "Button Variants",
      category: .basic,
      description: "All button styles",
      json: """
            [
              {
                "id": "1",
                "type": "vstack",
                "props": {"spacing": 12},
                "children": [
                  {"id": "2", "type": "text", "props": {"content": "Button Variants", "style": "headline"}},
                  {"id": "3", "type": "button", "props": {"label": "Default", "variant": "default"}},
                  {"id": "4", "type": "button", "props": {"label": "Secondary", "variant": "secondary"}},
                  {"id": "5", "type": "button", "props": {"label": "Destructive", "variant": "destructive"}},
                  {"id": "6", "type": "button", "props": {"label": "Outline", "variant": "outline"}},
                  {"id": "7", "type": "button", "props": {"label": "Ghost", "variant": "ghost"}},
                  {"id": "8", "type": "button", "props": {"label": "Link", "variant": "link"}}
                ]
              }
            ]
            """
    ),
    SDUITemplate(
      id: "badge-showcase",
      name: "Badge Showcase",
      category: .basic,
      description: "All badge variants",
      json: """
            [
              {
                "id": "1",
                "type": "vstack",
                "props": {"spacing": 16},
                "children": [
                  {"id": "2", "type": "text", "props": {"content": "Status Badges", "style": "headline"}},
                  {
                    "id": "3",
                    "type": "hstack",
                    "props": {"spacing": 8},
                    "children": [
                      {"id": "4", "type": "badge", "props": {"label": "New"}},
                      {"id": "5", "type": "badge", "props": {"label": "Beta", "variant": "secondary"}},
                      {"id": "6", "type": "badge", "props": {"label": "Error", "variant": "destructive"}},
                      {"id": "7", "type": "badge", "props": {"label": "v1.0", "variant": "outline"}}
                    ]
                  }
                ]
              }
            ]
            """
    ),
    
    // Form Examples
    SDUITemplate(
      id: "login-form",
      name: "Login Form",
      category: .forms,
      description: "Email and password login",
      json: """
            [
              {
                "id": "1",
                "type": "vstack",
                "props": {"spacing": 20},
                "children": [
                  {"id": "2", "type": "text", "props": {"content": "Welcome Back", "style": "title"}},
                  {"id": "3", "type": "text", "props": {"content": "Sign in to continue", "style": "subheadline"}},
                  {"id": "4", "type": "input", "props": {"placeholder": "Email address", "label": "Email", "inputId": "email"}},
                  {"id": "5", "type": "input", "props": {"placeholder": "Enter password", "label": "Password", "inputId": "password"}},
                  {"id": "6", "type": "button", "props": {"label": "Sign In", "variant": "default", "size": "lg", "actionId": "login"}},
                  {"id": "7", "type": "button", "props": {"label": "Forgot Password?", "variant": "link", "actionId": "forgot_password"}}
                ]
              }
            ]
            """
    ),
    SDUITemplate(
      id: "settings-form",
      name: "Settings Form",
      category: .forms,
      description: "Toggle switches and sliders",
      json: """
            [
              {
                "id": "1",
                "type": "vstack",
                "props": {"spacing": 16},
                "children": [
                  {"id": "2", "type": "text", "props": {"content": "Settings", "style": "title"}},
                  {"id": "3", "type": "divider", "props": {}},
                  {"id": "4", "type": "switch", "props": {"label": "Dark Mode", "isOn": true, "switchId": "dark_mode"}},
                  {"id": "5", "type": "switch", "props": {"label": "Notifications", "isOn": true, "switchId": "notifications"}},
                  {"id": "6", "type": "switch", "props": {"label": "Auto-Update", "isOn": false, "switchId": "auto_update"}},
                  {"id": "7", "type": "divider", "props": {}},
                  {"id": "8", "type": "text", "props": {"content": "Volume", "style": "headline"}},
                  {"id": "9", "type": "slider", "props": {"label": "Master Volume", "value": 0.7, "min": 0, "max": 1, "sliderId": "volume"}}
                ]
              }
            ]
            """
    ),
    SDUITemplate(
      id: "feedback-form",
      name: "Feedback Form",
      category: .forms,
      description: "User feedback with rating",
      json: """
            [
              {
                "id": "1",
                "type": "vstack",
                "props": {"spacing": 16},
                "children": [
                  {"id": "2", "type": "text", "props": {"content": "Send Feedback", "style": "title"}},
                  {"id": "3", "type": "text", "props": {"content": "We'd love to hear from you!", "style": "body"}},
                  {"id": "4", "type": "input", "props": {"placeholder": "Your name", "label": "Name", "inputId": "name"}},
                  {"id": "5", "type": "input", "props": {"placeholder": "What's on your mind?", "label": "Message", "inputId": "message"}},
                  {"id": "6", "type": "text", "props": {"content": "Rating", "style": "headline"}},
                  {"id": "7", "type": "slider", "props": {"label": "How satisfied are you?", "value": 3, "min": 1, "max": 5, "step": 1, "sliderId": "rating"}},
                  {"id": "8", "type": "button", "props": {"label": "Submit Feedback", "variant": "default", "actionId": "submit_feedback"}}
                ]
              }
            ]
            """
    ),
    
    // Layout Examples
    SDUITemplate(
      id: "two-column",
      name: "Two Column Layout",
      category: .layouts,
      description: "Side by side content",
      json: """
            [
              {
                "id": "1",
                "type": "vstack",
                "props": {"spacing": 16},
                "children": [
                  {"id": "2", "type": "text", "props": {"content": "Dashboard", "style": "title"}},
                  {
                    "id": "3",
                    "type": "hstack",
                    "props": {"spacing": 16},
                    "children": [
                      {
                        "id": "4",
                        "type": "card",
                        "props": {"variant": "elevated"},
                        "children": [
                          {"id": "5", "type": "text", "props": {"content": "Users", "style": "headline"}},
                          {"id": "6", "type": "text", "props": {"content": "1,234", "style": "largeTitle"}}
                        ]
                      },
                      {
                        "id": "7",
                        "type": "card",
                        "props": {"variant": "elevated"},
                        "children": [
                          {"id": "8", "type": "text", "props": {"content": "Revenue", "style": "headline"}},
                          {"id": "9", "type": "text", "props": {"content": "$12.5K", "style": "largeTitle"}}
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
            """
    ),
    SDUITemplate(
      id: "header-content-footer",
      name: "Header/Content/Footer",
      category: .layouts,
      description: "Classic page structure",
      json: """
            [
              {
                "id": "1",
                "type": "vstack",
                "props": {"spacing": 0},
                "children": [
                  {
                    "id": "2",
                    "type": "hstack",
                    "props": {"spacing": 8},
                    "children": [
                      {"id": "3", "type": "text", "props": {"content": "App Name", "style": "headline"}},
                      {"id": "4", "type": "spacer", "props": {}},
                      {"id": "5", "type": "badge", "props": {"label": "Pro", "variant": "secondary"}}
                    ]
                  },
                  {"id": "6", "type": "divider", "props": {}},
                  {"id": "7", "type": "spacer", "props": {}},
                  {
                    "id": "8",
                    "type": "vstack",
                    "props": {"spacing": 12},
                    "children": [
                      {"id": "9", "type": "text", "props": {"content": "Main Content Area", "style": "title"}},
                      {"id": "10", "type": "text", "props": {"content": "This is where your primary content goes.", "style": "body"}}
                    ]
                  },
                  {"id": "11", "type": "spacer", "props": {}},
                  {"id": "12", "type": "divider", "props": {}},
                  {"id": "13", "type": "text", "props": {"content": "© 2026 swiftcn", "style": "caption"}}
                ]
              }
            ]
            """
    ),
    
    // Card Examples
    SDUITemplate(
      id: "product-card",
      name: "Product Card",
      category: .cards,
      description: "E-commerce product display",
      json: """
            [
              {
                "id": "1",
                "type": "card",
                "props": {"variant": "elevated"},
                "children": [
                  {
                    "id": "2",
                    "type": "vstack",
                    "props": {"spacing": 12},
                    "children": [
                      {
                        "id": "3",
                        "type": "hstack",
                        "props": {"spacing": 8},
                        "children": [
                          {"id": "4", "type": "text", "props": {"content": "Premium Headphones", "style": "headline"}},
                          {"id": "5", "type": "spacer", "props": {}},
                          {"id": "6", "type": "badge", "props": {"label": "New"}}
                        ]
                      },
                      {"id": "7", "type": "text", "props": {"content": "High-quality wireless headphones with active noise cancellation.", "style": "body"}},
                      {
                        "id": "8",
                        "type": "hstack",
                        "props": {"spacing": 8},
                        "children": [
                          {"id": "9", "type": "text", "props": {"content": "$299", "style": "title"}},
                          {"id": "10", "type": "spacer", "props": {}},
                          {"id": "11", "type": "button", "props": {"label": "Add to Cart", "variant": "default", "actionId": "add_to_cart"}}
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
            """
    ),
    SDUITemplate(
      id: "notification-card",
      name: "Notification Card",
      category: .cards,
      description: "Alert/notification style",
      json: """
            [
              {
                "id": "1",
                "type": "card",
                "props": {"variant": "outlined"},
                "children": [
                  {
                    "id": "2",
                    "type": "vstack",
                    "props": {"spacing": 12},
                    "children": [
                      {
                        "id": "3",
                        "type": "hstack",
                        "props": {"spacing": 8},
                        "children": [
                          {"id": "4", "type": "text", "props": {"content": "Update Available", "style": "headline"}},
                          {"id": "5", "type": "badge", "props": {"label": "v2.0", "variant": "secondary"}}
                        ]
                      },
                      {"id": "6", "type": "text", "props": {"content": "A new version is available with bug fixes and improvements.", "style": "body"}},
                      {
                        "id": "7",
                        "type": "hstack",
                        "props": {"spacing": 8},
                        "children": [
                          {"id": "8", "type": "button", "props": {"label": "Update Now", "variant": "default", "size": "sm", "actionId": "update"}},
                          {"id": "9", "type": "button", "props": {"label": "Later", "variant": "ghost", "size": "sm", "actionId": "dismiss"}}
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
            """
    )
  ]
  
  static func templates(for category: TemplateCategory) -> [SDUITemplate] {
    all.filter { $0.category == category }
  }
}
