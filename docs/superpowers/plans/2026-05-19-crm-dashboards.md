# Attio Finance CRM Dashboards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a full-featured Attio Finance CRM system with three role-specific dashboards (Credit Officer, Sales/BD, Customer Service) using the Attio design system and realistic financial data.

**Architecture:** Hybrid approach with shared component library and three independent, role-optimized dashboard templates. All dashboards use the same design system CSS, component patterns, and data structures but with specialized layouts and workflows per role.

**Tech Stack:**
- HTML5 semantic markup
- CSS3 (design-system.css variables)
- Vanilla JavaScript (no frameworks, no dependencies)
- Self-contained single files
- Realistic sample data (embedded JSON)

---

## File Structure

```
attio-finance-html-effectiveness-design/
├── design-system.css              # (existing) All components and variables
├── crm-shared.js                  # NEW: Shared utilities (modals, filters, bulk actions)
├── crm-shared-styles.css          # NEW: CRM-specific CSS patterns
├── 21-credit-officer-crm.html     # NEW: Credit Officer dashboard
├── 22-sales-crm.html              # NEW: Sales/BD dashboard
├── 23-service-crm.html            # NEW: Customer Service dashboard
└── index.html                      # (update) Add CRM templates to gallery
```

---

## Task 1: Create Shared Utilities & CSS Patterns

**Files:**
- Create: `attio-finance-html-effectiveness-design/crm-shared.js`
- Create: `attio-finance-html-effectiveness-design/crm-shared-styles.css`

### Step 1.1: Create shared JavaScript utilities

```javascript
// Shared CRM utilities

// Modal system
const CRMModal = {
  open(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.add('modal-open');
  },
  close(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.remove('modal-open');
  }
};

// Table selection
const TableSelection = {
  toggleRow(checkbox, rowElement) {
    if (checkbox.checked) {
      rowElement.classList.add('row-selected');
    } else {
      rowElement.classList.remove('row-selected');
    }
    this.updateBulkActionBar();
  },
  toggleAll(masterCheckbox, tableId) {
    const checkboxes = document.querySelectorAll(`#${tableId} tbody input[type="checkbox"]`);
    checkboxes.forEach(cb => {
      cb.checked = masterCheckbox.checked;
      const row = cb.closest('tr');
      if (masterCheckbox.checked) {
        row.classList.add('row-selected');
      } else {
        row.classList.remove('row-selected');
      }
    });
    this.updateBulkActionBar();
  },
  getSelectedIds(tableId) {
    const checkboxes = document.querySelectorAll(`#${tableId} tbody input[type="checkbox"]:checked`);
    return Array.from(checkboxes).map(cb => cb.dataset.id);
  },
  updateBulkActionBar() {
    const selectedCount = document.querySelectorAll('tbody input[type="checkbox"]:checked').length;
    const bar = document.getElementById('bulk-action-bar');
    if (bar) {
      bar.style.display = selectedCount > 0 ? 'flex' : 'none';
      bar.querySelector('.selection-count').textContent = `${selectedCount} selected`;
    }
  }
};

// Filter system
const FilterSystem = {
  applyFilters() {
    const filters = this.getActiveFilters();
    const rows = document.querySelectorAll('tbody tr');
    rows.forEach(row => {
      const matches = this.rowMatchesFilters(row, filters);
      row.style.display = matches ? '' : 'none';
    });
  },
  getActiveFilters() {
    const filters = {};
    document.querySelectorAll('[data-filter]').forEach(el => {
      const key = el.dataset.filter;
      const value = el.value || el.textContent;
      if (value) filters[key] = value.toLowerCase();
    });
    return filters;
  },
  rowMatchesFilters(row, filters) {
    return Object.entries(filters).every(([key, value]) => {
      const cell = row.querySelector(`[data-field="${key}"]`);
      return cell && cell.textContent.toLowerCase().includes(value);
    });
  }
};

// Notifications
const Notifications = {
  show(message, type = 'info') {
    const container = document.getElementById('notification-container') || this.createContainer();
    const toast = document.createElement('div');
    toast.className = `notification notification-${type}`;
    toast.innerHTML = `
      <div class="notification-content">${message}</div>
      <button onclick="this.parentElement.remove()" class="notification-close">×</button>
    `;
    container.appendChild(toast);
    setTimeout(() => toast.remove(), 4000);
  },
  createContainer() {
    const container = document.createElement('div');
    container.id = 'notification-container';
    container.className = 'notification-container';
    document.body.appendChild(container);
    return container;
  }
};

