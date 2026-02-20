# 넥사크로 Grid 주요 기능 분석

> **출처:** [넥사크로플랫폼 17 컴포넌트 활용 워크북](https://docs.tobesoft.com/developer_guide_nexacro_17_ko/ccdb97b19fa824d8)  
> **제공:** 투비소프트 (시장점유율 1위)  
> **분석 목적:** LiveView Grid 개발을 위한 참고 자료  
> **분석일:** 2026-02-20

---

## 📊 넥사크로 Grid 개요

넥사크로 Grid는 **한국 UI/UX 플랫폼 시장 1위** 기업인 투비소프트의 엔터프라이즈급 그리드 컴포넌트입니다.

### 구조
- **head 밴드**: 컬럼 명 표시 (헤더)
- **body 밴드**: 데이터 표시 영역
- **summary 밴드**: 합계/평균/최대/최소값 등 집계 표시

### 데이터 바인딩
- **Dataset과 1:1 풀 바인딩** (넥사크로만의 특징)
- Grid 자체는 데이터를 갖지 않음
- Dataset이 데이터 저장소 역할

---

## 📚 Grid 문서 구성

넥사크로는 Grid 기능을 **4개 챕터**로 나눔:

| 챕터 | 내용 | 페이지 수 (추정) |
|------|------|-----------------|
| 22. Grid 기본 | Dataset 바인딩, CRUD, 필터/검색, 선택 | 19개 섹션 |
| 23. Grid 레이아웃 | 셀 크기, 틀 고정, 컬럼 이동, 다중 헤더 | 14개 섹션 |
| 24. Grid 셀 | 셀 타입, 편집, 스타일, 이벤트 | - |
| 25. Grid 응용 | 고급 기능, 성능 최적화 | - |

---

## 1. Grid 기본 기능 (22장)

### 1.1 Grid에 Dataset 바인딩하기

**핵심 속성:**
- `binddataset` - 바인딩할 Dataset ID 설정

**특징:**
- **풀 바인딩 (Full Binding)** - Grid ↔ Dataset 완전 동기화
- Grid 포커스 이동 → Dataset의 `rowposition` 자동 변경
- 컴포넌트 중 오직 Grid만 Dataset과 풀 바인딩

**바인딩 방법:**
1. Dataset을 Grid로 드래그 앤 드롭
2. 자동으로 컬럼 생성됨

---

### 1.2 조건에 맞는 레코드 필터링하기

**핵심 메서드:**
```javascript
Dataset.filter(strConditionExpression)
```

**조건 표현식 예시:**
```javascript
// 단일 조건
Name == "James"
Salary < 20000

// 복합 조건
Department == "Sales" || Department == "Consulting"
Company == "hangul" && Salary < 10000
```

**특징:**
- filter 호출 시 이전 필터 조건은 무시됨 (덮어쓰기)
- `filterstr` 속성으로도 동일 기능 구현 가능
- filter("")나 filter()로 필터링 해제

---

### 1.3 조건에 맞는 특정 레코드 검색하기

**핵심 메서드:**

**1) findRow** - 컬럼/값 기반 검색
```javascript
var nRow = this.Dataset00.findRow("column00", "100");
var nRow = this.Dataset00.findRow("column00", "100", 10); // 10번째 행부터
var nRow = this.Dataset00.findRow("column00", "100", 10, 10000); // 범위 지정
```

**2) findRowExpr** - 조건 표현식 기반 검색
```javascript
var nRow = this.Dataset00.findRowExpr("dept_cd == 'A2'");
var nRow = this.Dataset00.findRowExpr("dept_cd == 'A2'", 2); // 2번째 행부터
var nRow = this.Dataset00.findRowExpr("dept_cd == 'A2' && pos_cd > '03'", 2, 10);
```

**반환값:** 첫 번째 매칭 행의 인덱스 (없으면 -1)

---

### 1.4 레코드 추가/삭제하기

**핵심 메서드:**

**1) addRow** - 행 추가
```javascript
this.Dataset00.addRow(); // 마지막에 추가
```

**2) deleteRow** - 행 삭제
```javascript
this.Dataset00.deleteRow(this.Dataset00.rowposition); // 현재 행 삭제
```

