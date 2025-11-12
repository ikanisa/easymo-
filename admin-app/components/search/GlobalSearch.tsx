"use client";

import {
  useCallback,
  useEffect,
  useId,
  useMemo,
  useRef,
  useState,
  type ChangeEvent,
  type KeyboardEvent as ReactKeyboardEvent,
} from "react";
import classNames from "classnames";
import { AlertCircle, Loader2, Search, Sparkles } from "lucide-react";

import type {
  OmniSearchResult,
  OmniSearchSuggestion,
} from "@/lib/omnisearch/types";

import styles from "./GlobalSearch.module.css";

type SearchItem =
  | { type: "suggestion"; value: OmniSearchSuggestion }
  | { type: "result"; value: OmniSearchResult };

interface SearchResponse {
  query: string;
  results: OmniSearchResult[];
  suggestions: OmniSearchSuggestion[];
}

interface GlobalSearchProps {
  placeholder?: string;
  onResultSelect?: (result: OmniSearchResult) => void;
}

const MIN_QUERY_LENGTH = 2;

function isEditableTarget(target: EventTarget | null) {
  if (!target) return false;
  if (target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement) {
    return !target.readOnly && !target.disabled;
  }
  if (target instanceof HTMLSelectElement) {
    return !target.disabled;
  }
  if (target instanceof HTMLElement) {
    if (target.isContentEditable) return true;
    const editableAncestor = target.closest(
      "input, textarea, select, [contenteditable=\"\"], [contenteditable=\"true\"]",
    );
    if (!editableAncestor) return false;
    if (
      editableAncestor instanceof HTMLInputElement ||
      editableAncestor instanceof HTMLTextAreaElement
    ) {
      return !editableAncestor.readOnly && !editableAncestor.disabled;
    }
    if (editableAncestor instanceof HTMLSelectElement) {
      return !editableAncestor.disabled;
    }
    return editableAncestor instanceof HTMLElement && editableAncestor.isContentEditable;
  }
  return false;
}

