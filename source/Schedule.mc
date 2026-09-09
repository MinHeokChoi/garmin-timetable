using Toybox.Time;
using Toybox.Time.Gregorian;

//! 오늘의 일정과, 현재 시각 대비 각 일정의 위치를 계산한다.
//!
//! 데이터 자체는 만들지 않는다. 파싱은 Timetable 이 맡고,
//! 여기서는 "지금 기준으로 어디쯤인가" 만 다룬다.
//!
//! 개발 중 설정 없이 화면을 보고 싶으면 resources/settings/properties.xml
//! 의 기본값을 임시로 채운다. 단, 시뮬레이터는 설정을 한 번 저장하면
//! 기본값을 다시 읽지 않는다 (README 참고).
(:glance)
module Schedule {

    // 블록 항목 위치
    const START = 0;
    const END   = 1;
    const TITLE = 2;
    const PLACE = 3;

    // 현재 시각 대비 블록 상태
    enum {
        PAST   = 0,
        NOW    = 1,
        FUTURE = 2
    }

    //! 오늘(로컬 시간 기준) 블록 배열. 시작 시각 순으로 정렬돼 있다고 본다.
    function today() {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return Timetable.forDay(info.day_of_week);
    }

    //! 자정부터 지난 분. 00:00 -> 0, 23:59 -> 1439.
    function nowMinutes() {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return info.hour * 60 + info.min;
    }

    //! "HH:MM" -> 분. Timetable 이 이미 형식을 통일해 놓았다.
    function toMinutes(hhmm) {
        return hhmm.substring(0, 2).toNumber() * 60 + hhmm.substring(3, 5).toNumber();
    }

    function statusOf(block, minutes) {
        if (minutes < toMinutes(block[START])) { return FUTURE; }
        if (minutes < toMinutes(block[END]))   { return NOW; }
        return PAST;
    }

    //! 지금 진행 중인 블록, 없으면 다음 블록의 인덱스.
    //! 오늘 일정이 다 끝났거나 아예 없으면 blocks.size() 를 돌려준다(= 종료 화면).
    function anchorIndex(blocks, minutes) {
        for (var i = 0; i < blocks.size(); i++) {
            if (statusOf(blocks[i], minutes) != PAST) { return i; }
        }
        return blocks.size();
    }
}
