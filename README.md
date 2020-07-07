Dash Streaming in NS-3
================================

## Overview:
Setup for simulating Dash streaming over LTE. The code is based on NS-3.30 and requires additional configuration based on simulation preferences.

## Setup
1. Setup NS-3 and verify tests work before using this setup
2. Copy the modified files (from this repo) to NS-3 folder
3. Configure for DASH usage

```shell
./waf configure --enable-examples
```
4. Build
```shell
./waf
```
5. Run

## Scenarios
The scenarios are the desired configuration of setup and depends on the use case and available resources.
- Scenario 1: Simulated nodes and network

- Scenario 2: Virtual nodes and simulated network

- Scenario 3: Direct code execution (TODO)

## References

