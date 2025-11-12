import type { RouterContext } from "../../types.ts";
import { clearState, setState } from "../../state/store.ts";
import { t } from "../../i18n/translator.ts";
import { sendText } from "../../wa/client.ts";
import {
  buildButtons,
  homeOnly,
  sendButtonsMessage,
  sendListMessage,
} from "../../utils/reply.ts";
import { isFeatureEnabled } from "../../../_shared/feature-flags.ts";
import { IDS } from "../../wa/ids.ts";
import { routeToAIAgent, sendAgentOptions } from "../ai-agents/index.ts";
import { waChatLink } from "../../utils/links.ts";
import { listBusinesses } from "../../rpc/marketplace.ts";
import {
  getFavoriteById,
  listFavorites,
  type UserFavorite,
} from "../locations/favorites.ts";
import { buildSaveRows } from "../locations/save.ts";

const PHARMACY_RESULT_PREFIX = "PHARM::";

export type PharmacyResultsState = {
  entries: Array<{ id: string; name: string; whatsapp: string }>;
  prefill?: string | null;
};

export async function startNearbyPharmacies(
  ctx: RouterContext,
): Promise<boolean> {
  if (!ctx.profileId) return false;

  await setState(ctx.supabase, ctx.profileId, {
    key: "pharmacy_awaiting_location",
    data: {},
  });

  await sendButtonsMessage(
    ctx,
    t(ctx.locale, "pharmacy.flow.intro"),
    buildButtons(
      {
        id: IDS.LOCATION_SAVED_LIST,
        title: t(ctx.locale, "location.saved.button"),
      },
      { id: IDS.BACK_HOME, title: t(ctx.locale, "common.menu_back") },
    ),
    { emoji: "💊" },
  );

  return true;
}

export async function handlePharmacyLocation(
  ctx: RouterContext,
  location: { lat: number; lng: number },
): Promise<boolean> {
  if (!ctx.profileId) return false;

  await setState(ctx.supabase, ctx.profileId, {
    key: "pharmacy_awaiting_medicine",
    data: { location },
  });

  await sendButtonsMessage(
    ctx,
    t(ctx.locale, "pharmacy.flow.location_received"),
    buildButtons(
      {
        id: "pharmacy_add_medicine",
        title: t(ctx.locale, "pharmacy.buttons.specify_medicine"),
      },
      {
        id: "pharmacy_search_now",
        title: t(ctx.locale, "pharmacy.buttons.search_now"),
      },
      { id: IDS.BACK_HOME, title: t(ctx.locale, "common.menu_back") },
    ),
    { emoji: "📍" },
  );

  return true;
}

export async function startPharmacySavedLocationPicker(
  ctx: RouterContext,
): Promise<boolean> {
  if (!ctx.profileId) return false;
  const favorites = await listFavorites(ctx);

  await setState(ctx.supabase, ctx.profileId, {
    key: "location_saved_picker",
    data: { source: "pharmacy" },
  });

  const baseBody = t(ctx.locale, "location.saved.list.body", {
    context: t(ctx.locale, "location.context.pickup"),
  });
  const body = favorites.length
    ? baseBody
    : `${baseBody}\n\n${t(ctx.locale, "location.saved.list.empty")}`;

  await sendListMessage(
    ctx,
    {
      title: t(ctx.locale, "location.saved.list.title"),
      body,
      sectionTitle: t(ctx.locale, "location.saved.list.section"),
      rows: [
        ...favorites.map(favoriteToRow),
        ...buildSaveRows(ctx),
        {
          id: IDS.BACK_MENU,
          title: t(ctx.locale, "common.menu_back"),
          description: t(ctx.locale, "common.back_to_menu.description"),
        },
      ],
      buttonText: t(ctx.locale, "location.saved.list.button"),
    },
    { emoji: "⭐" },
  );

  return true;
}

export async function handlePharmacySavedLocationSelection(
  ctx: RouterContext,
  selectionId: string,
): Promise<boolean> {
  if (!ctx.profileId) return false;
  const favorite = await getFavoriteById(ctx, selectionId);
  if (!favorite) {
    await sendButtonsMessage(
      ctx,
      t(ctx.locale, "location.saved.list.expired"),
      homeOnly(),
    );
    return true;
  }
  return await handlePharmacyLocation(ctx, {
    lat: favorite.lat,
    lng: favorite.lng,
  });
}

export async function processPharmacyRequest(
  ctx: RouterContext,
  location: { lat: number; lng: number },
  rawInput: string,
): Promise<boolean> {
  if (!ctx.profileId) return false;
  const meds = parseKeywords(rawInput);
  if (!meds.length) {
    await sendText(ctx.from, t(ctx.locale, "pharmacy.prompt.medicines"));
    return true;
  }
  if (isFeatureEnabled("agent.pharmacy")) {
    const handled = await tryPharmacyAgent(ctx, location, meds);
    if (handled) return true;
  }
  return await sendPharmacyFallback(ctx, location, meds);
}

export async function handlePharmacyResultSelection(
  ctx: RouterContext,
  state: PharmacyResultsState,
  id: string,
): Promise<boolean> {
  if (!ctx.profileId) return false;
  const entry = state.entries.find((item) => item.id === id);
  if (!entry) return false;
  const medsText = state.prefill?.length ? state.prefill : null;
  const message = medsText
    ? t(ctx.locale, "pharmacy.prefill.with_items", { items: medsText })
    : t(ctx.locale, "pharmacy.prefill.generic");
  const link = waChatLink(entry.whatsapp, message);
  await sendButtonsMessage(
    ctx,
    t(ctx.locale, "pharmacy.results.chat_cta", { link }),
    homeOnly(),
  );
  await clearState(ctx.supabase, ctx.profileId);
  return true;
}