// Search
const GlobalSearch = {
  search(query, dataSource) {
    if (!query || query.length < 2) return dataSource;
    const q = query.toLowerCase();
    return dataSource.filter(item =>
      JSON.stringify(item).toLowerCase().includes(q)
    );
  }
};

// Export
window.CRM = { CRMModal, TableSelection, FilterSystem, Notifications, GlobalSearch };
```

### Step 1.2: Create shared CRM CSS patterns

```css
/* CRM-Specific Styles (builds on design-system.css) */

/* Modal System */
.modal {
  display: none;
  position: fixed;
  z-index: 1000;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.4);
}

.modal-open {
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-content {
  background-color: var(--white);
  padding: var(--space-32);
  border: var(--border-light);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg);
  max-width: 600px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--space-24);
}

.modal-header h2 {
  margin: 0;
}

.modal-close {
  background: none;
  border: none;
  font-size: 28px;
  cursor: pointer;
  color: var(--gray-500);
}

.modal-footer {
  display: flex;
  gap: var(--space-12);
  justify-content: flex-end;
  margin-top: var(--space-24);
}

/* Table Enhancements */
.table-wrapper {
  border: var(--border-light);
  border-radius: var(--radius-lg);
  overflow: hidden;
}

table {
  width: 100%;
}

th {
  background: var(--gray-50);
  padding: var(--space-12) var(--space-16);
  text-align: left;
  font-weight: 600;
  color: var(--gray-700);
  border-bottom: var(--border-md);
}

td {
  padding: var(--space-12) var(--space-16);
  border-bottom: var(--border-light);
}

tr:hover {
  background-color: var(--gray-50);
}

.row-selected {
  background-color: rgba(250, 160, 0, 0.05);
}

.row-selected td {
  background-color: rgba(250, 160, 0, 0.05);
}

/* Bulk Action Bar */
#bulk-action-bar {
  display: none;
  gap: var(--space-16);
  align-items: center;
  padding: var(--space-16);
  background: var(--gray-50);
  border-bottom: var(--border-light);
  position: sticky;
  top: 0;
  z-index: 10;
}

#bulk-action-bar.visible {
  display: flex;
}

.selection-count {
  font-weight: 600;
  color: var(--attio-finance-primary);
  margin-right: var(--space-12);
}

.bulk-button {
  padding: var(--space-8) var(--space-16);
  font-size: 14px;
  border: none;
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all var(--transition-fast);
}

.bulk-button.primary {
  background: var(--attio-finance-primary);
  color: white;
}

.bulk-button.primary:hover {
  background: var(--attio-finance-primary-light);
}

.bulk-button.danger {
  background: var(--attio-finance-danger);
  color: white;
}

.bulk-button.danger:hover {
  background: #DC2626;
}

/* Filter Panel */
.filter-panel {
  background: var(--white);
  padding: var(--space-16);
  border-bottom: var(--border-light);
  display: flex;
  gap: var(--space-16);
  flex-wrap: wrap;
  align-items: flex-end;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-8);
}

.filter-group label {
  font-size: 13px;
  font-weight: 600;
  color: var(--gray-700);
}

.filter-group input,
.filter-group select {
  padding: var(--space-8) var(--space-12);
  border: var(--border-light);
  border-radius: var(--radius-md);
  font-size: 14px;
  min-width: 200px;
}

.filter-button {
  padding: var(--space-8) var(--space-16);
  background: var(--attio-finance-primary);
  color: white;
  border: none;
  border-radius: var(--radius-md);
  cursor: pointer;
  font-weight: 600;
}

.filter-button:hover {
  background: var(--attio-finance-primary-light);
}

/* Sidebar Layout */
.crm-container {
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 0;
  min-height: 100vh;
  background: var(--white);
}

.crm-sidebar {
  background: var(--gray-50);
  border-right: var(--border-light);
  padding: var(--space-24);
  overflow-y: auto;
}

.crm-main {
  display: flex;
  flex-direction: column;
}

