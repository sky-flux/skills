# TypeBox (Elysia.t)
Common patterns for writing validation types using `Elysia.t`. TypeBox is the default schema validation library for Elysia.

## Primitive Type

The TypeBox API is designed around and is similar to TypeScript types. There are many familiar names and behaviors that intersect with TypeScript counterparts, such as **String**, **Number**, **Boolean**, and **Object**, as well as more advanced features like **Intersect**, **KeyOf**, and **Tuple** for versatility.

Creating a TypeBox schema behaves the same as writing a TypeScript type, except it provides actual type validation at runtime.

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
	.post('/', ({ body }) => `Hello ${body}`, {
		body: t.String()
	})
	.listen(3000)
```

This code tells Elysia to validate an incoming HTTP body, ensuring that the body is a string. If the shape does not match, it will throw an error into the Error Life Cycle.

### Basic Types

| TypeBox | TypeScript |
|---------|-----------|
| `t.String()` | `string` |
| `t.Number()` | `number` |
| `t.Boolean()` | `boolean` |
| `t.Array(t.Number())` | `number[]` |
| `t.Object({ x: t.Number() })` | `{ x: number }` |
| `t.Null()` | `null` |
| `t.Literal(42)` | `42` |

Elysia extends all types from TypeBox, allowing you to reference most of the API from TypeBox for use in Elysia.

### Attributes

TypeBox accepts arguments for more comprehensive behavior based on the JSON Schema 7 specification.

| TypeBox | Description | Example |
|---------|-------------|---------|
| `t.String({ format: 'email' })` | Email format | `[email protected]` |
| `t.Number({ minimum: 10, maximum: 100 })` | Number range | `10` |
| `t.Array(t.Number(), { minItems: 1, maxItems: 5 })` | Array with size constraints | `[1, 2, 3, 4, 5]` |
| `t.Object({ x: t.Number() }, { additionalProperties: true })` | Object with extra properties allowed | `x: 100, y: 200` |

Key attributes:
- **minItems** - Minimum number of items in an array
- **maxItems** - Maximum number of items in an array
- **additionalProperties** - Accept additional properties not specified in schema but still match the type (default: `false`)

### Union

Allows a field to have multiple types.

| TypeBox | TypeScript | Value |
|---------|-----------|-------|
| `t.Union([t.String(), t.Number()])` | `string \| number` | `Hello`, `123` |

### Optional

Allows a field in `t.Object` to be undefined or optional.

| TypeBox | TypeScript | Value |
|---------|-----------|-------|
| `t.Object({ x: t.Number(), y: t.Optional(t.Number()) })` | `{ x: number, y?: number }` | `{ x: 123 }` |

### Partial

Allows all fields in `t.Object` to be optional.

| TypeBox | TypeScript | Value |
|---------|-----------|-------|
| `t.Partial(t.Object({ x: t.Number(), y: t.Number() }))` | `{ x?: number, y?: number }` | `{ y: 123 }` |

## Elysia Type

`Elysia.t` is based on TypeBox with pre-configuration for server usage, providing additional types commonly found in server-side validation. Source code is in `elysia/type-system`.

### UnionEnum

Allows the value to be one of the specified values.

```typescript
t.UnionEnum(['rapi', 'anis', 1, true, false])
```

### File

A singular file type, useful for **file upload** validation.

```typescript
t.File()
```

File extends the attributes of the base schema with additional properties:

#### type

Specifies the format of the file, such as image, video, or audio. If an array is provided, it will attempt to validate if any of the formats are valid.

```typescript
type?: MaybeArray<string>
```

#### minSize

Minimum size of the file. Accepts a number in bytes or a suffix of file units:

```typescript
minSize?: number | `${number}${'k' | 'm'}`
```

#### maxSize

Maximum size of the file. Accepts a number in bytes or a suffix of file units:

```typescript
maxSize?: number | `${number}${'k' | 'm'}`
```

#### File Unit Suffix

- **m** - MegaByte (1048576 byte)
- **k** - KiloByte (1024 byte)

### Files

Extends from File, but adds support for an array of files in a single field.

```typescript
t.Files()
```

Files extends the attributes of the base schema, array, and File.

### Cookie

Object-like representation of a Cookie Jar extended from the Object type.

```typescript
t.Cookie({
    name: t.String()
})
```

Cookie extends the attributes of Object and Cookie with additional properties:

#### secrets

The secret key for signing cookies. Accepts a string or an array of strings.

```typescript
secrets?: string | string[]
```

If an array is provided, Key Rotation will be used. The newly signed value will use the first secret as the key.

### Nullable

Allows the value to be null but not undefined.

```typescript
t.Nullable(t.String())
```

### MaybeEmpty

Allows the value to be null and undefined.

```typescript
t.MaybeEmpty(t.String())
```

### Form

A syntax sugar for `t.Object` with support for verifying return value of form (FormData).

```typescript
t.Form({
	someValue: t.File()
})
```

### UInt8Array

Accepts a buffer that can be parsed into a `Uint8Array`. Useful for binary file upload with `arrayBuffer` parser to enforce the body type.

```typescript
t.UInt8Array()
```

### ArrayBuffer

Accepts a buffer that can be parsed into an `ArrayBuffer`. Useful for binary file upload with `arrayBuffer` parser to enforce the body type.

```typescript
t.ArrayBuffer()
```

### ObjectString

Accepts a string that can be parsed into an object. Useful when the environment does not allow explicit objects, such as in query strings, headers, or FormData body.

```typescript
t.ObjectString()
```

### BooleanString

Accepts a string that can be parsed into a boolean. Useful when the environment does not allow explicit booleans (similar to ObjectString).

```typescript
t.BooleanString()
```

### Numeric

Accepts a numeric string or number and then transforms the value into a number. Useful when an incoming value is a numeric string, for example a path parameter or query string.

```typescript
t.Numeric()
```

Numeric accepts the same attributes as Numeric Instance from JSON Schema 7 specification.

## Elysia Behavior

Elysia uses TypeBox by default. However, to help make handling HTTP easier, Elysia has some dedicated types and behavioral differences from TypeBox.

### Optional

To make a field optional, use `t.Optional`. This allows the client to optionally provide a query parameter. This behavior also applies to `body` and `headers`.

This is different from TypeBox where optional is to mark a field of an object as optional.

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
	.get('/optional', ({ query }) => query, {
		query: t.Optional(
			t.Object({
				name: t.String()
			})
		)
	})
```

### Number to Numeric

By default, Elysia will convert a `t.Number` to `t.Numeric` when provided as route schema. Because parsed HTTP headers, query, and URL parameters are always strings, even if a value is a number it will be treated as a string.

Elysia overrides this behavior by checking if a string value looks like a number then converting it when appropriate.

This is only applied when it is used as a route schema and not in a nested `t.Object`.

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
	.get('/:id', ({ id }) => id, {
		params: t.Object({
			// Converted to t.Numeric()
			id: t.Number()
		}),
		body: t.Object({
			// NOT converted to t.Numeric()
			id: t.Number()
		})
	})

// NOT converted to t.Numeric()
t.Number()
```

### Boolean to BooleanString

Similar to Number to Numeric. Any `t.Boolean` will be converted to `t.BooleanString` when used in route schema (params, query, headers).

```typescript
import { Elysia, t } from 'elysia'

new Elysia()
	.get('/:id', ({ id }) => id, {
		params: t.Object({
			// Converted to t.BooleanString()
			id: t.Boolean()
		}),
		body: t.Object({
			// NOT converted to t.BooleanString()
			id: t.Boolean()
		})
	})

// NOT converted to t.BooleanString()
t.Boolean()
```