function parseKeywords(input: string): string[] {
  return input.split(/[\n,]+/)
    .map((part) => part.trim())
    .filter((part) => part.length > 1);
}

function favoriteToRow(
  favorite: UserFavorite,
): { id: string; title: string; description?: string } {
  return {
    id: favorite.id,
    title: `⭐ ${favorite.label}`,
    description: favorite.address ??
      `${favorite.lat.toFixed(4)}, ${favorite.lng.toFixed(4)}`,
  };
}

async function tryPharmacyAgent(
  ctx: RouterContext,
  location: { lat: number; lng: number },
  medications: string[],
): Promise<boolean> {
  await sendText(ctx.from, t(ctx.locale, "agent.searching_pharmacies"));
  try {
    const response = await routeToAIAgent(ctx, {
      userId: ctx.from,
      agentType: "pharmacy",
      flowType: "find_medications",
      location: {
        latitude: location.lat,
        longitude: location.lng,
      },
      requestData: {
        medications,
        prescriptionImage: undefined,
      },
    });

    if (response.success && response.options?.length) {
      await sendAgentOptions(
        ctx,
        response.sessionId,
        response.options,
        t(ctx.locale, "pharmacy.options_found"),
      );
      await setState(ctx.supabase, ctx.profileId!, {
        key: "ai_agent_selection",
        data: {
          sessionId: response.sessionId,
          agentType: "pharmacy",
        },
      });
      return true;
    }

    if (response.message) {
      await sendText(ctx.from, response.message);
    }
  } catch (error) {
    console.error("pharmacy.agent_failure", error);
    await sendText(ctx.from, t(ctx.locale, "agent.error_occurred"));
  }
  return false;
}

async function sendPharmacyFallback(
  ctx: RouterContext,
  location: { lat: number; lng: number },
  medications: string[],
): Promise<boolean> {
  if (!ctx.profileId) return false;
  let entries: Array<{
    id: string;
    name: string;
    owner_whatsapp?: string | null;
    distance_km?: number | null;
    location_text?: string | null;
    description?: string | null;
  }> = [];
  try {
    entries = await listBusinesses(ctx.supabase, location, "pharmacies", 12);
  } catch (error) {
    console.error("pharmacy.fallback_fetch_failed", error);
  }
  const withContacts = entries.filter((entry) => entry.owner_whatsapp);
  if (!withContacts.length) {
    await sendButtonsMessage(
      ctx,
      t(ctx.locale, "pharmacy.results.empty"),
      homeOnly(),
    );
    return true;
  }
  const rows = withContacts.slice(0, 10).map((entry) => ({
    id: `${PHARMACY_RESULT_PREFIX}${entry.id}`,
    name: entry.name ?? t(ctx.locale, "pharmacy.results.unknown"),
    description: formatBusinessDescription(ctx, entry),
    whatsapp: entry.owner_whatsapp!,
  }));

  await setState(ctx.supabase, ctx.profileId, {
    key: "pharmacy_results",
    data: {
      entries: rows.map((row) => ({
        id: row.id,
        name: row.name,
        whatsapp: row.whatsapp,
      })),
      prefill: medications.join(", ") || null,
    } as Record<string, unknown>,
  });

  await sendListMessage(
    ctx,
    {
      title: t(ctx.locale, "pharmacy.results.title"),
      body: t(ctx.locale, "pharmacy.results.body"),
      sectionTitle: t(ctx.locale, "pharmacy.results.section"),
      rows: [
        ...rows.map((row) => ({
          id: row.id,
          title: `💊 ${row.name}`,
          description: row.description,
        })),
        {
          id: IDS.BACK_MENU,
          title: t(ctx.locale, "common.menu_back"),
          description: t(ctx.locale, "common.back_to_menu.description"),
        },
      ],
      buttonText: t(ctx.locale, "common.buttons.open"),
    },
    { emoji: "💊" },
  );
  return true;
}

export async function handlePharmacySearchNow(
  ctx: RouterContext,
  state: { location?: { lat: number; lng: number } } | undefined,
): Promise<boolean> {
  const location = state?.location;
  if (!location) {
    await sendButtonsMessage(
      ctx,
      t(ctx.locale, "pharmacy.flow.intro"),
      buildButtons(
        {
          id: IDS.LOCATION_SAVED_LIST,
          title: t(ctx.locale, "location.saved.button"),
        },
        { id: IDS.BACK_HOME, title: t(ctx.locale, "common.menu_back") },
      ),
      { emoji: "💊" },
    );
    return true;
  }
  return await sendPharmacyFallback(ctx, location, []);
}

export async function promptPharmacyMedicineInput(
  ctx: RouterContext,
): Promise<boolean> {
  await sendText(ctx.from, t(ctx.locale, "pharmacy.prompt.medicines"));
  return true;
}

function formatBusinessDescription(
  ctx: RouterContext,
  entry: {
    distance_km?: number | null;
    location_text?: string | null;
    description?: string | null;
  },
): string {
  const parts: string[] = [];
  if (typeof entry.distance_km === "number") {
    parts.push(
      t(ctx.locale, "marketplace.distance", {
        distance: entry.distance_km >= 1
          ? `${entry.distance_km.toFixed(1)} km`
          : `${Math.round(entry.distance_km * 1000)} m`,
      }),
    );
  }
  if (entry.location_text?.trim()) {
    parts.push(entry.location_text.trim());
  } else if (entry.description?.trim()) {
    parts.push(entry.description.trim());
  }
  return parts.join(" • ");
}
