"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import classNames from "classnames";
import { NAV_SECTIONS } from "@/components/layout/nav-items";

interface NavigationSidebarProps {
  id: string;
  variant?: "desktop" | "overlay";
  onRequestClose?: () => void;
  headingId?: string;
}

export function NavigationSidebar({
  id,
  variant = "desktop",
  onRequestClose,
  headingId,
}: NavigationSidebarProps) {
  const pathname = usePathname();

  const isActive = (href: string) => {
    if (!pathname) return false;
    if (href === "/") {
      return pathname === "/";
    }
    return pathname === href || pathname.startsWith(`${href}/`);
  };

  return (
    <aside
      id={id}
      className={classNames("panel-sidebar", {
        "panel-sidebar--overlay": variant === "overlay",
      })}
      aria-label="Primary navigation"
    >
      <div className="panel-sidebar__header">
        <div
          className="panel-sidebar__brand"
          aria-label="easyMO Command Center"
          id={headingId}
        >
          <span className="panel-sidebar__glyph" aria-hidden>
            ◎
          </span>
          <div>
            <p className="panel-sidebar__title">easyMO</p>
            <p className="panel-sidebar__subtitle">Command Center</p>
          </div>
        </div>
        {variant === "overlay" && (
          <button
            type="button"
            className="panel-sidebar__close"
            onClick={onRequestClose}
            aria-label="Close navigation"
          >
            ✕
          </button>
        )}
      </div>
      <nav className="panel-sidebar__sections" aria-label="Sections">
        {NAV_SECTIONS.map((section) => (
          <div key={section.title} className="panel-sidebar__section">
            <p className="panel-sidebar__section-label">{section.title}</p>
            <ul>
              {section.items.map((item) => {
                const active = isActive(item.href);
                return (
                  <li key={item.href}>
                    <Link
                      href={item.href}
                      className={classNames("panel-sidebar__link", {
                        "panel-sidebar__link--active": active,
                      })}
                      aria-current={active ? "page" : undefined}
                      onClick={variant === "overlay" ? onRequestClose : undefined}
                    >
                      <span className="panel-sidebar__icon" aria-hidden>
                        {item.icon}
                      </span>
                      <span className="panel-sidebar__label">{item.title}</span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </nav>
    </aside>
  );
}
