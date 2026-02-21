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

Grid 레이아웃 기능은 Grid의 시각적 구성을 제어합니다. 셀 크기 조절, 틀 고정, 다중 헤더, 자동 줄 바꿈 등 14가지 핵심 기능을 제공합니다.

---

### 2.1 Cell 크기 조절하기 (Row 크기 일괄 조절)

**개요:**  
Grid의 모든 Row 높이를 일괄적으로 조절합니다. Excel처럼 셀 크기를 마우스 드래그로 변경할 수 있습니다.

**핵심 속성:** `cellsizingtype`

**값:**
- `none` (기본값) - 크기 변경 불가
- `col` - 컬럼 너비만 변경 가능
- `row` - 행 높이만 변경 가능
- `both` - 너비/높이 모두 변경 가능

**특징:**
- 한 행의 높이를 변경하면 **모든 행에 동일하게 적용**
- 행별로 높이를 따로 조절하려면 → `extendsizetype` 사용 (23.2 참조)

**예시:**
```javascript
this.Grid00.set_cellsizingtype("both"); // 너비/높이 모두 조절 가능
```

---

### 2.2 Cell 크기 조절하기 (특정 Row 크기 조절)

**개요:**  
각 Row별로 높이를 개별적으로 조절합니다.

**핵심 속성:** `extendsizetype`

**값:**
- `none` (기본값) - 모든 행 높이 동일 적용
- `row` - 각 행별로 높이 개별 설정 가능

**사용 예시:**
```javascript
this.Grid00.set_cellsizingtype("both");
this.Grid00.set_extendsizetype("row");
```

**효과:** 각 행의 경계를 드래그하면 해당 행만 높이 변경

---

### 2.3 다중 헤드와 다중 레코드 표현하기

**개요:**  
헤더를 여러 행으로, 레코드를 여러 행으로 표현하여 화면 공간을 효율적으로 활용합니다.

**Band 구조:**
```
head → row (다중 헤드 가능)
body → row (다중 레코드 가능)
summary → row
```

**다중 헤드 예시:**
```
+-------------------+-------------------+
| Name              | Score             |
+------+------------+------+------------+
| Eng  | Korean     | Math | Science   |
+------+------------+------+------------+
```

**구현 방법:**
1. Grid Contents Editor 열기 (Grid 더블클릭)
2. Add Head Row/Add Body Row 버튼으로 행 추가
3. 셀 병합 (Merge Cells 버튼)
4. 각 셀의 text 속성 설정

**활용:** 가로 너비가 좁을 때 정보를 세로로 배치

---

### 2.4 자동 줄 바꿈과 자동 Cell 크기 조절하기

**개요:**  
데이터가 셀 너비보다 길 때 자동으로 줄 바꿈하고, 높이를 자동 조절합니다.

**핵심 속성:**

**1) wordwrap** (Cell 속성)
- `none` (기본값) - 줄 바꿈 없음
- `char` - 글자 단위 줄 바꿈
- `english` - 단어 단위 줄 바꿈 (영어만 해당)

**2) autosizingtype** (Grid 속성)
- `none` (기본값) - 크기 고정
- `col` - 컬럼 너비 자동 조절
- `row` - 행 높이 자동 조절
- `both` - 너비/높이 모두 자동 조절

**조합 예시:**
```javascript
// Grid 속성
this.Grid00.set_autosizingtype("row");

// Cell 속성 (Grid Contents Editor)
wordWrap = "char"
```

**효과:** 긴 텍스트가 잘리지 않고 자동으로 줄 바꿈 + 높이 확장

---

### 2.5 Head Column에 여러 줄 입력하기

**개요:**  
헤더 텍스트를 여러 줄로 입력하여 가로 공간 절약

**방법 1:** `\n` (줄 바꿈 문자)
```javascript
text = "Address\nCountry"
```

**방법 2:** Grid Contents Editor에서 직접 입력
- text 속성 편집 창에서 `Ctrl+Enter`로 줄 바꿈
- 예시:
  ```
  Address, [Ctrl+Enter]
  Country [Enter]
  ```

**활용:** 긴 헤더 이름을 여러 줄로 나눠 컬럼 너비 감소

---

### 2.6 틀 고정하기 - Column

**개요:**  
왼쪽/오른쪽 컬럼을 고정하여 스크롤 시에도 화면에 유지합니다. Excel의 틀 고정과 동일합니다.

**핵심 속성:** `band` (Column 속성)

**값:**
- `left` - 왼쪽 고정 영역
- `body` (기본값) - 스크롤 영역
- `right` - 오른쪽 고정 영역

**설정 방법:**
```javascript
// 스크립트
this.Grid00.setFormatColProperty(0, "band", "left");

// Grid Contents Editor
// Column 선택 → Properties → band = "left"
```

