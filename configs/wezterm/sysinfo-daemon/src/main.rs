use std::{env, fs, path::PathBuf, process::Command, thread, time::Duration};

/// Detect if running in WSL and return the Windows user's home path if so.
/// Returns path like "/mnt/c/Users/Randy" if in WSL, None otherwise.
fn detect_wsl_windows_home() -> Option<PathBuf> {
    // Check if we're in WSL by looking for WSL-specific indicators
    let is_wsl = fs::read_to_string("/proc/version")
        .map(|v| v.to_lowercase().contains("microsoft") || v.to_lowercase().contains("wsl"))
        .unwrap_or(false);

    if !is_wsl {
        return None;
    }

    // First try: check for common Windows user directories directly
    // This is the most reliable method in systemd service context
    for username in &["Randy", "rmurphy"] {
        let path = PathBuf::from(format!("/mnt/c/Users/{}", username));
        if path.exists() && path.is_dir() {
            return Some(path);
        }
    }

    // Second try: use wslpath with USERPROFILE env var (works in interactive shells)
    if let Ok(userprofile) = env::var("USERPROFILE") {
        if !userprofile.is_empty() {
            if let Ok(output) = Command::new("wslpath").args(["-u", &userprofile]).output() {
                if output.status.success() {
                    let path = String::from_utf8_lossy(&output.stdout).trim().to_string();
                    // Validate it's actually a Windows user path
                    if path.starts_with("/mnt/") && PathBuf::from(&path).exists() {
                        return Some(PathBuf::from(path));
                    }
                }
            }
        }
    }

    None
}

fn format_throughput(bytes_per_sec: f64) -> String {
    if bytes_per_sec >= 1_000_000_000.0 {
        format!("{:.1} GB/s", bytes_per_sec / 1_000_000_000.0)
    } else if bytes_per_sec >= 1_000_000.0 {
        format!("{:.1} MB/s", bytes_per_sec / 1_000_000.0)
    } else if bytes_per_sec >= 1_000.0 {
        format!("{:.0} KB/s", bytes_per_sec / 1_000.0)
    } else {
        format!("{:.0} B/s", bytes_per_sec)
    }
}

/// Find the best network interface to monitor.
/// Priority: default route interface > first interface with traffic > first non-loopback
fn detect_network_interface() -> Option<String> {
    // Try to get the default route interface from /proc/net/route
    if let Ok(content) = fs::read_to_string("/proc/net/route") {
        for line in content.lines().skip(1) {
            let parts: Vec<&str> = line.split_whitespace().collect();
            // Default route has destination 00000000
            if parts.len() >= 2 && parts[1] == "00000000" {
                return Some(parts[0].to_string());
            }
        }
    }

    // Fallback: find first non-loopback interface from /proc/net/dev
    if let Ok(content) = fs::read_to_string("/proc/net/dev") {
        for line in content.lines().skip(2) {
            let iface = line.split(':').next()?.trim();
            if iface != "lo" && !iface.starts_with("docker") && !iface.starts_with("br-") {
                return Some(iface.to_string());
            }
        }
    }

    None
}

fn parse_net_dev(interface: &str) -> Option<(u64, u64)> {
    let content = fs::read_to_string("/proc/net/dev").ok()?;
    let prefix = format!("{}:", interface);
    for line in content.lines() {
        if line.trim().starts_with(&prefix) {
            let parts: Vec<&str> = line.split_whitespace().collect();
            let rx = parts.get(1)?.parse().ok()?;
            let tx = parts.get(9)?.parse().ok()?;
            return Some((rx, tx));
        }
    }
    None
}

/// Find nvidia-smi binary path (WSL puts it in a non-standard location)
fn find_nvidia_smi() -> Option<&'static str> {
    const PATHS: &[&str] = &[
        "/usr/lib/wsl/lib/nvidia-smi", // WSL2
        "/usr/bin/nvidia-smi",          // Standard Linux
        "nvidia-smi",                   // In PATH
    ];

    for path in PATHS {
        let result = Command::new(path).arg("--version").output();
        if result.map(|o| o.status.success()).unwrap_or(false) {
            return Some(path);
        }
    }
    None
}

