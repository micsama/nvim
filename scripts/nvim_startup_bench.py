#!/usr/bin/env python3
import re
import shutil
import statistics
import subprocess
import time
from pathlib import Path

from tqdm import tqdm

NORMAL_RUNS = 20
CLEAN_RUNS = 5
SUMMARY_MD = Path(__file__).resolve().parent / "summary.md"
ROOT = Path(__file__).resolve().parents[1]

REQUIRE_RE = re.compile(r"(?<![\w.])require\(\s*['\"]([^'\"]+)['\"]\s*\)")
PCALL_REQUIRE_RE = re.compile(r"pcall\(\s*require\s*,\s*['\"]([^'\"]+)['\"]\s*\)")
SCRIPT_LINE_RE = re.compile(r"^\s*[0-9]+(?:\.[0-9]+)?\s+[0-9]+(?:\.[0-9]+)?\s+([0-9]+(?:\.[0-9]+)?):\s+(.*)$")
LOCAL_PATH_RE = re.compile(r"\.config/nvim/(.*\.lua)$")


def module_to_file(module: str) -> Path | None:
    base = module.replace(".", "/")
    candidates = [
        ROOT / "lua" / f"{base}.lua",
        ROOT / "lua" / base / "init.lua",
        ROOT / f"{base}.lua",
    ]
    for path in candidates:
        if path.is_file():
            return path
    return None


def module_to_rel(module: str) -> str | None:
    path = module_to_file(module)
    if path is None:
        return None
    return path.relative_to(ROOT).as_posix()


def parse_startup_log(log_path: Path) -> tuple[float | None, dict[str, float]]:
    total_ms = None
    file_costs: dict[str, float] = {}

    try:
        with log_path.open("r", encoding="utf-8", errors="ignore") as file:
            for line in file:
                parts = line.lstrip().split(None, 1)
                if parts:
                    try:
                        value = float(parts[0])
                        if total_ms is None or value > total_ms:
                            total_ms = value
                    except ValueError:
                        pass

                match = SCRIPT_LINE_RE.match(line)
                if not match:
                    continue

                self_ms = float(match.group(1))
                text = match.group(2)
                local_match = LOCAL_PATH_RE.search(text)
                if not local_match:
                    mod_match = REQUIRE_RE.search(text)
                    if not mod_match:
                        continue
                    rel = module_to_rel(mod_match.group(1))
                    if rel is None:
                        continue
                else:
                    rel = local_match.group(1)

                file_costs[rel] = file_costs.get(rel, 0.0) + self_ms
    except OSError:
        return None, {}

    return total_ms, file_costs


def run_once(is_clean: bool, log_path: Path) -> tuple[float | None, dict[str, float]]:
    cmd = ["nvim"]
    if is_clean:
        cmd.append("--clean")
    cmd.extend(["--headless", "--startuptime", str(log_path), "+qa"])

    try:
        proc = subprocess.run(cmd, capture_output=True, text=True)
    except FileNotFoundError:
        return None, {}

    if proc.returncode != 0:
        return None, {}

    return parse_startup_log(log_path)


def trimmed(values: list[float]) -> list[float]:
    if len(values) <= 1:
        return values[:]
    result = values[:]
    result.remove(max(result))
    return result


def trim_records(records: list[tuple[float, dict[str, float]]]) -> list[tuple[float, dict[str, float]]]:
    if len(records) <= 1:
        return records[:]
    worst = max(range(len(records)), key=lambda idx: records[idx][0])
    return [record for idx, record in enumerate(records) if idx != worst]


def mean_file_cost(records: list[tuple[float, dict[str, float]]]) -> dict[str, float]:
    if not records:
        return {}

    sums: dict[str, float] = {}
    for _, costs in records:
        for rel, ms in costs.items():
            sums[rel] = sums.get(rel, 0.0) + ms

    count = float(len(records))
    return {rel: total / count for rel, total in sums.items()}


def fmt(value: float | None) -> str:
    return "-" if value is None else f"{value:.2f}"


def fmt_cost(costs: dict[str, float], rel: str) -> str:
    if rel not in costs:
        return "-"
    return f"{costs[rel]:.2f}"


def summary_row(name: str, raw: list[float], cut: list[float]) -> str:
    removed = max(raw) if len(raw) > 1 else None
    return (
        f"| {name} | {len(raw)} | {fmt(removed)} | {len(cut)} | "
        f"{fmt(statistics.mean(raw) if raw else None)} | "
        f"{fmt(statistics.median(raw) if raw else None)} | "
        f"{fmt(statistics.mean(cut) if cut else None)} | "
        f"{fmt(statistics.median(cut) if cut else None)} |"
    )


def parse_require_targets(path: Path) -> list[Path]:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return []

    targets: list[Path] = []
    seen: set[Path] = set()

    modules = REQUIRE_RE.findall(text) + PCALL_REQUIRE_RE.findall(text)
    for module in modules:
        target = module_to_file(module)
        if target is None:
            continue
        target = target.resolve()
        if target in seen:
            continue
        seen.add(target)
        targets.append(target)

    return targets


def build_require_graph() -> dict[str, list[str]]:
    root_file = (ROOT / "init.lua").resolve()
    graph: dict[str, list[str]] = {}
    visited: set[Path] = set()
    stack: list[Path] = [root_file]

    while stack:
        node = stack.pop()
        if node in visited:
            continue
        visited.add(node)

        node_rel = node.relative_to(ROOT).as_posix()
        children = parse_require_targets(node)
        child_rels = sorted(child.relative_to(ROOT).as_posix() for child in children)
        graph[node_rel] = child_rels

        for child in children:
            if child not in visited:
                stack.append(child)

    return graph