**Band 구조:**
```
+------+-------------------+-------+
| left |  body (스크롤)     | right |
+------+-------------------+-------+
```

**활용:** 중요 컬럼(ID, 이름 등)을 고정하고 나머지만 스크롤

---

### 2.7 틀 고정하기 - Row

**개요:**  
상단(head)/하단(summary) 행을 고정합니다.

**핵심 개념:**  
- `head` 밴드: 컬럼 이름 표시용 (틀 고정 용도 X)
- `summary` 밴드: 합계/평균/최대/최소값 등 집계 표시 (틀 고정 용도 ✅)

**Band 구조:**
```
+-------------------+
| head (고정)       |
+-------------------+
| body (스크롤)     |
+-------------------+
| summary (고정)    |
+-------------------+
```

**Summary Row 추가:**
1. Grid Contents Editor에서 Add Summary Row 버튼 클릭
2. 각 Cell의 expr 속성 설정
   ```javascript
   expr = "dataset.getAvg('parseInt(Salary)')"
   expr = "dataset.getMax('parseInt(Salary)')"
   expr = "dataset.getMin('parseInt(Salary)')"
   ```

**활용:** 하단에 집계 정보를 고정 표시

---

### 2.8 Column 위치 이동하기

**개요:**  
런타임에 컬럼 헤더를 드래그하여 위치 변경

**핵심 속성:** `enableeditshift`

**설정:**
```javascript
this.Grid00.set_enableeditshift(true);
```

**사용법:** 컬럼 헤더를 마우스로 드래그 앤 드롭

---

### 2.9 변경된 Column 상태의 포맷 복사하기

**개요:**  
사용자가 변경한 컬럼 순서/너비를 문자열로 저장하여 재사용

**핵심 메서드:** `getCurFormatString`

**사용법:**
```javascript
var sFormat = this.Grid00.getCurFormatString();
// sFormat을 서버/로컬스토리지에 저장

// 나중에 복원
this.Grid00.set_formatid(sFormat);
```

**활용:** 사용자 맞춤 레이아웃 저장/복원

---

### 2.10 포맷 정보 확인하기

**개요:**  
Grid의 현재 포맷(행/열 수, 속성) 조회

**핵심 메서드:**

**1) getFormatRowCount** - 포맷 행 수
```javascript
var nRowCnt = this.Grid00.getFormatRowCount();
```

**2) getFormatColCount** - 포맷 컬럼 수
```javascript
var nColCnt = this.Grid00.getFormatColCount();
```

**3) getFormatRowProperty** - 행 속성 조회
```javascript
var strBand = this.Grid00.getFormatRowProperty(1, "band");
```

**4) getFormatColProperty** - 컬럼 속성 조회
```javascript
var strBand = this.Grid00.getFormatColProperty(0, "band");
```

---

### 2.11 틀 고정하기 - 선택한 Column

**개요:**  
사용자가 클릭한 컬럼까지 동적으로 틀 고정

**구현:**
```javascript
// oncellclick 이벤트에서
var nColIndex = e.col;
this.Grid00.set_fixedcol("left:" + (nColIndex + 1));
```

**활용:** 사용자가 원하는 만큼만 고정

---

### 2.12 컬럼 크기 조정 기능 제한하기

**개요:**  
특정 컬럼의 크기 조정을 막음

**핵심 속성:** `autowidth`

**값:**
- `none` (기본값) - 수동 조정 가능
- `default` - 컬럼 너비 고정 (조정 불가)

**활용:** 고정폭 컬럼(체크박스, 아이콘 등)에 적용

---

### 2.13 병합된 Head 영역의 컬럼 타이틀 텍스트 구하기

**핵심 메서드:** `getCellProperty`

**사용법:**
```javascript
var sText = this.Grid00.getCellProperty("head", nRow, nCol, "text");
```

**활용:** 다중 헤더에서 특정 셀의 제목 가져오기

---

### 2.14 병합된 셀의 자식셀 속성 지정하기

**개요:**  
병합된 셀의 자식 셀에 개별 속성 적용

**특징:**
- 병합 셀은 기본적으로 부모 셀 속성 상속
- 자식 셀의 속성을 개별적으로 변경 가능

**방법:** Grid Contents Editor에서 자식 셀 선택 후 속성 변경

---

## 3. Grid 셀 기능 (24장)

Grid 셀 기능은 데이터 표시/편집 방식과 스타일, 이벤트 처리를 다룹니다. **40개 섹션**으로 구성되어 있으며, 주제별로 그룹화하면 다음과 같습니다.

---

### 3.1 포맷 관리

**핵심 속성:**
- `formatid` - 적용할 포맷 ID (다중 포맷 지원)
- `createFormat()` - Dataset 구조 기반 포맷 자동 생성

**활용:** 같은 Grid에 상황별로 다른 레이아웃 적용

---

### 3.2 셀 표시 (displaytype)

