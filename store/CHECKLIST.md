# Store 업로드 — 남은 일

코드·빌드·등록물은 준비돼 있다. 아래는 **계정이 있어야 하거나 사람이 판단해야 하는** 것들이다.

## 1. Garmin 개발자 계정 (본인만 가능)

https://developer.garmin.com/connect-iq/ 에서 Garmin 계정으로 로그인.
개발자 등록은 무료다.

## 2. 업로드할 파일

| 항목 | 파일 | 상태 |
|---|---|---|
| 앱 패키지 | `bin/timetable.iq` | 준비됨 |
| 아이콘 | `store/icon-512.png` (또는 256) | 준비됨 |
| 스크린샷 | `store/screenshots/*.png` (260×260, 6장) | 준비됨 |
| 설명 (한국어) | `store/listing-ko.md` | 준비됨 |
| 설명 (영어) | `store/listing-en.md` | 준비됨 |

**업로드 화면에서 요구하는 아이콘·스크린샷 규격이 여기 준비한 것과 다르면 알려달라.**
크기는 `tools/render_icon.py` 로 즉시 다시 뽑을 수 있고, 스크린샷은 시뮬레이터에서
다시 캡처하면 된다.

## 3. 사람이 정해야 하는 것

**앱 이름** — `Next Class` 로 정했다. `Timetable` 은 이미 있어서 피했다.
바꾸려면 `resources/strings/strings.xml`(영어, 기본)을 비롯한 언어별
`strings.xml` 의 `AppName` 을 모두 고치고 다시 빌드한다.

**카테고리** — Connect IQ 카테고리 중 하나를 고른다. `Productivity` 계열이 맞다.

**공개 범위** — Connect IQ 에는 비공개·초대 배포가 없다. 올리면 전체 공개다.
시간표는 앱이 아니라 사용자 설정에 들어가므로 개인 정보가 노출되지는 않는다.

**가격** — 무료로 둔다.

## 4. 심사

제출 후 Garmin 심사에 며칠 걸린다. 반려되면 사유가 오고, 대부분 설명·스크린샷
규격 문제다. 코드 문제로 반려되면 사유를 알려주면 고친다.

## 5. 승인된 뒤

1. Store 에서 앱을 설치한다 (지금 시계에 사이드로드된 버전은 지워도 된다)
2. Garmin Connect 앱 → Next Class → 설정에서 요일별 시간표를 붙여넣는다
3. 붙여넣을 문자열은 이 명령으로 뽑는다

```bash
python3 tools/to_settings.py data/timetable.draft.json
```

친구들에게는 시간표를 받아 같은 형식으로 만들어 주면 된다.
그때부터는 케이블도, 내 컴퓨터도 필요 없다.
