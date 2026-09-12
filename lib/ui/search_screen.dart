import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/models.dart';
import '../theme/theme.dart';
import 'common.dart';
import 'detail_screen.dart';

// 검색 화면. 셸이 Scaffold 를 갖고 있어 여기서는 본문만 그린다.
// 검색어·결과·로딩은 이 화면 밖에서 쓸 일이 없어 전역 상태로 올리지 않는다
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Stock> _results = <Stock>[];
  bool _loading = false;
  bool _failed = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // 한 글자마다 요청하면 '삼성전자' 네 글자에 네 번 나간다
  void _searchDebounced(String query) {
    _debounce?.cancel();
    // 지우기·전송은 기다릴 이유가 없다
    if (query.isEmpty) {
      _search(query);
      return;
    }
    setState(() => _failed = false);
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = <Stock>[];
        _loading = false;
        _failed = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final List<Stock> found = await context.appState.repo.search(query);
      if (!mounted || query != _controller.text.trim()) return;
      setState(() {
        _results = found;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || query != _controller.text.trim()) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _SearchField(
          controller: _controller,
          onChanged: _searchDebounced,
          onSubmitted: _search,
        ),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final String query = _controller.text.trim();
    if (query.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: '종목을 검색해 보세요',
        description: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
      );
    }
    // 디바운스 대기 중에는 결과가 확정되지 않았다.
    // 보여줄 이전 결과가 있으면 그대로 두고, 없을 때만 스피너로 채운다
    final bool pending = _loading || (_debounce?.isActive ?? false);
    if (pending && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: '검색에 실패했습니다',
        description: '네트워크 상태를 확인하고\n다시 시도해 주세요.',
        actionLabel: '다시 시도',
        onAction: () => _search(query),
      );
    }
    if (_results.isEmpty && !pending) {
      return EmptyState(
        icon: Icons.search_off,
        title: '검색 결과가 없습니다',
        // 긴 검색어가 안내 문구를 밀어내지 않게 잘라서 넣는다
        description: "'${_shorten(query)}'와\n일치하는 검색 결과를 찾지 못했습니다.",
      );
    }
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _results.length,
      itemBuilder: (BuildContext context, int index) =>
          _ResultRow(stock: _results[index], query: query),
    );
  }

  static String _shorten(String query) =>
      query.length > 20 ? '${query.substring(0, 20)}…' : query;
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  // 전송은 디바운스를 건너뛴다
  final ValueChanged<String> onSubmitted;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space2,
      ),
      child: Container(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: dimens.space3),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(dimens.radiusMd),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.search, size: dimens.iconMd, color: colors.textTertiary),
            SizedBox(width: dimens.space2),
            Expanded(
              child: TextField(
                controller: widget.controller,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: AppTypography.regular,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '종목명 또는 종목코드',
                  hintStyle: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 15,
                    fontWeight: AppTypography.regular,
                  ),
                ),
                onChanged: (String value) {
                  setState(() {}); // 지우기 버튼 상태
                  widget.onChanged(value.trim());
                },
                onSubmitted: (String value) => widget.onSubmitted(value.trim()),
              ),
            ),
            SizedBox(width: dimens.space2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.controller.clear();
                setState(() {});
                widget.onChanged('');
              },
              child: Icon(
                Icons.close,
                size: dimens.iconMd,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.stock, required this.query});

  final Stock stock;
  final String query;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.appState;
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext _) => DetailScreen(stock: stock),
        ),
      ),
      child: Container(
        height: 60,
        // 별 아이콘이 자체 여백을 갖고 있어 우측 패딩은 그만큼 뺀다
        padding: EdgeInsets.only(left: dimens.space4, right: dimens.space2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.borderSubtle,
              width: dimens.borderHairline,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text.rich(
                    TextSpan(
                      children: highlightSpans(stock.name, query, colors),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                  Text(
                    stock.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: AppTypography.regular,
                    ),
                  ),
                ],
              ),
            ),
            StarButton(
              active: state.isFavorite(stock.symbol),
              onTap: () =>
                  showFavoriteToast(context, state.toggleFavorite(stock)),
            ),
          ],
        ),
      ),
    );
  }
}