**표시 타입 종류:**
- **텍스트**: `normal`, `text`, `currency`, `date`, `number`, `mask`
- **컨트롤**: `button`, `checkbox`, `combo`, `image`, `progressbarcontrol`
- **트리**: `treeitemcontrol`

**설정 예시:**
```javascript
// 화폐 형식
displaytype = "currency"

// 콤보박스
displaytype = "combocontrol"
combodataset = "ds_combo"
combocodecol = "code"
combodatacol = "name"

// 트리
displaytype = "treeitemcontrol"
treelevel = "bind:level"
```

**활용:** 데이터 타입에 맞는 시각화

---

### 3.3 셀 편집 (edittype)

**편집 타입 종류:**
- **텍스트**: `text`, `textarea`, `mask`, `readonly`
- **컨트롤**: `date`, `combo`, `checkbox`, `button`
- **트리**: `tree`

**자동 편집 모드:**
```javascript
// Grid 속성
autoenter = "select"  // 셀 선택 시 즉시 편집 모드
```

**활용:** 사용자 입력 방식 제어

---

### 3.4 그룹화/정렬 (Dataset 기반)

**그룹화 (keystring):**
```javascript
Dataset.set_keystring("G:+Company");  // Company 기준 오름차순 그룹화
```

**정렬:**
```javascript
Dataset.keystring = "S:-Salary";  // Salary 기준 내림차순 정렬
```

**복합:**
```javascript
Dataset.keystring = "G:+Company,S:-Salary";  // 그룹 + 정렬
```

---

### 3.5 Suppress (중복 셀 병합)

**개요:** 같은 값을 가진 셀을 하나로 병합하여 표시

**설정:**
```javascript
// Cell 속성
suppress = 1  // 바로 위 셀과 비교
```

**활용:** 그룹화된 데이터에서 키 컬럼 병합

---

### 3.6 셀 병합 (Merge)

**방법:**
- **디자인 타임**: Grid Contents Editor에서 셀 선택 → Merge Cells
- **런타임**: `setCellProperty()` 사용

**활용:** 헤더 병합, 요약 행 생성

---

### 3.7 조건부 스타일 (cssclass + expr)

**동적 스타일 적용:**
```javascript
// Cell 속성
cssclass = "expr:dataset.getRowLevel(currow)==1?'subtotal':''"
```

**XCSS 파일:**
```css
.Grid .body .row .cell.subtotal {
  background: #f0f0f0;
  font: bold 12px Arial;
}
```

**활용:** 소계 행, 음수 빨간색 표시 등

---

### 3.8 expr (수식) 사용

**기본 구조:**
```javascript
// Cell의 text 값 계산
expr = "dataset.getSum('parseInt(Salary)')"
```

**expr 전용 변수:**
- `currow` - 현재 행 인덱스
- `curcol` - 현재 열 인덱스
- `dataset` - 바인딩된 Dataset 객체

**예시:**
```javascript
// 행 번호 표시
expr = "currow + 1"

// 조건부 텍스트
expr = "Salary > 50000 ? 'High' : 'Low'"

// Dataset 메서드 호출
expr = "dataset.getRowLevel(currow) == 1 ? 'SUBTOTAL' : Company"
```

---

### 3.9 기타 셀 고급 기능

**40개 섹션 주요 주제:**
1. URL 링크 클릭 처리 (oncellclick)
2. 데이터 변경 시 셀 색상 변경
3. 특정 Row 깜빡임 효과 (setInterval)
4. 문자열 길이 표시/제한
5. 마스크 패턴 적용
6. 편집 중인 값 가져오기
7. 트리 padding 적용
8. 체크박스 병합
9. 행번호 자동 표시
10. 서브셀 속성 제어

---

## 4. Grid 응용 기능 (25장)

Grid 응용 기능은 실무에서 자주 사용하는 고급 패턴을 다룹니다. **32개 섹션**으로 구성되어 있습니다.

---

### 4.1 Excel/클립보드 연동

**Grid → Excel 복사:**
```javascript
// onkeydown 이벤트
if (e.ctrlkey && e.keycode == 67) {  // Ctrl+C
  var data = makeGridData(obj);  // 선택 영역 데이터 추출
  system.setClipboard("CF_TEXT", data);  // 클립보드에 복사
}
```

**데이터 추출:**
```javascript
function makeGridData(grid) {
  var result = "";
  for (var i = grid.selectstartrow; i <= grid.selectendrow; i++) {
    for (var j = grid.selectstartcol; j <= grid.selectendcol; j++) {
      result += grid.getCellText(i, j) + "\t";
    }
    result += "\r\n";
  }
  return result;
}
```

---

### 4.2 합계/소계 구하기

**합계 (Summary 밴드):**
```javascript
// Cell expr
expr = "dataset.getSum('parseInt(Salary)')"
displaytype = "currency"
```

