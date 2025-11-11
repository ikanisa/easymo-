"use client";

import classNames from "classnames";
import { NavigationBreadcrumbs } from "./NavigationBreadcrumbs";
import { NavigationSearch } from "./NavigationSearch";

interface NavigationTopbarProps {
  environmentLabel: string;
  actorLabel: string;
  actorInitials: string;
  signingOut: boolean;
  assistantEnabled: boolean;
  onOpenAssistant?: () => void;
  onSignOut: () => Promise<void>;
  onOpenNavigation?: () => void;
  navigationId: string;
  navigationOpen: boolean;
}

export function NavigationTopbar({
  environmentLabel,
  actorLabel,
  actorInitials,
  signingOut,
  assistantEnabled,
  onOpenAssistant,
  onSignOut,
  onOpenNavigation,
  navigationId,
  navigationOpen,
}: NavigationTopbarProps) {
  return (
    <header className="panel-topbar" role="banner">
      <div className="panel-topbar__primary">
        <button
          type="button"
          className={classNames("panel-topbar__menu", {
            "panel-topbar__menu--visible": Boolean(onOpenNavigation),
          })}
          onClick={onOpenNavigation}
          aria-label="Open navigation"
          aria-controls={navigationId}
          aria-expanded={navigationOpen}
          aria-haspopup="dialog"
        >
          ☰
        </button>
        <div className="panel-topbar__meta">
          <p className="panel-topbar__title">Operations Hub</p>
          <span className="panel-chip">{environmentLabel}</span>
        </div>
        <NavigationBreadcrumbs />
      </div>
      <div className="panel-topbar__secondary">
        <NavigationSearch />
        <div className="panel-topbar__actions">
          <button type="button" className="panel-icon-button" aria-label="Notifications">
            🔔
          </button>
          {assistantEnabled && (
            <button
              type="button"
              className="panel-icon-button"
              onClick={onOpenAssistant}
              aria-label="Open assistant"
            >
              🤖
            </button>
          )}
          <button
            type="button"
            className="panel-icon-button"
            onClick={() => onSignOut()}
            disabled={signingOut}
          >
            <span aria-hidden>{signingOut ? "…" : "⇦"}</span>
            <span className="visually-hidden">Sign out</span>
          </button>
          <div className="panel-avatar" aria-label={actorLabel} role="img">
            {actorInitials}
          </div>
        </div>
      </div>
    </header>
  );
}