/// Query NVIDIA GPU stats via nvidia-smi.
/// Returns (gpu_util%, mem_used_mb, mem_total_mb) or None if unavailable.
fn query_nvidia_gpu(nvidia_smi_path: &str) -> Option<(u32, u32, u32)> {
    let output = Command::new(nvidia_smi_path)
        .args([
            "--query-gpu=utilization.gpu,memory.used,memory.total",
            "--format=csv,noheader,nounits",
        ])
        .output()
        .ok()?;

    if !output.status.success() {
        return None;
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let parts: Vec<&str> = stdout.trim().split(',').map(|s| s.trim()).collect();

    if parts.len() >= 3 {
        let util = parts[0].parse().ok()?;
        let mem_used = parts[1].parse().ok()?;
        let mem_total = parts[2].parse().ok()?;
        Some((util, mem_used, mem_total))
    } else {
        None
    }
}

fn format_gpu_mem(mb: u32) -> String {
    if mb >= 1024 {
        format!("{:.1}G", mb as f64 / 1024.0)
    } else {
        format!("{}M", mb)
    }
}

fn main() {
    let mut prev_idle: u64 = 0;
    let mut prev_total: u64 = 0;
    let mut prev_rx: u64 = 0;
    let mut prev_tx: u64 = 0;
    let mut rx_ema: f64 = 0.0;
    let mut tx_ema: f64 = 0.0;
    let mut net_str = String::from("↓ 0 B/s ↑ 0 B/s");
    let mut gpu_str: Option<String> = None;
    let mut tick: u32 = 0;
    const EMA_ALPHA: f64 = 0.3; // 30% new, 70% history

    // Detect WSL and Windows home path for dual-write
    let windows_sysinfo_path = detect_wsl_windows_home().map(|home| {
        let path = home.join(".wezterm-sysinfo");
        eprintln!("sysinfo-daemon: WSL detected, will also write to {:?}", path);
        path
    });

    // Detect network interface once at startup
    let net_interface = detect_network_interface();
    if let Some(ref iface) = net_interface {
        eprintln!("sysinfo-daemon: monitoring interface {}", iface);
    } else {
        eprintln!("sysinfo-daemon: no network interface found, network stats disabled");
    }

    // Check if nvidia-smi is available once at startup
    let nvidia_smi_path = find_nvidia_smi();
    if let Some(path) = nvidia_smi_path {
        eprintln!("sysinfo-daemon: NVIDIA GPU detected at {}, enabling GPU stats", path);
    }

    loop {
        // CPU (every tick - 4Hz)
        let cpu_pct = if let Ok(stat) = fs::read_to_string("/proc/stat") {
            if let Some(cpu_line) = stat.lines().next() {
                let vals: Vec<u64> = cpu_line
                    .split_whitespace()
                    .skip(1)
                    .filter_map(|s| s.parse().ok())
                    .collect();

                if vals.len() >= 4 {
                    // idle = idle + iowait (indices 3 and 4)
                    let idle = vals[3] + vals.get(4).unwrap_or(&0);
                    let total: u64 = vals.iter().sum();

                    let diff_idle = idle.saturating_sub(prev_idle);
                    let diff_total = total.saturating_sub(prev_total);

                    prev_idle = idle;
                    prev_total = total;

                    if diff_total > 0 {
                        100 * (diff_total - diff_idle) / diff_total
                    } else {
                        0
                    }
                } else {
                    0
                }
            } else {
                0
            }
        } else {
            0
        };

        // Network with EMA smoothing (every 2nd tick - 2Hz at 4Hz base)
        if tick % 2 == 0 {
            if let Some(ref iface) = net_interface {
                let (rx, tx) = parse_net_dev(iface).unwrap_or((0, 0));
                let rx_rate = (rx.saturating_sub(prev_rx)) as f64 * 2.0; // 2Hz so * 2 = per second
                let tx_rate = (tx.saturating_sub(prev_tx)) as f64 * 2.0;
                prev_rx = rx;
                prev_tx = tx;

                // Apply EMA: avg = avg * (1 - alpha) + new * alpha
                rx_ema = rx_ema * (1.0 - EMA_ALPHA) + rx_rate * EMA_ALPHA;
                tx_ema = tx_ema * (1.0 - EMA_ALPHA) + tx_rate * EMA_ALPHA;

                net_str = format!("↓ {} ↑ {}", format_throughput(rx_ema), format_throughput(tx_ema));
            }
        }

        // GPU stats (every 4th tick - 1Hz at 4Hz base, nvidia-smi is relatively slow)
        if tick % 4 == 0 {
            if let Some(path) = nvidia_smi_path {
                gpu_str = query_nvidia_gpu(path).map(|(util, mem_used, mem_total)| {
                    format!(
                        "GPU: {}% {}/{}",
                        util,
                        format_gpu_mem(mem_used),
                        format_gpu_mem(mem_total)
                    )
                });
            }
        }

        // Memory (every tick - 4Hz)
        let mem_str = if let Ok(meminfo) = fs::read_to_string("/proc/meminfo") {
            let mut total_mem = 0u64;
            let mut avail_mem = 0u64;
            for line in meminfo.lines() {
                if line.starts_with("MemTotal:") {
                    total_mem = line
                        .split_whitespace()
                        .nth(1)
                        .and_then(|s| s.parse().ok())
                        .unwrap_or(0);
                } else if line.starts_with("MemAvailable:") {
                    avail_mem = line
                        .split_whitespace()
                        .nth(1)
                        .and_then(|s| s.parse().ok())
                        .unwrap_or(0);
                }
            }
            let used_mem_gb = (total_mem - avail_mem) as f64 / 1024.0 / 1024.0;
            let total_mem_gb = total_mem as f64 / 1024.0 / 1024.0;
            format!("RAM: {:.1}/{:.1}GB", used_mem_gb, total_mem_gb)
        } else {
            String::from("RAM: ?/?GB")
        };

        // Build output: NET || CPU | RAM | GPU (if available)
        // The || separator lets WezTerm split network from the rest
        let output = match &gpu_str {
            Some(gpu) => format!(
                "{}||CPU: {:3}% | {} | {}",
                net_str, cpu_pct, mem_str, gpu
            ),
            None => format!("{}||CPU: {:3}% | {}", net_str, cpu_pct, mem_str),
        };

        // Always write to Linux path
        let _ = fs::write("/tmp/sysinfo", &output);

        // Also write to Windows path if in WSL (for WezTerm to read without crossing boundary)
        if let Some(ref win_path) = windows_sysinfo_path {
            let _ = fs::write(win_path, &output);
        }

        tick = tick.wrapping_add(1);
        thread::sleep(Duration::from_millis(250)); // 4Hz base tick
    }
}