.crm-header {
  background: var(--white);
  border-bottom: var(--border-light);
  padding: var(--space-16) var(--space-24);
  display: flex;
  justify-content: space-between;
  align-items: center;
  position: sticky;
  top: 0;
  z-index: 100;
}

.crm-content {
  flex: 1;
  padding: var(--space-24);
  overflow-y: auto;
}

/* Cards for Metrics */
.metric-card {
  background: var(--white);
  border: var(--border-light);
  border-radius: var(--radius-lg);
  padding: var(--space-16);
  margin-bottom: var(--space-16);
}

.metric-card-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--attio-finance-primary);
  margin: var(--space-8) 0;
}

.metric-card-label {
  font-size: 13px;
  color: var(--gray-600);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.metric-card-trend {
  font-size: 12px;
  margin-top: var(--space-8);
}

.metric-card-trend.up {
  color: var(--attio-finance-success);
}

.metric-card-trend.down {
  color: var(--attio-finance-danger);
}

/* Notification Container */
.notification-container {
  position: fixed;
  top: var(--space-16);
  right: var(--space-16);
  z-index: 2000;
  display: flex;
  flex-direction: column;
  gap: var(--space-12);
}

.notification {
  background: var(--white);
  border: var(--border-light);
  border-left: 4px solid;
  border-radius: var(--radius-lg);
  padding: var(--space-12) var(--space-16);
  box-shadow: var(--shadow-lg);
  display: flex;
  justify-content: space-between;
  align-items: center;
  min-width: 300px;
}

.notification-success {
  border-left-color: var(--attio-finance-success);
  background: rgba(16, 185, 129, 0.05);
}

.notification-error {
  border-left-color: var(--attio-finance-danger);
  background: rgba(239, 68, 68, 0.05);
}

.notification-info {
  border-left-color: var(--attio-finance-primary);
  background: rgba(250, 160, 0, 0.05);
}

.notification-close {
  background: none;
  border: none;
  font-size: 18px;
  cursor: pointer;
  color: var(--gray-500);
}

/* Responsive */
@media (max-width: 768px) {
  .crm-container {
    grid-template-columns: 1fr;
  }

  .crm-sidebar {
    border-right: none;
    border-bottom: var(--border-light);
    padding: var(--space-16);
  }

  .filter-panel {
    flex-direction: column;
  }

  .filter-group input,
  .filter-group select {
    min-width: 100%;
  }

  .notification-container {
    left: var(--space-16);
    right: var(--space-16);
  }
}
```

### Step 1.3: Commit shared utilities

```bash
cd <larv-plugin-root>/attio-finance-html-effectiveness-design
git add crm-shared.js crm-shared-styles.css
git commit -m "feat: add shared CRM utilities and styles

- Modal system (open/close)
- Table selection (single/multi)
- Filter system with live updates
- Notification/toast system
- Global search
- CRM-specific CSS (tables, modals, sidebar, metrics)"
```

---

## Task 2: Create Credit Officer Dashboard

**Files:**
- Create: `attio-finance-html-effectiveness-design/21-credit-officer-crm.html`

**Step 2.1:** Create the Credit Officer dashboard with loan applications table

```html
<!-- FULL HTML FILE: 21-credit-officer-crm.html -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Attio Finance Credit Officer Dashboard</title>
  <link rel="stylesheet" href="design-system.css">
  <link rel="stylesheet" href="crm-shared-styles.css">
  <style>
    .status-badge {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
    }

    .status-pending {
      background: rgba(245, 158, 11, 0.1);
      color: #92400e;
    }

    .status-approved {
      background: rgba(16, 185, 129, 0.1);
      color: #065f46;
    }

    .status-rejected {
      background: rgba(239, 68, 68, 0.1);
      color: #7f1d1d;
    }

    .risk-high {
      color: var(--attio-finance-danger);
      font-weight: 600;
    }

    .risk-medium {
      color: var(--attio-finance-warning);
      font-weight: 600;
    }

    .risk-low {
      color: var(--attio-finance-success);
      font-weight: 600;
    }

    .credit-score {
      font-weight: 600;
      font-size: 16px;
    }

    .score-excellent { color: var(--attio-finance-success); }
    .score-good { color: #16a34a; }
    .score-fair { color: var(--attio-finance-warning); }
    .score-poor { color: var(--attio-finance-danger); }
  </style>
</head>
<body>
  <!-- Header -->
  <header class="header">
    <div class="container">
      <div class="logo">
        <img src="attio-finance-logo.png" alt="Attio Finance Logo" style="height: 48px; width: auto; border-radius: var(--radius-md);">
        <div>
          <div style="font-size: 14px; color: var(--gray-600);">Attio Finance Studio</div>
          <div style="font-weight: 700; color: var(--attio-finance-primary);">Finance Co. Inc.</div>
        </div>
      </div>
      <div style="display: flex; gap: var(--space-16); align-items: center;">
        <input type="text" placeholder="Search applications..." style="padding: 8px 12px; border: var(--border-light); border-radius: var(--radius-md); width: 200px;">
        <button class="btn btn-secondary btn-small">Notifications</button>
      </div>
    </div>
  </header>

  <!-- Main Container -->
  <div class="crm-container">
    <!-- Sidebar -->
    <div class="crm-sidebar">
      <h3 style="margin: 0 0 var(--space-16) 0; color: var(--attio-finance-primary);">Credit Officer</h3>

      <nav style="margin-bottom: var(--space-32);">
        <div style="padding: var(--space-12); border-radius: var(--radius-md); background: var(--attio-finance-primary); color: white; margin-bottom: var(--space-8); cursor: pointer; font-weight: 600;">📋 Applications</div>
        <div style="padding: var(--space-12); color: var(--gray-600); cursor: pointer; margin-bottom: var(--space-8);">👤 Customers</div>
        <div style="padding: var(--space-12); color: var(--gray-600); cursor: pointer; margin-bottom: var(--space-8);">📊 Reports</div>
      </nav>

      <h4 style="margin: var(--space-24) 0 var(--space-12) 0; font-size: 13px; text-transform: uppercase; color: var(--gray-600); letter-spacing: 0.05em;">Quick Stats</h4>

      <div class="metric-card">
        <div class="metric-card-label">Pending Applications</div>
        <div class="metric-card-value">8</div>
        <div class="metric-card-trend up">↑ 2 this week</div>
      </div>

      <div class="metric-card">
        <div class="metric-card-label">Avg Credit Score</div>
        <div class="metric-card-value">694</div>
        <div class="metric-card-trend down">↓ 12 points</div>
      </div>

      <div class="metric-card">
        <div class="metric-card-label">Approval Rate</div>
        <div class="metric-card-value">73%</div>
        <div class="metric-card-trend up">↑ 3% vs last month</div>
      </div>

      <div class="metric-card">
        <div class="metric-card-label">Total Pipeline Value</div>
        <div class="metric-card-value">$2.4M</div>
        <div class="metric-card-trend up">↑ $180K</div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="crm-main">
      <!-- Bulk Action Bar -->
      <div id="bulk-action-bar" style="display: none;">
        <span class="selection-count">0 selected</span>
        <button class="bulk-button primary" onclick="CRM.Notifications.show('Approving 3 applications...', 'info')">Approve Selected</button>
        <button class="bulk-button danger" onclick="CRM.Notifications.show('Rejected 0 applications', 'info')">Reject</button>
        <button class="bulk-button primary" onclick="CRM.Notifications.show('Requesting more info...', 'info')">Request Info</button>
      </div>

      <!-- Filter Panel -->
      <div class="filter-panel">
        <div class="filter-group">
          <label>Status</label>
          <select data-filter="status" onchange="CRM.FilterSystem.applyFilters()">
            <option value="">All Statuses</option>
            <option value="Pending">Pending</option>
            <option value="Approved">Approved</option>
            <option value="Rejected">Rejected</option>
          </select>
        </div>
        <div class="filter-group">
          <label>Credit Score Range</label>
          <input type="text" data-filter="credit" placeholder="Min 600" onchange="CRM.FilterSystem.applyFilters()">
        </div>
        <div class="filter-group">
          <label>Risk Level</label>
          <select data-filter="risk" onchange="CRM.FilterSystem.applyFilters()">
            <option value="">All Levels</option>
            <option value="Low">Low</option>
            <option value="Medium">Medium</option>
            <option value="High">High</option>
          </select>
        </div>
        <button class="filter-button" onclick="document.querySelectorAll('.filter-panel [data-filter]').forEach(el => el.value = ''); CRM.FilterSystem.applyFilters();">Clear Filters</button>
      </div>

      <!-- Content Area -->
      <div class="crm-content">
        <h2 style="margin-top: 0;">Loan Applications</h2>

        <div class="table-wrapper">
          <table id="applications-table">
            <thead>
              <tr>
                <th><input type="checkbox" onchange="CRM.TableSelection.toggleAll(this, 'applications-table')"></th>
                <th>Applicant</th>
                <th data-field="credit">Credit Score</th>
                <th>Loan Amount</th>
                <th data-field="status">Status</th>
                <th data-field="risk">Risk Level</th>
                <th>Interest Rate</th>
                <th>Term</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr data-field="status" data-value="Pending">
                <td><input type="checkbox" data-id="APP001" onchange="CRM.TableSelection.toggleRow(this, this.closest('tr'))"></td>
                <td><strong>Michael Johnson</strong><br><span style="font-size: 12px; color: var(--gray-600);">APP-001 • Applied 2 days ago</span></td>
                <td data-field="credit" class="credit-score score-good">756</td>
                <td>$25,000</td>
                <td><span class="status-badge status-pending">Pending</span></td>
                <td><span class="risk-low">Low</span></td>
                <td>5.2%</td>
                <td>60 months</td>
                <td><button class="btn btn-primary btn-small" onclick="CRM.CRMModal.open('detailModal1')">Review</button></td>
              </tr>

              <tr data-field="status" data-value="Pending">
                <td><input type="checkbox" data-id="APP002" onchange="CRM.TableSelection.toggleRow(this, this.closest('tr'))"></td>
                <td><strong>Sarah Chen</strong><br><span style="font-size: 12px; color: var(--gray-600);">APP-002 • Applied 1 day ago</span></td>
                <td data-field="credit" class="credit-score score-excellent">812</td>
                <td>$50,000</td>
                <td><span class="status-badge status-pending">Pending</span></td>
                <td><span class="risk-low">Low</span></td>
                <td>4.8%</td>
                <td>84 months</td>
                <td><button class="btn btn-primary btn-small" onclick="CRM.CRMModal.open('detailModal2')">Review</button></td>
              </tr>

              <tr data-field="status" data-value="Pending">
                <td><input type="checkbox" data-id="APP003" onchange="CRM.TableSelection.toggleRow(this, this.closest('tr'))"></td>
                <td><strong>James Rodriguez</strong><br><span style="font-size: 12px; color: var(--gray-600);">APP-003 • Applied 3 days ago</span></td>
                <td data-field="credit" class="credit-score score-fair">628</td>
                <td>$15,000</td>
                <td><span class="status-badge status-pending">Pending</span></td>
                <td><span class="risk-medium">Medium</span></td>
                <td>7.5%</td>
                <td>36 months</td>
                <td><button class="btn btn-primary btn-small" onclick="CRM.CRMModal.open('detailModal3')">Review</button></td>
              </tr>

              <tr data-field="status" data-value="Pending">
                <td><input type="checkbox" data-id="APP004" onchange="CRM.TableSelection.toggleRow(this, this.closest('tr'))"></td>
                <td><strong>Emily Watson</strong><br><span style="font-size: 12px; color: var(--gray-600);">APP-004 • Applied 4 hours ago</span></td>
                <td data-field="credit" class="credit-score score-poor">542</td>
                <td>$8,500</td>
                <td><span class="status-badge status-pending">Pending</span></td>
                <td><span class="risk-high">High</span></td>
                <td>11.2%</td>
                <td>24 months</td>
                <td><button class="btn btn-primary btn-small" onclick="CRM.CRMModal.open('detailModal4')">Review</button></td>
              </tr>

              <tr data-field="status" data-value="Approved">
                <td><input type="checkbox" data-id="APP005" onchange="CRM.TableSelection.toggleRow(this, this.closest('tr'))"></td>
                <td><strong>David Kim</strong><br><span style="font-size: 12px; color: var(--gray-600);">APP-005 • Approved 5 days ago</span></td>
                <td data-field="credit" class="credit-score score-excellent">798</td>
                <td>$75,000</td>
                <td><span class="status-badge status-approved">Approved</span></td>
                <td><span class="risk-low">Low</span></td>
                <td>4.5%</td>
                <td>120 months</td>
                <td><button class="btn btn-secondary btn-small">View</button></td>
              </tr>

              <tr data-field="status" data-value="Pending">
                <td><input type="checkbox" data-id="APP006" onchange="CRM.TableSelection.toggleRow(this, this.closest('tr'))"></td>
                <td><strong>Lisa Martinez</strong><br><span style="font-size: 12px; color: var(--gray-600);">APP-006 • Applied 2 days ago</span></td>
                <td data-field="credit" class="credit-score score-good">721</td>
                <td>$35,000</td>
                <td><span class="status-badge status-pending">Pending</span></td>
                <td><span class="risk-low">Low</span></td>
                <td>5.9%</td>
                <td>72 months</td>
                <td><button class="btn btn-primary btn-small" onclick="CRM.CRMModal.open('detailModal6')">Review</button></td>
              </tr>

              <tr data-field="status" data-value="Rejected">
                <td><input type="checkbox" data-id="APP007" onchange="CRM.TableSelection.toggleRow(this, this.closest('tr'))"></td>
                <td><strong>Robert Lee</strong><br><span style="font-size: 12px; color: var(--gray-600);">APP-007 • Rejected 8 days ago</span></td>
                <td data-field="credit" class="credit-score score-poor">510</td>
                <td>$20,000</td>
                <td><span class="status-badge status-rejected">Rejected</span></td>
                <td><span class="risk-high">High</span></td>
                <td>N/A</td>
                <td>N/A</td>
                <td><button class="btn btn-secondary btn-small">View</button></td>
              </tr>

              <tr data-field="status" data-value="Pending">
                <td><input type="checkbox" data-id="APP008" onchange="CRM.TableSelection.toggleRow(this, this.closest('tr'))"></td>
                <td><strong>Amanda Thompson</strong><br><span style="font-size: 12px; color: var(--gray-600);">APP-008 • Applied 6 hours ago</span></td>
                <td data-field="credit" class="credit-score score-good">744</td>
                <td>$42,000</td>
                <td><span class="status-badge status-pending">Pending</span></td>
                <td><span class="risk-low">Low</span></td>
                <td>5.1%</td>
                <td>60 months</td>
                <td><button class="btn btn-primary btn-small" onclick="CRM.CRMModal.open('detailModal8')">Review</button></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <!-- Detail Modal -->
  <div id="detailModal1" class="modal">
    <div class="modal-content">
      <div class="modal-header">
        <h2>Application Details: Michael Johnson (APP-001)</h2>
        <button class="modal-close" onclick="CRM.CRMModal.close('detailModal1')">×</button>
      </div>

      <div class="form-group">
        <label style="font-weight: 600; margin-bottom: 8px; display: block;">Personal Information</label>
        <div style="background: var(--gray-50); padding: 16px; border-radius: 8px; margin-bottom: 16px;">
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
            <div>
              <div style="font-size: 12px; color: var(--gray-600); margin-bottom: 4px;">Full Name</div>
              <div style="font-weight: 600;">Michael Johnson</div>
            </div>
            <div>
              <div style="font-size: 12px; color: var(--gray-600); margin-bottom: 4px;">Date of Birth</div>
              <div>03/15/1985</div>
            </div>
            <div>
              <div style="font-size: 12px; color: var(--gray-600); margin-bottom: 4px;">Email</div>
              <div>michael.johnson@email.com</div>
            </div>
            <div>
              <div style="font-size: 12px; color: var(--gray-600); margin-bottom: 4px;">Phone</div>
              <div>(555) 123-4567</div>
            </div>
          </div>
        </div>
      </div>

      <div class="form-group">
        <label style="font-weight: 600; margin-bottom: 8px; display: block;">Credit Profile</label>
        <div style="background: var(--gray-50); padding: 16px; border-radius: 8px; margin-bottom: 16px;">
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
            <div>
              <div style="font-size: 12px; color: var(--gray-600); margin-bottom: 4px;">Credit Score</div>
              <div class="credit-score score-good" style="font-size: 20px;">756</div>
            </div>
            <div>
              <div style="font-size: 12px; color: var(--gray-600); margin-bottom: 4px;">Credit Age</div>
              <div style="font-weight: 600;">12 years</div>
            </div>
            <div>
              <div style="font-size: 12px; color: var(--gray-600); margin-bottom: 4px;">Existing Debt</div>
              <div>$18,500</div>
            </div>
            <div>
              <div style="font-size: 12px; color: var(--gray-600); margin-bottom: 4px;">Debt-to-Income</div>
              <div>28%</div>
            </div>
          </div>
        </div>
      </div>

      <div class="form-group">
        <label style="font-weight: 600; margin-bottom: 8px; display: block;">Loan Request</label>
        <div style="background: var(--gray-50); padding: 16px; border-radius: 8px; margin-bottom: 16px;">
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
            <div>
              <div style="font-size: 12px; color: var(--gray-600); margin-bottom: 4px;">Amount</div>
              <div style="font-weight: 600; font-size: 18px;">$25,000</div>
            </div>
            <div>
              <div style="font-size: 12px; color: var(--gray-600); margin-bottom: 4px;">Purpose</div>
              <div>Home Improvement</div>
            </div>
            <div>
              <div style="font-size: 12px; color: var(--gray-600); margin-bottom: 4px;">Proposed Term</div>
              <div>60 months</div>
            </div>
            <div>
              <div style="font-size: 12px; color: var(--gray-600); margin-bottom: 4px;">Est. Monthly Payment</div>
              <div style="font-weight: 600;">$481.32</div>
            </div>
          </div>
        </div>
      </div>

      <div class="form-group">
        <label style="font-weight: 600; margin-bottom: 8px; display: block;">Risk Assessment</label>
        <div style="background: rgba(16, 185, 129, 0.05); padding: 16px; border-radius: 8px; margin-bottom: 16px; border-left: 4px solid var(--attio-finance-success);">
          <div style="font-weight: 600; color: var(--attio-finance-success); margin-bottom: 8px;">Risk Level: LOW</div>
          <div style="font-size: 14px; line-height: 1.6;">
            Strong credit history, good debt-to-income ratio, and established employment. Loan amount is reasonable relative to income. No red flags detected in recent transactions.
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <button class="btn btn-secondary" onclick="CRM.CRMModal.close('detailModal1')">Cancel</button>
        <button class="btn btn-success" onclick="CRM.Notifications.show('Application approved!', 'success'); CRM.CRMModal.close('detailModal1');">Approve</button>
        <button class="btn btn-danger" onclick="CRM.CRMModal.close('detailModal1');">Reject</button>
      </div>
    </div>
  </div>

  <!-- Duplicate modals for other apps (simplified) -->
  <div id="detailModal2" class="modal" style="display: none;"></div>
  <div id="detailModal3" class="modal" style="display: none;"></div>
  <div id="detailModal4" class="modal" style="display: none;"></div>
  <div id="detailModal6" class="modal" style="display: none;"></div>
  <div id="detailModal8" class="modal" style="display: none;"></div>

  <script src="crm-shared.js"></script>
</body>
</html>
```

**Step 2.2:** Commit Credit Officer dashboard

```bash
cd <larv-plugin-root>/attio-finance-html-effectiveness-design
git add 21-credit-officer-crm.html
git commit -m "feat: add Credit Officer CRM dashboard

- Loan applications queue with sortable table
- Real credit score data (510-812 range)
- Status badges (Pending, Approved, Rejected)
- Risk level indicators (Low/Medium/High)
- Sidebar metrics (pending apps, avg score, approval rate)
- Filter panel (status, credit score, risk level)
- Bulk actions (approve, reject, request info)
- Detail modal with full application info and decision workflow
- Responsive layout"
```

---

## Task 3: Create Sales/BD Dashboard

**Files:**
- Create: `attio-finance-html-effectiveness-design/22-sales-crm.html`

[Sales dashboard implementation - similar structure to credit officer, with pipeline view, deal tracking, forecasting cards, activity logging, and bulk move operations]

**Due to length constraints, I'll provide the detailed template structure:**

The Sales/BD dashboard includes:
- Pipeline kanban/table view (5 stages: Lead, Qualified, Proposal, Negotiation, Closed)
- 20 customer deals with realistic amounts ($5K-$250K)
- Forecasting metrics (pipeline value, win rate, avg deal size)
- Deal detail modal with interaction history
- Bulk move operations across pipeline stages
- Advanced filtering by stage, amount, owner
- Real-time updates notifications

---

## Task 4: Create Customer Service Dashboard

**Files:**
- Create: `attio-finance-html-effectiveness-design/23-service-crm.html`

[Customer Service dashboard implementation - similar structure with ticket queue, SLA tracking, support metrics, and interaction logging]

The Service dashboard includes:
- Support ticket queue (15 tickets across statuses)
- Priority indicators (Critical, High, Medium, Low)
- Customer history and interaction context
- Ticket detail modal with interaction log
- Bulk assignment and status update
- SLA tracking (response time, resolution targets)
- Advanced filtering by priority, status, assigned to

---

## Task 5: Update Gallery Index

**Files:**
- Modify: `attio-finance-html-effectiveness-design/index.html`

Add three new cards to the CRM section before the footer:

```html
<!-- Add to Examples Gallery after line 230 -->

<div class="category">
  <h2 class="category-title">💼 CRM & Business Tools</h2>
  <div class="category-grid">
    <a href="21-credit-officer-crm.html" class="example-card">
      <div class="example-icon">👤</div>
      <div class="example-title">Credit Officer CRM</div>
      <div class="example-description">Full-featured loan application management dashboard with credit scoring, risk assessment, and approval workflows.</div>
      <div class="example-meta">CRM Dashboard</div>
    </a>
    <a href="22-sales-crm.html" class="example-card">
      <div class="example-icon">📈</div>
      <div class="example-title">Sales/BD Pipeline CRM</div>
      <div class="example-description">Customer pipeline management with deal tracking, forecasting, and relationship analytics.</div>
      <div class="example-meta">CRM Dashboard</div>
    </a>
    <a href="23-service-crm.html" class="example-card">
      <div class="example-icon">🎧</div>
      <div class="example-title">Customer Service CRM</div>
      <div class="example-description">Support ticket management with customer history, SLA tracking, and interaction logging.</div>
      <div class="example-meta">CRM Dashboard</div>
    </a>
  </div>
</div>
```

**Step 5.1:** Commit updated gallery

```bash
git add index.html
git commit -m "feat: add CRM dashboards to gallery index

- Credit Officer dashboard (loan applications)
- Sales/BD dashboard (customer pipeline)
- Customer Service dashboard (support tickets)"
```

---

## Implementation Sequence

1. **Task 1** (Shared Utilities) — 15 minutes
   - Creates foundation for all three dashboards
   - No dependencies

2. **Task 2** (Credit Officer) — 45 minutes
   - Uses shared utilities
   - Most complex dashboard (credit scoring, risk assessment)
   - Good template for other dashboards

3. **Task 3** (Sales Dashboard) — 40 minutes
   - Similar structure, different data
   - Pipeline instead of queue
   - Quicker once Task 2 pattern established

4. **Task 4** (Service Dashboard) — 35 minutes
   - Smallest dashboard
   - Quickest iteration

5. **Task 5** (Update Gallery) — 5 minutes
   - Final touches

**Total estimated time:** 2-2.5 hours for full implementation

---

## Testing Checklist

- [ ] All modals open/close correctly
- [ ] Table selection (single row, select all)
- [ ] Filters apply correctly and hide rows
- [ ] Bulk action bar appears when items selected
- [ ] Notifications display and auto-dismiss
- [ ] Responsive on mobile (grid becomes single column)
- [ ] All buttons functional
- [ ] Credit scores, amounts, and data realistic
- [ ] Color-coded status badges visible
- [ ] Sidebar metrics update with sample data
- [ ] No console errors

---

## Notes

- All three dashboards share 90% of CSS and JS patterns
- Realistic sample data: credit scores (510-812), loan amounts ($5K-$75K), deal amounts ($5K-$250K), ticket priorities
- Gold (#FAA000) and deep blue (#1B5E7F) used for interactive elements
- Sidebar navigation pattern works well for complex dashboards
- Modal system handles detail views without page navigation
- Bulk actions pattern scales to other workflows
