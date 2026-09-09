using Toybox.Application;
using Toybox.WatchUi;

class TimetableApp extends Application.AppBase {

    hidden var mView;

    function initialize() {
        AppBase.initialize();
    }

    //! 폰(Garmin Connect)에서 시간표 설정을 바꾸면 호출된다.
    //! 앱이 열려 있는 채로 바뀌어도 바로 반영되게 다시 읽는다.
    function onSettingsChanged() {
        if (mView != null) {
            mView.reload();
        }
    }

    //! 시계 화면에서 UP/DOWN 으로 넘겨볼 때 나오는 요약 화면.
    (:glance)
    function getGlanceView() {
        return [ new TimetableGlanceView() ];
    }

    function getInitialView() {
        mView = new TimetableView();
        return [ mView, new TimetableDelegate(mView) ];
    }
}
