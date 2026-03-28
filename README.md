# Zarch 

**A strictly-typed, lightweight hierarchical state machine (HSM) library for Roblox.**

## Overview

Zarch is a minimal implementation for managing complex state-driven architectures within Roblox projects, with a massive focus on **complete Luau type-safety** and a clean API.

> **Note:** This library is a direct, heavily-inspired rewrite of the fantastic [Arch library by bohraz](https://github.com/bohraz/Arch). Zarch is a rewrite of Arch with a focus on strict typing and a more minimal API.

## Why Zarch?

- **Strictly Typed:** The primary benefit to using Zarch over arch is the strict typing. 
- **Hierarchical State Management:** Zarch enables the creation of a structured system where states can be organized hierarchically, offering a clear and intuitive way to represent complex game behaviors.
- **Parallel State Management:** Zarch allows for the management of multiple states simultaneously, enabling the creation of complex game mechanics that require concurrent state handling.
- **Lightweight & Zero-Dependency:** minimal API with no bloat. 

## Installation


### [Wally](https://wally.run/)
Add the following to your `wally.toml`:
```toml
[dependencies]
zarch = "zarchify/zarch@0.1.0"
```

### [Pesde](https://pesde.dev/)
Alternatively, install via pesde:
```bash
pesde install zarchify/zarch
```

## Quick Start Example

I reccomend you refer to the [Arch](https://github.com/bohraz/Arch) documentation for a more in depth look at how to use state machines.

## Acknowledgements 

Zarch would not exist without the foundational blueprint established by [Arch](https://github.com/bohraz/Arch). Massive credit to **bohraz** for their original design. 

## License

Zarch is licensed under the MIT License.
