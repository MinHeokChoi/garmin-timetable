using Toybox.Graphics;
using Toybox.Math;
using Toybox.System;

//! 디자인 시스템.
//!
//! 화면에 쓰이는 색·글자 크기·간격을 전부 여기서 정한다.
//! 뷰는 "무엇을 보여줄지"만 정하고, "어떻게 보일지"는 이 모듈이 책임진다.
//!
//! 전제:
//!   - Forerunner 255 는 260x260 원형 MIP 화면이다.
//!   - MIP 는 백라이트 없이 보는 시간이 대부분이라 대비를 최대로 둔다.
//!   - 손목에서 2초 안에 읽혀야 한다. 정보는 4줄을 넘기지 않는다.
(:glance)
module Theme {

    // --- 색 토큰 ---------------------------------------------------------

    const BG             = 0x000000;   // 순수 검정. MIP 에서 전력도 가장 적게 쓴다
    const TEXT_PRIMARY   = 0xFFFFFF;   // 과목명, 시간
    const TEXT_SECONDARY = 0xAAAAAA;   // 강의실 - 한 단계 낮은 정보

    // 상태별 강조색. 헤더 한 줄에만 쓴다.
    // NEXT 에 기본 파랑(0x0000FF)을 쓰면 MIP 반사광에서 거의 검정으로 보여
    // 밝은 하늘색을 대신 쓴다.
    const ACCENT_NOW  = 0x00FF00;
    const ACCENT_NEXT = 0x55AAFF;
    const ACCENT_PREV = 0xAAAAAA;
    const ACCENT_DONE = 0xFFAA00;

    // --- 타입 스케일 -----------------------------------------------------
    //
    // 역할마다 폰트 "사다리"를 둔다. 앞쪽이 우선이고, 글자가 폭에 안 맞으면
    // 한 단계씩 내려간다. 기기 폰트만 쓸 수 있으므로 크기를 임의로 못 정한다.

    const RAMP_TITLE_1LINE = [ Graphics.FONT_LARGE, Graphics.FONT_MEDIUM ];
    const RAMP_TITLE_2LINE = [ Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY ];
    const RAMP_TIME        = [ Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY ];
    const RAMP_PLACE       = [ Graphics.FONT_SMALL, Graphics.FONT_TINY ];
    const RAMP_MESSAGE     = [ Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL ];

    // 요약(Glance)은 가로 띠라 세로가 좁다. 본체보다 한 단계씩 작게 간다.
    const RAMP_GLANCE_TITLE = [ Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY ];
    const FONT_LABEL       = Graphics.FONT_TINY;

    // --- 레이아웃 --------------------------------------------------------
    //
    // 세로 위치는 화면 높이에 대한 %로 둔다. fr255(260px)와 fr255s(218px)
    // 양쪽에서 같은 비율로 앉는다.

    const LABEL_Y_PCT   = 18;   // 상태 라벨(NOW/NEXT/...)의 세로 중심
    const CONTENT_Y_PCT = 56;   // 본문 묶음의 광학 중심
    const EDGE_INSET    = 12;   // 원 테두리에서 띄울 좌우 여백(px)
    const GAP_TITLE     = 10;   // 과목명 -> 시간
    const GAP_TIME      = 6;    // 시간 -> 강의실

    //! 화면 모양을 한 번만 읽어 둔다. 그리기마다 조회할 이유가 없다.
    var mShape = null;

    function isRound() {
        if (mShape == null) {
            try {
                mShape = System.getDeviceSettings().screenShape;
            } catch (e) {
                mShape = System.SCREEN_SHAPE_ROUND;   // 모르면 좁은 쪽으로 가정한다
            }
        }
        return mShape != System.SCREEN_SHAPE_RECTANGLE;
    }

    //! 세로 위치 y 에 실제로 글자를 놓을 수 있는 가로 폭.
    //!
    //! 사각 화면은 어느 높이에서나 화면 폭이지만, 원형은 위아래로 갈수록 좁아진다.
    //! 반지름 r 인 원에서 중심으로부터 dy 만큼 떨어진 가로선의 길이는
    //! 2 * sqrt(r^2 - dy^2) 이다. 여기서 좌우 여백을 뺀다.
    //!
    //! 반원형·반8각형은 원으로 친다. 실제보다 좁게 잡을 뿐 넘치지는 않는다.
    function usableWidth(dc, y) {
        if (!isRound()) {
            return dc.getWidth() - 2 * EDGE_INSET;
        }
        var r = dc.getWidth() / 2.0;
        var dy = y - dc.getHeight() / 2.0;
        var inner = r * r - dy * dy;
        if (inner <= 0) { return 0; }
        var width = 2 * Math.sqrt(inner) - 2 * EDGE_INSET;
        return (width < 0) ? 0 : width;
    }

    //! 주어진 폭에 들어가는 가장 큰 폰트. 전부 넘치면 사다리의 마지막(가장 작은) 것.
    function fit(dc, text, maxWidth, ramp) {
        for (var i = 0; i < ramp.size(); i++) {
            if (dc.getTextWidthInPixels(text, ramp[i]) <= maxWidth) {
                return ramp[i];
            }
        }
        return ramp[ramp.size() - 1];
    }

    //! 폭에 안 들어가면 뒤를 잘라내고 ".." 를 붙인다.
    //!
    //! 유니코드 말줄임표(U+2026)는 기기 폰트에 없어서 빈 네모로 나온다.
    //! ASCII 점 두 개를 쓴다.
    //!
    //! 폰트 사다리를 다 내려가도 안 들어가는 경우가 있다. 특히 요약(glance)은
    //! 시스템이 왼쪽에 아이콘을 그리는데 dc.getWidth() 는 그 영역까지 포함한
    //! 폭을 돌려줘서, 작은 화면에서는 글자가 오른쪽으로 넘쳐 잘린다.
    //! 잘린 글자보다 말줄임표가 낫다.
    function ellipsize(dc, text, maxWidth, font) {
        if (dc.getTextWidthInPixels(text, font) <= maxWidth) { return text; }
        var n = text.length();
        while (n > 1) {
            n--;
            var cut = text.substring(0, n) + "..";
            if (dc.getTextWidthInPixels(cut, font) <= maxWidth) { return cut; }
        }
        return text.substring(0, 1);
    }

    //! 가운데 정렬로 한 줄 그린다. y 는 글자의 세로 중심.
    function drawLine(dc, y, font, color, text) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, font, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
