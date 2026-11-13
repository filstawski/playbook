---
name: website-nextjs-dashboard-forms
description: >-
  How forms are built in a Next.js dashboard — react-hook-form driven by a
  Zod schema via zodResolver, a composable Field/FieldGroup/FieldLabel/
  FieldError primitive set instead of hand-rolled label+input+error markup
  per field, submission wired through a TanStack Query mutation, a
  MutateButton that mirrors a mutation's pending/success/error state, and a
  portaled "unsaved changes" submit footer for settings-style forms. Use
  when building any form (settings page, create/edit dialog, auth form) in
  a dashboard app.
metadata:
  type: practice
  category: architecture
---

## Rule

### Schema first: a Zod object is the single source of truth for a form's shape

Define the shape once as a Zod schema; `react-hook-form`'s types,
validation, and the eventual submit payload all derive from it instead of
being declared three times.

```ts
// lib/schemas.ts
import z from "zod";

export const EditProfileSchema = z
  .object({
    username: z.string("Must be a string").min(3).max(20),
    bio: z.string("Must be a string").max(280),
    hideProfile: z.boolean(),
  })
  .strict();
```

`.strict()` on every form schema means an unexpected extra key is a schema
error, not a silently-ignored typo. Compose a page-specific schema out of
a shared one with `.pick()`/`.extend()` rather than duplicating fields:

```ts
// A page that only edits a subset of fields, plus one field
// (a file input) that doesn't map to a plain server field at all.
const AvatarFieldSchema = z
  .custom<{ file: File | null; removed: boolean }>()
  .refine((val) => !val?.file || val.file.size <= 5 * 1024 * 1024, {
    message: "File must be under 5MB",
  });

const ProfileFormSchema = EditProfileSchema
  .pick({ username: true, bio: true, hideProfile: true })
  .extend({ avatar: AvatarFieldSchema });

type ProfileFormValues = z.infer<typeof ProfileFormSchema>;
```

### Wire the schema into react-hook-form with `zodResolver`

```tsx
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";

const form = useForm<ProfileFormValues>({
  resolver: zodResolver(ProfileFormSchema),
  mode: "onTouched",
  reValidateMode: "onChange",
  // `values` (not `defaultValues`) keeps the form in sync if the
  // underlying data changes out from under it (e.g. a websocket update) —
  // defaultValues only seeds the form once and never re-syncs.
  values: {
    avatar: { file: null, removed: false },
    username: user.username,
    bio: user.bio,
    hideProfile: user.hideProfile,
  },
});
```

