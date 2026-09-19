import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/config.dart';
import '../data/api.dart';
import '../state/providers.dart';
import 'design_system.dart';

class LiveQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final DateTime validUntil;
  final int points;

  LiveQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.validUntil,
    required this.points,
  });

  static LiveQuestion fromMap(Map<String, dynamic> m) {
    return LiveQuestion(
      id: m['id'] as String,
      questionText: m['questionText'] as String,
      options: (m['options'] as List).map((e) => e.toString()).toList(),
      validUntil: DateTime.parse(m['validUntil'] as String),
      points: (m['points'] as int?) ?? 10,
    );
  }
}

class SessionPage extends ConsumerStatefulWidget {
  final String mediaId;
  final String mediaName;
  final String mediaType; // TV | RADIO

  const SessionPage({super.key, required this.mediaId, required this.mediaName, required this.mediaType});

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  io.Socket? _socket;
  LiveQuestion? _q;
  Timer? _timer;
  int _remainingMs = 0;
  DateTime? _receivedAt;
  bool _answering = false;
  String? _selectedAnswer;
  bool? _wasCorrect;
  int _sessionPoints = 0;
  int _totalPoints = 0;

  // Leaderboard state
  Map<String, dynamic>? _lastLeaderboard;

  @override
  void initState() {
    super.initState();
    _connect();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final api = Api(ref.read(apiClientProvider));
      final me = await api.me();
      if (!mounted) return;
      setState(() => _totalPoints = (me['totalPoints'] as int?) ?? 0);
    } catch (_) {
      // Keep the session usable even if the balance fetch fails.
    }
  }

  void _tick() {
    final q = _q;
    if (q == null) return;
    final ms = q.validUntil.difference(DateTime.now()).inMilliseconds;
    setState(() => _remainingMs = ms.clamp(0, 60 * 1000));
  }

  void _connect() {
    final s = io.io(
      '${AppConfig.socketBaseUrl}/live',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );

    s.onConnect((_) {
      s.emit('join_media', {'mediaId': widget.mediaId});
    });

    s.on('question', (data) {
      final m = Map<String, dynamic>.from(data as Map);
      setState(() {
        _q = LiveQuestion.fromMap(m);
        _receivedAt = DateTime.now();
        _answering = false;
        _selectedAnswer = null;
        _wasCorrect = null;
        _lastLeaderboard = null; // clear previous leaderboard
      });
    });

    s.on('leaderboard', (data) {
      final lb = Map<String, dynamic>.from(data as Map);
      setState(() => _lastLeaderboard = lb);
      if (mounted) _showLeaderboard(lb);
    });

    s.connect();
    _socket = s;
  }

  void _showLeaderboard(Map<String, dynamic> lb) {
    final entries   = (lb['entries'] as List? ?? []).cast<dynamic>();
    final total     = (lb['totalAnswers']   as int?) ?? 0;
    final correct   = (lb['correctAnswers'] as int?) ?? 0;
    final answer    = (lb['correctAnswer']  as String?) ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeaderboardSheet(
        entries: entries,
        totalAnswers: total,
        correctAnswers: correct,
        correctAnswer: answer,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _submit(String selected) async {
    final q = _q;
    final receivedAt = _receivedAt;
    if (q == null || receivedAt == null) return;
    if (_answering) return;
    setState(() {
      _answering = true;
      _selectedAnswer = selected;
    });

    final api = Api(ref.read(apiClientProvider));
    final rt = DateTime.now().difference(receivedAt).inMilliseconds;

    try {
      final res = await api.submitAnswer(questionId: q.id, selectedAnswer: selected, responseTimeMs: rt);
      final answer        = Map<String, dynamic>.from(res['answer'] as Map);
      final isCorrect     = (answer['isCorrect'] as bool?) ?? false;
      final pointsAwarded = (answer['pointsAwarded'] as int?) ?? 0;
      final speedBonus    = (answer['speedBonus'] as int?) ?? 0;
      final total         = (res['totalPoints'] as int?) ?? 0;
      final remaining     = (res['remainingToNextCoupon'] as int?) ?? 0;
      final nextThreshold = (res['nextCouponThreshold'] as int?) ?? 1000;

      if (!mounted) return;
      setState(() {
        _wasCorrect = isCorrect;
        _totalPoints = total;
        if (isCorrect) _sessionPoints += pointsAwarded;
      });

      // Build result dialog with speed bonus breakdown
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(isCorrect ? 'صحيح!' : 'غلطت'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCorrect) ...[
                // Points breakdown
                _PointRow(label: 'إجابة صحيحة', value: '+${q.points}'),
                if (speedBonus > 0)
                  _PointRow(label: 'بونوس السرعة ⚡', value: '+$speedBonus', highlight: true),
                const Divider(height: 16),
                _PointRow(label: 'المجموع هذا السؤال', value: '+$pointsAwarded', bold: true),
                const SizedBox(height: 8),
                _PointRow(label: 'رصيدك الكلي', value: '$total نقطة', bold: true),
                const SizedBox(height: 8),
                // Progress toward next coupon
                Text(
                  'باقي $remaining نقطة للكوبون التالي ($nextThreshold)',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: nextThreshold > 0 ? (total % nextThreshold) / nextThreshold : 1.0,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B2EFF)),
                  ),
                ),
              ] else ...[
                Text('جرّب في السؤال الجاي. رصيدك توا: $total نقطة'),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('تمام'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('صار مشكل. جرّب مرة أخرى.')));
    } finally {
      if (mounted) setState(() => _answering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _q;
    final remaining = (_remainingMs / 1000).ceil();
    final progress = (_totalPoints % 1000) / 1000.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mediaName),
        actions: [
          IconButton(
            onPressed: () => _socket?.emit('dev_generate_question', {'mediaId': widget.mediaId}),
            icon: const Icon(Icons.bolt),
            tooltip: 'سؤال جديد (dev)',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.22), blurRadius: 24, offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.mediaType == 'TV' ? 'لايف من التلفزة' : 'لايف من الراديو',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.mediaName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Chip(label: Text('LIVE')),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Chip(label: Text('Session +$_sessionPoints')),
                    const SizedBox(width: 8),
                    Chip(label: Text('Total $_totalPoints')),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AppTimerRing(remainingSeconds: remaining.clamp(0, 15)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEDE8FB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('عندك $remaining ثواني', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('جاوب بسرعة باش ما يطيرش الوقت.', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (q == null)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: AppEmptyView(
                icon: Icons.live_tv_rounded,
                title: 'استنّى السؤال الجاي',
                subtitle: 'خليك مركز، لايف جديد داخل توّا.',
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFEDE8FB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('اختار الإجابة الصحيحة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text(q.questionText, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Chip(label: Text('+${q.points} نقاط')),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...q.options.map((opt) {
              final disabled = _answering || _remainingMs <= 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppOptionCard(
                  label: opt,
                  selected: _selectedAnswer == opt,
                  correct: _wasCorrect == true && _selectedAnswer == opt,
                  incorrect: _wasCorrect == false && _selectedAnswer == opt,
                  onTap: disabled ? () {} : () => _submit(opt),
                ),
              );
            }),
            if (_remainingMs <= 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('وفّى الوقت! نستناو السؤال الجاي...', style: Theme.of(context).textTheme.bodyMedium),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Leaderboard bottom sheet ─────────────────────────────────────────────────
class _LeaderboardSheet extends StatelessWidget {
  final List<dynamic> entries;
  final int totalAnswers;
  final int correctAnswers;
  final String correctAnswer;

  const _LeaderboardSheet({
    required this.entries,
    required this.totalAnswers,
    required this.correctAnswers,
    required this.correctAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final wrongAnswers = totalAnswers - correctAnswers;
    final pct = totalAnswers > 0 ? (correctAnswers / totalAnswers * 100).round() : 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B2EFF), Color(0xFF8E5BFF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ترتيب السؤال',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      Text('الإجابة الصحيحة: $correctAnswer',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF22C55E), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _StatBadge(icon: Icons.people_alt_rounded, label: 'أجابوا', value: '$totalAnswers', color: const Color(0xFF5B2EFF)),
                const SizedBox(width: 10),
                _StatBadge(icon: Icons.check_rounded, label: 'صحيح', value: '$correctAnswers ($pct%)', color: const Color(0xFF22C55E)),
                const SizedBox(width: 10),
                _StatBadge(icon: Icons.close_rounded, label: 'غلط', value: '$wrongAnswers', color: const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 20),

            if (entries.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('ما حدّ جاوب في هذا السؤال.', style: TextStyle(color: Color(0xFF6B7280))),
                ),
              )
            else ...[
              const Text('أحسن المتسابقين',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF374151))),
              const SizedBox(height: 10),
              ...entries.asMap().entries.map((e) {
                final idx   = e.key;
                final entry = Map<String, dynamic>.from(e.value as Map);
                final rank  = (entry['rank'] as int?) ?? (idx + 1);
                final first = (entry['firstName'] as String?) ?? '';
                final last  = ((entry['lastName'] as String?) ?? '');
                final name  = '$first $last'.trim();
                final pts   = (entry['pointsAwarded'] as int?) ?? 0;
                final ms    = (entry['responseTimeMs'] as int?) ?? 0;
                final secs  = (ms / 1000).toStringAsFixed(1);

                final medals = ['🥇', '🥈', '🥉'];
                final medal  = rank <= 3 ? medals[rank - 1] : '$rank.';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: rank == 1
                        ? const Color(0xFFFFFBEB)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: rank == 1
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(medal, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.isEmpty ? 'مستخدم' : name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            Text('جاوب في ${secs}ث',
                              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B2EFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('+$pts نقطة',
                          style: const TextStyle(
                            color: Color(0xFF5B2EFF),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          )),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBadge({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Small helper widget for the score breakdown rows in the result dialog ──
class _PointRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool highlight;

  const _PointRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color  = highlight ? const Color(0xFF5B2EFF) : null;
    final weight = bold || highlight ? FontWeight.w900 : FontWeight.normal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: weight, color: color)),
          Text(value,  style: TextStyle(fontWeight: weight, color: color)),
        ],
      ),
    );
  }
}

