import type { Metadata } from "next";

export type PanelNavGroupId = "utilities" | "archive";

export interface PanelNavItem {
  href: string;
  title: string;
  icon?: string;
  description?: string;
}

export interface PanelNavGroup {
  id: PanelNavGroupId;
  title: string;
  description?: string;
  collapsedByDefault?: boolean;
  links: PanelNavItem[];
}

export interface PanelNavigation {
  root: PanelNavItem;
  groups: PanelNavGroup[];
}

export interface PanelBreadcrumb {
  href?: string;
  label: string;
  current?: boolean;
}

const defaultDescription =
  "Unified operations environment for the Insurance Command program and supporting tooling.";

const panelRoot: PanelNavItem = {
  href: "/insurance",
  title: "Insurance Command Hub",
  icon: "🛡️",
  description:
    "Operational console for insurance submissions, underwriting workflows, and approvals.",
};

const adminUtilitiesGroup: PanelNavGroup = {
  id: "utilities",
  title: "Operations Toolkit",
  description: "Cross-functional controls that support the Insurance Command program.",
  links: [
    { href: "/notifications", title: "Alerts Center" },
    { href: "/logs", title: "System Logs" },
    { href: "/settings", title: "Workspace Settings" },
    { href: "/users", title: "Customer Directory" },
    { href: "/trips", title: "Trip Ledger" },
    { href: "/marketplace", title: "Marketplace" },
    { href: "/menus", title: "Menu Operations" },
    { href: "/files", title: "File Vault" },
    { href: "/qr", title: "Token Programs" },
    { href: "/whatsapp-health", title: "Messaging Health" },
    { href: "/live-calls", title: "Live Calls" },
    { href: "/voice-analytics", title: "Voice Analytics" },
    { href: "/vendor-responses", title: "Vendor Inbox" },
    { href: "/negotiations", title: "Negotiation Desk" },
    { href: "/agent-orchestration", title: "Agent Orchestration" },
    { href: "/wallet/topup", title: "Wallet Top-up" },
  ],
};

const legacyArchiveGroup: PanelNavGroup = {
  id: "archive",
  title: "Legacy Archive",
  description: "In-flight destinations retained while the migration completes.",
  collapsedByDefault: true,
  links: [
    { href: "/dashboard", title: "Legacy Dashboard" },
    { href: "/sessions", title: "Legacy Sessions" },
    { href: "/agents", title: "Agents" },
    { href: "/agents/dashboard", title: "Agents Dashboard" },
    { href: "/agents/[id]", title: "Agent Details" },
    { href: "/ai", title: "AI Prototypes" },
    { href: "/bars", title: "Bars" },
    { href: "/marketplace/settings", title: "Marketplace Settings" },
  ],
};

const archiveVisible =
  (process.env.NEXT_PUBLIC_SHOW_LEGACY_NAV ?? "false").trim().toLowerCase() === "true";

const allGroups: PanelNavGroup[] = [adminUtilitiesGroup, legacyArchiveGroup];

export const panelNavigation: PanelNavigation = {
  root: panelRoot,
  groups: allGroups.filter(
    (group) => group.id !== "archive" || archiveVisible,
  ),
};

const routeMetadata: Record<string, { title: string; description: string }> = {
  [panelRoot.href]: {
    title: panelRoot.title,
    description: panelRoot.description ?? defaultDescription,
  },
  "/notifications": {
    title: "Alerts Center",
    description: "Preview outbound alerts and confirm delivery health across channels.",
  },
  "/logs": {
    title: "System Logs",
    description: "Investigate platform events, webhook retries, and integration noise.",
  },
  "/settings": {
    title: "Workspace Settings",
    description: "Toggle feature flags, update credentials, and manage rollout controls.",
  },
  "/users": {
    title: "Customer Directory",
    description: "Search operators, review profiles, and stage messaging follow-ups.",
  },
  "/trips": {
    title: "Trip Ledger",
    description: "Audit trip requests, expirations, and fulfillment states across tenants.",
  },
  "/marketplace": {
    title: "Marketplace",
    description: "Review vendor onboarding health and catalog configuration progress.",
  },
  "/marketplace/settings": {
    title: "Marketplace Settings",
    description: "Adjust vendor entitlements, contact windows, and subscription quotas.",
  },
  "/menus": {
    title: "Menu Operations",
    description: "Manage menu syncs, price accuracy checks, and content completeness.",
  },
  "/files": {
    title: "File Vault",
    description: "Inspect uploaded assets, OCR extracts, and pipeline processing states.",
  },
  "/qr": {
    title: "Token Programs",
    description: "Generate ordering codes and confirm routing details for storefronts.",
  },
  "/whatsapp-health": {
    title: "Messaging Health",
    description: "Monitor template delivery, opt-outs, and live conversation health.",
  },
  "/live-calls": {
    title: "Live Calls",
    description: "Observe call center volume, connect rates, and agent assignment flow.",
  },
  "/voice-analytics": {
    title: "Voice Analytics",
    description: "Review transcription quality and AI scoring pipelines for calls.",
  },
  "/vendor-responses": {
    title: "Vendor Inbox",
    description: "Track marketplace vendor replies, SLAs, and negotiation outcomes.",
  },
  "/negotiations": {
    title: "Negotiation Desk",
    description: "Inspect AI-led negotiation transcripts and pricing adjustments.",
  },
  "/agent-orchestration": {
    title: "Agent Orchestration",
    description: "Monitor multi-agent registry, health metrics, and rollout cadence.",
  },
  "/wallet/topup": {
    title: "Wallet Top-up",
    description: "Provision platform wallets, apply FX, and credit vendor balances.",
  },
  "/dashboard": {
    title: "Legacy Dashboard",
    description: "Historical metrics retained during the Insurance Agent migration.",
  },
  "/sessions": {
    title: "Legacy Sessions",
    description: "Archive of prior agent sessions for reference during migration.",
  },
  "/agents": {
    title: "Agents",
    description: "Legacy agent registry management interface.",
  },
  "/agents/dashboard": {
    title: "Agents Dashboard",
    description: "Legacy dashboard for monitoring aggregate agent performance.",
  },
  "/agents/[id]": {
    title: "Agent Details",
    description: "Legacy detail view for managing individual agent assets and runs.",
  },
  "/ai": {
    title: "AI Prototypes",
    description: "Experimental AI flows maintained for regression testing.",
  },
  "/bars": {
    title: "Bars",
    description: "Historic data visualisations awaiting migration.",
  },
  "/leads": {
    title: "Leads",
    description: "Inspect marketing-sourced leads before routing into Insurance Agent.",
  },
  "/sessions/[id]": {
    title: "Session Details",
    description: "Legacy session drill-in retained for auditing conversations.",
  },
  "/vendor-responses/[id]": {
    title: "Vendor Response",
    description: "Legacy vendor response review page.",
  },
};