---

### 1.5 여러 레코드 선택하기

**핵심 속성:** `selecttype`

**선택 타입:**
| 타입 | 설명 |
|------|------|
| row | 단일 행 선택 |
| multirow | 다중 행 선택 (드래그/Ctrl/Shift) |
| cell | 단일 셀 선택 |
| area | 영역 선택 (드래그) |
| multiarea | 다중 영역 선택 |

**예시:**
```javascript
this.Grid00.set_selecttype("multirow");
```

---

### 1.6 여러 레코드 삭제하기

**핵심 메서드:**

**1) getSelectedDatasetRows** - 선택된 행 인덱스 배열 반환
```javascript
var arrSelectedRow = this.Grid00.getSelectedDatasetRows();
```

**2) deleteMultiRows** - 배열로 된 행 목록 삭제
```javascript
this.Dataset00.deleteMultiRows(arrSelectedRow);
```

**예시:**
```javascript
this.Button_onclick = function() {
    var arrSelectedRow = this.Grid00.getSelectedDatasetRows();
    this.Dataset00.deleteMultiRows(arrSelectedRow);
};
```

---

### 1.7 다른 데이터셋의 레코드 추가하기

**핵심 메서드:** `appendData`

**사용법:**
```javascript
// 컬럼 순서대로 추가 (컬럼 이름 무시)
this.Dataset00.appendData(this.Dataset01);

// 컬럼 이름이 같은 것만 추가
this.Dataset00.appendData(this.Dataset01, true);
```

**반환값:** 추가된 행 개수

---

### 1.8 레코드 개수 구하기

**핵심 메서드:**
```javascript
this.Dataset00.getRowCount(); // 전체 행 수
this.Dataset00.getDeletedRowCount(); // 삭제된 행 수
```

---

### 1.9 변경된 데이터가 있는지 확인하기

**핵심 속성/메서드:**

**1) enableevent** - 이벤트 활성화/비활성화
```javascript
this.Dataset00.set_enableevent(false); // 이벤트 끄기 (성능 최적화)
// 대량 데이터 처리
this.Dataset00.set_enableevent(true); // 이벤트 다시 켜기
```

**2) getRowType** - 행 상태 확인
```javascript
// 반환값: 1(추가), 2(수정), 4(삭제), 8(일반)
var nType = this.Dataset00.getRowType(nRow);
```

**3) getRowCount** - 상태별 행 수 조회
```javascript
this.Dataset00.getRowCount(); // 전체
this.Dataset00.getDeletedRowCount(); // 삭제된 행
```

---

### 1.10 변경 내용 데이터셋에 반영하기 / 되돌리기

**핵심 메서드:**

**1) applyChange** - 변경 내용 확정 (더 이상 되돌릴 수 없음)
```javascript
this.Dataset00.applyChange();
```

**2) reset** - 변경 내용 모두 되돌리기
```javascript
this.Dataset00.reset();
```

**차이점:**
- applyChange 후에는 reset 불가
- reset은 applyChange 전에만 가능

---

### 1.11 툴팁(Tooltip) 보여주기

**핵심 이벤트:** `oncellclick`

**구현 방법:**
```javascript
this.Grid00_oncellclick = function(obj, e) {
    var sTooltip = this.Dataset00.getColumn(e.row, e.cell);
    obj.set_tooltiptext(sTooltip);
};
```

**응용:** 컬럼 너비보다 긴 텍스트만 툴팁으로 표시

---

### 1.12 Smart Scroll 기능 사용하기

**핵심 속성:** `scrolltype`

**값:**
- `none` - 일반 스크롤
- `horizontal` - 가로 스크롤만
- `vertical` - 세로 스크롤만
- `both` - 양방향 스크롤
- `none` + 속성 조합으로 Smart Scroll 구현

**Smart Scroll:** 내용에 맞춰 자동으로 Grid 크기 조정

---

### 1.13 선택한 셀 테두리선 표현하기

**핵심 속성:**

**1) selectstyle** - 선택 스타일
- `select` - 기본 선택 스타일
- `background` - 배경색만
- `border` - 테두리만

