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
  let description: String
  let tags: [String]
  let json: String
}

extension SDUITemplate {
  static let all: [SDUITemplate] = [
    // 1. E-Commerce Checkout Experience (Default)
    SDUITemplate(
      id: "ecommerce-checkout",
      name: "E-Commerce Checkout",
      description: "Full cart & order experience with sliders, switches, badges, and cards",
      tags: ["Card", "Slider", "Switch", "Input", "Button"],
      json: """
            [
              {
                "id": "root",
                "type": "vstack",
                "props": { "spacing": 16 },
                "children": [
                  {
                    "id": "header_hstack",
                    "type": "hstack",
                    "props": { "spacing": 8 },
                    "children": [
                      { "id": "t1", "type": "text", "props": { "content": "Shopping Cart", "style": "title" } },
                      { "id": "sp1", "type": "spacer", "props": {} },
                      { "id": "b1", "type": "badge", "props": { "label": "2 Items", "variant": "secondary" } }
                    ]
                  },
                  {
                    "id": "card_item1",
                    "type": "card",
                    "props": { "variant": "elevated" },
                    "children": [
                      {
                        "id": "card1_vstack",
                        "type": "vstack",
                        "props": { "spacing": 12 },
                        "children": [
                          {
                            "id": "card1_h1",
                            "type": "hstack",
                            "props": { "spacing": 8 },
                            "children": [
                              { "id": "card1_title", "type": "text", "props": { "content": "Studio Pro Headphones", "style": "headline" } },
                              { "id": "sp2", "type": "spacer", "props": {} },
                              { "id": "b_sale", "type": "badge", "props": { "label": "-20% OFF", "variant": "destructive" } }
                            ]
                          },
                          { "id": "card1_desc", "type": "text", "props": { "content": "Wireless over-ear with spatial audio and active noise cancellation.", "style": "body" } },
                          { "id": "div1", "type": "divider", "props": {} },
                          { "id": "card1_slider", "type": "slider", "props": { "label": "Quantity", "value": 1, "min": 1, "max": 5, "step": 1, "showValue": true, "sliderId": "item_qty" } },
                          {
                            "id": "card1_h2",
                            "type": "hstack",
                            "props": { "spacing": 8 },
                            "children": [
                              { "id": "card1_price", "type": "text", "props": { "content": "$240.00", "style": "title2" } },
                              { "id": "sp3", "type": "spacer", "props": {} },
                              { "id": "btn_wishlist", "type": "button", "props": { "label": "Wishlist", "variant": "ghost", "size": "sm", "actionId": "add_wishlist" } }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  {
                    "id": "card_delivery",
                    "type": "card",
                    "props": { "variant": "outlined" },
                    "children": [
                      {
                        "id": "delivery_vstack",
                        "type": "vstack",
                        "props": { "spacing": 14 },
                        "children": [
                          { "id": "del_title", "type": "text", "props": { "content": "Delivery & Options", "style": "headline" } },
                          { "id": "sw_express", "type": "switch", "props": { "label": "Express Priority Shipping", "isOn": true, "switchId": "express_shipping" } },
                          { "id": "sw_gift", "type": "switch", "props": { "label": "Eco-Friendly Gift Wrapping", "isOn": false, "switchId": "gift_wrap" } },
                          { "id": "inp_promo", "type": "input", "props": { "label": "Promo Code", "placeholder": "e.g. SWIFTCN20", "inputId": "promo_code" } }
                        ]
                      }
                    ]
                  },
                  {
                    "id": "card_summary",
                    "type": "card",
                    "props": { "variant": "filled" },
                    "children": [
                      {
                        "id": "summary_vstack",
                        "type": "vstack",
                        "props": { "spacing": 12 },
                        "children": [
                          {
                            "id": "sum_h1",
                            "type": "hstack",
                            "props": { "spacing": 8 },
                            "children": [
                              { "id": "sum_label", "type": "text", "props": { "content": "Estimated Total", "style": "headline" } },
                              { "id": "sp4", "type": "spacer", "props": {} },
                              { "id": "sum_val", "type": "text", "props": { "content": "$255.00", "style": "title" } }
                            ]
                          },
                          { "id": "btn_checkout", "type": "button", "props": { "label": "Complete Order 🚀", "variant": "default", "size": "lg", "actionId": "checkout_completed" } }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
            """
    ),

    // 2. SaaS Analytics & Cloud Dashboard
    SDUITemplate(
      id: "saas-dashboard",
      name: "SaaS Analytics & Cloud",
      description: "Multi-column metrics grid, cloud resource sliders, and deployment toggles",
      tags: ["Metrics", "Card", "Slider", "Switch", "Button"],
      json: """
            [
              {
                "id": "root",
                "type": "vstack",
                "props": { "spacing": 16 },
                "children": [
                  {
                    "id": "dash_h1",
                    "type": "hstack",
                    "props": { "spacing": 8 },
                    "children": [
                      { "id": "d_title", "type": "text", "props": { "content": "Cloud Cluster 01", "style": "title" } },
                      { "id": "sp1", "type": "spacer", "props": {} },
                      { "id": "b_online", "type": "badge", "props": { "label": "Online", "variant": "default" } }
                    ]
                  },
                  { "id": "d_sub", "type": "text", "props": { "content": "Real-time telemetry and cluster controls", "style": "subheadline" } },
                  {
                    "id": "metrics_hstack",
                    "type": "hstack",
                    "props": { "spacing": 12 },
                    "children": [
                      {
                        "id": "m1_card",
                        "type": "card",
                        "props": { "variant": "elevated" },
                        "children": [
                          {
                            "id": "m1_v",
                            "type": "vstack",
                            "props": { "spacing": 6 },
                            "children": [
                              { "id": "m1_lbl", "type": "text", "props": { "content": "Requests / sec", "style": "caption" } },
                              { "id": "m1_val", "type": "text", "props": { "content": "4,821", "style": "title" } },
                              { "id": "m1_bdg", "type": "badge", "props": { "label": "+12.4%", "variant": "secondary" } }
                            ]
                          }
                        ]
                      },
                      {
                        "id": "m2_card",
                        "type": "card",
                        "props": { "variant": "elevated" },
                        "children": [
                          {
                            "id": "m2_v",
                            "type": "vstack",
                            "props": { "spacing": 6 },
                            "children": [
                              { "id": "m2_lbl", "type": "text", "props": { "content": "Error Rate", "style": "caption" } },
                              { "id": "m2_val", "type": "text", "props": { "content": "0.02%", "style": "title" } },
                              { "id": "m2_bdg", "type": "badge", "props": { "label": "Nominal", "variant": "outline" } }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  {
                    "id": "card_controls",
                    "type": "card",
                    "props": { "variant": "outlined" },
                    "children": [
                      {
                        "id": "ctl_v",
                        "type": "vstack",
                        "props": { "spacing": 14 },
                        "children": [
                          { "id": "ctl_h", "type": "text", "props": { "content": "Performance Tuning", "style": "headline" } },
                          { "id": "sl_cpu", "type": "slider", "props": { "label": "CPU Throttle Limit (%)", "value": 75, "min": 10, "max": 100, "step": 5, "showValue": true, "sliderId": "cpu_limit" } },
                          { "id": "sl_mem", "type": "slider", "props": { "label": "Max Memory Buffer (GB)", "value": 16, "min": 2, "max": 64, "step": 2, "showValue": true, "sliderId": "mem_buffer" } },
                          { "id": "div2", "type": "divider", "props": {} },
                          { "id": "sw_autoscale", "type": "switch", "props": { "label": "Dynamic Auto-Scaling", "isOn": true, "switchId": "autoscale_toggle" } },
                          { "id": "sw_backup", "type": "switch", "props": { "label": "Hourly Snapshots", "isOn": false, "switchId": "backup_toggle" } }
                        ]
                      }
                    ]
                  },
                  {
                    "id": "actions_hstack",
                    "type": "hstack",
                    "props": { "spacing": 12 },
                    "children": [
                      { "id": "btn_scale", "type": "button", "props": { "label": "Deploy Changes", "variant": "default", "size": "md", "actionId": "deploy_cluster" } },
                      { "id": "btn_flush", "type": "button", "props": { "label": "Flush Cache", "variant": "secondary", "size": "md", "actionId": "flush_cache" } }
                    ]
                  }
                ]
              }
            ]
            """
    ),

    // 3. Smart Account & Security Hub
    SDUITemplate(
      id: "smart-settings",
      name: "Account & Security Hub",
      description: "Credential inputs, biometrics toggles, and destructive danger zones",
      tags: ["Security", "Input", "Switch", "Slider", "Destructive"],
      json: """
            [
              {
                "id": "root",
                "type": "vstack",
                "props": { "spacing": 16 },
                "children": [
                  {
                    "id": "prof_h",
                    "type": "hstack",
                    "props": { "spacing": 8 },
                    "children": [
                      { "id": "p_title", "type": "text", "props": { "content": "Developer Settings", "style": "title" } },
                      { "id": "sp1", "type": "spacer", "props": {} },
                      { "id": "b_tier", "type": "badge", "props": { "label": "Pro Tier", "variant": "secondary" } }
                    ]
                  },
                  {
                    "id": "card_identity",
                    "type": "card",
                    "props": { "variant": "elevated" },
                    "children": [
                      {
                        "id": "id_v",
                        "type": "vstack",
                        "props": { "spacing": 12 },
                        "children": [
                          { "id": "id_hdr", "type": "text", "props": { "content": "API Credentials", "style": "headline" } },
                          { "id": "inp_name", "type": "input", "props": { "label": "Organization ID", "placeholder": "org_swiftcn_987", "inputId": "org_id" } },
                          { "id": "inp_key", "type": "input", "props": { "label": "Production API Token", "placeholder": "sk_live_...", "inputId": "api_token" } }
                        ]
                      }
                    ]
                  },
                  {
                    "id": "card_security",
                    "type": "card",
                    "props": { "variant": "outlined" },
                    "children": [
                      {
                        "id": "sec_v",
                        "type": "vstack",
                        "props": { "spacing": 14 },
                        "children": [
                          { "id": "sec_hdr", "type": "text", "props": { "content": "Security & Sessions", "style": "headline" } },
                          { "id": "sw_2fa", "type": "switch", "props": { "label": "Enforce Hardware 2FA", "isOn": true, "switchId": "hardware_2fa" } },
                          { "id": "sw_ip", "type": "switch", "props": { "label": "IP Whitelist Guard", "isOn": true, "switchId": "ip_guard" } },
                          { "id": "sl_session", "type": "slider", "props": { "label": "Session Timeout (minutes)", "value": 30, "min": 5, "max": 120, "step": 5, "showValue": true, "sliderId": "session_timeout" } }
                        ]
                      }
                    ]
                  },
                  {
                    "id": "card_danger",
                    "type": "card",
                    "props": { "variant": "filled" },
                    "children": [
                      {
                        "id": "danger_v",
                        "type": "vstack",
                        "props": { "spacing": 10 },
                        "children": [
                          { "id": "d_title", "type": "text", "props": { "content": "Danger Zone", "style": "headline" } },
                          { "id": "d_desc", "type": "text", "props": { "content": "Immediately invalidate active tokens across all devices.", "style": "caption" } },
                          {
                            "id": "d_actions",
                            "type": "hstack",
                            "props": { "spacing": 8 },
                            "children": [
                              { "id": "btn_revoke", "type": "button", "props": { "label": "Revoke Keys", "variant": "destructive", "size": "md", "actionId": "revoke_keys" } },
                              { "id": "btn_lock", "type": "button", "props": { "label": "Lock Workspace", "variant": "outline", "size": "md", "actionId": "lock_workspace" } }
                            ]
                          }
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
}
