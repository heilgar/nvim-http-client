# Request Profiling

The nvim-http-client plugin includes request profiling capabilities that show you detailed timing metrics for your HTTP requests.

## Overview

Profiling helps you understand the performance of your HTTP requests by providing timing information for each stage of the request lifecycle:

- DNS resolution time
- TCP connection time
- TLS handshake time (for HTTPS requests)
- Request sending time
- Server processing time
- Content transfer time
- Total request time

## Configuration

You can configure profiling in your setup:

```lua
profiling = {
  enabled = true,               -- Enable or disable profiling
  show_in_response = true,      -- Show timing metrics in response output
  detailed_metrics = true,      -- Show detailed breakdown of timings
},
```

### Options

- `enabled`: Turn profiling on or off globally (default: true)
- `show_in_response`: Include timing metrics in the response window (default: true)
- `detailed_metrics`: Show a detailed breakdown of each timing component (default: true)

## Using Profiling

### Commands

The plugin provides a command to toggle profiling on or off:

- `:HttpProfiling` - Toggle profiling on/off

### Keybindings

The default keybinding to toggle profiling is:

- `<leader>hp` - Toggle profiling (if `create_keybindings` is true)

You can customize this in your configuration:

```lua
keybindings = {
  toggle_profiling = "<leader>hp",
}
```

## Viewing Timing Metrics

When profiling is enabled, the response window will include a "Timing" section that shows:

```
Timing:
  Total: 1023.45 ms
  DNS Resolution: 12.34 ms
  TCP Connection: 56.78 ms
  TLS Handshake: 89.01 ms
  Request Sending: 23.45 ms
  Server Processing: 789.01 ms
  Content Transfer: 52.86 ms
```

This helps you identify bottlenecks in your HTTP requests and understand where time is being spent during request execution.

## Interpreting Results

- **Total**: The complete time from request initiation to response completion
- **DNS Resolution**: Time to resolve the domain name to an IP address
- **TCP Connection**: Time to establish a TCP connection to the server
- **TLS Handshake**: Time to complete the TLS/SSL handshake (HTTPS only)
- **Request Sending**: Time to send the HTTP request headers and body
- **Server Processing**: Time the server takes to process the request and generate a response
- **Content Transfer**: Time to download the response body

High values in specific areas can help you diagnose issues:

- High DNS resolution time may indicate DNS server issues
- High connection time could suggest network latency
- High server processing time indicates server-side performance issues
- High content transfer time might mean large response payloads or bandwidth limitations 