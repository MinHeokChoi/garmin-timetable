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

    // 요일 표시. KEYS 와 같은 순서로 늘어놓는다.
    //
    // 설정 힌트와 웹 도구는 영문 세 글자만 내보내지만, 그것만 받으면 안 된다.
    // 챗봇은 프롬프트를 무시하고 제 나라 말로 요일을 적어 줄 때가 있고,
    // 손으로 적는 사람은 힌트가 아니라 자기 언어로 적는다. 읽히지 않으면
    // 화면에는 "시간표 없음" 만 뜨고, 무엇이 틀렸는지 알 길이 없다.
    //
    // 비교는 소문자로 한다. 세 글자 이상은 앞부분만 맞아도 받는다 —
    // "lun" 하나로 lundi 와 lunes 를 모두 읽는다. 두 글자(독일어 Mo/Di)는
    // 흔한 낱말과 부딪히므로 정확히 맞을 때만 받는다.
    const MARKERS = [
        [ "일", "sun", "日", "周日", "週日", "星期日", "周天", "星期天", "週天", "dim", "dom", "son", "so", "nie", "nd" ],
        [ "월", "mon", "月", "周一", "週一", "星期一", "lun", "mo", "pon" ],
        [ "화", "tue", "火", "周二", "週二", "星期二", "mar", "die", "di", "wto", "wt" ],
        // "Śro" "Śr" 도 넣는다 — toLower() 는 ASCII 만 내리므로 첫 글자가
        // 다중바이트인 "Środa" 는 소문자로 안 바뀐다.
        [ "수", "wed", "水", "周三", "週三", "星期三", "mer", "mié", "mie", "mit", "mi", "śro", "Śro", "sro", "śr", "Śr", "sr" ],
        [ "목", "thu", "木", "周四", "週四", "星期四", "jeu", "jue", "don", "do", "gio", "czw" ],
        [ "금", "fri", "金", "周五", "週五", "星期五", "ven", "vie", "fre", "fr", "pią", "pia", "pt" ],
        [ "토", "sat", "土", "周六", "週六", "星期六", "sam", "sáb", "sab", "sa", "sob" ]
    ];

    //! Gregorian day_of_week (1=일요일 ... 7=토요일) 에 해당하는 설정 키.
    function keyFor(dayOfWeek) {
        if (dayOfWeek >= 1 && dayOfWeek <= 7) {
            return KEYS[dayOfWeek - 1];
        }
        return null;
    }

    //! 해당 요일의 블록 배열. 설정이 없거나 못 읽으면 빈 배열.
    //!
    //! 어느 칸에 무엇을 넣든 최대한 읽어낸다. 사용자는 챗봇이 준 결과를
    //! 그대로 붙여넣는다 — 요일 표시가 붙어 있을 수도, 줄바꿈으로 나뉘어
    //! 있을 수도 있다. 형식을 강요하면 조용히 "일정 없음" 만 뜨고
    //! 무엇이 틀렸는지 알 길이 없다.
    function forDay(dayOfWeek) {
        var week = readProperty("Week");
        if (week != null && hasDayMarker(week)) {
            return parseWeek(week, dayOfWeek);
        }

        var text = rawFor(dayOfWeek);
        if (text == null) { return []; }

        // 요일 칸에 요일 표시가 붙은 채로 들어올 수 있다. 그때도 읽어낸다.
        if (hasDayMarker(text)) { return parseWeek(text, dayOfWeek); }
        return parseDay(text);
    }

    //! 요일 표시(월: / Mon: / Lun:)로 시작하는 조각이 있는가.
    //!
    //! 조각 맨 앞만 본다. 아무 데나 찾으면 과목명에 콜론이 들어간 것만으로
    //! ("Chemo:Lab") 주 전체 형식으로 오인해서 그 요일이 통째로 사라진다.
    function hasDayMarker(text) {
        var chunks = splitLines(splitOn(text, "|"));
        for (var i = 0; i < chunks.size(); i++) {
            var c = trim(chunks[i]);
            var at = c.find(":");
            if (at == null) { continue; }
            if (dayIndexOf(trim(c.substring(0, at))) != null) { return true; }
        }
        return false;
    }

    //! 어느 요일이든 읽어낸 수업이 하나라도 있는가.
    //!
    //! 설정은 들어 있는데 한 줄도 못 읽었다면 형식이 틀린 것이다.
    //! 그 경우와 "오늘만 수업이 없는 날" 을 화면에서 구분하기 위해 쓴다.
    function anyParsed() {
        for (var dow = 1; dow <= 7; dow++) {
            if (forDay(dow).size() > 0) { return true; }
        }
        return false;
    }

    //! "월:09:00-09:50,근로|화:11:00-12:50,생물학" 에서 해당 요일만 꺼낸다.
    //! 요일 표시는 한글 한 글자와 영문 세 글자를 모두 받는다.
    //!
    //! 요일 구분자는 파이프와 줄바꿈을 모두 받는다. 챗봇이 주는 형태가
    //! 둘 중 무엇일지 사용자가 알 이유가 없다.
    function parseWeek(text, dayOfWeek) {
        var chunks = splitLines(splitOn(text, "|"));
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
        var t = dropDaySuffix(token.toLower());
        for (var i = 0; i < MARKERS.size(); i++) {
            var row = MARKERS[i];
            for (var j = 0; j < row.size(); j++) {
                var m = row[j];
                if (t.equals(m)) { return i + 1; }
                if (m.length() >= 3 && t.find(m) == 0) { return i + 1; }
            }
        }
        return null;
    }

    //! 뒤에 붙는 "요일" "曜日" "曜" 를 떼어낸다. ("월요일" -> "월")
    //! 설정 화면의 요일 이름이 그 형태라, 손으로 적으면 그대로 따라 적는다.
    function dropDaySuffix(t) {
        var tails = [ "요일", "曜日", "曜" ];
        for (var i = 0; i < tails.size(); i++) {
            var tail = tails[i];
            var cut = t.length() - tail.length();
            if (cut > 0 && t.substring(cut, t.length()).equals(tail)) {
                return t.substring(0, cut);
            }
        }
        return t;
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

    //! 각 조각을 줄바꿈으로 한 번 더 나눠 평평하게 만든다.
    function splitLines(chunks) {
        var out = [];
        for (var i = 0; i < chunks.size(); i++) {
            var lines = splitOn(chunks[i], "\n");
            for (var j = 0; j < lines.size(); j++) {
                out.add(lines[j]);
            }
        }
        return out;
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

    //! 앞뒤 공백·줄바꿈·탭을 정리한다.
    //! 붙여넣기에는 \r 이 섞여 들어오는 경우가 있다.
    function trim(s) {
        var a = 0;
        var b = s.length();
        while (a < b && isBlank(s.substring(a, a + 1))) { a++; }
        while (b > a && isBlank(s.substring(b - 1, b))) { b--; }
        return s.substring(a, b);
    }

    function isBlank(ch) {
        return ch.equals(" ") || ch.equals("\r") || ch.equals("\n") || ch.equals("\t");
    }
}
