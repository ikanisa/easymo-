"use client";

import { ReactNode, useEffect, useId, useState } from "react";
import { usePathname } from "next/navigation";
import classNames from "classnames";
import { NavigationSidebar } from "./NavigationSidebar";
import { NavigationTopbar } from "./NavigationTopbar";

interface NavigationChromeProps {
  children: ReactNode;
  environmentLabel: string;
  actorLabel: string;
  actorInitials: string;
  signingOut: boolean;
  onSignOut: () => Promise<void>;
  assistantEnabled: boolean;
  onOpenAssistant?: () => void;
}

export function NavigationChrome({
  children,
  environmentLabel,
  actorLabel,
  actorInitials,
  signingOut,
  onSignOut,
  assistantEnabled,
  onOpenAssistant,
}: NavigationChromeProps) {
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const pathname = usePathname();
  const baseId = useId();
  const desktopNavId = `${baseId}-desktop-nav`;
  const mobileNavId = `${baseId}-mobile-nav`;
  const desktopHeadingId = `${baseId}-desktop-heading`;
  const mobileHeadingId = `${baseId}-mobile-heading`;

  useEffect(() => {
    setMobileNavOpen(false);
  }, [pathname]);

  useEffect(() => {
    if (!mobileNavOpen) {
      return undefined;
    }
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setMobileNavOpen(false);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [mobileNavOpen]);

  return (
    <div className="panel-chrome">
      <a className="panel-skip-link" href="#main-content">
        Skip to main content
      </a>
      <NavigationSidebar id={desktopNavId} headingId={desktopHeadingId} />
      <div className="panel-chrome__workspace">
        <NavigationTopbar
          environmentLabel={environmentLabel}
          actorLabel={actorLabel}
          actorInitials={actorInitials}
          signingOut={signingOut}
          assistantEnabled={assistantEnabled}
          onOpenAssistant={onOpenAssistant}
          onSignOut={onSignOut}
          onOpenNavigation={() => setMobileNavOpen(true)}
          navigationId={mobileNavId}
          navigationOpen={mobileNavOpen}
        />
        <main id="main-content" className="panel-chrome__content" aria-live="polite" tabIndex={-1}>
          {children}
        </main>
      </div>
      <div
        className={classNames("panel-chrome__mobile", {
          "panel-chrome__mobile--visible": mobileNavOpen,
        })}
        aria-hidden={!mobileNavOpen}
      >
        <button
          type="button"
          className="panel-chrome__backdrop"
          aria-label="Close navigation"
          onClick={() => setMobileNavOpen(false)}
        />
        <div
          className="panel-chrome__dialog"
          role="dialog"
          aria-modal="true"
          aria-labelledby={mobileHeadingId}
        >
          <NavigationSidebar
            id={mobileNavId}
            variant="overlay"
            onRequestClose={() => setMobileNavOpen(false)}
            headingId={mobileHeadingId}
          />
        </div>
      </div>
    </div>
  );
}
