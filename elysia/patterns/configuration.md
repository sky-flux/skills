# Configuration
Elysia comes with configurable behavior, allowing customization of various aspects of its functionality. Configuration is defined using the constructor.

```typescript
import { Elysia, t } from 'elysia'

new Elysia({
	prefix: '/v1',
	normalize: true
})
```

## Configuration Options

### adapter
**Since 1.1.11**

Runtime adapter for different environments, defaulting to the appropriate adapter based on the environment.

```typescript
import { Elysia, t } from 'elysia'
import { BunAdapter } from 'elysia/adapter/bun'

new Elysia({
	adapter: BunAdapter
})
```

### allowUnsafeValidationDetails
**Since 1.4.13**

Controls inclusion of validation error details in production responses. By default, Elysia will omit all validation detail on production to prevent exposing sensitive schema information.

- `true` - Include unsafe validation details
- `false` - Exclude validation details (default)

```typescript
new Elysia({
	allowUnsafeValidationDetails: true
})
```

### aot (Ahead of Time)
**Since 0.4.0**

Elysia includes a JIT compiler optimizing performance.

- `true` - Precompile every route before startup
- `false` - Disable JIT (default); faster startup without performance optimization

```typescript
new Elysia({
	aot: true
})
```

### detail

Define OpenAPI schema for all routes of an instance.

```typescript
new Elysia({
	detail: {
		hide: true,
		tags: ['elysia']
	}
})
```

### encodeSchema
**Default: `true`**

Handle custom `t.Transform` schema with custom `Encode` before response.

- `true` - Run `Encode` before sending response
- `false` - Skip `Encode` entirely

```typescript
new Elysia({ encodeSchema: true })
```

### name

Define instance name for debugging and Plugin Deduplication.

```typescript
new Elysia({
	name: 'service.thing'
})
```

### nativeStaticResponse
**Since 1.1.11**

Use optimized functions for handling inline values per runtime.

```typescript
new Elysia({
	nativeStaticResponse: true
})
```

On Bun, inline values insert into `Bun.serve.static`:

```typescript
new Elysia({
	nativeStaticResponse: true
}).get('/version', 1)

// Equivalent to:
Bun.serve({
	static: {
		'/version': new Response(1)
	}
})
```

### normalize
**Since 1.1.0**

Controls field coercion for unknown properties not in schema.

- `true` - Coerce using exact mirror (default)
- `typebox` - Coerce using TypeBox's `Value.Clean`
- `false` - Raise error on unknown fields

```typescript
new Elysia({
	normalize: true
})
```

### precompile
**Since 1.0.0**

Whether Elysia should precompile all routes ahead of time before starting the server.

- `true` - Run JIT on all routes before startup
- `false` - Dynamically compile on demand (default; recommended)

```typescript
new Elysia({
	precompile: true
})
```

### prefix

Define prefix for all routes of an instance.

```typescript
new Elysia({
	prefix: '/v1'
})
// Path becomes /v1/name
.get('/name', 'elysia')
```

### sanitize

Function or array of functions intercepting every `t.String` validation, allowing transformation.

```typescript
new Elysia({
	sanitize: (value) => Bun.escapeHTML(value)
})
```

### seed

Define value for generating instance checksum, used for Plugin Deduplication. Accepts any type.

```typescript
new Elysia({
	seed: {
		value: 'service.thing'
	}
})
```

### strictPath

Whether Elysia handles path matching strictly per RFC 3986.

- `true` - Strict RFC 3986 compliance
- `false` - Tolerate suffix `/` or vice-versa (default)

```typescript
// With strictPath: false (default)
new Elysia({ strictPath: false }).get('/name', 'elysia')
// Accepts /name or /name/

// With strictPath: true
new Elysia({ strictPath: true }).get('/name', 'elysia')
// Accepts only /name
```

### systemRouter

Use runtime/framework provided router when possible. On Bun, uses `Bun.serve.routes` with Elysia router fallback.

### tags

Define tags for OpenAPI schema across all instance routes.

```typescript
new Elysia({
	tags: ['elysia']
})
```

### websocket

Override WebSocket configuration. Recommended to leave as default. Extends Bun's WebSocket API.

```typescript
new Elysia({
	websocket: {
		perMessageDeflate: true
	}
})
```

## serve

Customize HTTP server behavior, extending Bun Serve API and TLS configuration.

```typescript
new Elysia({
	serve: {
		hostname: 'elysiajs.com',
		tls: {
			cert: Bun.file('cert.pem'),
			key: Bun.file('key.pem')
		}
	}
})
```

### serve.hostname
**Default: `0.0.0.0`**

Set hostname the server listens on.

### serve.id

Uniquely identify server instance. Enables hot reload without interrupting pending requests/websockets. Set to `null` to disable.

### serve.idleTimeout
**Default: `10` seconds**

Idle timeout before request abort (Bun default).

### serve.maxRequestBodySize
**Default: `1024 * 1024 * 128` (128MB)**

Maximum request body size in bytes.

```typescript
new Elysia({
	serve: {
		maxRequestBodySize: 1024 * 1024 * 256 // 256MB
	}
})
```

### serve.port
**Default: `3000`**

Port to listen on.

### serve.rejectUnauthorized

Based on `NODE_TLS_REJECT_UNAUTHORIZED` environment variable. Set to `false` to accept any certificate.

### serve.reusePort
**Default: `true`**

Enable `SO_REUSEPORT` flag, allowing multiple processes binding to same port for load balancing. Overridden and enabled by default in Elysia.

### serve.unix

Listen on unix socket instead of port (cannot use with hostname+port).

### serve.tls

Enable TLS by providing key and cert (both required).

```typescript
import { Elysia, file } from 'elysia'

new Elysia({
	serve: {
		tls: {
			cert: file('cert.pem'),
			key: file('key.pem')
		}
	}
})
```

#### serve.tls.ca

Override trusted CA certificates. Defaults to Mozilla-curated well-known CAs.

#### serve.tls.cert

PEM format cert chains, with optional intermediate certificates.

#### serve.tls.dhParamsFile

File path to custom Diffie Hellman parameters (.pem).

#### serve.tls.key

PEM format private keys. Encrypted keys need passphrase.

#### serve.tls.lowMemoryMode
**Default: `false`**

Sets `OPENSSL_RELEASE_BUFFERS=1`, reducing performance but saving memory.

#### serve.tls.passphrase

Shared passphrase for private key or PFX.

#### serve.tls.requestCert
**Default: `false`**

Request client certificate if `true`.

#### serve.tls.secureOptions

Numeric bitmask affecting OpenSSL protocol behavior (use cautiously).

#### serve.tls.serverName

Explicitly set server name.
