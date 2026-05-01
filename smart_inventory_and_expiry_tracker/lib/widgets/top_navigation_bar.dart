import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

typedef SearchCallback = void Function(String query);

class CupertinoTopNavigationBar extends StatefulWidget implements ObstructingPreferredSizeWidget {
  final String title;
  final SearchCallback? onSearch;
  final bool showSearch;
  final String placeholder;

  const CupertinoTopNavigationBar({
    super.key,
    required this.title,
    this.onSearch,
    this.placeholder = 'Search',
    this.showSearch = true,
  });

  @override
  State<CupertinoTopNavigationBar> createState() => _CupertinoTopNavigationBarState();

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  bool shouldFullyObstruct(BuildContext context) => false;
}

class _CupertinoTopNavigationBarState extends State<CupertinoTopNavigationBar> {
  bool _isSearching = false;
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      if (_isSearching) {
        _isSearching = false;
        _controller.clear();
        widget.onSearch?.call('');
      } else {
        _isSearching = true;
      }
    });
  }

  @override
  void didUpdateWidget(covariant CupertinoTopNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If search is disabled by the parent, clear any existing search state.
    if (!widget.showSearch && _isSearching) {
      _isSearching = false;
      _controller.clear();
      widget.onSearch?.call('');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get brightness from CupertinoTheme to support system theme mode
    final theme = CupertinoTheme.of(context);
    final brightness = theme.brightness ?? Brightness.light;
    final isDark = brightness == Brightness.dark;

    return CupertinoNavigationBar(
      backgroundColor: isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground,
      border: Border(
        bottom: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      leading: _isSearching
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20.0, 
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
      middle: _isSearching
          ? SizedBox(
              height: 36,
              child: CupertinoSearchTextField(
                controller: _controller,
                placeholder: widget.placeholder,
                onChanged: (v) => widget.onSearch?.call(v),
                onSubmitted: (v) => widget.onSearch?.call(v),
                style: TextStyle(color: isDark ? AppColors.darkText : AppColors.lightText),
                placeholderStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                backgroundColor: isDark ? Colors.grey.shade900 : CupertinoColors.tertiarySystemFill,
              ),
            )
          : null,
      trailing: widget.showSearch
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: _toggleSearch,
              child: Icon(
                _isSearching ? CupertinoIcons.clear : CupertinoIcons.search,
                color: isDark ? Colors.green.shade700 : Colors.green.shade700,
                size: 24,
              ),
            )
          : null,
    );
  }
}
