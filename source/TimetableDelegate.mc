using Toybox.WatchUi;

//! Forerunner 255 는 터치가 없으므로 버튼만 사용한다.
//!   UP    - 이전 일정
//!   DOWN  - 다음 일정
//!   START - 현재 시각 위치로 복귀
//!   BACK  - 앱 종료 (기본 동작)
class TimetableDelegate extends WatchUi.BehaviorDelegate {

    hidden var mView;

    function initialize(view) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    function onNextPage() {
        mView.next();
        return true;
    }

    function onPreviousPage() {
        mView.prev();
        return true;
    }

    function onSelect() {
        mView.reset();
        return true;
    }
}
