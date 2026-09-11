using Toybox.WatchUi;
using Toybox.Graphics;

//! 요약(Glance) 화면.
//!
//! 시계 화면에서 UP/DOWN 으로 넘겨볼 때 나오는 가로 띠다.
//! 앱을 열지 않고 지금/다음 일정만 확인하는 용도라 탐색 기능이 없다.
//!
//! 요약은 앱 본체와 다른 메모리 공간(64KB)에서 돌아가기 때문에
//! 여기서 쓰는 코드에는 전부 (:glance) 표시가 붙어 있어야 한다.
(:glance)
class TimetableGlanceView extends WatchUi.GlanceView {

    hidden var mBlocks;
    hidden var mConfigured;
    hidden var mBadFormat;

    function initialize() {
        GlanceView.initialize();
        // 요약은 메모리도 시간도 빠듯하다. 파싱은 생성 시 한 번만 한다.
        // 상태(NOW/NEXT)는 매 그리기마다 현재 시각으로 다시 계산하므로
        // 블록만 캐시해도 화면이 낡지 않는다.
        mConfigured = Timetable.isConfigured();
        mBlocks = Schedule.today();
        mBadFormat = mConfigured && mBlocks.size() == 0 && !Timetable.anyParsed();
    }

    function onUpdate(dc) {
        dc.setColor(Theme.TEXT_PRIMARY, Theme.BG);
        dc.clear();

        var blocks = mBlocks;
        var minutes = Schedule.nowMinutes();
        var index = Schedule.anchorIndex(blocks, minutes);

        if (!mConfigured || mBadFormat) {
            dc.setColor(Theme.ACCENT_DONE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0, dc.getHeight() / 2, Graphics.FONT_TINY,
                WatchUi.loadResource(mBadFormat
                    ? Rez.Strings.BadTitleGlance : Rez.Strings.SetupTitleGlance),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        if (index >= blocks.size()) {
            drawDone(dc, blocks.size() == 0);
        } else {
            drawBlock(dc, blocks[index], minutes);
        }
    }

    hidden function drawDone(dc, empty) {
        var message = empty ? "오늘 일정 없음" : "오늘 일정 끝";
        dc.setColor(Theme.ACCENT_DONE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, dc.getHeight() / 2, Graphics.FONT_TINY, message,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawBlock(dc, block, minutes) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        var isNow = Schedule.statusOf(block, minutes) == Schedule.NOW;
        var label = isNow ? "NOW" : "NEXT";
        var labelColor = isNow ? Theme.ACCENT_NOW : Theme.ACCENT_NEXT;

        var title = block[Schedule.TITLE];
        var time = block[Schedule.START] + "-" + block[Schedule.END];
        var place = block[Schedule.PLACE];

        // 요약은 세로가 좁다. 세 줄이 안 들어가면 상태 줄을 버리고 두 줄로 간다.
        var labelH  = dc.getFontHeight(Graphics.FONT_XTINY);
        var detailH = dc.getFontHeight(Graphics.FONT_XTINY);
        // dc.getWidth() 는 시스템 아이콘 영역까지 포함한 폭을 돌려주는데,
        // 글자를 놓을 수 있는 시작점(x=0)은 아이콘 오른쪽이다. 그대로 믿으면
        // 오른쪽으로 넘쳐 잘린다 (218px 기기에서 실제로 잘렸다).
        //
        // 아이콘 폭을 알아낼 API 가 없다. 실측으로 정했다 —
        // 454px 기기 화면을 픽셀 단위로 재 보니 아이콘이 왼쪽 35.5% 를 먹고
        // 글자는 그 뒤부터 시작한다. 즉 실제 한계는 약 64.5% 다.
        // 218px 기기에서 68% 가 잘리고 50% 가 들어갔던 것과도 맞는다.
        // 여유를 조금 남겨 62% 를 쓴다.
        var avail = (w * 62) / 100;
        var titleFont = Theme.fit(dc, title, avail, Theme.RAMP_GLANCE_TITLE);
        title = Theme.ellipsize(dc, title, avail, titleFont);
        var titleH  = dc.getFontHeight(titleFont);

        var threeLines = (labelH + titleH + detailH) <= h;
        var total = threeLines ? (labelH + titleH + detailH) : (titleH + detailH);
        var y = (h - total) / 2;
        if (y < 0) { y = 0; }

        if (threeLines) {
            dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0, y, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_LEFT);
            y += labelH;
        }

        // 두 줄로 줄인 경우엔 과목명 자체를 상태 색으로 칠해 지금/다음을 구분한다.
        dc.setColor(threeLines ? Theme.TEXT_PRIMARY : labelColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, y, titleFont, title, Graphics.TEXT_JUSTIFY_LEFT);
        y += titleH;

        // 시간과 강의실이 같이 안 들어가면 강의실을 버린다.
        // 시각이 잘려 "09:48-10:3.." 이 되면 언제 끝나는지를 알 수 없다.
        // 강의실은 앱을 열면 보이지만, 끝나는 시각은 요약에서 봐야 의미가 있다.
        var detail = time;
        if (!place.equals("")) {
            var both = time + "  " + place;
            if (dc.getTextWidthInPixels(both, Graphics.FONT_XTINY) <= avail) {
                detail = both;
            }
        }
        detail = Theme.ellipsize(dc, detail, avail, Graphics.FONT_XTINY);

        dc.setColor(Theme.TEXT_SECONDARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, y, Graphics.FONT_XTINY, detail, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
