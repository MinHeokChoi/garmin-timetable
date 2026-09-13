# Next Class

> Garmin 시계용 시간표 앱

Garmin 시계에서 지금·다음 수업을 확인하는 앱.

앱을 열면 현재 시각 기준으로 가장 관련 있는 수업을 보여주고, 버튼으로 앞뒤를 넘겨본다.
요약(Glance)에서는 앱을 열지 않고도 다음 수업이 보인다.

지원 언어는 한국어·영어·중국어 간체다. 문자열은 `resources/`(한국어, 기본),
`resources-eng/`, `resources-zhs/` 에 있다. **과목명을 그 언어로 쓰려면
시계 언어도 같아야 한다** — Connect IQ 앱은 펌웨어 폰트를 쓴다.

- 화면 규칙과 코드 구조는 [DESIGN.md](DESIGN.md)
- Store 등록에 필요한 것은 [store/CHECKLIST.md](store/CHECKLIST.md)
- 시간표 입력 도구는 [docs/](docs/) — GitHub Pages 로 서비스한다

## 시간표 입력 도구

사용자가 시간표를 만들어 넣는 웹 페이지. `docs/` 에 있고 정적 파일 셋뿐이라
서버가 없다. 저장소 설정에서 **Pages 를 `/docs` 로 켜면** 아래 주소로 열린다.

```
https://minheokchoi.github.io/garmin-timetable/
```

이 주소는 앱 설정의 `helpUrl` 에 박혀 있다. **저장소 이름을 바꾸면 앱도 다시 빌드해야 한다.**

- `index.html` `style.css` `app.js` — 편집 화면
- `i18n.js` — 화면 문구 (한국어·영어·중국어 간체)
- `prompt.txt` `prompt-en.txt` `prompt-zh.txt` — 사진에서 읽어올 때 쓰는 프롬프트

언어는 브라우저 설정에서 짐작하고, 고른 값은 브라우저에 저장한다.

**요일은 화면에 보여줄 이름과 출력에 넣을 표시가 다르다.** 앱이 인식하는 건
한글 한 글자(`월`)와 영문 세 글자(`Mon`) 두 가지뿐이라, 중국어 화면에서도
출력에는 `Mon:` 을 쓴다. 화면에만 `周一` 로 보여준다.
붙여넣기를 읽을 때는 세 가지를 다 받는다 — 챗봇이 어느 언어로 답하든 읽혀야 한다.

**`app.js` 의 파서는 `source/Timetable.mc` 와 같은 규칙을 구현한다.**
한쪽만 고치면 "페이지에선 되는데 시계에선 안 되는" 상황이 생긴다. 규칙을 바꿀 때는
둘 다 고친다 — 시간 정규화, 종료<=시작 거부, 시작 시각 정렬, 띄어쓰기 접기.

로컬에서 보려면:

```bash
python3 -m http.server 8765 --directory docs
```

## 시간표는 앱 설정에서

코드에 하드코딩하지 않는다. Garmin Connect 앱의 설정에서 요일별로 넣는다.

```
09:00-09:50,운영체제,T0503;10:00-11:50,데이터베이스,B201
```

- 월~일 **7일** 각각 한 칸
- 수업 구분 `;` / 필드 구분 `,` / 시간 구분 `-` 또는 `~`
- 순서는 `시간,이름,강의실`. 강의실은 생략 가능
- `09:00` `9:00` `0900` 전부 인식. 앞뒤 공백 자동 정리
- 입력 순서가 뒤바뀌어도 시간순으로 정렬
- 못 읽는 항목은 건너뛴다. 종료가 시작보다 빠른 항목도 버린다

**이름이 길면 띄어쓰기한 자리에서 두 줄로 접힌다.** 화면이 좁으니 이름은 짧을수록 좋다.

```
데이터베이스 시스템   ->  데이터베이스
                        시스템
```

공백이 없으면 글자 수 절반에서 끊긴다. 어색하면 공백을 넣는다.

기존 시간표 JSON에서 뽑으려면:

```bash
python3 tools/to_settings.py data/timetable.draft.json
```

## 지원 기기

**107종.** 계열별로는 이렇다.

| 화면 계열 | 기기 수 |
|---|---|
| round-240x240 | 23 |
| round-390x390 | 22 |
| round-454x454 | 14 |
| round-260x260 | 13 |
| round-416x416 | 12 |
| round-280x280 | 9 |
| round-218x218 | 5 |
| round-360x360 | 2 |
| rectangle-240x240 | 2 |
| rectangle-320x360 | 2 |
| round-466x466 | 1 |
| round-208x208 | 1 |
| rectangle-448x486 | 1 |

원형과 사각형을 모두 지원한다. `Theme.isRound()` 가 `System.getDeviceSettings().screenShape`
를 한 번 읽어 두고, 가용 폭 계산과 QR 크기를 거기에 맞춘다.
반원형·반8각형은 원으로 쳐서 좁게 잡는다 — 넘치지는 않는다.

**Instinct(반8각형)와 Edge(자전거 컴퓨터)는 넣지 않았다.**
Instinct 는 176x176 에 보조 화면이 따로 있어 레이아웃을 다시 짜야 하고,
QR 도 모듈당 3.5px 이라 스캔이 어렵다. Edge 는 손목에 차는 물건이 아니다.

구형 20종(fenix 3/5, vívoactive 3, fr645, fr935 등)은 `minApiLevel 3.2.0` 을
만족하지 못해 빠졌다.

