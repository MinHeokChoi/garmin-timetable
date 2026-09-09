using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Timer;

//! 한 번에 일정 하나를 보여준다.
//! 색·글자 크기·간격은 전부 Theme 이 정하고, 여기서는 무엇을 보여줄지만 정한다.
class TimetableView extends WatchUi.View {

    hidden var mBlocks;
    hidden var mIndex;      // 0 .. mBlocks.size()  (마지막 값 = 종료 화면)
    hidden var mConfigured;
    hidden var mShowQr;     // 온보딩 화면에서 QR 을 보고 있는가
    hidden var mTimer;

    function initialize() {
        View.initialize();
        mBlocks = [];
        mConfigured = false;
        mShowQr = false;
        mIndex = 0;
    }

    // --- 화면 수명주기 ---------------------------------------------------

    function onShow() {
        // 앱을 열 때마다 시간표를 다시 읽고 현재 시각 기준으로 맞춘다.
        reload();

        // 화면을 켜 둔 채로 수업 경계를 넘어가도 NOW/NEXT 가 어긋나지 않게.
        mTimer = new Timer.Timer();
        mTimer.start(method(:onTick), 30000, true);
    }

    function onHide() {
        if (mTimer != null) {
            mTimer.stop();
            mTimer = null;
        }
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    // --- 버튼 동작 -------------------------------------------------------

    function next() {
        if (!mConfigured) { mShowQr = true; WatchUi.requestUpdate(); return; }
        if (mIndex < mBlocks.size()) {
            mIndex++;
            WatchUi.requestUpdate();
        }
    }

    function prev() {
        if (!mConfigured) { mShowQr = false; WatchUi.requestUpdate(); return; }
        if (mIndex > 0) {
            mIndex--;
            WatchUi.requestUpdate();
        }
    }

    //! 시간표를 다시 읽는다. 설정이 바뀌었을 때도 호출된다.
    //!
    //! 파싱과 설정 조회는 여기서 한 번만 한다. onUpdate 에서 매번 하면
    //! 30초마다(그리고 버튼을 누를 때마다) 속성 5개를 다시 읽고 다시 파싱하게 된다.
    function reload() {
        mConfigured = Timetable.isConfigured();
        mBlocks = Schedule.today();
        mShowQr = false;
        reset();
    }

    //! 지금 시각 위치로 복귀.
    function reset() {
        mIndex = Schedule.anchorIndex(mBlocks, Schedule.nowMinutes());
        WatchUi.requestUpdate();
    }

    // --- 그리기 ----------------------------------------------------------

    function onUpdate(dc) {
        dc.setColor(Theme.TEXT_PRIMARY, Theme.BG);
        dc.clear();

        if (!mConfigured) {
            if (mShowQr) { Qr.draw(dc); } else { drawSetup(dc); }
        } else if (mIndex >= mBlocks.size()) {
            drawDone(dc);
        } else {
            drawBlock(dc, mBlocks[mIndex]);
        }
    }

    //! 시간표가 한 번도 입력되지 않았을 때.
    //! 앱을 처음 설치한 사용자가 보게 되는 화면이라, 어디서 입력하는지를 알려준다.
    hidden function drawSetup(dc) {
        var h = dc.getHeight();
        var cy = (h * Theme.CONTENT_Y_PCT) / 100;

        drawLabel(dc, "SETUP", Theme.ACCENT_DONE);

        var title = WatchUi.loadResource(Rez.Strings.SetupTitle);
        var l1 = WatchUi.loadResource(Rez.Strings.SetupHint);
        var l2 = WatchUi.loadResource(Rez.Strings.SetupHint2);

        var titleFont = Theme.fit(dc, title, Theme.usableWidth(dc, cy - h / 8), Theme.RAMP_MESSAGE);
        var hintFont = Theme.fit(dc, l1, Theme.usableWidth(dc, cy + h / 8), Theme.RAMP_PLACE);
        var titleH = dc.getFontHeight(titleFont);
        var hintH = dc.getFontHeight(hintFont);

        var qr = WatchUi.loadResource(Rez.Strings.SetupQr);
        var total = titleH + Theme.GAP_TITLE + hintH * 3 + Theme.GAP_TIME;
        var y = cy - total / 2;

        Theme.drawLine(dc, y + titleH / 2, titleFont, Theme.TEXT_PRIMARY, title);
        y += titleH + Theme.GAP_TITLE;
        Theme.drawLine(dc, y + hintH / 2, hintFont, Theme.TEXT_SECONDARY, l1);
        y += hintH;
        Theme.drawLine(dc, y + hintH / 2, hintFont, Theme.TEXT_SECONDARY, l2);
        y += hintH + Theme.GAP_TIME;
        Theme.drawLine(dc, y + hintH / 2, hintFont, Theme.ACCENT_NEXT, qr);
    }

    //! 오늘 볼 일정이 더 없을 때.
    hidden function drawDone(dc) {
        var h = dc.getHeight();
        var cy = (h * Theme.CONTENT_Y_PCT) / 100;
        var message = (mBlocks.size() == 0) ? "오늘 일정 없음" : "오늘 일정 끝";

        drawLabel(dc, "DONE", Theme.ACCENT_DONE);
        Theme.drawLine(dc, cy,
            Theme.fit(dc, message, Theme.usableWidth(dc, cy), Theme.RAMP_MESSAGE),
            Theme.TEXT_PRIMARY, message);
    }

    //! 일정 하나. 과목명 / 시간 / 강의실을 세로로 쌓아 광학 중심에 맞춘다.
    hidden function drawBlock(dc, block) {
        var h = dc.getHeight();
        var cy = (h * Theme.CONTENT_Y_PCT) / 100;

        var status = headerLabel();
        drawLabel(dc, status[0], status[1]);

        // 1) 각 요소가 놓일 대략적인 높이에서의 가용 폭으로 폰트를 고른다.
        //    원형 화면이라 위아래로 갈수록 쓸 수 있는 폭이 줄어든다.
        var title = block[Schedule.TITLE];
        var titleLines = splitTitle(dc, title, Theme.usableWidth(dc, cy - h / 10));
        var titleFont = titleLines.size() == 1
            ? Theme.fit(dc, title, Theme.usableWidth(dc, cy - h / 10), Theme.RAMP_TITLE_1LINE)
            : Theme.fit(dc, widest(dc, titleLines), Theme.usableWidth(dc, cy - h / 10), Theme.RAMP_TITLE_2LINE);

        var time = block[Schedule.START] + " - " + block[Schedule.END];
        var timeFont = Theme.fit(dc, time, Theme.usableWidth(dc, cy + h / 12), Theme.RAMP_TIME);

        var place = block[Schedule.PLACE];
        var hasPlace = !place.equals("");
        var placeFont = hasPlace
            ? Theme.fit(dc, place, Theme.usableWidth(dc, cy + h / 5), Theme.RAMP_PLACE)
            : Theme.FONT_LABEL;

        // 2) 실제 높이를 재서 묶음 전체를 cy 에 세로 중앙 정렬한다.
        var titleLineH = dc.getFontHeight(titleFont);
        var timeH = dc.getFontHeight(timeFont);
        var placeH = hasPlace ? dc.getFontHeight(placeFont) : 0;

        var total = titleLineH * titleLines.size() + Theme.GAP_TITLE + timeH;
        if (hasPlace) { total += Theme.GAP_TIME + placeH; }

        // 3) 위에서부터 차례로 그린다.
        var y = cy - total / 2;
        for (var i = 0; i < titleLines.size(); i++) {
            Theme.drawLine(dc, y + titleLineH / 2, titleFont, Theme.TEXT_PRIMARY, titleLines[i]);
            y += titleLineH;
        }
        y += Theme.GAP_TITLE;
        Theme.drawLine(dc, y + timeH / 2, timeFont, Theme.TEXT_PRIMARY, time);
        y += timeH;
        if (hasPlace) {
            y += Theme.GAP_TIME;
            Theme.drawLine(dc, y + placeH / 2, placeFont, Theme.TEXT_SECONDARY, place);
        }
    }

    hidden function drawLabel(dc, text, color) {
        Theme.drawLine(dc, (dc.getHeight() * Theme.LABEL_Y_PCT) / 100,
            Theme.FONT_LABEL, color, text);
    }

    //! 과목명이 한 줄에 안 들어가면 두 줄로 접는다.
    //!
    //! 접는 자리는 띄어쓰기로 정한다. 한글 합성어는 사전 없이 단어 경계를 알 수
    //! 없으므로, 어디서 끊을지는 이름을 적는 사람이 공백으로 알려준다.
    //!   "데이터베이스 시스템"  -> 데이터베이스 / 시스템
    //!   "Operating Systems"   -> Operating / Systems
    //! 공백이 없으면 글자 수 절반에서 끊는다. 보기 싫으면 공백을 넣으면 된다.
    hidden function splitTitle(dc, title, maxWidth) {
        if (dc.getTextWidthInPixels(title, Graphics.FONT_MEDIUM) <= maxWidth) {
            return [ title ];
        }

        var at = spaceNearestMiddle(title);
        if (at != null) {
            // 공백 자체는 버린다
            return [ title.substring(0, at), title.substring(at + 1, title.length()) ];
        }

        var half = (title.length() + 1) / 2;
        return [ title.substring(0, half), title.substring(half, title.length()) ];
    }

    //! 가운데에 가장 가까운 공백의 위치. 없으면 null.
    //! 가운데를 기준으로 삼아야 두 줄 길이가 비슷해진다.
    hidden function spaceNearestMiddle(title) {
        var len = title.length();
        var middle = len / 2;
        var best = null;
        var bestGap = len;
        for (var i = 1; i < len - 1; i++) {
            if (!title.substring(i, i + 1).equals(" ")) { continue; }
            var gap = (i > middle) ? (i - middle) : (middle - i);
            if (gap < bestGap) {
                bestGap = gap;
                best = i;
            }
        }
        return best;
    }

    hidden function widest(dc, lines) {
        var best = lines[0];
        for (var i = 1; i < lines.size(); i++) {
            if (dc.getTextWidthInPixels(lines[i], Graphics.FONT_MEDIUM)
                > dc.getTextWidthInPixels(best, Graphics.FONT_MEDIUM)) {
                best = lines[i];
            }
        }
        return best;
    }

    //! 지금 보고 있는 일정이 현재 시각 대비 어디쯤인지 -> [문구, 색].
    hidden function headerLabel() {
        var minutes = Schedule.nowMinutes();
        var status = Schedule.statusOf(mBlocks[mIndex], minutes);

        if (status == Schedule.NOW) {
            return [ "NOW", Theme.ACCENT_NOW ];
        }

        // anchor == 이미 지나간 일정의 개수
        var anchor = Schedule.anchorIndex(mBlocks, minutes);

        if (status == Schedule.PAST) {
            var back = (anchor - 1) - mIndex;
            return [ (back == 0) ? "PREV" : "PREV -" + back, Theme.ACCENT_PREV ];
        }

        var hasNow = (anchor < mBlocks.size())
                  && (Schedule.statusOf(mBlocks[anchor], minutes) == Schedule.NOW);
        var firstFuture = hasNow ? anchor + 1 : anchor;
        var ahead = mIndex - firstFuture;
        return [ (ahead == 0) ? "NEXT" : "NEXT +" + ahead, Theme.ACCENT_NEXT ];
    }
}
