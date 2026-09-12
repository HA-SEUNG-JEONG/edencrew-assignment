import 'package:flutter/material.dart';

import 'app_state.dart';
import 'data/stock_repository.dart';
import 'theme/theme.dart';
import 'ui/search_screen.dart';
import 'ui/watchlist_screen.dart';

void main() {
  runApp(const EdencrewAssignmentApp());
}

class EdencrewAssignmentApp extends StatefulWidget {
  const EdencrewAssignmentApp({super.key, this.repository});

  // 테스트에서 네트워크를 끊기 위한 주입구
  final StockRepository? repository;

  @override
  State<EdencrewAssignmentApp> createState() => _EdencrewAssignmentAppState();
}

class _EdencrewAssignmentAppState extends State<EdencrewAssignmentApp> {
  late final AppState _state = AppState(widget.repository ?? StockRepository());

  @override
  void initState() {
    super.initState();
    // 필드 초기화 cascade 는 Future 를 버리므로 여기서 호출한다
    _state.refreshQuotes();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: '이든크루 평가 과제',
        theme: AppTheme.dark,
        home: const _HomeShell(),
      ),
    );
  }
}

// 앱에서 유일한 Scaffold. 화면마다 두면 ScaffoldMessenger 가 토스트를 중복으로 띄운다
class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  void _select(int index) {
    // 검색 탭을 벗어나도 키보드가 남는다
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        // 탭을 오가도 검색어와 스크롤 위치를 잃지 않는다
        child: IndexedStack(
          index: _index,
          children: const <Widget>[WatchlistScreen(), SearchScreen()],
        ),
      ),
      // body 안에 넣으면 floating 토스트가 탭을 덮는다
      bottomNavigationBar: _BottomNav(index: _index, onSelect: _select),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      color: colors.surfaceRaised,
      // Scaffold 는 커스텀 bottomNavigationBar 에 안전영역 패딩을 넣어주지 않는다
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Divider(
              height: dimens.borderHairline,
              thickness: dimens.borderHairline,
              color: colors.borderSubtle,
            ),
            Row(
              children: <Widget>[
                _NavItem(
                  label: '관심',
                  selected: index == 0,
                  onTap: () => onSelect(0),
                ),
                _NavItem(
                  label: '검색',
                  selected: index == 1,
                  onTap: () => onSelect(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 시안의 탭은 아이콘 없이 라벨만 두고 선택 여부를 색 대비로만 나타낸다
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color color = selected ? colors.navActive : colors.navInactive;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        // 라벨만 남으면 시안 높이(약 31)가 터치 영역에 못 미친다
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: AppTypography.regular,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
