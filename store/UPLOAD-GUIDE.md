# Store 업로드 — 따라 하기

준비된 파일은 전부 이 저장소 안에 있다. 순서대로만 하면 된다.

---

## 1단계 · 로그인

https://apps.garmin.com 에 접속해서 오른쪽 위 로그인.

**시계에 쓰는 Garmin 계정 그대로 쓴다.** 개발자 계정을 따로 만들 필요 없고 돈도 안 든다.
Garmin Connect 앱에 로그인한 그 계정이다.

## 2단계 · 이름 정하기 (업로드 전에)

업로드하면 이름을 바로 정해야 하니 미리 확인한다.

앱 이름은 **`Next Class`** 로 정했다.

`timetable` 로 검색하면 995개가 나온다 — 그 단어로는 순위를 못 잡는다.
대신 설명에 timetable, 시간표, class, schedule 을 넣어 뒀다.
Connect IQ 검색은 **제목뿐 아니라 설명도 걸린다.**

이름을 또 바꾸려면 언어별 `strings.xml` 의 `AppName` 을 전부 고치고 다시 빌드한다.

```
resources/strings/strings.xml       (영어, 기본)
resources-kor/strings/strings.xml   (한국어)
resources-zhs, -jpn, -fre, -deu, -spa
```

## 3단계 · 업로드

https://apps.garmin.com/en-US/developer/upload

여기에 이 파일을 올린다.

```
bin/timetable.iq
```

올리면 Garmin 이 **바이너리 검사**를 먼저 한다. 매니페스트에 적힌 기기들과
서명이 맞는지 보는 단계다. 여기서 걸리면 코드 문제이니 오류 메시지를 알려달라.

검사를 통과해야 다음 입력 화면이 열린다.

## 4단계 · 정보 입력

### 앱 종류
`Watch App` 을 고른다. (워치페이스나 데이터 필드가 아니다)

### 카테고리
`Productivity` 계열을 고른다. 목록에 `Tools` 나 `Utilities` 만 있으면 그쪽이다.
러닝·사이클 같은 운동 카테고리는 맞지 않는다.

### 이름과 설명

언어별로 따로 넣는다. 문안은 준비돼 있으니 복사해서 붙이면 된다.

| 언어 | 파일 |
|---|---|
| 한국어 | `store/listing-ko.md` |
| 영어 | `store/listing-en.md` |
| 중국어 간체 | `store/listing-zhs.md` |
| 일본어 | `store/listing-jpn.md` |
| 프랑스어 | `store/listing-fre.md` |
| 독일어 | `store/listing-deu.md` |
| 스페인어 | `store/listing-spa.md` |
| 이탈리아어 | `store/listing-ita.md` |
| 폴란드어 | `store/listing-pol.md` |

`manifest.xml` 의 `<iq:languages>` 에 선언한 언어와 이 목록을 같이 간다.
앱은 그 언어를 지원하는데 스토어 설명은 영어만 있으면, 설치 전에 읽는 글과
설치 후에 보는 화면의 언어가 달라진다.

