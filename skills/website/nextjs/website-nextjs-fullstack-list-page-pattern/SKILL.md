---
name: website-nextjs-fullstack-list-page-pattern
description: >-
  How a paginated, sortable entity list page is built with plain React
  Server Components and no client state library — a per-feature Zod
  "tolerant parser" that reads Next.js's searchParams prop into typed
  page/sort/order/perPage values, a matching buildUrl helper that emits
  clean query strings (only non-default params appear), and a shared
  SortableHeader component that turns column headers into plain links.
  Explicitly the alternative to reaching for nuqs, TanStack Query, or
  Zustand for list-view state. Use when building any filterable/sortable/
  paginated list view (a table, a kanban-ish grouped view) in a Next.js app
  that has its own backend. Assumes a multi-user dashboard/admin app with
  a real database behind it — a simple site with no real dataset to
  paginate doesn't need this.
metadata:
  type: practice
  category: architecture
---

## Rule

### The whole state model is the URL — parsed once, server-side, per request

No client-side filter/sort/page state at all. A Server Component page
receives Next.js's `searchParams` prop, runs it through one small
tolerant-parsing function, and passes the typed result straight into a
`queries.ts` read (see
[website-nextjs-fullstack-layered-architecture](../website-nextjs-fullstack-layered-architecture/SKILL.md)):

```ts
// features/companies/company-search-params.ts
import { z } from 'zod';
import { PER_PAGE_OPTIONS, SORTABLE_FIELDS, type PerPage, type SortField } from './list-constants';

const PageSchema = z.coerce.number().int().min(1).default(1);
const PerPageSchema = z.coerce
  .number()
  .int()
  .refine((n): n is PerPage => (PER_PAGE_OPTIONS as readonly number[]).includes(n))
  .default(25);
const SortSchema = z.enum(SORTABLE_FIELDS as unknown as [SortField, ...SortField[]]).default('createdAt');
const OrderSchema = z.enum(['asc', 'desc']).default('desc');

/** Tolerant parser for ?page=…&perPage=…&sort=…&order=… — invalid or
 *  missing values fall back to sane defaults via `.catch()` instead of
 *  the page erroring on a malformed URL someone hand-edited or bookmarked. */
export function parseCompanySearchParams(raw: Record<string, string | string[] | undefined>) {
  return {
    page: PageSchema.catch(1).parse(raw.page),
    perPage: PerPageSchema.catch(25 as PerPage).parse(raw.perPage),
    sort: SortSchema.catch('createdAt').parse(raw.sort),
    order: OrderSchema.catch('desc').parse(raw.order),
  };
}
```

```tsx
// app/(app)/companies/page.tsx
interface CompaniesPageProps {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}

export default async function CompaniesPage({ searchParams }: CompaniesPageProps) {
  const params = parseCompanySearchParams(await searchParams);
  const [result, trashCount, user] = await Promise.all([
    listCompanies(params),
    countDeletedCompanies(),
    requireUser(),
  ]);
  const canDelete = can(user, 'companies.delete');

  return result.total === 0 ? (
    <CompaniesEmpty />
  ) : (
    <>
      <CompaniesTable result={result} params={params} canDelete={canDelete} />
      <CompaniesPagination result={result} params={params} />
    </>
  );
}
```

There is no `useState` for the current page, no client-side filter store,
no library syncing state to the URL — the URL **is** the state, parsed
fresh on every request. Bookmarking, sharing a filtered link, and
back/forward navigation all work automatically because there's nothing
client-side to get out of sync with the address bar.

### A `buildUrl` helper turns state changes into plain hrefs

Every state transition (click a column header, go to page 3, change page
size) is just a `<Link>` to a new URL — never an `onClick` that calls
`setState` or a router push with manually-assembled params:

```ts
export function buildCompanyUrl(
  base: string,
  current: ReturnType<typeof parseCompanySearchParams>,
  overrides: Partial<ReturnType<typeof parseCompanySearchParams>>,
): string {
  const merged = { ...current, ...overrides };
  const params = new URLSearchParams();
  // Only non-default values appear in the querystring — keeps URLs short
  // and means the "no params" URL is the same as the "all defaults" URL.
  if (merged.page !== 1) params.set('page', String(merged.page));
  if (merged.perPage !== 25) params.set('perPage', String(merged.perPage));
  if (merged.sort !== 'createdAt') params.set('sort', merged.sort);
  if (merged.order !== 'desc') params.set('order', merged.order);
  const qs = params.toString();
  return qs ? `${base}?${qs}` : base;
}
```

