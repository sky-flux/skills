# Playground

> **Source:** https://elysiajs.com/playground

---

## Overview

The ElysiaJS playground is an interactive learning environment designed to help you get started with Elysia quickly and easily. Unlike traditional backend frameworks, Elysia can also run in a browser, allowing you to write and try out Elysia directly without any local setup.

## Interface Layout

The playground interface consists of three main sections:

1. **Documentation and task panel** (left side) - Displays the current tutorial content and assignment instructions
2. **Code editor** (top right) - Where you write and edit your Elysia application code
3. **Preview, output, and console** (bottom right) - Shows the running application output and request results

## Interactive Features

The playground provides a full HTTP testing interface:

- **HTTP method selector** - Choose from GET, POST, PUT, DELETE, PATCH, OPTIONS, and HEAD methods
- **Request body editor** - Compose request bodies for POST/PUT/PATCH requests
- **Headers input section** - Add custom HTTP headers to your requests
- **Cookie management panel** - View and manage cookies sent with requests

## Tutorial Topics

The playground covers a comprehensive set of learning modules organized by category:

### Getting Started
- Introduction
- Your First Route
- Handler and Context
- Status and Headers
- Validation
- Lifecycle
- Guard
- Plugin
- Encapsulation

### Patterns
- Cookie
- Error Handling
- Validation Error
- Extends Context
- Standalone Schema
- Macro

### Features
- OpenAPI
- Mount
- Unit Test
- End-to-End Type Safety

### Completion
- What's Next?

## Getting Started

To begin using the playground:

1. Navigate to https://elysiajs.com/playground
2. The playground loads with a default Elysia application
3. Follow the tutorial prompts on the left panel
4. Edit code in the editor and observe results in the preview panel
5. Use the HTTP testing tools to send requests and inspect responses

## Limitations

While the browser-based playground supports most Elysia features, some capabilities that require filesystem access or native runtime features (such as OpenAPI Type Generation with `fromTypes()`) are not available in the browser environment. For full functionality, use a local development setup with Bun.

## Navigation

The sidebar provides navigation through all major documentation sections:

- **Getting Started** - Core framework concepts
- **Essential** - Fundamental building blocks
- **Patterns** - Common usage patterns
- **Eden** - End-to-end type safety client
- **Plugins** - Official and community plugins
- **Comparison** - Framework comparisons
- **Integration** - Meta-framework integration guides

Start with the Introduction module and progress through the tutorials sequentially for the best learning experience.