**소계 (Dataset 그룹화):**
```javascript
// Dataset 설정
Dataset.keystring = "G:+Company";  // Company 기준 그룹화

// Column 설정 (Dataset Editor)
Salary.prop = "SUM";  // 소계 계산 타입
```

**소계 스타일링:**
```javascript
// Cell cssclass
cssclass = "expr:dataset.getRowLevel(currow)==1?'subtotal':''"
```

---

### 4.3 트리 그리드

**트리 설정:**
```javascript
// Grid 속성
treeusecheckbox = false  // 체크박스 숨김

// Cell 속성 (Label 컬럼)
displaytype = "treeitemcontrol"
edittype = "tree"
treelevel = "bind:Level"  // 레벨 컬럼 바인딩
textAlign = "left"
```

**트리 편집 가능하게:**
```javascript
// oncelldblclick 이벤트
Grid.setCellProperty("body", e.cell, "edittype", "text");
Grid.setCellPos(e.cell);
```

---

### 4.4 헤더 클릭 정렬

**구현:**
```javascript
// onheadclick 이벤트
function Grid_onheadclick(obj, e) {
  var colid = obj.getCellProperty("body", e.cell, "text");
  
  // 현재 정렬 상태 확인
  if (gv_sortType == "ASC") {
    Dataset.keystring = "S:-" + colid;
    gv_sortType = "DESC";
  } else {
    Dataset.keystring = "S:+" + colid;
    gv_sortType = "ASC";
  }
}
```

---

### 4.5 전체 선택/해제 (CheckBox)

**헤더 체크박스:**
```javascript
// Head 밴드 Cell
displaytype = "checkboxcontrol"
text = "0"  // 0=미선택, 1=선택

// onheadclick 이벤트
function Grid_onheadclick(obj, e) {
  var checked = obj.getCellProperty("head", 0, e.cell, "text");
  var newValue = (checked == "0") ? "1" : "0";
  
  // 모든 행 체크 상태 변경
  for (var i = 0; i < Dataset.rowcount; i++) {
    Dataset.setColumn(i, "chk", newValue);
  }
  
  // 헤더 체크박스 상태 변경
  obj.setCellProperty("head", 0, e.cell, "text", newValue);
}
```

---

### 4.6 페이징 처리

**기본 개념:**
```javascript
var pageSize = 10;  // 페이지당 행 수
var currentPage = 1;

function loadPage(page) {
  var start = (page - 1) * pageSize;
  var end = start + pageSize;
  
  // Dataset 필터링
  Dataset.filter("idx >= " + start + " && idx < " + end);
}
```

**마우스 휠 페이징:**
```javascript
// onmousewheel 이벤트
function Grid_onmousewheel(obj, e) {
  if (e.wheelDelta < 0) {
    nextPage();  // 아래로 스크롤 → 다음 페이지
  } else {
    prevPage();  // 위로 스크롤 → 이전 페이지
  }
  return false;  // 기본 스크롤 차단
}
```

---

### 4.7 동적 Grid 생성

**런타임 생성:**
```javascript
// Grid 생성
var grid = new Grid("Grid00", 10, 10, 500, 300);
this.addChild("Grid00", grid);
grid.show();

// Dataset 바인딩
grid.set_binddataset("Dataset00");
grid.createFormat();  // 포맷 자동 생성
```

---

### 4.8 드래그 앤 드롭

**구현:**
```javascript
// ondrag 이벤트
function Grid_ondrag(obj, e) {
  return obj.getCellText(e.row, e.cell);  // 드래그 데이터
}

// ondrop 이벤트
function Grid_ondrop(obj, e) {
  obj.setCellText(e.row, e.cell, e.dragdata);  // 드롭 위치에 설정
}
```

---

### 4.9 두 Grid 스크롤 동기화

**구현:**
```javascript
// Grid00의 onvscroll 이벤트
function Grid00_onvscroll(obj, e) {
  Grid01.setVScrollPos(e.pos);  // Grid01 스크롤 위치 동기화
}

// Grid01의 onvscroll 이벤트
function Grid01_onvscroll(obj, e) {
  Grid00.setVScrollPos(e.pos);
}
```

---

### 4.10 기타 응용 기능

**32개 섹션 주요 주제:**
1. Like 조건 검색 (`Dataset.filter("Name like '%Kim%'")`)
2. 중복 항목 제거
3. Radio 버튼 표현
4. 세계 시간 표시
5. PopupDiv 테두리선 표현
6. 트리 구조 자식 정보 확인
7. Null 값 정렬 우선순위
8. 데이터 너비에 맞춰 컬럼 자동 조절
9. 특정 Grid만 합계 행 추가
10. 선택 영역 합계 표시
11. 클릭한 셀 강조
12. 달력 형태 일정표 만들기

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