### A shared, generic `SortableHeader` — one component, every table

Column-header sorting was originally copy-pasted per table; it was
extracted into one generic component the moment a second near-identical
copy showed up:

```tsx
// components/data-table/sortable-header.tsx
export function SortableHeader<F extends string>({
  field, label, activeField, activeOrder, buildHref, align = 'left',
}: SortableHeaderProps<F>) {
  const active = activeField === field;
  const nextOrder = active && activeOrder === 'desc' ? 'asc' : 'desc';
  const Icon = !active ? ArrowUpDown : activeOrder === 'desc' ? ArrowDown : ArrowUp;

  return (
    <Link href={buildHref(field, nextOrder)} className={cn('inline-flex items-center gap-1.5', active && 'text-foreground')}>
      <span>{label}</span>
      <Icon className={cn('size-3', active ? 'opacity-100' : 'opacity-40')} aria-hidden />
    </Link>
  );
}
```

Used from a table's header row, generic over the feature's own `SortField`
union:

```tsx
const buildHref = (field: SortField, nextOrder: 'asc' | 'desc') =>
  buildCompanyUrl('/companies', params, { sort: field, order: nextOrder, page: 1 });

<SortableHeader field="name" label="Name" activeField={params.sort} activeOrder={params.order} buildHref={buildHref} />
```

Changing sort always resets `page` back to 1 — a stale page number past
the end of a newly-sorted, differently-filtered result set is a common,
easy-to-miss bug in hand-rolled pagination.

### Mutating from inside a list row: `useTransition` + `router.refresh()`

Row-level actions (delete, restore) are Client Components that call a
Server Action directly and refresh — no client cache to patch (see
[website-nextjs-fullstack-server-actions](../website-nextjs-fullstack-server-actions/SKILL.md)
for the full pattern). `router.refresh()` re-runs the same
`searchParams`-driven Server Component, so the list re-fetches with the
exact same page/sort/filter state the user was looking at.

## Why

Putting filter/sort/page state in the URL instead of a client store or a
URL-syncing library (nuqs, etc.) isn't a compromise made for lack of a
better tool — for a server-rendered list page, the URL is already the
correct source of truth (it's what makes a link shareable and the back
button work), and RSC means "re-render with the new params" is just
"navigate," no library required to keep two sources of truth in sync
because there's only ever one. A hand-rolled tolerant parser
(`.catch(default)` per field) exists because a URL is user-editable input —
a page has to handle `?perPage=999999&sort=nonsense` from a bookmarked or
hand-typed URL exactly as gracefully as the well-formed link a header click
generates. This is worth calling out explicitly: an earlier architecture
pass for this exact app proposed TanStack Query + Zustand + `nuqs` for
state management generally — none of the three ended up used anywhere in
the app (verified against the actual dependency list and source), because
RSC + URL search params + Server Actions turned out to cover every real
list-page need. Don't add a client state library to a list page until this
pattern genuinely can't do the job — not because a spec once assumed you
would.

## Exceptions

- This pattern is for **server-paginated, server-rendered lists**. A view
  that needs client-side instant filtering over an already-fetched small
  dataset (a command palette, an in-memory multi-select), or genuine
  infinite-scroll with prefetching, is a different problem and may
  legitimately want client state or a query library.
- If a list page needs to feel instant on every keystroke of a search box
  (as opposed to on navigation/submit), a fully server-driven round trip
  per keystroke is the wrong tradeoff — debounce client-side before
  navigating, or accept a small amount of client state scoped to just the
  search input, not the whole filter/sort/page model.
- Don't build a generic `buildUrl`/`parseSearchParams` pair speculatively
  for a list that doesn't sort or paginate yet — write it once a second
  sortable/filterable column or a second page of results actually exists.

## See also

- [website-nextjs-fullstack-layered-architecture](../website-nextjs-fullstack-layered-architecture/SKILL.md) — the `queries.ts` list function this page's parsed params feed into.
- [website-nextjs-fullstack-server-actions](../website-nextjs-fullstack-server-actions/SKILL.md) — how a row's delete/restore action is called and how the page refreshes afterward.
- [website-nextjs-fullstack-soft-delete-lifecycle](../website-nextjs-fullstack-soft-delete-lifecycle/SKILL.md) — the trash/restore/purge views that pair with a list page's delete action.
