import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';

class StatPage extends StatefulWidget {
  const StatPage({super.key});
  @override
  State<StatPage> createState() => _StatPageState();
}

class _StatPageState extends State<StatPage> {
  String _period = 'week'; // week / month / year

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final expenseByCategory = provider.expenseByCategory;
    final dailyStats = provider.dailyStats;

    // 排行榜数据
    final ranked = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxExpense = ranked.isNotEmpty ? ranked.first.value : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(children: [
          // 标题+周期切换
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('统计', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  _periodTab('周', 'week'),
                  _periodTab('月', 'month'),
                  _periodTab('年', 'year'),
                ]),
              ),
            ]),
          ),
          // 支出构成饼图
          _buildCard(
            title: '支出构成',
            child: SizedBox(
              height: 200,
              child: Row(children: [
                Expanded(
                  child: ranked.isEmpty
                      ? const Center(child: Text('暂无数据', style: TextStyle(color: Color(0xFF9CA3AF))))
                      : PieChart(PieChartData(
                          sections: _buildPieSections(ranked, provider.monthExpense),
                          centerSpaceRadius: 45,
                          sectionsSpace: 2,
                        )),
                ),
                // 中心文字覆盖
                SizedBox(width: 0),
              ]),
            ),
            centerLabel: '总支出',
            centerValue: '¥${provider.monthExpense.toStringAsFixed(0)}',
          ),
          // 收支趋势柱状图
          _buildCard(
            title: '收支趋势',
            child: SizedBox(
              height: 180,
              child: dailyStats.isEmpty
                  ? const Center(child: Text('暂无数据', style: TextStyle(color: Color(0xFF9CA3AF))))
                  : BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxValue(dailyStats) * 1.2,
                      barGroups: _buildBarGroups(dailyStats),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            getTitlesWidget: (v, _) {
                              final keys = dailyStats.keys.toList()..sort();
                              if (v.toInt() < keys.length) {
                                final d = DateTime.parse(keys[v.toInt()]);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('${d.day}', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                    )),
            ),
          ),
          // 图例
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _legend(const Color(0xFFF5365C), '支出'),
              const SizedBox(width: 20),
              _legend(const Color(0xFF2DC653), '收入'),
            ]),
          ),
          // 支出排行
          _buildCard(
            title: '支出排行',
            child: ranked.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('暂无数据', style: TextStyle(color: Color(0xFF9CA3AF)))))
                : Column(children: ranked.take(5).toList().asMap().entries.map((e) {
                    final i = e.key;
                    final entry = e.value;
                    final cat = provider.getCategoryById(entry.key);
                    final pct = maxExpense > 0 ? entry.value / maxExpense : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Text('${i + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF))),
                        const SizedBox(width: 8),
                        Text(cat?.emoji ?? '📦', style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(cat?.name ?? '未知', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: const Color(0xFFF3F4F6),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF4F6EF7)),
                              minHeight: 4,
                            ),
                          ),
                        ])),
                        const SizedBox(width: 10),
                        Text('¥${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ]),
                    );
                  }).toList()),
          ),
        ]),
      ),
    );
  }

  Widget _periodTab(String label, String value) {
    final active = _period == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))] : [],
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? const Color(0xFF4F6EF7) : const Color(0xFF9CA3AF))),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child, String? centerLabel, String? centerValue}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Stack(alignment: Alignment.center, children: [
          child,
          if (centerLabel != null)
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(centerLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              Text(centerValue ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
        ]),
      ]),
    );
  }

  List<PieChartSectionData> _buildPieSections(List<MapEntry<String, double>> ranked, double total) {
    final colors = [const Color(0xFFF5365C), const Color(0xFFFF8C42), const Color(0xFFFFD166), const Color(0xFF06D6A0), const Color(0xFF118AB2), const Color(0xFF9CA3AF)];
    return ranked.asMap().entries.map((e) {
      final i = e.key;
      final value = e.value.value;
      // ignore: unused_local_variable
      final pct = total > 0 ? value / total : 0;
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: value,
        title: '',
        radius: 60,
        showTitle: false,
      );
    }).toList();
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, Map<String, double>> dailyStats) {
    final keys = dailyStats.keys.toList()..sort();
    return keys.asMap().entries.map((e) {
      final i = e.key;
      final data = dailyStats[e.value]!;
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: data['expense'] ?? 0, color: const Color(0xFFF5365C), width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
        BarChartRodData(toY: data['income'] ?? 0, color: const Color(0xFF2DC653), width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
      ]);
    }).toList();
  }

  double _getMaxValue(Map<String, Map<String, double>> dailyStats) {
    double max = 0;
    for (final v in dailyStats.values) {
      if ((v['expense'] ?? 0) > max) max = v['expense']!;
      if ((v['income'] ?? 0) > max) max = v['income']!;
    }
    return max;
  }

  Widget _legend(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}
