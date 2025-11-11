export {
  panelNavigation as PANEL_NAVIGATION,
  type PanelNavigation,
  type PanelNavGroup,
  type PanelNavItem,
  type PanelNavGroupId,
  type PanelBreadcrumb,
  buildPanelBreadcrumbs,
  createPanelPageMetadata,
  getRouteMetadata,
} from "@/lib/panel-navigation";
import { isFeatureFlagEnabled } from "@/lib/flags";

// Core navigation sections
const commandDeckItems = [
  { href: "/dashboard", title: "Mission Control", icon: "🛰️" },
  { href: "/analytics", title: "Operational Insights", icon: "📈" },
];

// AI Agents section - Main focus of the platform
const agentProgramItems = [
  { href: "/agents/overview", title: "Agent Roster", icon: "🧭" },
  { href: "/agents/dashboard", title: "Performance Console", icon: "🤖" },
  { href: "/agents/driver-negotiation", title: "Mobility Negotiator", icon: "🚕" },
  { href: "/agents/pharmacy", title: "Health Supply Agent", icon: "💊" },
  { href: "/agents/shops", title: "Retail Ops Agent", icon: "🛍️" },
  { href: "/agents/quincaillerie", title: "Hardware Ops Agent", icon: "🛠️" },
  { href: "/agents/property-rental", title: "Housing Agent", icon: "🏘️" },
  { href: "/agents/schedule-trip", title: "Itinerary Agent", icon: "🗺️" },
  { href: "/agents/conversations", title: "Live Conversations", icon: "💬" },
  { href: "/agents/instructions", title: "Playbook Library", icon: "📘" },
  { href: "/agents/learning", title: "Enablement Studio", icon: "🧠" },
  { href: "/agents/performance", title: "Scorecards", icon: "📊" },
  { href: "/agents/settings", title: "Agent Controls", icon: "⚙️" },
  { href: "/agents/tools", title: "Tool Registry", icon: "🗃️" },
];

// Operations section - Active sessions and monitoring
const liveOperationsItems = [
  { href: "/tasks", title: "Task Orchestrator", icon: "✅" },
  { href: "/sessions", title: "Active Missions", icon: "🚀" },
  { href: "/negotiations", title: "Negotiation Desk", icon: "🤝" },
  { href: "/vendor-responses", title: "Vendor Inbox", icon: "📨" },
  { href: "/video/jobs", title: "Video Pipelines", icon: "🎬" },
];

// Business modules
const partnerNetworkItems = [
  { href: "/users", title: "Customer Directory", icon: "👥" },
  { href: "/trips", title: "Trip Ledger", icon: "🧾" },
  { href: "/insurance", title: "Insurance Desk", icon: "🛡️" },
  { href: "/marketplace", title: "Marketplace", icon: "🏪" },
  { href: "/pharmacies", title: "Pharmacy Partners", icon: "💊" },
  { href: "/quincailleries", title: "Hardware Partners", icon: "🔧" },
  { href: "/shops", title: "Retail Partners", icon: "🛒" },
  { href: "/bars", title: "Hospitality", icon: "🍽️" },
  { href: "/property-rentals", title: "Property Rentals", icon: "🏠" },
  { href: "/qr", title: "Token Programs", icon: "💳" },
];

// Marketing & Sales
const growthSignalsItems = [
  { href: "/leads", title: "Lead Intake", icon: "🎯" },
  { href: "/live-calls", title: "Live Calls", icon: "📞" },
  { href: "/voice-analytics", title: "Voice Analytics", icon: "🎙️" },
  { href: "/video/analytics", title: "Video Analytics", icon: "🎬" },
];

// System & Settings
const platformControlsItems = [
  { href: "/tools", title: "Integrations", icon: "🔌" },
  { href: "/logs", title: "System Logs", icon: "📝" },
  { href: "/whatsapp-health", title: "Messaging Health", icon: "💚" },
  { href: "/settings", title: "Workspace Settings", icon: "⚙️" },
  { href: "/settings/admin", title: "Admin Controls", icon: "🛡️" },
];

const uiKitEnabled = (process.env.NEXT_PUBLIC_UI_V2_ENABLED ?? "false").trim().toLowerCase() === "true";
const adminHubV2Enabled = isFeatureFlagEnabled("adminHubV2");

const hubNavItems = [
  { href: "/hub", title: "Admin Hub", icon: "✨" },
];

// Organize navigation with sections
export const NAV_SECTIONS = adminHubV2Enabled
  ? [{ title: "Hub", items: hubNavItems }]
  : [
      { title: "Command Deck", items: commandDeckItems },
      { title: "Agent Programs", items: agentProgramItems },
      { title: "Live Operations", items: liveOperationsItems },
      { title: "Partner Network", items: partnerNetworkItems },
      { title: "Growth Signals", items: growthSignalsItems },
      { title: "Platform", items: platformControlsItems },
    ];

// Flat list for backward compatibility
const baseNavItems = [
  ...commandDeckItems,
  ...agentProgramItems,
  ...liveOperationsItems,
  ...partnerNetworkItems,
  ...growthSignalsItems,
  ...platformControlsItems,
];

const legacyNavItems = uiKitEnabled
  ? [...baseNavItems, { href: "/design-system", title: "Design System", icon: "🎨" }]
  : baseNavItems;

export const NAV_ITEMS = adminHubV2Enabled ? hubNavItems : legacyNavItems;
