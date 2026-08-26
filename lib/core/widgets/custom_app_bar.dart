import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool? centerTitle;
  final bool? isTransparent;
  final bool showBackIcon;
  final Widget? action;
  final List<Widget>? extraActions;
  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.isTransparent = false,
    this.showBackIcon = true,
    this.action,
    this.extraActions,
    this.onBackPressed});

  final VoidCallback? onBackPressed;


  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: isTransparent! ? Colors.transparent : Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0.0,
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      leading:showBackIcon?MaterialButton(
        onPressed: onBackPressed ?? () => Navigator.pop(context),
        child: const Icon(CupertinoIcons.left_chevron),
      ):null,
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 2.0, right: 8, top: 8, bottom: 8),
          child: Row(
            children: [
              ...?extraActions,
              action ?? const SizedBox(),
            ],
          ),
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
