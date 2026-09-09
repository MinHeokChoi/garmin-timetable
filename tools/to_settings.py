#!/usr/bin/env python3
"""시간표 JSON -> Garmin Connect 앱 설정에 붙여넣을 문자열.

사용법: python3 tools/to_settings.py data/timetable.draft.json

입력 형식(weekly 배열):
    {"dow": 1, "start": "09:00", "end": "09:50", "title": "근로", "place": "WORK"}
    dow: 1=월 ... 7=일
    place 는 places 사전의 키. places[k]["name"] 이 있으면 그 값을 표시명으로 쓴다.

출력: 요일별 한 줄. 그대로 복사해 폰의 해당 요일 칸에 붙여넣는다.
"""
import json, sys

DAYS = {1: "월요일", 2: "화요일", 3: "수요일", 4: "목요일", 5: "금요일",
        6: "토요일", 7: "일요일"}
MAXLEN = 300   # settings.xml 의 maxLength 와 맞춰야 한다

def place_name(places, key):
    if not key:
        return ""
    p = places.get(key, {})
    return p.get("name") or p.get("label") or key

def main(path):
    d = json.load(open(path, encoding="utf-8"))
    places = d.get("places", {})
    by_day = {}
    for b in d.get("weekly", []):
        by_day.setdefault(b["dow"], []).append(b)

    over = False
    for dow in sorted(DAYS):
        blocks = sorted(by_day.get(dow, []), key=lambda b: b["start"])
        parts = []
        for b in blocks:
            name = place_name(places, b.get("place"))
            item = "%s-%s,%s" % (b["start"], b["end"], b["title"])
            if name:
                item += "," + name
            parts.append(item)
        line = ";".join(parts)
        mark = ""
        if len(line) > MAXLEN:
            mark = "   <-- %d자, 한도 %d 초과!" % (len(line), MAXLEN)
            over = True
        print("%s (%d자)%s" % (DAYS[dow], len(line), mark))
        print(line if line else "(수업 없음 - 비워 둔다)")
        print()

    if over:
        print("한도를 넘는 요일이 있다. 과목명을 줄이거나 settings.xml 의 maxLength 를 올려야 한다.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__); sys.exit(1)
    main(sys.argv[1])
