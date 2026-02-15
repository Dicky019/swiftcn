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
    case interactive = "Interactive"
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
      description: "Dashboard with stat cards",
      json: """
            [
              {
                "id": "root",
                "type": "vstack",
                "props": {"spacing": 16},
                "children": [
                  {
                    "id": "header",
                    "type": "hstack",
                    "props": {"spacing": 8},
                    "children": [
                      {"id": "title", "type": "text", "props": {"content": "Dashboard", "style": "title"}},
                      {"id": "spacer_h", "type": "spacer", "props": {}},
                      {"id": "status", "type": "badge", "props": {"label": "Live", "variant": "default"}}
                    ]
                  },
                  {"id": "subtitle", "type": "text", "props": {"content": "Your overview at a glance", "style": "subheadline"}},
                  {
                    "id": "row1",
                    "type": "hstack",
                    "props": {"spacing": 12},
                    "children": [
                      {
                        "id": "card_users",
                        "type": "card",
                        "props": {"variant": "elevated"},
                        "children": [
                          {
                            "id": "card_users_inner",
                            "type": "vstack",
                            "props": {"spacing": 4},
                            "children": [
                              {"id": "users_label", "type": "text", "props": {"content": "Users", "style": "caption"}},
                              {"id": "users_value", "type": "text", "props": {"content": "1,234", "style": "title"}},
                              {"id": "users_badge", "type": "badge", "props": {"label": "+12%", "variant": "secondary"}}
                            ]
                          }
                        ]
                      },
                      {
                        "id": "card_revenue",
                        "type": "card",
                        "props": {"variant": "elevated"},
                        "children": [
                          {
                            "id": "card_revenue_inner",
                            "type": "vstack",
                            "props": {"spacing": 4},
                            "children": [
                              {"id": "revenue_label", "type": "text", "props": {"content": "Revenue", "style": "caption"}},
                              {"id": "revenue_value", "type": "text", "props": {"content": "$12.5K", "style": "title"}},
                              {"id": "revenue_badge", "type": "badge", "props": {"label": "+8.3%", "variant": "secondary"}}
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  {
                    "id": "row2",
                    "type": "hstack",
                    "props": {"spacing": 12},
                    "children": [
                      {
                        "id": "card_orders",
                        "type": "card",
                        "props": {"variant": "outlined"},
                        "children": [
                          {
                            "id": "card_orders_inner",
                            "type": "vstack",
                            "props": {"spacing": 4},
                            "children": [
                              {"id": "orders_label", "type": "text", "props": {"content": "Orders", "style": "caption"}},
                              {"id": "orders_value", "type": "text", "props": {"content": "356", "style": "title"}},
                              {"id": "orders_badge", "type": "badge", "props": {"label": "Pending 5", "variant": "outline"}}
                            ]
                          }
                        ]
                      },
                      {
                        "id": "card_conversion",
                        "type": "card",
                        "props": {"variant": "outlined"},
                        "children": [
                          {
                            "id": "card_conv_inner",
                            "type": "vstack",
                            "props": {"spacing": 4},
                            "children": [
                              {"id": "conv_label", "type": "text", "props": {"content": "Conversion", "style": "caption"}},
                              {"id": "conv_value", "type": "text", "props": {"content": "4.2%", "style": "title"}},
                              {"id": "conv_badge", "type": "badge", "props": {"label": "-0.5%", "variant": "destructive"}}
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  {"id": "div", "type": "divider", "props": {}},
                  {
                    "id": "actions",
                    "type": "hstack",
                    "props": {"spacing": 8},
                    "children": [
                      {"id": "btn_detail", "type": "button", "props": {"label": "View Details", "variant": "default", "navigate": "detail"}},
                      {"id": "btn_settings", "type": "button", "props": {"label": "Settings", "variant": "outline", "navigate": "settings"}}
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
      description: "Profile page structure",
      json: """
            [
              {
                "id": "root",
                "type": "vstack",
                "props": {"spacing": 12},
                "children": [
                  {
                    "id": "header",
                    "type": "hstack",
                    "props": {"spacing": 8},
                    "children": [
                      {
                        "id": "header_left",
                        "type": "vstack",
                        "props": {"spacing": 2},
                        "children": [
                          {"id": "app_name", "type": "text", "props": {"content": "My Profile", "style": "headline"}},
                          {"id": "app_sub", "type": "text", "props": {"content": "Manage your account", "style": "caption"}}
                        ]
                      },
                      {"id": "spacer_h", "type": "spacer", "props": {}},
                      {"id": "plan_badge", "type": "badge", "props": {"label": "Pro", "variant": "default"}}
                    ]
                  },
                  {"id": "div1", "type": "divider", "props": {}},
                  {
                    "id": "content",
                    "type": "vstack",
                    "props": {"spacing": 16},
                    "children": [
                      {
                        "id": "info_card",
                        "type": "card",
                        "props": {},
                        "children": [
                          {
                            "id": "info_inner",
                            "type": "vstack",
                            "props": {"spacing": 12},
                            "children": [
                              {"id": "info_title", "type": "text", "props": {"content": "Account Info", "style": "headline"}},
                              {"id": "input_name", "type": "input", "props": {"placeholder": "Your name", "label": "Display Name", "inputId": "name"}},
                              {"id": "input_email", "type": "input", "props": {"placeholder": "you@example.com", "label": "Email", "inputId": "email"}}
                            ]
                          }
                        ]
                      },
                      {
                        "id": "prefs_card",
                        "type": "card",
                        "props": {},
                        "children": [
                          {
                            "id": "prefs_inner",
                            "type": "vstack",
                            "props": {"spacing": 12},
                            "children": [
                              {"id": "prefs_title", "type": "text", "props": {"content": "Preferences", "style": "headline"}},
                              {"id": "sw_dark", "type": "switch", "props": {"label": "Dark Mode", "isOn": true, "switchId": "dark_mode"}},
                              {"id": "sw_notif", "type": "switch", "props": {"label": "Notifications", "isOn": true, "switchId": "notifications"}}
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  {"id": "div2", "type": "divider", "props": {}},
                  {
                    "id": "footer",
                    "type": "hstack",
                    "props": {"spacing": 8},
                    "children": [
                      {"id": "footer_text", "type": "text", "props": {"content": "swiftcn v1.0", "style": "caption"}},
                      {"id": "spacer_f", "type": "spacer", "props": {}},
                      {"id": "btn_save", "type": "button", "props": {"label": "Save", "variant": "default", "size": "sm", "actionId": "submit_feedback"}},
                      {"id": "btn_cancel", "type": "button", "props": {"label": "Cancel", "variant": "ghost", "size": "sm", "actionId": "dismiss"}}
                    ]
                  }
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
    ),

    // Interactive Examples
    SDUITemplate(
      id: "full-example",
      name: "Full Example",
      category: .interactive,
      description: "Actions, navigation, and counter",
      json: """
            [
              {
                "id": "root",
                "type": "vstack",
                "props": {"spacing": 16},
                "children": [
                  {"id": "title", "type": "text", "props": {"content": "Full Example", "style": "title"}},
                  {
                    "id": "counter_section",
                    "type": "card",
                    "props": {},
                    "children": [
                      {
                        "id": "counter_content",
                        "type": "vstack",
                        "props": {"spacing": 12},
                        "children": [
                          {"id": "counter_label", "type": "text", "props": {"content": "Counter", "style": "headline"}},
                          {"id": "counter_hint", "type": "text", "props": {"content": "Tap the buttons and watch the Action Log", "style": "caption"}},
                          {
                            "id": "counter_buttons",
                            "type": "hstack",
                            "props": {"spacing": 8},
                            "children": [
                              {"id": "btn_decrement", "type": "button", "props": {"label": "−", "variant": "outline", "actionId": "count_decrement"}},
                              {"id": "btn_increment", "type": "button", "props": {"label": "+", "variant": "default", "actionId": "count_increment"}},
                              {"id": "btn_reset", "type": "button", "props": {"label": "Reset", "variant": "secondary", "actionId": "count_reset"}}
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  {"id": "nav_header", "type": "text", "props": {"content": "Navigation", "style": "headline"}},
                  {
                    "id": "nav_section",
                    "type": "vstack",
                    "props": {"spacing": 8},
                    "children": [
                      {"id": "btn_settings", "type": "button", "props": {"label": "Go to Settings", "variant": "default", "navigate": "settings"}},
                      {"id": "btn_components", "type": "button", "props": {"label": "Go to Components", "variant": "secondary", "navigate": "components"}},
                      {"id": "btn_comp_button", "type": "button", "props": {"label": "Button Detail", "variant": "outline", "navigate": "components_button"}},
                      {"id": "btn_comp_card", "type": "button", "props": {"label": "Card Detail", "variant": "outline", "navigate": "components_card"}},
                      {"id": "btn_comp_slider", "type": "button", "props": {"label": "Slider Detail", "variant": "outline", "navigate": "components_slider"}}
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
