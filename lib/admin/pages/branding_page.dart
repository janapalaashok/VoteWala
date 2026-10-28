import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../admin_widgets.dart';

class BrandingPage extends StatelessWidget {
  const BrandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final b = admin.draft.branding;
    void set(BrandingConfig Function(BrandingConfig b) f) => admin.update((c) => c.copyWith(branding: f(c.branding)));

    final form = Column(children: [
      AdminCard(
        title: 'Identity',
        child: Column(children: [
          DraftField(label: 'App name', value: b.appName, onChanged: (v) => set((b) => b.copyWith(appName: v.isEmpty ? 'VoteWala' : v))),
          const SizedBox(height: 14),
          DraftField(label: 'Tagline (English)', value: b.taglineEn, onChanged: (v) => set((b) => b.copyWith(taglineEn: v))),
          const SizedBox(height: 14),
          DraftField(label: 'Tagline (Telugu)', value: b.taglineTe, onChanged: (v) => set((b) => b.copyWith(taglineTe: v))),
        ]),
      ),
      AdminCard(
        title: 'Colours',
        subtitle: 'Used for buttons, highlights and live badges in the app and website.',
        child: Wrap(spacing: 40, runSpacing: 24, children: [
          ColorField(label: 'Primary (orange)', color: b.primary, onChanged: (v) => set((b) => b.copyWith(primary: v))),
          ColorField(label: 'Secondary (green)', color: b.secondary, onChanged: (v) => set((b) => b.copyWith(secondary: v))),
        ]),
      ),
      AdminCard(
        title: 'Logos',
        subtitle: 'PNG with a transparent background works best.',
        child: Column(children: [
          ImageField(
            label: 'Full logo (mark + wordmark)',
            url: b.logoUrl,
            folder: 'branding',
            fallback: Padding(padding: const EdgeInsets.all(8), child: Image.asset('assets/brand/logo.png')),
            onChanged: (u) => set((b) => b.copyWith(logoUrl: u, clearLogo: u == null)),
          ),
          const Divider(height: 36),
          ImageField(
            label: 'Mark (square symbol)',
            url: b.markUrl,
            folder: 'branding',
            fallback: Padding(padding: const EdgeInsets.all(12), child: Image.asset('assets/brand/mark.png')),
            onChanged: (u) => set((b) => b.copyWith(markUrl: u, clearMark: u == null)),
          ),
          const Divider(height: 36),
          ImageField(
            label: 'App icon',
            helper: 'Phones cannot change an installed app\'s icon remotely: this icon is used by the next app '
                'build (see docs/FIREBASE_SETUP.md).',
            url: b.appIconUrl,
            folder: 'branding',
            fallback: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset('assets/brand/mark.png'),
            ),
            onChanged: (u) => set((b) => b.copyWith(appIconUrl: u, clearAppIcon: u == null)),
          ),
        ]),
      ),
    ]);

    return AdminPage(
      title: 'Branding',
      subtitle: 'Name, colours and logos shown in the app and on the website.',
      children: [
        LayoutBuilder(builder: (context, box) {
          final preview = _Preview(branding: b);
          if (box.maxWidth < 1000) return Column(children: [preview, const SizedBox(height: 20), form]);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: form),
            const SizedBox(width: 24),
            SizedBox(width: 340, child: preview),
          ]);
        }),
      ],
    );
  }
}

/// Phone-shaped live preview of the branding.
class _Preview extends StatelessWidget {
  const _Preview({required this.branding});

  final BrandingConfig branding;

  @override
  Widget build(BuildContext context) {
    final b = branding;
    final logo = b.logoUrl == null
        ? Image.asset('assets/brand/logo.png', height: 34)
        : Image.network(b.logoUrl!, height: 34, errorBuilder: (_, _, _) => Image.asset('assets/brand/logo.png', height: 34));
    return Column(children: [
      const Text('LIVE PREVIEW', style: TextStyle(letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.muted)),
      const SizedBox(height: 12),
      Container(
        width: 300,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [BoxShadow(color: Color(0x330F172A), blurRadius: 40, offset: Offset(0, 20))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: const Color(0xFFF6F7F9),
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: logo),
              const SizedBox(height: 12),
              Container(
                height: 110,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFF1F4E79), Color(0xFF6FA8D6)]),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Your Voice.\nYour Choice.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, height: 1.1)),
                  const SizedBox(height: 6),
                  Text(b.taglineTe, style: const TextStyle(color: Color(0xFFF6B21A), fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _tile(b.primary, 'MLA Polls')),
                const SizedBox(width: 8),
                Expanded(child: _tile(b.secondary, 'MP Polls')),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: b.secondary, borderRadius: BorderRadius.circular(6)),
                    child: const Text('● LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: b.primary, borderRadius: BorderRadius.circular(16)),
                    child: const Text('Vote', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              Text(b.appName, textAlign: TextAlign.center, style: const TextStyle(color: AdminColors.muted, fontSize: 12)),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _tile(Color color, String label) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Text('Vote Now', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}
