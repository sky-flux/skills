# Error Handling
Advanced error handling patterns in ElysiaJS. Review the Life Cycle (`onError`) section for foundational concepts before proceeding.

## Custom Validation Message

Custom validation messages can be defined at the schema level. When validation fails, the specified message returns as-is.

```typescript
import { Elysia, t } from 'elysia'

new Elysia().get('/:id', ({ params: { id } }) => id, {
    params: t.Object({
        id: t.Number({
            error: 'id must be a number'
        })
    })
})
```

## Validation Detail

The `validationDetail` function returns validation errors including field names and expected types, enabling richer error responses.

```typescript
import { Elysia, validationDetail } from 'elysia'

new Elysia().get('/:id', ({ params: { id } }) => id, {
    params: t.Object({
        id: t.Number({
            error: validationDetail('id must be a number')
        })
    })
})
```

### Automated Approach

Rather than manually adding `validationDetail` to each field, apply it globally via the `onError` hook:

```typescript
new Elysia()
    .onError(({ error, code }) => {
        if (code === 'VALIDATION') return error.detail(error.message)
    })
    .get('/:id', ({ params: { id } }) => id, {
        params: t.Object({
            id: t.Number({
                error: 'id must be a number'
            })
        })
    })
    .listen(3000)
```

## Validation Detail on Production

By default, Elysia omits validation details when `NODE_ENV` is `production`. This prevents exposing schema information that could be exploited. Only custom error messages appear in production responses:

```json
{
    "type": "validation",
    "on": "body",
    "found": {},
    "message": "x must be a number"
}
```

Override this behavior with `allowUnsafeValidationDetails` set to `true` in the Elysia constructor.

## Custom Error

Elysia supports custom error types with type safety and auto-completion via `Elysia.error`:

```typescript
import { Elysia } from 'elysia'

class MyError extends Error {
    constructor(public message: string) {
        super(message)
    }
}

new Elysia()
    .error({
        MyError
    })
    .onError(({ code, error }) => {
        switch (code) {
            case 'MyError':
                return error
        }
    })
    .get('/:id', () => {
        throw new MyError('Hello Error')
    })
```

### Custom Status Code

Add a `status` property to the error class:

```typescript
import { Elysia } from 'elysia'

class MyError extends Error {
    status = 418

    constructor(public message: string) {
        super(message)
    }
}
```

Alternatively, set status manually in `onError`:

```typescript
import { Elysia } from 'elysia'

class MyError extends Error {
    constructor(public message: string) {
        super(message)
    }
}

new Elysia()
    .error({
        MyError
    })
    .onError(({ code, error, status }) => {
        switch (code) {
            case 'MyError':
                return status(418, error.message)
        }
    })
    .get('/:id', () => {
        throw new MyError('Hello Error')
    })
```

### Custom Error Response

Implement a `toResponse` method for fully custom responses:

```typescript
import { Elysia } from 'elysia'

class MyError extends Error {
    status = 418

    constructor(public message: string) {
        super(message)
    }

    toResponse() {
        return Response.json({
            error: this.message,
            code: this.status
        }, {
            status: 418
        })
    }
}
```

## Throw vs Return

Status codes can be both thrown and returned, with different outcomes:

- **Throw**: caught by `onError` middleware
- **Return**: NOT caught by `onError` middleware

```typescript
import { Elysia, file } from 'elysia'

new Elysia()
    .onError(({ code, error, path }) => {
        if (code === 418) return 'caught'
    })
    .get('/throw', ({ status }) => {
        // This will be caught by onError
        throw status(418)
    })
    .get('/return', ({ status }) => {
        // This will NOT be caught by onError
        return status(418)
    })
```

Status codes can use numeric values (e.g. `418`) or string names (e.g. `"I'm a teapot"`).
