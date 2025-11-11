"use client";

import { FormEvent, useState } from "react";

interface NavigationSearchProps {
  id?: string;
}

export function NavigationSearch({ id = "panel-search" }: NavigationSearchProps) {
  const [query, setQuery] = useState("");

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const trimmed = query.trim();
    if (!trimmed) {
      return;
    }

    window.dispatchEvent(
      new CustomEvent("admin-search", {
        detail: { query: trimmed },
      }),
    );

    setQuery("");
  };

  return (
    <form className="panel-search" role="search" aria-label="Admin search" onSubmit={handleSubmit}>
      <label htmlFor={id} className="visually-hidden">
        Search the admin workspace
      </label>
      <span aria-hidden className="panel-search__icon">
        🔍
      </span>
      <input
        id={id}
        type="search"
        name="q"
        autoComplete="off"
        placeholder="Search agents, missions, logs…"
        value={query}
        onChange={(event) => setQuery(event.target.value)}
      />
      <button type="submit" className="panel-search__submit">
        <span>Search</span>
      </button>
    </form>
  );
}