export function GlobalSearch({
  placeholder = "Search agents, requests, policies…",
  onResultSelect,
}: GlobalSearchProps) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [results, setResults] = useState<OmniSearchResult[]>([]);
  const [suggestions, setSuggestions] = useState<OmniSearchSuggestion[]>([]);
  const [activeIndex, setActiveIndex] = useState(0);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const inputRef = useRef<HTMLInputElement | null>(null);
  const requestRef = useRef<AbortController | null>(null);
  const lastQueryRef = useRef<string | null>(null);
  const listboxId = useId();

  const showingResults = query.trim().length >= MIN_QUERY_LENGTH;

  const items: SearchItem[] = useMemo(() => {
    if (showingResults) {
      return results.map((value) => ({ type: "result", value }));
    }
    return suggestions.map((value) => ({ type: "suggestion", value }));
  }, [results, showingResults, suggestions]);

  const resetActiveIndex = useCallback(() => setActiveIndex(0), []);

  const closePanel = useCallback(() => {
    setOpen(false);
    requestRef.current?.abort();
    requestRef.current = null;
    lastQueryRef.current = null;
    resetActiveIndex();
  }, [resetActiveIndex]);

  const fetchResults = useCallback(
    async (search: string) => {
      requestRef.current?.abort();
      const controller = new AbortController();
      requestRef.current = controller;
      setStatus("loading");
      setErrorMessage(null);

      try {
        const response = await fetch(
          `/api/omnisearch?q=${encodeURIComponent(search)}`,
          { signal: controller.signal },
        );
        if (!response.ok) {
          throw new Error(`Search request failed (${response.status}).`);
        }
        const payload = (await response.json()) as SearchResponse;
        if (!controller.signal.aborted) {
          setResults(payload.results);
          setSuggestions(payload.suggestions);
          setStatus("idle");
        }
      } catch (error) {
        if (controller.signal.aborted) return;
        setStatus("error");
        setErrorMessage(
          error instanceof Error
            ? error.message
            : "We couldn’t load search results. Try again.",
        );
      }
    },
    [],
  );

  useEffect(() => {
    if (!open) return undefined;

    const trimmed = query.trim();
    if (lastQueryRef.current === trimmed) {
      return undefined;
    }

    const handle = window.setTimeout(() => {
      lastQueryRef.current = trimmed;
      void fetchResults(trimmed);
    }, trimmed ? 160 : 0);

    return () => {
      window.clearTimeout(handle);
      requestRef.current?.abort();
    };
  }, [fetchResults, open, query]);

  useEffect(() => {
    if (typeof window === "undefined") {
      return undefined;
    }

    const handleGlobalShortcut = (event: KeyboardEvent) => {
      const key = typeof event.key === "string" ? event.key.toLowerCase() : "";
      const usingMeta = event.metaKey && key === "k";
      const usingCtrl = event.ctrlKey && key === "k";

      if ((!usingMeta && !usingCtrl) || event.defaultPrevented) {
        return;
      }

      const targetNode = event.target instanceof Node ? event.target : null;
      if (
        isEditableTarget(event.target) &&
        (!targetNode || !containerRef.current?.contains(targetNode))
      ) {
        return;
      }

      event.preventDefault();

      if (open) {
        closePanel();
        return;
      }

      setOpen(true);
    };

    window.addEventListener("keydown", handleGlobalShortcut);
    return () => {
      window.removeEventListener("keydown", handleGlobalShortcut);
    };
  }, [closePanel, open]);

  useEffect(() => {
    if (!open) return undefined;
    const handle = (event: MouseEvent) => {
      if (!inputRef.current) return;
      if (event.target instanceof Node) {
        const container = inputRef.current.closest(`.${styles.container}`);
        if (container && !container.contains(event.target)) {
          closePanel();
        }
      }
    };
    document.addEventListener("mousedown", handle);
    return () => document.removeEventListener("mousedown", handle);
  }, [closePanel, open]);

  useEffect(() => {
    if (open) {
      inputRef.current?.focus();
    }
  }, [open]);

  const handleFocus = useCallback(() => {
    setOpen(true);
  }, []);

  const handleChange = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setQuery(event.target.value);
    resetActiveIndex();
  }, [resetActiveIndex]);

  const handleClear = useCallback(() => {
    setQuery("");
    resetActiveIndex();
    setResults([]);
    setSuggestions([]);
    lastQueryRef.current = null;
    void fetchResults("");
    inputRef.current?.focus();
  }, [fetchResults, resetActiveIndex]);

  const handleResultSelection = useCallback(
    (result: OmniSearchResult) => {
      window.dispatchEvent(
        new CustomEvent("admin-search", {
          detail: { query: query.trim(), result },
        }),
      );
      onResultSelect?.(result);
      closePanel();
    },
    [closePanel, onResultSelect, query],
  );

  const handleSuggestionSelection = useCallback(
    (suggestion: OmniSearchSuggestion) => {
      setQuery(suggestion.query);
      resetActiveIndex();
      lastQueryRef.current = null;
    },
    [resetActiveIndex],
  );

  const handleKeyDown = useCallback(
    (event: ReactKeyboardEvent<HTMLInputElement>) => {
      if (!open && (event.key === "ArrowDown" || event.key === "ArrowUp")) {
        setOpen(true);
        return;
      }

      if (event.key === "Escape") {
        event.preventDefault();
        closePanel();
        return;
      }

      if (event.key === "ArrowDown") {
        event.preventDefault();
        setActiveIndex((prev) => (prev + 1) % Math.max(items.length, 1));
        return;
      }

      if (event.key === "ArrowUp") {
        event.preventDefault();
        setActiveIndex((prev) =>
          prev - 1 < 0 ? Math.max(items.length - 1, 0) : prev - 1,
        );
        return;
      }

      if (event.key === "Enter") {
        event.preventDefault();
        const current = items[activeIndex];
        if (!current) {
          window.dispatchEvent(
            new CustomEvent("admin-search", {
              detail: { query: query.trim() },
            }),
          );
          return;
        }
        if (current.type === "suggestion") {
          setQuery(current.value.query);
          resetActiveIndex();
          lastQueryRef.current = null;
          return;
        }
        if (current.type === "result") {
          handleResultSelection(current.value);
        }
      }
    },
    [activeIndex, closePanel, handleResultSelection, items, open, query, resetActiveIndex],
  );

  const renderHighlight = useCallback(
    (text: string) => {
      const trimmed = query.trim();
      if (trimmed.length < MIN_QUERY_LENGTH) {
        return text;
      }
      const pattern = new RegExp(
        `(${trimmed.replace(/[.*+?^${}()|[\\]\\]/g, "\\$&")})`,
        "ig",
      );
      const parts = text.split(pattern);
      return parts.map((part, index) =>
        index % 2 === 1 ? (
          <span key={`${part}-${index}`} className={styles.highlight}>
            {part}
          </span>
        ) : (
          <span key={`${part}-${index}`}>{part}</span>
        ),
      );
    },
    [query],
  );

  const statusMessage = useMemo(() => {
    if (status === "loading") {
      return "Searching workspace…";
    }
    if (status === "error" && errorMessage) {
      return errorMessage;
    }
    return null;
  }, [errorMessage, status]);

  return (
    <div ref={containerRef} className={styles.container}>
      <div className={styles.inputWrapper}>
        <Search className="h-4 w-4 text-slate-400" aria-hidden />
        <input
          ref={inputRef}
          type="search"
          className={styles.searchInput}
          placeholder={placeholder}
          value={query}
          onFocus={handleFocus}
          onChange={handleChange}
          onKeyDown={handleKeyDown}
          aria-label="Search admin workspace"
          role="combobox"
          aria-expanded={open}
          aria-haspopup="listbox"
          aria-controls={listboxId}
          aria-autocomplete="list"
        />
        {query && (
          <button
            type="button"
            onClick={handleClear}
            className={styles.clearButton}
            aria-label="Clear search"
          >
            ×
          </button>
        )}
        <kbd
          className="hidden select-none rounded border border-slate-200 bg-white px-2 py-0.5 text-[0.65rem] text-slate-500 md:block"
          aria-hidden
        >
          ⌘K / Ctrl+K
        </kbd>
      </div>

      {open && (
        <div
          className={styles.panel}
          role="listbox"
          id={listboxId}
          aria-label="Global search suggestions"
        >
          <div className={styles.panelHeader}>
            <span className={styles.panelTitle}>
              {showingResults ? "Results" : "Suggested"}
            </span>
            <span className={styles.shortcutsHint}>
              {showingResults ? "Press Enter to open" : "Start typing to search"}
            </span>
          </div>

          {status === "loading" && (
            <div className={styles.statusLine} role="status">
              <Loader2 className="mr-2 inline h-3.5 w-3.5 animate-spin" aria-hidden />
              Looking up “{query.trim() || "everything"}”…
            </div>
          )}

          {status === "error" && errorMessage && (
            <div className={styles.statusLine} role="alert">
              <AlertCircle className="mr-2 inline h-3.5 w-3.5 text-red-500" aria-hidden />
              {errorMessage}
            </div>
          )}

          <div className={styles.list}>
            {items.map((item, index) => {
              if (item.type === "suggestion") {
                const { value } = item;
                return (
                  <button
                    key={value.id}
                    type="button"
                    className={classNames(styles.itemButton)}
                    onClick={() => handleSuggestionSelection(value)}
                    data-active={index === activeIndex}
                    role="option"
                    aria-selected={index === activeIndex}
                  >
                    <span className={styles.categoryBadge}>{value.category}</span>
                    <span className={styles.itemTitle}>
                      <Sparkles className="mr-2 inline h-3 w-3 text-slate-400" aria-hidden />
                      {renderHighlight(value.label)}
                    </span>
                    {value.description && (
                      <span className={styles.itemMeta}>{value.description}</span>
                    )}
                  </button>
                );
              }

              const { value } = item;
              return (
                <button
                  key={`${value.category}-${value.id}`}
                  type="button"
                  className={styles.itemButton}
                  onClick={() => handleResultSelection(value)}
                  data-active={index === activeIndex}
                  role="option"
                  aria-selected={index === activeIndex}
                >
                  <span className={styles.categoryBadge}>{value.category}</span>
                  <span className={styles.itemTitle}>{renderHighlight(value.title)}</span>
                  {value.subtitle && (
                    <span className={styles.itemMeta}>{value.subtitle}</span>
                  )}
                  {value.description && (
                    <span className={styles.itemMeta}>{value.description}</span>
                  )}
                </button>
              );
            })}
          </div>

          {items.length === 0 && status === "idle" && (
            <div className={styles.emptyState} role="status">
              {showingResults
                ? `No results for “${query.trim()}”. Try a different keyword or filter.`
                : "No saved suggestions yet. Start searching to populate this space."}
            </div>
          )}

          {statusMessage && status !== "loading" && (
            <div className={styles.statusLine} role="status">
              {statusMessage}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