**2) selectchangetype** - 선택 변경 방식
- `down` - 마우스 다운 시
- `up` - 마우스 업 시 (기본값)

---

### 1.14 Grid 높이 자동 조정하기

**핵심 속성:** `autofittype`

**값:**
- `none` - 고정 높이
- `row` - 행 수에 맞춰 높이 자동 조정 (스크롤바 없음)
- `col` - 컬럼 너비에 맞춤
- `both` - 행/열 모두

**활용:** 페이징 없는 소량 데이터 표시

---

### 1.15 Row 높이 직접 지정하기

**핵심 속성:**

**1) body** - body 영역 설정
- `body.height` - 전체 행 높이 일괄 지정

**2) setRealRowSize** - 특정 행 높이 지정
```javascript
this.Grid00.setRealRowSize(0, 50); // 0번 행을 50px로
```

---

### 1.16 한 행씩 스크롤하기

**핵심 속성:** `scrollbartype`

**값:**
- `default` - 기본 (픽셀 단위 스크롤)
- `fixed` - 행 단위 스크롤
- `none` - 스크롤바 숨김

---

### 1.17 Row 위치 변경하기

**핵심 메서드:**

**1) moveRow** - 행 이동
```javascript
this.Dataset00.moveRow(nFromRow, nToRow);
```

**예시:** 현재 행을 위로 이동
```javascript
var nRow = this.Dataset00.rowposition;
if (nRow > 0) {
    this.Dataset00.moveRow(nRow, nRow - 1);
}
```

---

## 2. Grid 레이아웃 기능 (23장)

### 2.1 Cell 크기 조절하기

**방법 1: Row 높이 일괄 조절**
```javascript
this.Grid00.set_rowheight(40); // 모든 행 높이 40px
```

**방법 2: 특정 Row 높이 조절**
```javascript
this.Grid00.setRealRowSize(0, 50); // 0번 행만 50px
```

**방법 3: 컬럼 너비 조절**
- 디자인 타임: Grid Editor에서 드래그
- 런타임: `setFormatColProperty` 메서드

---

### 2.2 다중 헤드와 다중 레코드 표현하기

**Band 구조:**
```
head → cell (다중 헤드 가능)
body → cell (다중 레코드 가능)
summary → cell
```

**다중 헤드 예시:**
```
+----------+----------+
| Name     | Score    |
+-----+----+-----+----+
| Eng | Kor| Math| Sci|
+-----+----+-----+----+
```

**구현:** Grid Editor에서 band 추가/셀 병합

---

### 2.3 자동 줄 바꿈과 자동 Cell 크기 조절하기

**핵심 속성:**

**1) wordWrap** - 줄 바꿈
- `char` - 문자 단위 줄 바꿈
- `word` - 단어 단위 줄 바꿈
- `none` - 줄 바꿈 없음 (기본값)

**2) autosizerow** - 높이 자동 조절
- `limitmin` - 최소 높이 유지
- `true` - 내용에 맞춰 확장

**조합:**
```javascript
// Cell 속성
wordWrap = "char"
autosizerow = "limitmin"
```

---

### 2.4 Head Column에 여러 줄 입력하기

**방법 1:** `\n` 사용
```
text="Line1\nLine2"
```

**방법 2:** wordWrap 사용
```javascript
wordWrap = "char"
text = "Very Long Header Text"
```

---

### 2.5 틀 고정하기 - Column

**핵심 속성:** `fixedcol`

**값:**
- `leftzero` - 왼쪽 틀 고정 없음 (기본값)
- `left:2` - 왼쪽 2개 컬럼 고정
- `right:1` - 오른쪽 1개 컬럼 고정

**예시:**
```javascript
this.Grid00.set_fixedcol("left:2"); // 왼쪽 2개 컬럼 고정
```

**효과:** 스크롤 시에도 고정된 컬럼은 화면에 유지

---

### 2.6 틀 고정하기 - Row

**핵심 속성:** `fixedrow`

**값:**
- `none` - 틀 고정 없음 (기본값)
- `head:1` - 헤더 1행 고정
- `head:2` - 헤더 2행 고정
- `summary:1` - Summary 1행 고정

**예시:**
```javascript
this.Grid00.set_fixedrow("head:1");
```

