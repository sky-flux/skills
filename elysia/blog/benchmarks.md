# Elysia Benchmarks & Tooling

Consolidated from the official Elysia blog. Covers performance benchmarks and the OpenAPI Type Gen feature.

---

## Elysia vs Encore - 2x Faster

Benchmark comparison between Elysia (v1.4.16) and Encore (v1.5.17), following up on Encore's June 2024 claims.

### Results

| Framework | Without Validation | With Validation |
|-----------|-------------------|-----------------|
| Encore    | 139,033 req/s     | 95,854 req/s    |
| Elysia    | 293,991 req/s     | 223,924 req/s   |

Elysia achieved approximately 2x the throughput of Encore across both test scenarios.

### Test Environment

- **Date**: November 14, 2025
- **CPU**: Intel i7-13700K
- **RAM**: DDR5 32GB 5600MHz
- **OS**: Debian 11 on WSL2
- **Tool**: oha (concurrency adjusted from 150 to 450)

### Methodology

The researchers modified the original Encore benchmark for fairness:

1. Added `bun compile` for production optimization
2. Updated Elysia bare requests to use static resources
3. Scaled concurrency based on machine specifications
4. Updated all dependencies to latest versions

### Performance Optimizations in Elysia

**Exact Mirror Technology** (introduced in v1.3): JIT compilation approach replacing dynamic data mutation, delivering approximately 30x faster processing for medium-sized payloads during validation.

**General optimizations**:
- Constant folding and lifecycle event inlining
- Reduced validation and coercion overhead
- Minimized middleware and plugin overhead
- Native routing leveraging Bun's optimization layer
- Enhanced internal data structure efficiency

---

## OpenAPI Type Gen

Automatically generates API documentation from Elysia TypeScript code without manual annotations. Analyzes Elysia instances and produces OpenAPI schemas on-the-fly with no build step required.

### Key Features

**Automatic Type Inference**: Converts any TypeScript type into OpenAPI documentation, supporting external libraries like Drizzle and Prisma without limitation. Unlike Python's FastAPI (restricted to pydantic models), this approach works with any library.

**Type Soundness**: Handles complex scenarios including multiple status codes from lifecycle/macro overlaps, union types across same status codes, and accurate listing of all possible return values.

**Non-Breaking Integration**: Coexists with existing schema definitions by prioritizing manual schemas first, then falling back to type inference. No breaking changes or additional configuration required.

### Setup

Requires 2 steps:
1. Export an Elysia instance
2. Provide root Elysia file path (defaults to `src/index.ts`)

```typescript
import { Elysia } from 'elysia'
import { openapi, fromTypes } from '@elysiajs/openapi'

export const app = new Elysia()
  .use(
    openapi({
      references: fromTypes()
    })
  )
```

### Scalar UI

Includes a 1-line OpenAPI plugin adding Scalar UI for interactive API exploration.

See also: `/patterns/openapi.html#openapi-from-types` for detailed patterns and configuration.
