import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    return CupertinoNavigationBar(
      leading: _isSearching
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
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
              ),
            )
          : null,
      trailing: widget.showSearch
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              child: IconTheme(
                data: const IconThemeData(color: CupertinoColors.black, size: 24),
                child: Icon(_isSearching ? CupertinoIcons.clear : CupertinoIcons.search),
              ),
              onPressed: _toggleSearch,
            )
          : null,
    );
  }
}
