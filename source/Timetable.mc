using Toybox.Application;

//! 앱 설정(Garmin Connect)에 적힌 시간표 문자열을 블록 배열로 바꾼다.
//!
//! 형식: "09:00-09:50,근로,문헌관;10:00-11:50,데이터베이스시스템,T0503"
//!   항목 구분 ';'  /  필드 구분 ','  /  시간 구분 '-' 또는 '~'
//!   강의실은 생략 가능
//!
//! 사용자가 폰에서 직접 적거나 붙여넣는 값이다. 형식을 하나로 강요하면
//! 안 되고, 하나 틀렸다고 전체가 죽어도 안 된다. 그래서
//!   - "9:00" "09:00" "0900" 을 모두 받고 "09:00" 으로 통일한다
//!   - 앞뒤 공백을 정리한다
//!   - 못 읽는 항목은 조용히 건너뛰고 나머지는 살린다
(:glance)
module Timetable {

    // Gregorian day_of_week 순서: 1=일요일 ... 7=토요일
    const KEYS = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ];

    //! Gregorian day_of_week (1=일요일 ... 7=토요일) 에 해당하는 설정 키.
    function keyFor(dayOfWeek) {
        if (dayOfWeek >= 1 && dayOfWeek <= 7) {
            return KEYS[dayOfWeek - 1];
        }
        return null;
    }

    //! 해당 요일의 블록 배열. 설정이 없거나 못 읽으면 빈 배열.
    //!
    //! "한 번에 입력" 칸이 채워져 있으면 그쪽이 이긴다. 폰에서 요일마다
    //! 붙여넣는 게 번거로워서 한 칸으로 끝낼 수 있게 둔 경로다.
    function forDay(dayOfWeek) {
        var week = readProperty("Week");
        if (week != null) {
            return parseWeek(week, dayOfWeek);
        }
        var text = rawFor(dayOfWeek);
        return (text == null) ? [] : parseDay(text);
    }

    //! "월:09:00-09:50,근로|화:11:00-12:50,생물학" 에서 해당 요일만 꺼낸다.
    //! 요일 표시는 한글 한 글자와 영문 세 글자를 모두 받는다.
    function parseWeek(text, dayOfWeek) {
        var chunks = splitOn(text, "|");
        for (var i = 0; i < chunks.size(); i++) {
            var c = trim(chunks[i]);
            var at = c.find(":");
            if (at == null) { continue; }
            if (dayIndexOf(trim(c.substring(0, at))) != dayOfWeek) { continue; }
            return parseDay(c.substring(at + 1, c.length()));
        }
        return [];
    }

    //! 요일 표시 -> Gregorian day_of_week (1=일 ... 7=토). 못 읽으면 null.
    function dayIndexOf(token) {
        var ko = [ "일", "월", "화", "수", "목", "금", "토" ];
        for (var i = 0; i < ko.size(); i++) {
            if (token.equals(ko[i])) { return i + 1; }
        }
        for (var j = 0; j < KEYS.size(); j++) {
            if (token.equals(KEYS[j])) { return j + 1; }
        }
        return null;
    }

    //! 어느 요일이든 시간표가 하나라도 적혀 있으면 true.
    //! 하나도 없으면 앱이 "설정에서 입력하세요" 안내를 띄운다.
    function isConfigured() {
        if (readProperty("Week") != null) { return true; }
        for (var i = 0; i < KEYS.size(); i++) {
            if (readProperty(KEYS[i]) != null) { return true; }
        }
        return false;
    }

    // --- 내부 ------------------------------------------------------------

    function rawFor(dayOfWeek) {
        var key = keyFor(dayOfWeek);
        return (key == null) ? null : readProperty(key);
    }

    //! 설정값을 읽어 빈 문자열이면 null 로 정규화한다.
    function readProperty(key) {
        var v = null;
        try {
            v = Application.Properties.getValue(key);
        } catch (e) {
            return null;
        }
        if (v == null) { return null; }
        var s = trim(v.toString());
        return (s.length() == 0) ? null : s;
    }

    function parseDay(text) {
        var out = [];
        var items = splitOn(text, ";");
        for (var i = 0; i < items.size(); i++) {
            var f = splitOn(items[i], ",");
            if (f.size() < 2) { continue; }

            var t = splitOn(f[0], "-");
            if (t.size() != 2) { t = splitOn(f[0], "~"); }
            if (t.size() != 2) { continue; }

            var start = normalizeTime(t[0]);
            var end = normalizeTime(t[1]);
            if (start == null || end == null) { continue; }

            var title = trim(f[1]);
            if (title.length() == 0) { continue; }

            // 종료가 시작보다 빠르면 버린다.
            // 자정을 넘는 일정은 이 앱의 모델(하루 = 0~1439분)에 안 맞고,
            // "10:00-09:50" 같은 오타도 여기서 걸린다. 그대로 두면
            // 영영 PAST 로 잡혀서 화면에서 조용히 사라진 것처럼 보인다.
            if (minutesOf(end) <= minutesOf(start)) { continue; }

            var place = (f.size() > 2) ? trim(f[2]) : "";
            out.add([ start, end, title, place ]);
        }
        return sortByStart(out);
    }

    //! "HH:MM" -> 분.
    function minutesOf(hhmm) {
        return hhmm.substring(0, 2).toNumber() * 60 + hhmm.substring(3, 5).toNumber();
    }

    //! 시작 시각 순으로 정렬한다.
    //!
    //! 이후 계산(anchorIndex, PREV/NEXT 카운트)이 전부 "정렬돼 있다"를 전제한다.
    //! 사용자가 순서를 뒤섞어 적을 수 있으므로 여기서 한 번 맞춰 둔다.
    //! 하루 항목 수가 열 몇 개라 삽입 정렬로 충분하다.
    function sortByStart(blocks) {
        for (var i = 1; i < blocks.size(); i++) {
            var cur = blocks[i];
            var key = minutesOf(cur[0]);
            var j = i - 1;
            while (j >= 0 && minutesOf(blocks[j][0]) > key) {
                blocks[j + 1] = blocks[j];
                j--;
            }
            blocks[j + 1] = cur;
        }
        return blocks;
    }

    //! "9:00", "09:00", "0900", " 9 : 00 " 을 전부 "09:00" 으로. 못 읽으면 null.
    function normalizeTime(raw) {
        var t = trim(raw);
        var h = null;
        var m = null;

        var c = t.find(":");
        if (c != null) {
            h = trim(t.substring(0, c)).toNumber();
            m = trim(t.substring(c + 1, t.length())).toNumber();
        } else if (t.length() == 4) {
            h = t.substring(0, 2).toNumber();
            m = t.substring(2, 4).toNumber();
        } else if (t.length() == 3) {
            h = t.substring(0, 1).toNumber();
            m = t.substring(1, 3).toNumber();
        }

        if (h == null || m == null) { return null; }
        if (h < 0 || h > 23 || m < 0 || m > 59) { return null; }
        return pad2(h) + ":" + pad2(m);
    }

    function pad2(n) {
        return (n < 10) ? ("0" + n.toString()) : n.toString();
    }

    function splitOn(text, sep) {
        var out = [];
        var rest = text;
        var i = rest.find(sep);
        while (i != null) {
            out.add(rest.substring(0, i));
            rest = rest.substring(i + sep.length(), rest.length());
            i = rest.find(sep);
        }
        out.add(rest);
        return out;
    }

    function trim(s) {
        var a = 0;
        var b = s.length();
        while (a < b && s.substring(a, a + 1).equals(" ")) { a++; }
        while (b > a && s.substring(b - 1, b).equals(" ")) { b--; }
        return s.substring(a, b);
    }
}
