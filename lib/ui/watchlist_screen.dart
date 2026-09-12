import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/format.dart';
import '../domain/models.dart';
import '../theme/theme.dart';
import 'common.dart';

// 관심 화면. 셸이 Scaffold 를 갖고 있어 여기서는 본문만 그린다
class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = context.appState;
    final List<Stock> favorites = state.favorites;

    return Column(
      children: <Widget>[
        const _Header(),
        // 빈 상태에서도 헤더와 하단 탭은 그대로 유지된다
        Expanded(child: _body(context, state, favorites)),
      ],
    );
  }

  Widget _body(BuildContext context, AppState state, List<Stock> favorites) {
    if (favorites.isEmpty) {
      return const EmptyState(
        icon: Icons.star_border,
        title: '관심 종목이 없습니다',
        description: '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
      );
    }
    // 오래된 시세라도 빈 화면보다 낫다. 보여줄 값이 하나도 없을 때만 전면 에러
    if (state.blankError) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: '시세를 불러오지 못했습니다',
        description: '네트워크 상태를 확인하고\n다시 시도해 주세요.',
        actionLabel: '다시 시도',
        onAction: state.refreshQuotes,
      );
    }
    return RefreshIndicator(
      onRefresh: state.refreshQuotes,
      child: ListView.builder(
        // 목록이 화면을 못 채워도 당겨서 새로고침이 되게 한다
        physics: const AlwaysScrollableScrollPhysics(),
        // 마지막 행 아래에도 구분선이 있어 separated 대신 행이 직접 그린다
        itemCount: favorites.length,
        itemBuilder: (BuildContext _, int index) {
          final Stock stock = favorites[index];
          return Dismissible(
            // 인덱스를 키로 쓰면 정렬이 바뀔 때 엉뚱한 행이 사라진다
            key: ValueKey<String>(stock.symbol),
            direction: DismissDirection.endToStart,
            background: const _DeleteBackground(),
            onDismissed: (DismissDirection _) {
              state.removeFavorite(stock.symbol);
              // 행은 이미 트리에서 빠져 셸 context 로 띄운다
              showFavoriteToast(context, false);
            },
            child: _WatchRow(stock: stock, quote: state.quoteOf(stock.symbol)),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final AppState state = context.appState;
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return SizedBox(
      height: dimens.rowMinHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        child: Row(
          children: <Widget>[
            Text(
              '관심',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: AppTypography.bold,
              ),
            ),
            const Spacer(),
            const _SortChip(),
            SizedBox(width: dimens.space3),
            // 재조회 중에는 값을 지우지 않고 이 버튼만 스피너로 바꾼다
            if (state.refreshing)
              SizedBox(
                width: dimens.iconSm,
                height: dimens.iconSm,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.textSecondary,
                ),
              )
            else
              InkWell(
                onTap: state.refreshQuotes,
                child: Icon(
                  Icons.refresh,
                  size: dimens.iconSm,
                  color: colors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WatchRow extends StatelessWidget {
  const _WatchRow({required this.stock, required this.quote});

  final Stock stock;
  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final Quote? quote = this.quote;

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: dimens.space4),
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
                // 긴 종목명이 가격 컬럼을 밀면 행끼리 세로 정렬이 깨진다
                Text(
                  stock.name,
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
                    color: colors.textTertiary,
                    fontSize: 11,
                    fontWeight: AppTypography.regular,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: dimens.space3),
          // 종목명과 코드는 시세 없이도 아는 값이라 가격·등락만 스켈레톤으로 둔다
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: quote == null
                ? <Widget>[
                    const SkeletonBox(width: 64, height: 16),
                    SizedBox(height: dimens.space1 / 2),
                    const SkeletonBox(width: 48, height: 12),
                  ]
                : <Widget>[
                    Text(
                      formatNumber(quote.price),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      formatChange(quote.change, quote.changeRate),
                      style: TextStyle(
                        color: priceColor(context, quote.change),
                        fontSize: 11,
                        fontWeight: AppTypography.regular,
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

// 스와이프 삭제는 시안에 없다. 행 높이·구분선을 그대로 두고 경고색 아이콘만 드러낸다
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return Container(
      alignment: Alignment.centerRight,
      color: context.colors.surfaceSunken,
      padding: EdgeInsets.only(right: dimens.space4),
      child: Icon(
        Icons.delete_outline,
        size: dimens.iconMd,
        color: context.colors.feedbackWarning,
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip();

  @override
  Widget build(BuildContext context) {
    final AppState state = context.appState;
    final AppColors colors = context.colors;

    return InkWell(
      onTap: () => _openSortSheet(context, state),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            state.sortKey.label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: AppTypography.regular,
            ),
          ),
          SizedBox(width: context.dimens.space1),
          Icon(
            Icons.arrow_downward,
            size: context.dimens.iconSm,
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }

  void _openSortSheet(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surfaceOverlay,
      // 스크림은 실측값이 Material 기본값과 같아 지정하지 않는다
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) => _SortSheet(state: state),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              dimens.space6,
              dimens.space6,
              dimens.space6,
              dimens.space2,
            ),
            child: Text(
              '정렬',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
          for (final SortKey key in SortKey.values)
            InkWell(
              onTap: () {
                state.setSortKey(key);
                Navigator.pop(context);
              },
              child: SizedBox(
                height: dimens.rowMinHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: dimens.space6),
                  child: Row(
                    children: <Widget>[
                      Text(
                        key.label,
                        style: TextStyle(
                          color: key == state.sortKey
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontSize: 15,
                          fontWeight: AppTypography.regular,
                        ),
                      ),
                      const Spacer(),
                      if (key == state.sortKey)
                        Icon(
                          Icons.check,
                          size: dimens.iconMd,
                          color: colors.textPrimary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          SizedBox(height: dimens.space2),
        ],
      ),
    );
  }
}