Use `mode: "onTouched"`. A field is first checked when the person leaves
it, and from then on on every keystroke, so an error clears the moment it's
fixed. With `onChange`, a half-typed email already showed "invalid" after
its first letter. `reValidateMode: "onChange"` keeps the same live
re-check after a submit (decided 2026-11-13; see
[forms](../../../../guidelines/ui-ux/forms.md#check-a-field-when-its-left-then-live-once-its-wrong)).

**Changed:** this skill used `mode: "onChange"` until 2026-11-13.

### `Field` / `FieldGroup` / `FieldLabel` / `FieldContent` / `FieldError`: compose form markup instead of hand-rolling it per field

Every field in every form is built from the same small set of primitives —
this is what makes a form's JSX describe *what* each field is, not *how*
to lay out a label+description+control+error block every single time.

```tsx
// components/ui/field.tsx (the pieces that matter for authoring a form —
// see the stack skill for how these are all CVA-variant-driven internally)
export {
  Field,          // <div role="group"> wrapping one control; owns orientation ("vertical" | "horizontal" | "custom-settings" | ...)
  FieldGroup,     // groups multiple Fields with consistent vertical spacing
  FieldLabel,     // <Label>, auto-dims when the field is disabled
  FieldDescription, // muted helper text under the label
  FieldContent,   // wraps the actual input/control
  FieldError,     // renders one message, or a bulleted list if `errors` has more than one distinct message
};
```

A field in practice — a `Controller`-wrapped textarea with a description
and an error slot, and a `Switch` field using the same shape:

```tsx
<Field>
  <FieldLabel htmlFor="bio">Bio</FieldLabel>
  <FieldDescription>A short description of yourself.</FieldDescription>
  <FieldContent>
    <Controller
      name="bio"
      control={form.control}
      render={({ field }) => (
        <Textarea {...field} id="bio" placeholder="Tell us about yourself..." rows={4} />
      )}
    />
  </FieldContent>
  <FieldError errors={[form.formState.errors.bio]} />
</Field>

<Field orientation="custom-settings">
  <FieldLabel htmlFor="hide-profile">Hide profile</FieldLabel>
  <FieldDescription>
    When enabled, your profile is hidden from other users.
  </FieldDescription>
  <FieldContent>
    <Switch
      id="hide-profile"
      checked={form.watch("hideProfile")}
      onCheckedChange={(checked) =>
        form.setValue("hideProfile", checked, { shouldDirty: true, shouldValidate: true })
      }
    />
  </FieldContent>
  <FieldError errors={[form.formState.errors.hideProfile]} />
</Field>
```

`FieldError`'s `errors` prop takes an *array* on purpose — pass one field's
error wrapped in an array (`[form.formState.errors.bio]`), or several
related errors at once (e.g. a compound field backed by more than one
schema path). It de-duplicates by message and renders a single line for
one distinct error, or a bulleted list once there's more than one:

```tsx
// components/ui/field.tsx (FieldError, relevant part)
function FieldError({ errors, children, className, ...props }: {
  errors?: Array<{ message?: string } | undefined>;
} & React.ComponentProps<"div">) {
  const content = useMemo(() => {
    if (children) return children;
    if (!errors?.length) return null;
    const unique = [...new Map(errors.map((e) => [e?.message, e])).values()];
    if (unique.length === 1) return unique[0]?.message;
    return (
      <ul className="ml-4 flex list-disc flex-col gap-1">
        {unique.map((e, i) => e?.message && <li key={i}>{e.message}</li>)}
      </ul>
    );
  }, [children, errors]);
  if (!content) return null;
  return <div role="alert" className={cn("text-destructive text-sm", className)} {...props}>{content}</div>;
}
```

### Submission: a TanStack Query mutation, not a bare async `onSubmit`

```tsx
const editMutation = useMutation({
  mutationFn: async (data: ProfileFormValues) => {
    const { avatar, ...rest } = data;
    if (avatar.file) await uploadAvatar(avatar.file);
    if (avatar.removed) await deleteAvatar();

    const changes = getChangedFields(rest, {
      username: user.username,
      bio: user.bio,
      hideProfile: user.hideProfile,
    });
    if (Object.keys(changes).length === 0) return;
    await updateProfile(changes);
  },
  onSuccess: () => {
    toast.success("Profile updated");
    form.reset({ avatar: { file: null, removed: false }, username: user.username, bio: user.bio, hideProfile: user.hideProfile });
  },
  onError: (error) => {
    applyServerErrorToForm(form, error);
    toast.error("Failed to update profile");
  },
});

<form onSubmit={form.handleSubmit((data) => editMutation.mutateAsync(data), shakeInvalid)}>
```

The second `handleSubmit` callback runs when the browser-side check fails.
`shakeInvalid` shakes each wrong field slightly, once, and react-hook-form
focuses the first one itself. Server errors don't shake anything: they go
to `root`, above the buttons. The helper and its values are in
[website-motion P2](../../website-motion/patterns.md#p2-heightwidth-auto-collapse-animatedimensions-fielderror).

`getChangedFields` (a two-object diff — see the project-structure skill's
`lib/utils.ts` example) keeps the request payload to only what actually
changed, instead of re-sending every field on every save — useful both to
cut payload size and to avoid overwriting a field the server computes from
absence-vs-presence semantics.

### Mapping server errors back onto the form

Whatever shape your API client's errors come in, the principle is the
same: **field-level validation issues become `form.setError(fieldName,
...)`, everything else becomes a single `form.setError("root", ...)`** so
it can be rendered once near the submit button instead of per-field.

```ts
// A generic version of the mapping — adapt the `error` shape to
// whatever your own API client actually throws.
function applyServerErrorToForm<T extends FieldValues>(
  form: UseFormReturn<T>,
  error: unknown,
): void {
  if (isFieldValidationError(error)) {
    for (const [field, message] of Object.entries(error.fieldErrors)) {
      form.setError(field as Path<T>, { type: "server", message });
    }
    return;
  }
  const message = error instanceof Error ? error.message : "Something went wrong";
  form.setError("root" as Path<T>, { type: "server", message });
}
```

Render `root` once, near the submit control, rather than duplicating it per
field:

```tsx
{form.formState.errors.root && (
  <FieldError errors={[form.formState.errors.root]} />
)}
```

### `MutateButton` — a button whose label *is* the mutation's state

For a one-off action (not a full form submit) that's backed by a
`useMutation`, `MutateButton` removes the boilerplate of manually tracking
`isPending`/`isSuccess`/`isError` and swapping button content yourself:

```tsx
<MutateButton
  mutation={deleteMutation}
  variables={{ id: item.id }}
  enableFeedback
  successChildren={<><CircleCheck className="size-4" /> Deleted</>}
>
  Delete
</MutateButton>
```

It runs `mutation.mutateAsync(variables)` on click, shows a spinner while
`isPending`, and — with `enableFeedback` — briefly shows success/error
content before resetting back to idle. `noMutate` lets a second button
mirror the same mutation's state without triggering it a second time (e.g.
a "cancel" button next to a "confirm delete" button that both react to one
shared mutation). Two internal details worth keeping if you build this
yourself: an invisible measurement layer keeps the button's width/height
constant across idle/loading/success text so the layout doesn't jump, and
`AnimatePresence mode="wait"` cross-fades between states instead of
popping.

### `FormSubmitButton` + `FormSubmitFooter` — the settings-page save pattern

For a settings-style form (edit in place, save only what's dirty), pair a
submit button that's disabled until the form is actually dirty and error-
free, with a floating footer that only appears once there's something to
save:

```tsx
// components/form-submit-button.tsx
function FormSubmitButton({ children, disabled, ignoreRootError = false, ...props }: FormSubmitButtonProps) {
  const { formState: { isSubmitting, isDirty, errors } } = useFormContext();
  const hasErrors = ignoreRootError
    ? Object.keys(errors).some((k) => k !== "root")
    : Object.keys(errors).length > 0;
  const isDisabled = disabled || isSubmitting || hasErrors || !isDirty;
  return (
    <Button type="submit" disabled={isDisabled} aria-disabled={isDisabled} {...props}>
      {isSubmitting ? <Spinner /> : children}
    </Button>
  );
}
```

The footer itself portals to `document.body` (so it floats above page
content regardless of DOM position) and only renders while
`formState.isDirty`:

```tsx
// components/form-submit-footer.tsx (shape)
function FormSubmitFooter({ formId }: { formId: string }) {
  const form = useFormContext();
  const unsavedCount = Object.keys(form.formState.dirtyFields).length;

  return createPortal(
    <AnimatePresence>
      {form.formState.isDirty && (
        <motion.div
          initial={{ y: 80, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={{ y: 80, opacity: 0 }}
          className="fixed bottom-4 z-50 w-full"
        >
          <div className="mx-4 flex items-center justify-between gap-4 rounded-xl border bg-background/80 backdrop-blur px-4 py-3 shadow-lg">
            {form.formState.errors.root ? (
              <FieldError errors={[form.formState.errors.root]} />
            ) : (
              <p>You have {unsavedCount} unsaved change{unsavedCount === 1 ? "" : "s"}</p>
            )}
            <div className="flex items-center gap-2">
              <Button type="button" variant="ghost" onClick={() => form.reset()}>Reset</Button>
              <FormSubmitButton form={formId}>Save changes</FormSubmitButton>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>,
    document.body,
  );
}
```

Both read the active form via a thin wrapper around react-hook-form's own
`useFormContext`, which throws a clear error if used outside a
`FormProvider` instead of silently returning `undefined`-shaped state:

```ts
// hooks/form-context.ts
import { useFormContext as _useFormContext, FieldValues } from "react-hook-form";

export function useFormContext<T extends FieldValues>() {
  const form = _useFormContext<T>();
  if (!form) throw new Error("useFormContext must be used within a FormProvider");
  return form;
}
```

## Why

Deriving RHF's types and validation from one Zod schema (instead of a
hand-written TS interface plus separate hand-written validation) means the
two can't drift — a field added to the schema shows up in the type and in
validation simultaneously. The `Field`/`FieldGroup` primitive set exists
for the same reason `components/ui` exists at all (see the stack skill):
without it, every form re-derives its own label/description/error layout,
and small inconsistencies (does the error render above or below the input?
is the description muted-colored?) accumulate across a growing settings
area. Driving submission through `useMutation` rather than a bare async
`onSubmit` means loading/error/success state is uniform across every form
in the app and composes for free with `MutateButton` and the submit
footer, instead of every form reinventing its own `isSubmitting` flag.

## Exceptions

- Not every form needs the floating `FormSubmitFooter` — that pattern fits
  "edit in place, save when ready" settings pages. A create/edit dialog
  that's fully modal (can't be left half-filled and walked away from) is
  better served by an ordinary submit button inside the dialog's footer.
- Once a field has been touched, `onTouched` re-runs the Zod resolver on
  every keystroke. That's fine for dashboard forms. If a schema does
  something expensive (a `.refine()` that makes a network call), use
  `mode: "onBlur"` with `reValidateMode: "onBlur"` for that form, so the cost
  runs once per field instead of once per key.
- `MutateButton`'s invisible-measurement-layer trick to keep dimensions
  stable is only worth the complexity when a layout jump would actually be
  visually disruptive (a button inline with body text). A block-level
  button in an otherwise empty area can just let its content change size.
- The generic `applyServerErrorToForm` example intentionally doesn't assume
  any particular API client's error shape — adapt the "field errors here,
  everything else to root" split to whatever your own backend actually
  returns.

## See also

- [website-nextjs-dashboard-stack](../website-nextjs-dashboard-stack/SKILL.md) — how the underlying `Button`, `Card`, and other primitives these forms use are built.
- [website-nextjs-dashboard-project-structure](../website-nextjs-dashboard-project-structure/SKILL.md) — where a form's schema (`lib/schemas.ts`) and generic helpers (`lib/utils.ts`) live.
