"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { buildPanelBreadcrumbs } from "@/components/layout/nav-items";

interface NavigationBreadcrumbsProps {
  currentLabel?: string;
}

export function NavigationBreadcrumbs({ currentLabel }: NavigationBreadcrumbsProps) {
  const pathname = usePathname() ?? "/";
  const breadcrumbs = buildPanelBreadcrumbs(pathname, currentLabel);

  if (breadcrumbs.length <= 1) {
    return null;
  }

  return (
    <nav aria-label="Breadcrumb" className="panel-breadcrumbs">
      <ol>
        {breadcrumbs.map((crumb) => {
          const label = crumb.label;
          if (!crumb.href || crumb.current) {
            return (
              <li key={label} aria-current={crumb.current ? "page" : undefined}>
                <span>{label}</span>
              </li>
            );
          }

          return (
            <li key={label}>
              <Link href={crumb.href}>{label}</Link>
            </li>
          );
        })}
      </ol>
    </nav>
  );
}
