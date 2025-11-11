"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  HomeIcon,
  UsersIcon,
  TruckIcon,
  MapPinIcon,
  ChartBarIcon,
  CogIcon,
} from "@heroicons/react/24/outline";

const navigation = [
  { name: "Mission Control", href: "/v2/dashboard", icon: HomeIcon },
  { name: "Agent Directory", href: "/v2/agents", icon: UsersIcon },
  { name: "Driver Ops", href: "/v2/drivers", icon: TruckIcon },
  { name: "Station Network", href: "/v2/stations", icon: MapPinIcon },
  { name: "Insights", href: "/v2/analytics", icon: ChartBarIcon },
  { name: "Workspace Settings", href: "/v2/settings", icon: CogIcon },
] as const;

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="dashboard-shell__sidebar">
      <div className="dashboard-shell__sidebar-inner">
        <div className="dashboard-shell__sidebar-header">
          <h1 className="dashboard-shell__sidebar-title">EasyMO Admin</h1>
        </div>

        <nav className="flex-1 p-4" aria-label="Secondary">
          <ul className="space-y-1">
        <nav className="dashboard-shell__sidebar-nav" aria-label="Primary">
          <ul>
            {navigation.map((item) => {
              const isActive = pathname?.startsWith(item.href);

              return (
                <li key={item.name}>
                  <Link
                    href={item.href}
                    className={[
                      "flex items-center gap-3 px-3 py-2 rounded-lg transition-colors duration-150",
                      isActive
                        ? "bg-blue-50 text-blue-600"
                        : "text-gray-700 hover:bg-gray-50",
                    ].join(" ")}
                    aria-current={isActive ? "page" : undefined}
                      "dashboard-shell__sidebar-link",
                      isActive ? "dashboard-shell__sidebar-link--active" : "",
                    ]
                      .join(" ")
                      .trim()}
                  >
                    <item.icon className="dashboard-shell__sidebar-icon" />
                    <span>{item.name}</span>
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>
      </div>
    </aside>
  );
}
