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
        Expanded(
          child: ListView.builder(
            // 마지막 행 아래에도 구분선이 있어 separated 대신 행이 직접 그린다
            itemCount: favorites.length,
            itemBuilder: (BuildContext context, int index) {
              final Stock stock = favorites[index];
              return _WatchRow(
                stock: stock,
                quote: state.quoteOf(stock.symbol),
              );
            },
          ),
        ),
      ],
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
                    fontSize: 16,
                    fontWeight: AppTypography.medium,
                  ),
                ),
                SizedBox(height: dimens.space1),
                Text(
                  stock.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 13,
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
                    SizedBox(height: dimens.space1),
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
