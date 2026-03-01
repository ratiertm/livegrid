/**
 * FA-019: DatePicker Hook
 * Date 타입 셀 편집 시 커스텀 캘린더 UI를 표시한다.
 */
const DatePickerHook = {
  mounted() {
    this.input = this.el.querySelector('input[type="date"], input[type="text"]');
    if (!this.input) return;

    this.picker = null;
    this.currentDate = this.input.value ? new Date(this.input.value + 'T00:00:00') : new Date();

    // 캘린더 생성
    this.createPicker();

    // 외부 클릭 감지
    this._outsideClick = (e) => {
      if (this.picker && !this.el.contains(e.target) && !this.picker.contains(e.target)) {
        this.closePicker();
      }
    };
    document.addEventListener('click', this._outsideClick);

    // ESC 키 감지
    this._escHandler = (e) => {
      if (e.key === 'Escape' && this.picker) {
        this.closePicker();
      }
    };
    document.addEventListener('keydown', this._escHandler);
  },

  destroyed() {
    if (this._outsideClick) document.removeEventListener('click', this._outsideClick);
    if (this._escHandler) document.removeEventListener('keydown', this._escHandler);
    this.closePicker();
  },

  createPicker() {
    this.picker = document.createElement('div');
    this.picker.className = 'lv-grid__date-picker';
    this.renderCalendar();

    // 위치 결정
    const rect = this.el.getBoundingClientRect();
    this.picker.style.position = 'fixed';
    this.picker.style.left = `${rect.left}px`;
    this.picker.style.top = `${rect.bottom + 2}px`;
    this.picker.style.zIndex = '10000';

    document.body.appendChild(this.picker);
  },

  renderCalendar() {
    if (!this.picker) return;

    const year = this.currentDate.getFullYear();
    const month = this.currentDate.getMonth();
    const today = new Date();
    const selectedStr = this.input.value;

    const monthNames = ['1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'];
    const dayNames = ['일', '월', '화', '수', '목', '금', '토'];

    // 해당 월의 첫 날과 마지막 날
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const startDayOfWeek = firstDay.getDay();

    let html = `
      <div class="lv-grid__date-picker-header">
        <button class="lv-grid__date-picker-nav" data-action="prev-month">&lt;</button>
        <span class="lv-grid__date-picker-title">${year}년 ${monthNames[month]}</span>
        <button class="lv-grid__date-picker-nav" data-action="next-month">&gt;</button>
      </div>
      <div class="lv-grid__date-picker-days">
        ${dayNames.map(d => `<span class="lv-grid__date-picker-dayname">${d}</span>`).join('')}
    `;

    // 빈 칸 채우기
    for (let i = 0; i < startDayOfWeek; i++) {
      html += '<span class="lv-grid__date-picker-day lv-grid__date-picker-day--empty"></span>';
    }

    // 날짜 채우기
    for (let d = 1; d <= lastDay.getDate(); d++) {
      const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      const isToday = today.getFullYear() === year && today.getMonth() === month && today.getDate() === d;
      const isSelected = dateStr === selectedStr;

      let cls = 'lv-grid__date-picker-day';
      if (isToday) cls += ' lv-grid__date-picker-day--today';
      if (isSelected) cls += ' lv-grid__date-picker-day--selected';

      html += `<span class="${cls}" data-date="${dateStr}">${d}</span>`;
    }

    html += '</div>';
    html += '<div class="lv-grid__date-picker-footer">';
    html += '<button class="lv-grid__date-picker-today" data-action="today">오늘</button>';
    html += '<button class="lv-grid__date-picker-clear" data-action="clear">초기화</button>';
    html += '</div>';

    this.picker.innerHTML = html;

    // 이벤트 바인딩
    this.picker.querySelectorAll('[data-date]').forEach(el => {
      el.addEventListener('click', (e) => {
        const date = e.target.dataset.date;
        this.selectDate(date);
      });
    });

    this.picker.querySelectorAll('[data-action]').forEach(el => {
      el.addEventListener('click', (e) => {
        const action = e.target.dataset.action;
        if (action === 'prev-month') {
          this.currentDate.setMonth(this.currentDate.getMonth() - 1);
          this.renderCalendar();
        } else if (action === 'next-month') {
          this.currentDate.setMonth(this.currentDate.getMonth() + 1);
          this.renderCalendar();
        } else if (action === 'today') {
          const t = new Date();
          this.selectDate(`${t.getFullYear()}-${String(t.getMonth() + 1).padStart(2, '0')}-${String(t.getDate()).padStart(2, '0')}`);
        } else if (action === 'clear') {
          this.selectDate('');
        }
      });
    });
  },

  selectDate(dateStr) {
    if (this.input) {
      this.input.value = dateStr;
      // LiveView에 변경 통지
      this.input.dispatchEvent(new Event('input', { bubbles: true }));
      this.input.dispatchEvent(new Event('change', { bubbles: true }));
    }
    this.closePicker();
  },

  closePicker() {
    if (this.picker && this.picker.parentNode) {
      this.picker.parentNode.removeChild(this.picker);
    }
    this.picker = null;
  }
};

export default DatePickerHook;