기기를 늘릴 때는 **계열마다 최소 한 종을 시뮬레이터로 확인하고** 넣는다.
빌드가 된다고 화면이 제대로 나오는 건 아니다.

## 빌드

```bash
export PATH="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2/bin:$PATH"
```

한 기기용 (시뮬레이터·사이드로드):

```bash
monkeyc -f monkey.jungle -o bin/timetable-fr255m.prg -y ~/.Garmin/developer_key -d fr255m
```

Store 업로드용 (전 기기 묶음):

```bash
monkeyc -e -f monkey.jungle -o bin/timetable.iq -y ~/.Garmin/developer_key
```

## 시뮬레이터

```bash
connectiq &
monkeydo bin/timetable-fr255m.prg fr255m
```

- 한글이 `?` 로 깨지면 **Settings → Language → Korean (kor)**
- 요약을 보려면 **Settings → Glance Launch Mode → Launch in Glance Mode** 로 바꾸고 다시 푸시
- `monkeydo` 는 한 번에 안 먹을 때가 있다. 두 번 실행하면 붙는다

**설정 기본값을 바꿨는데 반영이 안 되면** 시뮬레이터가 이전 설정을 붙들고 있는 것이다.
`properties.xml` 기본값은 최초 설치 때만 적용되고, 메뉴의 `Reset All App Data` 로는 안 지워진다.

```bash
rm -f /private/var/folders/*/*/T/com.garmin.connectiq/GARMIN/APPS/SETTINGS/*.SET
```

## 실제 시계에 설치 (개발용)

Store 승인 전에 시계에서 확인하려면 사이드로드해야 한다.

**최신 Garmin 기기는 macOS에서 볼륨으로 마운트되지 않는다.** USB 모드가 `Garmin`이든
`MTP`든 `/Volumes/GARMIN`은 뜨지 않는다. `brew install libmtp` 의 `mtp-sendfile` 도
읽기만 되고 쓰기에서 `kIOReturnExclusiveAccess` 가 난다.

통하는 방법은 **OpenMTP** 뿐이다.

1. 시계 USB 모드를 `MTP(미디어 전송)` 로 (설정 → 시스템 → USB 모드)
2. USB 연결. 인식 확인: `ioreg -p IOUSB -l -w 0 | grep -q '"idVendor" = 2334' && echo OK`
   - 전원만 주고 데이터 라인이 없는 허브 포트가 있다. 안 잡히면 포트를 바꾼다
3. [OpenMTP](https://openmtp.ganeshrvel.com) 에서 `.prg` 를 `GARMIN/Apps/` 로 드래그
4. 파일 크기로 검증: `mtp-files | grep -A3 timetable`

기기 변종을 확인하고 맞는 빌드를 넣는다. `fr255` 와 `fr255m` 은 다르고,
잘못 넣으면 설치는 되는데 앱 목록에 안 뜬다.

```bash
mtp-detect | grep -E "is a Garmin|Model:"
```

### 개인용 빌드를 다시 넣을 때는 설정 파일을 지운다

시계는 앱 설정을 `GARMIN/Apps/SETTINGS/` 안에 파일로 따로 보관한다.
**이 파일이 남아 있으면 새 빌드에 박아 둔 기본값이 무시된다.** 설정을 보존하려는
정상 동작이지만, 시간표를 기본값에 넣어 쓰는 개인용 빌드에서는 예전 값이 계속 이긴다.

증상은 "시간표 없음" 안내 화면이다. 앱이 잘못된 게 아니라 빈 설정을 읽은 것이다.

```bash
mtp-filetree 2>/dev/null | grep -i "\.SET"   # timetable...SET 앞의 번호 확인
mtp-delfile -n <번호>
```

지운 뒤 시계에서 앱을 다시 열면 새 기본값을 읽는다.
`mtp-sendfile` 은 막히지만 **`mtp-delfile` 은 동작한다.**

Store 버전은 설정을 폰에서 받으므로 이 문제가 없다.

## 아이콘

시계용은 `resources/drawables/launcher_icon.svg` 하나로 5가지 크기(40~70px)를 처리한다.
Store 용 고해상도 PNG는 같은 도형을 다시 그린다.

```bash
python3 tools/render_icon.py store/icon-512.png 512
```

SVG를 고치면 `tools/render_icon.py` 의 `BARS` 도 같이 고쳐야 한다.

## 버튼

| 버튼 | 동작 |
|---|---|
| UP | 이전 수업 |
| DOWN | 다음 수업 |
| START | 현재 시각으로 복귀 |
| BACK | 종료 |

시간표가 없을 때(온보딩 화면)는 `DOWN` 이 입력 도구 주소의 QR 을 띄우고 `UP` 이 되돌린다.

## QR 다시 만들기

`source/Qr.mc` 의 모듈 배열은 주소가 바뀔 때만 다시 만든다.
브라우저에서 qrcode-generator 로 뽑는다 — 별도 설치가 필요 없다.

```js
const q = qrcode(0, 'L');
q.addData('https://minheokchoi.github.io/garmin-timetable/');
q.make();
// q.getModuleCount() 와 q.isDark(r, c) 로 배열을 만든다
```

오류정정 `L` 을 쓴다. 화면은 훼손될 일이 없고, L 이어야 29모듈에 담긴다.

학식 앱은 별도 프로젝트 `~/Developer/projects/hongik-cafeteria/` 에 있다.