---

### 2.7 Column 위치 이동하기

**핵심 속성:** `enableeditshift`

**방법:**
- 런타임에 컬럼 헤더를 드래그하여 위치 이동
- `enableeditshift = true` 설정 필요

---

### 2.8 변경된 Column 상태의 포맷 복사하기

**핵심 메서드:** `getCurFormatString`

**사용법:**
```javascript
var sFormat = this.Grid00.getCurFormatString();
// sFormat을 저장하거나 다른 Grid에 적용
```

**활용:** 사용자가 변경한 컬럼 순서/너비 저장 후 복원

---

### 2.9 포맷 정보 확인하기

**핵심 메서드:**

**1) getFormatRowCount** - 포맷 행 수
```javascript
var nCnt = this.Grid00.getFormatRowCount();
```

**2) getFormatColCount** - 포맷 컬럼 수
```javascript
var nCnt = this.Grid00.getFormatColCount();
```

**3) getFormatRowProperty** - 행 속성 조회
**4) getFormatColProperty** - 컬럼 속성 조회

---

### 2.10 틀 고정하기 - 선택한 Column

**응용 기능:**
- 사용자가 선택한 컬럼까지만 틀 고정
- 런타임에 동적으로 고정 컬럼 변경

**구현:**
```javascript
var nColIndex = e.col; // 선택된 컬럼 인덱스
this.Grid00.set_fixedcol("left:" + (nColIndex + 1));
```

---

### 2.11 컬럼 크기 조정 기능 제한하기

**핵심 속성:** `autowidth`

**값:**
- `none` - 수동 크기 조정 가능 (기본값)
- `default` - 컬럼 너비 고정 (사용자 조정 불가)

**활용:** 특정 컬럼만 조정 가능하도록 제한

---

### 2.12 병합된 Head 영역의 컬럼 타이틀 텍스트 구하기

**핵심 메서드:** `getCellProperty`

**사용법:**
```javascript
var sText = this.Grid00.getCellProperty("head", nRow, nCol, "text");
```

---

### 2.13 병합된 셀의 자식셀 속성 지정하기

**특징:**
- 병합된 셀은 부모 셀의 속성을 상속
- 자식 셀의 개별 속성 지정 가능

**방법:** Grid Editor에서 셀 속성 개별 설정

---

## 3. Grid 셀 기능 (24장)

넥사크로 Grid 셀의 주요 기능 (문서 미수집, 예상 내용):

### 3.1 셀 타입 (예상)
- **displaytype**: 표시 타입 (text, image, button, combo, checkbox 등)
- **edittype**: 편집 타입 (text, combo, date 등)

### 3.2 셀 스타일 (예상)
- 배경색, 폰트, 정렬
- 조건부 스타일 (cssclass)

### 3.3 셀 이벤트 (예상)
- oncellclick
- oncelldblclick
- oneditchange

---

## 4. Grid 응용 기능 (25장)

고급 기능 (문서 미수집, 예상 내용):

### 4.1 트리 그리드 (예상)
### 4.2 그룹핑 (예상)
### 4.3 피벗 (예상)
### 4.4 Excel Export/Import (예상)
### 4.5 대용량 데이터 처리 (예상)

---

## 🎯 Toast UI Grid vs 넥사크로 Grid 비교

| 기능 | Toast UI Grid | 넥사크로 Grid |
|------|---------------|---------------|
| **데이터 바인딩** | 단방향 (Grid → Data) | 양방향 (Grid ↔ Dataset) |
| **필터링** | Client-side (v4.6+) | filter/filterstr |
| **검색** | 없음 (직접 구현) | findRow/findRowExpr |
| **다중 선택** | API 호출 | selecttype 속성 |
| **틀 고정** | Frozen Columns | fixedcol/fixedrow |
| **셀 타입** | Custom Renderer | displaytype/edittype |
| **Dataset** | 없음 (JSON 직접) | Dataset 객체 (핵심) |
| **플랫폼** | Web (JavaScript) | 넥사크로 플랫폼 |

---

## 🔍 넥사크로 Grid 핵심 특징

