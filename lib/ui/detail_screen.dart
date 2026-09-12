import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/format.dart';
import '../domain/models.dart';
import '../theme/theme.dart';
import 'candle_chart.dart';
import 'common.dart';

// 종목상세. 셸 위에 push 되는 라우트라 자체 Scaffold 를 갖는다.
// 검색·관심에서 이미 종목명과 시장을 받았으므로 fetchMeta 는 부르지 않는다
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.stock});

  final Stock stock;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Period _period = Period.month1;
  List<DailyPrice> _prices = <DailyPrice>[];
  bool _loading = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // initState 에서는 InheritedWidget 을 읽을 수 없다
    if (_started) return;
    _started = true;
    final AppState state = context.appState;
    // 관심 목록에 없는 종목으로 들어오면 시세가 아직 없다
    state.fetchQuote(widget.stock.symbol);
    _load(state);
  }

  void _selectPeriod(Period period) {
    if (period == _period) return;
    setState(() => _period = period);
    // 이미 받은 페이지는 저장소가 캐시하고 있어 되돌아오면 즉시 그려진다
    _load(context.appState);
  }

  Future<void> _load(AppState state) async {
    final Period period = _period;
    setState(() => _loading = true);
    try {
      final List<DailyPrice> prices = await state.repo.dailyPrices(
        widget.stock.symbol,
        period.pages,
      );
      if (!mounted || period != _period) return;
      setState(() {
        _prices = prices;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || period != _period) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.appState;
    final Quote? quote = state.quoteOf(widget.stock.symbol);

    return Scaffold(
      body: SafeArea(
        child: ListView.builder(
          // 마지막 행 아래 여백. 시안의 본문 하단 패딩이다
          padding: EdgeInsets.only(bottom: context.dimens.space4),
          // 머리 블록 전체가 0번 항목, 그 뒤가 일별 시세 행
          itemCount: _prices.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index > 0) return _DailyRow(price: _prices[index - 1]);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _DetailHeader(stock: widget.stock, state: state),
                _PriceBlock(quote: quote),
                _PeriodTabs(selected: _period, onSelect: _selectPeriod),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.dimens.space4,
                    vertical: context.dimens.space6,
                  ),
                  // 로딩 중에도 높이를 유지해 아래 요소가 튀지 않게 한다
                  child: _loading
                      ? const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : CandleChart(prices: _prices),
                ),
                _SummaryGrid(quote: quote),
                _DailyHeader(loading: _loading),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.stock, required this.state});

  final Stock stock;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      height: 54,
      // 좌우 아이콘이 모두 자체 여백을 갖고 있어 그만큼 뺀다
      padding: EdgeInsets.only(left: dimens.space1, right: dimens.space2),
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            // 시안의 아이콘 박스는 20 이지만 탭 영역은 44 로 남긴다.
            // 좌측 패딩 4 + 44 = 48 이 시안의 종목명 시작점과 맞는다
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              Icons.arrow_back,
              size: dimens.iconMd,
              color: colors.textSecondary,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 1,
              children: <Widget>[
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
            size: 22,
            onTap: () =>
                showFavoriteToast(context, state.toggleFavorite(stock)),
          ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.quote});

  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final Quote? quote = this.quote;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        dimens.space4,
        14,
        dimens.space4,
        dimens.space4,
      ),
      child: quote == null
          ? Row(
              children: const <Widget>[
                SkeletonBox(width: 150, height: 30),
                SizedBox(width: 8),
                SkeletonBox(width: 110, height: 20),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: dimens.space2,
              children: <Widget>[
                Text(
                  formatNumber(quote.price),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 30,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                // 시안은 화살표까지 한 덩어리다. 방향은 화살표가 말해주므로
                // 숫자에는 부호를 붙이지 않는다
                Text(
                  '${_arrowOf(quote.change)}'
                  '${formatNumber(quote.change.abs())} '
                  '(${formatRate(quote.changeRate)})',
                  style: TextStyle(
                    color: priceColor(context, quote.change),
                    fontSize: 15,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ],
            ),
    );
  }
}

String _arrowOf(int change) => change > 0
    ? '\u25b2 '
    : change < 0
    ? '\u25bc '
    : '';

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.quote});

  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final Quote? quote = this.quote;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dimens.space4),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _SummaryCard(
                label: '시가',
                value: quote == null ? null : formatNumber(quote.open),
              ),
              SizedBox(width: dimens.space2),
              _SummaryCard(
                label: '고가',
                value: quote == null ? null : formatNumber(quote.high),
              ),
              SizedBox(width: dimens.space2),
              _SummaryCard(
                label: '저가',
                value: quote == null ? null : formatNumber(quote.low),
              ),
            ],
          ),
          SizedBox(height: dimens.space2),
          Row(
            children: <Widget>[
              _SummaryCard(
                label: '거래량',
                value: quote == null ? null : formatVolume(quote.volume),
              ),
              SizedBox(width: dimens.space2),
              _SummaryCard(
                label: '시가총액',
                value: quote == null ? null : formatMarketCap(quote.marketCap),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final String? value = this.value;

    return Expanded(
      child: Container(
        height: 55,
        // 시안 실측 10. space 토큰에 10 이 없다
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(dimens.radiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: AppTypography.regular,
              ),
            ),
            // 시안 실측 3. space 토큰에 3 이 없다
            const SizedBox(height: 3),
            if (value == null)
              const SkeletonBox(width: 72, height: 16)
            else
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: AppTypography.medium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyHeader extends StatelessWidget {
  const _DailyHeader({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
            dimens.space4,
            dimens.space6,
            dimens.space4,
            dimens.space1,
          ),
          child: Row(
            children: <Widget>[
              Text(
                '일별 시세',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: AppTypography.bold,
                ),
              ),
              if (loading) ...<Widget>[
                SizedBox(width: dimens.space2),
                SizedBox(
                  width: dimens.space3,
                  height: dimens.space3,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        DailyTableRow(
          cells: const <String>['날짜', '종가', '등락', '거래량'],
          color: colors.textSecondary,
          // 구분선은 데이터 행 위에만 온다
          showBorder: false,
        ),
      ],
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({required this.price});

  final DailyPrice price;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return DailyTableRow(
      cells: <String>[
        formatMonthDay(price.date),
        formatNumber(price.close),
        formatSigned(price.change),
        // 표는 시안이 전체 자릿수를 쓴다. 축약은 요약 카드 전용
        formatNumber(price.volume),
      ],
      color: colors.textSecondary,
      closeColor: colors.textPrimary,
      changeColor: priceColor(context, price.change),
    );
  }
}

// 표 헤더와 본문이 같은 규칙으로 컬럼을 나눠야 해서 한 위젯으로 둔다.
// 날짜 칸은 시안대로 글자 폭을 쓰므로 헤더('날짜')와 본문('09.11')의 폭이
// 달라 가운데 두 칸의 우측 끝이 약 4 어긋난다 — 시안도 같은 구조다
class DailyTableRow extends StatelessWidget {
  const DailyTableRow({
    super.key,
    required this.cells,
    required this.color,
    this.closeColor,
    this.changeColor,
    this.showBorder = true,
  });

  final List<String> cells;
  final Color color;
  final Color? closeColor;
  final Color? changeColor;
  final bool showBorder;

  Widget _cell(int i, Color color, Alignment alignment) => Align(
    alignment: alignment,
    child: Text(
      cells[i],
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: AppTypography.regular,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final List<Color> colorsOf = <Color>[
      color,
      closeColor ?? color,
      changeColor ?? color,
      color,
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dimens.space4),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  top: BorderSide(
                    color: colors.borderSubtle,
                    width: dimens.borderHairline,
                  ),
                )
              : null,
        ),
        child: Row(
          spacing: dimens.space2,
          children: <Widget>[
            // 날짜는 글자 폭만 쓰고, 나머지 세 칸이 남은 폭을 균등히 나눈다
            for (int i = 0; i < cells.length; i++)
              if (i == 0)
                _cell(i, colorsOf[i], Alignment.centerLeft)
              else
                Expanded(child: _cell(i, colorsOf[i], Alignment.centerRight)),
          ],
        ),
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.selected, required this.onSelect});

  final Period selected;
  final ValueChanged<Period> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dimens.space4),
      child: Row(
        spacing: dimens.space1,
        children: <Widget>[
          for (final Period period in Period.values)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(dimens.radiusMd),
                onTap: () => onSelect(period),
                child: Container(
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: period == selected ? colors.accentBg : null,
                    borderRadius: BorderRadius.circular(dimens.radiusMd),
                  ),
                  child: Text(
                    period.label,
                    style: TextStyle(
                      color: period == selected
                          ? colors.accentDefault
                          : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: AppTypography.regular,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