파일 안에 ` ``` ` 로 감싼 부분이 그대로 붙여넣을 내용이다.

**설명에서 제일 중요한 건 시간표 입력 형식 부분이다.** 사용자가 이걸 못 읽으면
앱을 못 쓴다. 길다고 줄이지 않는 편이 좋다.

### 아이콘

```
store/icon-512.png
```

512픽셀이 안 맞다고 하면 `store/icon-256.png` 을 쓴다. 둘 다 안 맞으면
요구하는 크기를 알려달라 — 바로 다시 뽑는다.

### 스크린샷

```
store/screenshots/  (260×260, 6장)
```

순서대로 올리는 걸 권한다. 앞에 오는 것이 목록에 먼저 보인다.

| 파일 | 무엇 |
|---|---|
| `01-now.png` | 수업 진행 중 |
| `02-next.png` | 다음 수업 |
| `06-glance.png` | 요약 화면 |
| `03-prev.png` | 지난 수업 넘겨보기 |
| `04-done.png` | 오늘 끝 |
| `05-setup.png` | 처음 켰을 때 |

전부 안 올려도 된다. 최소 3장이면 충분하다.

### 가격
무료로 둔다.

## 5단계 · 제출

**Connect IQ 에는 비공개 배포가 없다.** 제출하면 전체 공개다.
시간표는 앱이 아니라 사용자 설정에 들어가므로 개인 정보가 나가지는 않는다.

제출 후 Garmin 심사에 며칠 걸린다. 반려되면 사유가 오는데 대부분 설명이나
스크린샷 규격 문제다. 코드 문제라면 사유를 알려달라.

---

## 업데이트를 올릴 때

처음 등록과 흐름이 다르다. 새 바이너리를 올리고 언어별 문안을 손본다.

### 1 · 묶음 빌드

```bash
monkeyc -e -f monkey.jungle -o bin/timetable.iq -y ~/.Garmin/developer_key
```

### 2 · 스토어

https://apps.garmin.com → 로그인 → My Apps → Next Class → 새 버전 업로드.

**버전 번호는 스토어 화면에서 직접 적는다.** `manifest.xml` 에는 버전이 없다.

### 3 · 언어별 문안

이미 올라가 있는 언어는 **What's New 만** 갈면 된다.
이번에 새로 넣은 언어는 **이름·한 줄 소개·설명·키워드를 처음부터** 넣어야 한다.

| 언어 | 파일 | 1.0.3 에서 할 일 |
|---|---|---|
| 영어 | `listing-en.md` | What's New 만 |
| 한국어 | `listing-ko.md` | What's New 만 |
| 중국어 간체 | `listing-zhs.md` | What's New 만 |
| 일본어 | `listing-jpn.md` | 전부 새로 |
| 프랑스어 | `listing-fre.md` | 전부 새로 |
| 독일어 | `listing-deu.md` | 전부 새로 |
| 스페인어 | `listing-spa.md` | 전부 새로 |
| 이탈리아어 | `listing-ita.md` | 전부 새로 |
| 폴란드어 | `listing-pol.md` | 전부 새로 |

각 파일 `### 1.0.3` 아래의 ` ``` ` 블록이 What's New 에 그대로 들어간다.

### 4 · 스크린샷

화면 구조가 그대로면 다시 안 올려도 된다.

`store/screenshots/` 는 1.0.3 에서 **영어로 다시 찍었다.** 스크린샷은 언어별로
나뉘지 않고 앱 하나에 하나만 달린다. 한국어 화면을 걸어 두면 스토어에 오는
사람 대부분이 못 읽는 것을 보고 설치를 정하게 된다.

### 다시 찍는 방법

시뮬레이터에서 `File → Save Screen Capture` 를 쓰면 기기 화면만 260×260 으로
저장된다. 창을 잘라내지 않아도 된다.

- **언어는 `Settings → Language` 에서 바꾼다.** `simulator.ini` 의 `Language=`
  를 고치는 방법도 있지만, 시뮬레이터가 시작할 때 제 값으로 덮어쓸 때가 있다.
- **기본값을 넣은 빌드를 따로 만든다.** `properties.xml` 의 `Week` 에 시간표를
  박아 두면 설정 없이 화면이 나온다. 단 예전 설정이 남아 있으면 무시되므로
  `File → Reset All App Data` 를 먼저 누른다.
- NOW/NEXT/PREV 는 현재 시각 기준이다. 찍는 날의 요일과 시각에 맞춰 시간표를
  짠다 — 지난 수업 하나, 지금 수업 하나, 앞으로의 수업 둘 정도면 다 나온다.
- 요약 화면은 `Settings → Glance Launch Mode → Launch in Glance Mode` 로 켜고
  앱을 다시 올린다. **찍고 나면 Normal Mode 로 되돌린다.**

### 릴리스 전 확인

- [ ] `manifest.xml` 의 `<iq:languages>`, `resources-*` 폴더, `store/listing-*` 세 목록이 같다
- [ ] 각 언어 `SettingWeekHint` 의 요일 예시가 `Mon:` 이다 (앱이 읽을 수 있는 형태)
- [ ] `docs/index.html` 의 `?v=` 가 이번 버전이다
- [ ] 묶음 빌드가 전 기기에서 통과한다
- [ ] 새 언어를 시뮬레이터에서 한 번 띄워 글자가 안 깨지고 안 넘친다

---

## 승인된 뒤

1. 시계에서 Connect IQ Store 로 앱을 설치한다
   (지금 사이드로드된 버전은 지워도 되고 그냥 둬도 된다)
2. Garmin Connect 앱 → Next Class → 설정 → 요일별 시간표를 붙여넣는다
3. 붙여넣을 문자열은 이 명령으로 뽑는다

```bash
python3 tools/to_settings.py data/timetable.draft.json
```

친구들에게는 시간표를 받아 같은 형식으로 만들어 주면 된다.
**그때부터는 케이블도, 내 컴퓨터도 필요 없다.**
