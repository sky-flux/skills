# Cookie
Reactive cookie pattern in ElysiaJS using a signal-based API. Cookies behave as mutable proxy objects — no explicit get/set calls needed.

## Basic Usage

Extract cookies by name from the handler context. Reading and writing use `.value` directly:

```typescript
import { Elysia } from 'elysia'

new Elysia()
    .get('/', ({ cookie: { name } }) => {
        // Get
        name.value

        // Set
        name.value = "New Value"
    })
```

Object types are automatically encoded/decoded, so cookies can store JavaScript objects without manual serialization.

## Cookie Attributes

### Property Assignment

Set attributes directly on the cookie object:

```typescript
name.domain = 'millennium.sh'
name.httpOnly = true
```

### set Method

Resets all properties, then applies the provided values:

```typescript
name.set({
    domain: 'millennium.sh',
    httpOnly: true
})
```

### add Method

Updates only the specified properties without resetting others. Use `add` when you want to merge changes.

### remove Method

Delete a cookie:

```typescript
name.remove()
// OR
delete cookie.name
```

## Cookie Schema & Validation

Enforce type safety with `t.Cookie`:

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
    .get('/', ({ cookie: { name } }) => {
        name.value = {
            id: 617,
            name: 'Summoning 101'
        }
    }, {
        cookie: t.Cookie({
            name: t.Object({
                id: t.Numeric(),
                name: t.String()
            })
        })
    })
```

### Nullable Cookies

Wrap the schema in `t.Optional` for cookies that may not exist:

```typescript
cookie: t.Cookie({
    name: t.Optional(
        t.Object({
            id: t.Numeric(),
            name: t.String()
        })
    )
})
```

## Cookie Signatures

Cryptographic signing verifies cookie authenticity. A hash is appended to the cookie value using a secret key.

### Signing a Cookie

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
    .get('/', ({ cookie: { profile } }) => {
        profile.value = {
            id: 617,
            name: 'Summoning 101'
        }
    }, {
        cookie: t.Cookie({
            profile: t.Object({
                id: t.Numeric(),
                name: t.String()
            })
        }, {
            secrets: 'Fischl von Luftschloss Narfidort',
            sign: ['profile']
        })
    })
```

### Global Configuration

Set secrets and sign targets at the constructor level so every route inherits them:

```typescript
new Elysia({
    cookie: {
        secrets: 'Fischl von Luftschloss Narfidort',
        sign: ['profile']
    }
})
```

## Cookie Rotation

Provide an array of secrets for seamless key transitions. The first secret signs new cookies; all secrets are tried during verification:

```typescript
new Elysia({
    cookie: {
        secrets: ['Vengeance will be mine', 'Fischl von Luftschloss Narfidort']
    }
})
```

## Configuration Reference

| Option      | Description                                                        |
| ----------- | ------------------------------------------------------------------ |
| `domain`    | Domain Set-Cookie attribute — controls which domains receive it    |
| `encode`    | Function for encoding values (default: `encodeURIComponent`)       |
| `expires`   | Expiration date (`Date` object)                                    |
| `httpOnly`  | Prevents client-side JavaScript access                             |
| `maxAge`    | Duration in seconds before expiration                              |
| `path`      | Path Set-Cookie attribute                                          |
| `priority`  | Priority level: `low`, `medium`, or `high`                         |
| `sameSite`  | Cross-site behavior: `strict`, `lax`, or `none`                    |
| `secure`    | Requires HTTPS transmission                                        |
