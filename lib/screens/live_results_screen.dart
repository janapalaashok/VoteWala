import 'dart:async';

import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

class LiveResultsScreen extends StatefulWidget {
  const LiveResultsScreen({super.key, required this.constituency});

  final Constituency constituency;

  @override
  State<LiveResultsScreen> createState() => _LiveResultsScreenState();
}

class _LiveResultsScreenState extends State<LiveResultsScreen> {
  late final Timer _refresh;
  DateTime _updated = istNow();

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) => setState(() => _updated = istNow()));
  }

  @override
  void dispose() {
    _refresh.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.constituency;
    final te = context.isTelugu;
    final snapshot = AppScope.of(context).snapshot(c);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(context.tr('liveResults')),
        actions: [IconButton(icon: const Icon(Icons.share_outlined), onPressed: () => sharePoll(context, c))],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _updated = istNow()),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          PageBody(
            maxWidth: 640,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${c.name(te)}\n${context.tr(c.isMla ? 'assemblyConstituency' : 'parliamentConstituency')}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 10),
              Row(children: [
                LiveBadge(closed: snapshot.closed),
                const Spacer(),
                Text('${snapshot.month.label(te)} · ${context.tr('updatedJustNow')}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ]),
              const SizedBox(height: 10),
              for (final i in snapshot.ranking)
                ResultRow(snapshot: snapshot, index: i, highlight: i == snapshot.leader),
              const SizedBox(height: 16),
              AppCard(
                padding: EdgeInsets.zero,
                child: IntrinsicHeight(
                  child: Row(children: [
                    _Stat(label: context.tr('totalVotes'), value: formatIndian(snapshot.total)),
                    const VerticalDivider(width: 1),
                    _Stat(label: context.tr('participation'), value: context.tr('verifiedAccounts'), small: true),
                    const VerticalDivider(width: 1),
                    _Stat(label: context.tr('lastUpdated'), value: formatTime(_updated)),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.small = false});

  final String label;
  final String value;
  final bool small;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: small ? 12.5 : 17, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}
