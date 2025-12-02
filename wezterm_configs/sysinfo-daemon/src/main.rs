use std::{fs, thread, time::Duration};

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

fn parse_net_dev() -> Option<(u64, u64)> {
    let content = fs::read_to_string("/proc/net/dev").ok()?;
    for line in content.lines() {
        if line.trim().starts_with("eth0:") {
            let parts: Vec<&str> = line.split_whitespace().collect();
            let rx = parts.get(1)?.parse().ok()?;
            let tx = parts.get(9)?.parse().ok()?;
            return Some((rx, tx));
        }
    }
    None
}

fn main() {
    let mut prev_idle: u64 = 0;
    let mut prev_total: u64 = 0;
    let mut prev_rx: u64 = 0;
    let mut prev_tx: u64 = 0;
    let mut rx_ema: f64 = 0.0;
    let mut tx_ema: f64 = 0.0;
    let mut net_str = String::from("↓ 0 B/s ↑ 0 B/s");
    let mut tick: u32 = 0;
    const EMA_ALPHA: f64 = 0.3; // 30% new, 70% history

    loop {
        // CPU (every tick - 8Hz)
        let stat = fs::read_to_string("/proc/stat").unwrap();
        let cpu_line = stat.lines().next().unwrap();
        let vals: Vec<u64> = cpu_line.split_whitespace()
            .skip(1)
            .filter_map(|s| s.parse().ok())
            .collect();

        // idle = idle + iowait (indices 3 and 4)
        let idle = vals[3] + vals.get(4).unwrap_or(&0);
        let total: u64 = vals.iter().sum();

        let diff_idle = idle.saturating_sub(prev_idle);
        let diff_total = total.saturating_sub(prev_total);

        let cpu_pct = if diff_total > 0 {
            100 * (diff_total - diff_idle) / diff_total
        } else { 0 };

        prev_idle = idle;
        prev_total = total;

        // Network with EMA smoothing (every 4th tick - 2Hz)
        if tick % 4 == 0 {
            let (rx, tx) = parse_net_dev().unwrap_or((0, 0));
            let rx_rate = (rx.saturating_sub(prev_rx)) as f64 * 2.0; // 2Hz so * 2 = per second
            let tx_rate = (tx.saturating_sub(prev_tx)) as f64 * 2.0;
            prev_rx = rx;
            prev_tx = tx;

            // Apply EMA: avg = avg * (1 - alpha) + new * alpha
            rx_ema = rx_ema * (1.0 - EMA_ALPHA) + rx_rate * EMA_ALPHA;
            tx_ema = tx_ema * (1.0 - EMA_ALPHA) + tx_rate * EMA_ALPHA;

            net_str = format!("↓ {} ↑ {}", format_throughput(rx_ema), format_throughput(tx_ema));
        }

        // Memory (every tick - 8Hz)
        let meminfo = fs::read_to_string("/proc/meminfo").unwrap();
        let mut total_mem = 0u64;
        let mut avail_mem = 0u64;
        for line in meminfo.lines() {
            if line.starts_with("MemTotal:") {
                total_mem = line.split_whitespace().nth(1).unwrap().parse().unwrap();
            } else if line.starts_with("MemAvailable:") {
                avail_mem = line.split_whitespace().nth(1).unwrap().parse().unwrap();
            }
        }
        let used_mem_gb = (total_mem - avail_mem) as f64 / 1024.0 / 1024.0;
        let total_mem_gb = total_mem as f64 / 1024.0 / 1024.0;

        // Format: NET | CPU | RAM (pipe-pipe separator for wezterm parsing)
        let output = format!("{}||CPU: {:3}% | RAM: {:.1}/{:.1}GB", net_str, cpu_pct, used_mem_gb, total_mem_gb);
        let _ = fs::write("/tmp/sysinfo", &output);

        tick = tick.wrapping_add(1);
        thread::sleep(Duration::from_millis(125)); // 8Hz base tick
    }
}