def build_tree_lines(graph: dict[str, list[str]], normal_cost: dict[str, float], clean_cost: dict[str, float]) -> list[str]:
    lines: list[str] = []

    def node_line(rel: str, depth: int) -> str:
        indent = "  " * depth
        return f"{indent}- {rel} (normal={fmt_cost(normal_cost, rel)}ms, clean={fmt_cost(clean_cost, rel)}ms)"

    def dfs(node: str, depth: int, stack: set[str]) -> None:
        lines.append(node_line(node, depth))
        if node in stack:
            lines[-1] += " [循环引用已截断]"
            return

        children = graph.get(node, [])
        children = sorted(
            children,
            key=lambda rel: (max(normal_cost.get(rel, 0.0), clean_cost.get(rel, 0.0)), rel),
            reverse=True,
        )
        next_stack = set(stack)
        next_stack.add(node)
        for child in children:
            dfs(child, depth + 1, next_stack)

    if "init.lua" in graph:
        dfs("init.lua", 0, set())
    else:
        lines.append("- init.lua (未在图中找到)")

    return lines


def write_markdown(
    normal_raw: list[float],
    clean_raw: list[float],
    normal_records: list[tuple[float, dict[str, float]]],
    clean_records: list[tuple[float, dict[str, float]]],
) -> None:
    normal_cut = trimmed(normal_raw)
    clean_cut = trimmed(clean_raw)
    normal_file_cost = mean_file_cost(trim_records(normal_records))
    clean_file_cost = mean_file_cost(trim_records(clean_records))

    file_keys = sorted(
        set(normal_file_cost.keys()) | set(clean_file_cost.keys()),
        key=lambda rel: (max(normal_file_cost.get(rel, 0.0), clean_file_cost.get(rel, 0.0)), rel),
        reverse=True,
    )

    graph = build_require_graph()
    tree_lines = build_tree_lines(graph, normal_file_cost, clean_file_cost)

    lines = [
        "# Neovim 启动性能报告",
        "",
        f"- 生成时间：{time.strftime('%Y-%m-%d %H:%M:%S')}",
        "- 执行方式：串行（不并行）",
        "- 统计策略：每组去掉最慢 1 次（冷启动去极值）后，计算均值与中位数",
        "",
        "## 启动总耗时统计",
        "",
        "| 模式 | 原始次数 | 去掉最大值(ms) | 去极值后次数 | 原始均值(ms) | 原始中位数(ms) | 去极值均值(ms) | 去极值中位数(ms) |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
        summary_row("normal", normal_raw, normal_cut),
        summary_row("clean", clean_raw, clean_cut),
        "",
        "## 文件级耗时（单位：ms，去极值后按次平均）",
        "",
        "| 文件 | normal | clean |",
        "|---|---:|---:|",
    ]

    for rel in file_keys:
        lines.append(f"| {rel} | {fmt_cost(normal_file_cost, rel)} | {fmt_cost(clean_file_cost, rel)} |")

    lines.extend([
        "",
        "## require 树（节点显示文件级平均耗时）",
        "",
    ])
    lines.extend(tree_lines)

    lines.extend(
        [
            "",
            "## 最终结论（去极值）",
            (
                f"- normal：均值 {statistics.mean(normal_cut):.2f}ms，中位数 {statistics.median(normal_cut):.2f}ms"
                if normal_cut
                else "- normal：无成功样本"
            ),
            (
                f"- clean：均值 {statistics.mean(clean_cut):.2f}ms，中位数 {statistics.median(clean_cut):.2f}ms"
                if clean_cut
                else "- clean：无成功样本"
            ),
        ]
    )

    SUMMARY_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_benchmark(temp_dir: Path) -> tuple[
    list[float],
    list[float],
    list[tuple[float, dict[str, float]]],
    list[tuple[float, dict[str, float]]],
]:
    runs = [("normal", False, i) for i in range(1, NORMAL_RUNS + 1)]
    runs.extend(("clean", True, i) for i in range(1, CLEAN_RUNS + 1))

    normal: list[float] = []
    clean: list[float] = []
    normal_records: list[tuple[float, dict[str, float]]] = []
    clean_records: list[tuple[float, dict[str, float]]] = []

    with tqdm(total=len(runs), desc="nvim 启动测试", unit="次", dynamic_ncols=True) as bar:
        for run_type, is_clean, idx in runs:
            log_path = temp_dir / f"{run_type}-{idx:02d}.log"
            ms, file_costs = run_once(is_clean, log_path)
            status = "FAIL" if ms is None else f"{ms:.2f}ms"
            bar.set_postfix_str(f"{run_type}#{idx} {status}")
            bar.update(1)

            if ms is None:
                continue

            if is_clean:
                clean.append(ms)
                clean_records.append((ms, file_costs))
            else:
                normal.append(ms)
                normal_records.append((ms, file_costs))

    return normal, clean, normal_records, clean_records


def main() -> int:
    temp_dir = Path(f"/tmp/nvim-startup-bench-{int(time.time())}")
    temp_dir.mkdir(parents=True, exist_ok=True)

    try:
        normal, clean, normal_records, clean_records = run_benchmark(temp_dir)
        write_markdown(normal, clean, normal_records, clean_records)

        normal_cut = trimmed(normal)
        clean_cut = trimmed(clean)
        print("\n最终统计（去极值）")
        if normal_cut:
            print(f"- normal：均值={statistics.mean(normal_cut):.2f}ms 中位数={statistics.median(normal_cut):.2f}ms")
        else:
            print("- normal：无成功样本")
        if clean_cut:
            print(f"- clean：均值={statistics.mean(clean_cut):.2f}ms 中位数={statistics.median(clean_cut):.2f}ms")
        else:
            print("- clean：无成功样本")
        print(f"- 报告：{SUMMARY_MD}")

        return 0
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
