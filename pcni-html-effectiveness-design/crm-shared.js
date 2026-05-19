// CRM Shared Utilities
// Modal system, table selection, filtering, notifications, global search

const CRMModal = {
  open(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.style.display = 'flex';
      document.body.style.overflow = 'hidden';
    }
  },

  close(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.style.display = 'none';
      document.body.style.overflow = 'auto';
    }
  }
};

const TableSelection = {
  selectedIds: new Set(),

  toggleRow(rowElement, id) {
    const checkbox = rowElement.querySelector('input[type="checkbox"]');
    if (this.selectedIds.has(id)) {
      this.selectedIds.delete(id);
      checkbox.checked = false;
      rowElement.classList.remove('selected');
    } else {
      this.selectedIds.add(id);
      checkbox.checked = true;
      rowElement.classList.add('selected');
    }
    this.updateBulkActionBar();
  },

  toggleAll(allCheckbox) {
    const rows = document.querySelectorAll('tbody tr');
    if (allCheckbox.checked) {
      rows.forEach(row => {
        const id = row.dataset.id;
        this.selectedIds.add(id);
        row.classList.add('selected');
        row.querySelector('input[type="checkbox"]').checked = true;
      });
    } else {
      rows.forEach(row => {
        const id = row.dataset.id;
        this.selectedIds.delete(id);
        row.classList.remove('selected');
        row.querySelector('input[type="checkbox"]').checked = false;
      });
    }
    this.updateBulkActionBar();
  },

  getSelectedIds() {
    return Array.from(this.selectedIds);
  },

  updateBulkActionBar() {
    const bar = document.querySelector('.bulk-action-bar');
    const count = this.selectedIds.size;
    if (bar) {
      if (count > 0) {
        bar.style.display = 'flex';
        const countEl = bar.querySelector('.action-count');
        if (countEl) {
          countEl.textContent = `${count} selected`;
        }
      } else {
        bar.style.display = 'none';
      }
    }
  }
};

const FilterSystem = {
  activeFilters: {},

  applyFilters(filterObj) {
    this.activeFilters = filterObj;
    const rows = document.querySelectorAll('tbody tr');
    rows.forEach(row => {
      if (this.rowMatchesFilters(row)) {
        row.style.display = '';
      } else {
        row.style.display = 'none';
      }
    });
  },

  getActiveFilters() {
    return this.activeFilters;
  },

  rowMatchesFilters(row) {
    for (const [key, value] of Object.entries(this.activeFilters)) {
      if (!value) continue;

      if (key === 'status') {
        const statusEl = row.querySelector(`[data-status]`);
        if (!statusEl || statusEl.dataset.status !== value) return false;
      } else if (key === 'priority') {
        const priorityEl = row.querySelector(`[data-priority]`);
        if (!priorityEl || priorityEl.dataset.priority !== value) return false;
      } else if (key === 'risk') {
        const riskEl = row.querySelector(`[data-risk]`);
        if (!riskEl || riskEl.dataset.risk !== value) return false;
      } else if (key === 'minCredit') {
        const creditEl = row.querySelector(`[data-credit]`);
        const score = parseInt(creditEl?.textContent || 0);
        if (score < value) return false;
      } else if (key === 'maxCredit') {
        const creditEl = row.querySelector(`[data-credit]`);
        const score = parseInt(creditEl?.textContent || 0);
        if (score > value) return false;
      }
    }
    return true;
  }
};

const Notifications = {
  container: null,

  createContainer() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'notification-container';
      document.body.appendChild(this.container);
    }
    return this.container;
  },

  show(message, type = 'info', duration = 3000) {
    const container = this.createContainer();
    const toast = document.createElement('div');
    toast.className = `notification notification-${type}`;
    toast.innerHTML = `
      <div class="notification-content">${message}</div>
      <button class="notification-close" onclick="this.parentElement.remove();">×</button>
    `;
    container.appendChild(toast);

    if (duration > 0) {
      setTimeout(() => toast.remove(), duration);
    }
  }
};

const GlobalSearch = {
  search(query, dataSource) {
    if (!query.trim()) return dataSource;

    const q = query.toLowerCase();
    return dataSource.filter(item => {
      return Object.values(item).some(val =>
        String(val).toLowerCase().includes(q)
      );
    });
  }
};