### 1. Dataset 중심 아키텍처
```
Grid (View) ↔ Dataset (Model)
```
- Grid는 형태만 제공, 데이터는 Dataset이 관리
- **풀 바인딩:** Grid 동작이 Dataset에 즉시 반영
- 장점: 데이터와 UI 완전 분리

### 2. 엔터프라이즈 기능 중심
- 필터링, 검색, 정렬 등 기본 제공
- 틀 고정, 다중 헤더 등 복잡한 레이아웃
- 대용량 데이터 처리 최적화

### 3. 개발 도구 통합
- Grid Editor (WYSIWYG)
- QuickView (Ctrl + F6) 실시간 미리보기
- Dataset Editor (드래그 앤 드롭 바인딩)

---

## 📋 LiveView Grid에 적용할 핵심 기능 (우선순위)

### Phase 1 (기본) - v0.2
- [x] Dataset 바인딩 개념 → LiveView assigns
- [ ] filter (조건 표현식)
- [ ] findRow/findRowExpr (검색)
- [ ] selecttype (다중 선택)

### Phase 2 (레이아웃) - v0.3
- [ ] fixedcol (틀 고정)
- [ ] autofittype (자동 높이)
- [ ] wordWrap (줄 바꿈)
- [ ] 다중 헤더

### Phase 3 (편집) - v0.4
- [ ] addRow/deleteRow (CRUD)
- [ ] deleteMultiRows (다중 삭제)
- [ ] applyChange/reset (Undo/Redo)

### Phase 4 (응용) - v0.5
- [ ] appendData (Dataset 병합)
- [ ] getRowType (행 상태)
- [ ] moveRow (행 이동)
- [ ] Smart Scroll

---

## 🌍 넥사크로의 차별점

### 1. 한국 시장 특화
- 공공기관/금융권 요구사항 반영
- 한글 문서 완비
- 국내 기술 지원

### 2. 플랫폼 통합
- Grid는 넥사크로 플랫폼의 일부
- Form, Application, Dataset 등과 통합
- 원스톱 솔루션

### 3. ActiveX 대체
- 웹 표준 기반 (HTML5)
- 크로스 브라우저 지원
- 모바일 지원

---

## 📚 참고 문서

### 넥사크로 공식 문서
- **컴포넌트 활용 워크북**: https://docs.tobesoft.com/developer_guide_nexacro_17_ko/ccdb97b19fa824d8
- **개발도구 가이드**: https://docs.tobesoft.com/
- **API Reference**: 넥사크로 스튜디오 내장

### LiveView Grid 개발 가이드
- **DEVELOPMENT.md** - 독자 개발 원칙
- **toastgrid_function.md** - Toast UI Grid 기능 분석
- **README.md** - 프로젝트 소개

---

## 💡 LiveView Grid 설계 인사이트

### 1. Dataset 개념 → LiveView assigns
```elixir
# 넥사크로
Grid.binddataset = "Dataset00"

# LiveView Grid
assign(socket, :grid_data, data)
assign(socket, :grid_columns, columns)
```

### 2. 필터링 → Elixir Enum
```elixir
# 넥사크로
Dataset.filter("dept == 'Sales'")

# LiveView Grid
Enum.filter(data, fn row -> row.dept == "Sales" end)
```

### 3. Full Binding → LiveView 상태 동기화
```elixir
# Grid 클릭 → rowposition 변경
def handle_event("select_row", %{"row_id" => id}, socket) do
  {:noreply, assign(socket, :selected_row_id, id)}
end
```

### 4. 틀 고정 → CSS Grid/Flexbox
```css
.grid-container {
  display: grid;
  grid-template-columns: 200px 1fr; /* 왼쪽 고정 */
}
```

---

**분석 결과:**  
넥사크로 Grid는 **Dataset 중심 아키텍처**와 **엔터프라이즈 기능**에 특화되어 있습니다.  
LiveView Grid는 이 **아이디어**를 참고하되, Phoenix LiveView의 **실시간 동기화 강점**을 살려 독자적으로 구현할 수 있습니다.

**핵심 차별점:**
- 넥사크로 = 클라이언트 사이드 (JavaScript)
- LiveView Grid = 서버 사이드 (Elixir) + WebSocket

🐾
