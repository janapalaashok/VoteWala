import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import 'admin_controller.dart';

/// Admin palette (independent of the app's brand colours).
class AdminColors {
  static const sidebar = Color(0xFF0F172A);
  static const sidebarHover = Color(0xFF1E293B);
  static const bg = Color(0xFFF4F6FA);
  static const card = Colors.white;
  static const border = Color(0xFFE5E9F0);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const accent = Color(0xFFF47A1F);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
}

class AdminScope extends InheritedNotifier<AdminController> {
  const AdminScope({super.key, required AdminController controller, required super.child})
      : super(notifier: controller);

  static AdminController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminScope>()!.notifier!;

  static AdminController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AdminScope>()!.notifier!;
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.title, this.subtitle, this.actions = const [], required this.children});

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final phone = isAdminPhone(context);
    final heading = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontSize: phone ? 22 : 26, fontWeight: FontWeight.w800, color: AdminColors.ink, letterSpacing: -0.4)),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle!, style: TextStyle(color: AdminColors.muted, fontSize: phone ? 13.5 : 14.5)),
      ],
    ]);
    return ListView(
      padding: phone ? const EdgeInsets.fromLTRB(14, 16, 14, 40) : const EdgeInsets.fromLTRB(32, 28, 32, 48),
      children: [
        if (phone) ...[
          heading,
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
          ],
        ] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: heading), ...actions]),
        SizedBox(height: phone ? 16 : 24),
        ...children,
      ],
    );
  }
}

/// Phones: the admin console fits the screen width.
bool isAdminPhone(BuildContext context) => MediaQuery.sizeOf(context).width < 720;

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AdminColors.ink)),
      if (subtitle != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle!, style: const TextStyle(color: AdminColors.muted, fontSize: 13)),
        ),
    ]);
    // Phones: a wide button or field next to the title would squeeze it, so
    // it goes underneath (small icons stay on the right).
    final t = trailing;
    if (t != null && isAdminPhone(context) && t is! Icon && t is! IconButton) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        text,
        const SizedBox(height: 12),
        t,
      ]);
    }
    return Row(children: [Expanded(child: text), ?t]);
  }
}

/// Fields side by side on wide screens, one under the other on phones.
/// Children may be Expanded (as in a Row); gaps are added automatically.
class AdminFieldRow extends StatelessWidget {
  const AdminFieldRow({super.key, required this.children});

  final List<Widget> children;

  static bool _isGap(Widget w) => w is SizedBox && w.child == null && w.height == null;

  @override
  Widget build(BuildContext context) {
    if (!isAdminPhone(context)) return Row(children: children);
    final items = [for (final w in children) if (!_isGap(w)) w is Expanded ? w.child : w];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(height: 12), items[i]],
    ]);
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({super.key, this.title, this.subtitle, this.trailing, required this.child, this.padding = 22});

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AdminColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AdminColors.border),
          boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 24, offset: Offset(0, 8))],
        ),
        padding: EdgeInsets.all(isAdminPhone(context) ? (padding > 16 ? 16 : padding) : padding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (title != null) ...[
            _CardHeader(title: title!, subtitle: subtitle, trailing: trailing),
            const SizedBox(height: 18),
          ],
          child,
        ]),
      );
}

/// Text field that edits a draft value; [onChanged] receives trimmed text
/// (empty means "use the default").
class DraftField extends StatefulWidget {
  const DraftField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.helper,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final String? helper;
  final int maxLines;

  @override
  State<DraftField> createState() => _DraftFieldState();
}

class _DraftFieldState extends State<DraftField> {
  late final TextEditingController _c = TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(DraftField old) {
    super.didUpdateWidget(old);
    if ((widget.value ?? '') != _c.text && !(_focus.hasFocus)) _c.text = widget.value ?? '';
  }

  final _focus = FocusNode();

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _c,
        focusNode: _focus,
        maxLines: widget.maxLines,
        minLines: 1,
        onChanged: (v) => widget.onChanged(v.trim()),
        decoration: InputDecoration(labelText: widget.label, hintText: widget.hint, helperText: widget.helper),
      );
}

const brandSwatches = [
  Color(0xFFF47A1F), Color(0xFFE5640C), Color(0xFF1E9A3F), Color(0xFF0F766E), Color(0xFF2F6FDB),
  Color(0xFF1D4ED8), Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFE53935), Color(0xFFF5C400),
  Color(0xFF0F172A), Color(0xFF64748B),
];

class ColorField extends StatelessWidget {
  const ColorField({super.key, required this.label, required this.color, required this.onChanged});

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AdminColors.ink)),
        const SizedBox(height: 10),
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.border, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: DraftField(
              key: ValueKey('$label-${colorToHex(color)}'),
              label: 'Hex',
              value: colorToHex(color),
              onChanged: (v) {
                final c = colorFromHex(v);
                if (c != null) onChanged(c);
              },
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in brandSwatches)
            InkWell(
              onTap: () => onChanged(s),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: s,
                  shape: BoxShape.circle,
                  border: Border.all(color: s == color ? AdminColors.ink : Colors.white, width: 2.5),
                  boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 3)],
                ),
              ),
            ),
        ]),
      ]);
}

/// Image preview with upload / URL / clear.
class ImageField extends StatelessWidget {
  const ImageField({
    super.key,
    required this.label,
    required this.url,
    required this.folder,
    required this.onChanged,
    this.fallback,
    this.size = 96,
    this.helper,
  });

  final String label;
  final String? url;
  final String folder;
  final ValueChanged<String?> onChanged;
  final Widget? fallback;
  final double size;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.read(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: url == null
            ? (fallback ?? const Icon(Icons.image_outlined, color: AdminColors.muted))
            : Image.network(url!, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined)),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AdminColors.ink)),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(helper!, style: const TextStyle(color: AdminColors.muted, fontSize: 12.5)),
            ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              onPressed: () async {
                final u = await admin.uploadImage(folder);
                if (u != null) onChanged(u);
              },
              icon: const Icon(Icons.upload, size: 18),
              label: const Text('Upload'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final u = await promptText(context, 'Image URL', url ?? '');
                if (u != null) onChanged(u.isEmpty ? null : u);
              },
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Paste URL'),
            ),
            if (url != null)
              TextButton.icon(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Reset'),
              ),
          ]),
        ]),
      ),
    ]);
  }
}

Future<String?> promptText(BuildContext context, String title, String initial, {int maxLines = 1}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        child: TextField(controller: c, autofocus: true, maxLines: maxLines, minLines: 1),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
      ],
    ),
  );
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon, required this.color, this.footer});

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? footer;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AdminColors.border),
          boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: AdminColors.muted, fontSize: 13)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AdminColors.ink)),
              if (footer != null) Text(footer!, style: const TextStyle(color: AdminColors.muted, fontSize: 12)),
            ]),
          ),
        ]),
      );
}

/// Responsive grid of fixed-min-width children.
class AdminGrid extends StatelessWidget {
  const AdminGrid({super.key, required this.children, this.minWidth = 260, this.spacing = 20});

  final List<Widget> children;
  final double minWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final cols = (box.maxWidth / minWidth).floor().clamp(1, 6);
        final w = (box.maxWidth - (cols - 1) * spacing) / cols;
        return Wrap(spacing: spacing, runSpacing: spacing, children: [
          for (final c in children) SizedBox(width: w, child: c),
        ]);
      });
}

void showAdminSnack(BuildContext context, String text, {bool error = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      width: 460,
      backgroundColor: error ? AdminColors.danger : AdminColors.ink,
      content: Text(text),
    ));
