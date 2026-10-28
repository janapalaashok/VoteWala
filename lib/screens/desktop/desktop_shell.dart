import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../browse_screens.dart';

/// Desktop website frame: frosted top navigation over the page content.
class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key, required this.index, required this.onSelect, required this.body});

  final int index;
  final ValueChanged<int> onSelect;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final labels = [context.tr('home'), context.tr('mla'), context.tr('mp'), context.tr('results'), context.tr('profile')];
    final initials = (state.user?.name ?? 'V').trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(children: [
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                border: const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Row(children: [
                    InkWell(onTap: () => onSelect(0), child: const VoteWalaLogo(markSize: 50, horizontal: true)),
                    const SizedBox(width: 36),
                    for (var i = 0; i < 4; i++)
                      _NavLink(label: labels[i], selected: index == i, onTap: () => onSelect(i)),
                    const Spacer(),
                    IconButton(
                      tooltip: context.tr('search'),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
                      icon: const Icon(Icons.search),
                    ),
                    const SizedBox(width: 8),
                    _LangToggle(state: state),
                    const SizedBox(width: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => onSelect(4),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: index == 4 ? AppColors.orange : AppColors.border),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: AppColors.orange,
                            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          Text(labels[4], style: const TextStyle(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: body),
      ]),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: selected ? AppColors.orange : Colors.transparent, width: 3)),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? AppColors.ink : AppColors.muted,
              )),
        ),
      );
}

class _LangToggle extends StatelessWidget {
  const _LangToggle({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          for (final (code, label) in [('en', 'EN'), ('te', 'తెలుగు')])
            GestureDetector(
              onTap: () => state.setLanguage(code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: state.language == code ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: state.language == code ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6)] : null,
                ),
                child: Text(label, style: TextStyle(fontWeight: state.language == code ? FontWeight.w800 : FontWeight.w500)),
              ),
            ),
        ]),
      );
}