const routeIndex = new Map<string, { title: string; groupId?: PanelNavGroupId }>();
routeIndex.set(panelRoot.href, { title: panelRoot.title });
for (const group of allGroups) {
  for (const link of group.links) {
    routeIndex.set(link.href, { title: link.title, groupId: group.id });
  }
}

function normalizePath(pathname: string): string {
  if (!pathname) return "/";
  const value = pathname.split("?")[0].replace(/\/+$/, "");
  return value === "" ? "/" : value;
}

function titleize(segment: string): string {
  return segment
    .split(/[\s/-]+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function findLongestMatch(pathname: string) {
  let match: { title: string; groupId?: PanelNavGroupId; href: string } | undefined;
  for (const [href, value] of routeIndex.entries()) {
    if (pathname === href || pathname.startsWith(`${href}/`)) {
      if (!match || href.length > match.href.length) {
        match = { ...value, href };
      }
    }
  }
  return match;
}

export function buildPanelBreadcrumbs(
  pathname: string,
  currentLabel?: string,
): PanelBreadcrumb[] {
  const normalized = normalizePath(pathname);
  const breadcrumbs: PanelBreadcrumb[] = [];

  breadcrumbs.push({
    href: panelRoot.href,
    label: panelRoot.title,
    current: normalized === panelRoot.href,
  });

  if (normalized === panelRoot.href) {
    if (currentLabel) {
      breadcrumbs[0].label = currentLabel;
    }
    return breadcrumbs;
  }

  const match = findLongestMatch(normalized);
  const isExactMatch = match && match.href === normalized;

  if (match?.groupId) {
    const group = allGroups.find((entry) => entry.id === match.groupId);
    if (group) {
      breadcrumbs[0].current = false;
      breadcrumbs.push({ label: group.title });
    }
  } else {
    breadcrumbs[0].current = false;
  }

  if (match) {
    breadcrumbs.push({
      href: match.href,
      label: match.title,
      current: isExactMatch && !currentLabel,
    });
  }

  if (!isExactMatch) {
    const startIndex = match ? match.href.split("/").filter(Boolean).length : 0;
    const segments = normalized.split("/").filter(Boolean);
    let accumulator = match ? match.href : "";

    for (let index = startIndex; index < segments.length; index += 1) {
      const segment = segments[index];
      accumulator = `${accumulator}/${segment}`.replace(/\/+/, "/");
      const isLast = index === segments.length - 1;
      breadcrumbs.push({
        href: accumulator,
        label: isLast && currentLabel ? currentLabel : titleize(segment),
        current: isLast,
      });
    }
  } else if (currentLabel) {
    breadcrumbs[breadcrumbs.length - 1] = {
      ...(breadcrumbs[breadcrumbs.length - 1] ?? {}),
      href: match.href,
      label: currentLabel,
      current: true,
    };
  }

  return breadcrumbs.map((crumb, index, array) => ({
    ...crumb,
    current: index === array.length - 1,
  }));
}

export function createPanelPageMetadata(pathname: string): Metadata {
  const normalized = normalizePath(pathname);
  const entry = routeMetadata[normalized];
  const title = entry?.title ?? panelRoot.title;
  const description = entry?.description ?? defaultDescription;

  return {
    title,
    description,
    alternates: {
      canonical: normalized,
    },
  } satisfies Metadata;
}

export function getRouteMetadata(pathname: string) {
  const normalized = normalizePath(pathname);
  return routeMetadata[normalized];
}

