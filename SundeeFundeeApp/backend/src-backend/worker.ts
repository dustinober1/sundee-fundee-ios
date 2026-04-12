import { $Database, $Env, OpenApiExtension, PocketUIExtension, teenyHono } from 'teenybase/worker';
import config from '../migrations/config.json';
import { DatabaseSettings } from "teenybase";

export interface Env {
  Bindings: $Env['Bindings'] & {
    PRIMARY_DB: D1Database;
    PRIMARY_R2?: R2Bucket;
  },
  Variables: $Env['Variables']
}

const app = teenyHono<Env>(async (c)=> {
  const db = new $Database(c, config as unknown as DatabaseSettings, c.env.PRIMARY_DB, c.env.PRIMARY_R2)
  db.extensions.push(new OpenApiExtension(db, true))
  db.extensions.push(new PocketUIExtension(db))

  return db
}, undefined, {
  logger: false,
  cors: true,
})

app.get('/', (c)=>{
  return c.json({message: 'Hello Hono'})
})

// Admin content dashboard removed — workout content is now bundled in the iOS app.
// Remote content management (exercises, programs, benchmarks) is deferred to v2.

const ADMIN_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sundee Fundee Content Admin</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: #f4f0df;
      color: #0d1a40;
    }

    .header {
      background-color: #0d1a40;
      color: #f4f0df;
      padding: 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 15px;
    }

    .header h1 {
      font-size: 24px;
      font-weight: 600;
    }

    .token-input-container {
      display: flex;
      gap: 10px;
      align-items: center;
    }

    .token-input-container input {
      padding: 8px 12px;
      border: none;
      border-radius: 4px;
      font-size: 14px;
      width: 300px;
    }

    .token-input-container button {
      padding: 8px 16px;
      background-color: #f27319;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-weight: 500;
    }

    .token-input-container button:hover {
      background-color: #e06612;
    }

    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
    }

    .tabs {
      display: flex;
      gap: 10px;
      margin-bottom: 20px;
      border-bottom: 2px solid #0d1a40;
      padding-bottom: 10px;
    }

    .tab {
      padding: 10px 20px;
      background-color: transparent;
      border: none;
      cursor: pointer;
      font-size: 16px;
      color: #0d1a40;
      font-weight: 500;
      position: relative;
    }

    .tab.active {
      color: #f27319;
    }

    .tab.active::after {
      content: '';
      position: absolute;
      bottom: -12px;
      left: 0;
      right: 0;
      height: 2px;
      background-color: #f27319;
    }

    .tab:hover:not(.active) {
      color: #f27319;
    }

    .content {
      background-color: white;
      border-radius: 8px;
      padding: 20px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .content-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }

    .content-header h2 {
      font-size: 20px;
      font-weight: 600;
    }

    .btn {
      padding: 10px 20px;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-weight: 500;
      font-size: 14px;
    }

    .btn-primary {
      background-color: #f27319;
      color: white;
    }

    .btn-primary:hover {
      background-color: #e06612;
    }

    .btn-secondary {
      background-color: #0d1a40;
      color: white;
    }

    .btn-secondary:hover {
      background-color: #0a1429;
    }

    .btn-danger {
      background-color: #dc3545;
      color: white;
    }

    .btn-danger:hover {
      background-color: #c82333;
    }

    .btn-small {
      padding: 6px 12px;
      font-size: 12px;
    }

    table {
      width: 100%;
      border-collapse: collapse;
    }

    th, td {
      padding: 12px;
      text-align: left;
      border-bottom: 1px solid #dee2e6;
    }

    th {
      background-color: #f8f9fa;
      font-weight: 600;
      font-size: 14px;
      color: #495057;
    }

    td {
      font-size: 14px;
    }

    .badge {
      display: inline-block;
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 500;
    }

    .badge-published {
      background-color: #d4edda;
      color: #155724;
    }

    .badge-draft {
      background-color: #fff3cd;
      color: #856404;
    }

    .actions {
      display: flex;
      gap: 8px;
    }

    .modal {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background-color: rgba(0,0,0,0.5);
      z-index: 1000;
      align-items: center;
      justify-content: center;
    }

    .modal.active {
      display: flex;
    }

    .modal-content {
      background-color: white;
      padding: 30px;
      border-radius: 8px;
      max-width: 600px;
      width: 90%;
      max-height: 80vh;
      overflow-y: auto;
    }

    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }

    .modal-header h2 {
      font-size: 20px;
      font-weight: 600;
    }

    .close {
      background: none;
      border: none;
      font-size: 24px;
      cursor: pointer;
      color: #6c757d;
    }

    .close:hover {
      color: #0d1a40;
    }

    .form-group {
      margin-bottom: 15px;
    }

    .form-group label {
      display: block;
      margin-bottom: 5px;
      font-weight: 500;
      font-size: 14px;
    }

    .form-group input,
    .form-group select,
    .form-group textarea {
      width: 100%;
      padding: 10px;
      border: 1px solid #ced4da;
      border-radius: 4px;
      font-size: 14px;
      font-family: inherit;
    }

    .form-group textarea {
      resize: vertical;
      min-height: 80px;
    }

    .form-group input[type="checkbox"] {
      width: auto;
      margin-right: 8px;
    }

    .form-group input[type="checkbox"] + label {
      display: inline;
    }

    .form-actions {
      display: flex;
      gap: 10px;
      justify-content: flex-end;
      margin-top: 20px;
    }

    .loading {
      text-align: center;
      padding: 40px;
      color: #6c757d;
    }

    .error {
      background-color: #f8d7da;
      color: #721c24;
      padding: 12px;
      border-radius: 4px;
      margin-bottom: 20px;
    }

    .empty-state {
      text-align: center;
      padding: 40px;
      color: #6c757d;
    }

    .checkbox-group {
      display: flex;
      align-items: center;
    }

    .checkbox-group input {
      width: auto;
      margin-right: 8px;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>Sundee Fundee Content Admin</h1>
    <div class="token-input-container">
      <input type="text" id="tokenInput" placeholder="Enter admin token">
      <button onclick="saveToken()">Save Token</button>
    </div>
  </div>

  <div class="container">
    <div class="tabs">
      <button class="tab active" onclick="switchTab('benchmarks')">Benchmarks</button>
      <button class="tab" onclick="switchTab('programs')">Programs</button>
      <button class="tab" onclick="switchTab('exercises')">Exercises</button>
    </div>

    <div class="content">
      <div class="content-header">
        <h2 id="currentTabTitle">Benchmarks</h2>
        <button class="btn btn-primary" onclick="openModal()">+ Add New</button>
      </div>

      <div id="errorContainer"></div>
      <div id="loadingContainer" class="loading" style="display: none;">Loading...</div>
      <div id="tableContainer"></div>
    </div>
  </div>

  <div id="modal" class="modal">
    <div class="modal-content">
      <div class="modal-header">
        <h2 id="modalTitle">Add New Item</h2>
        <button class="close" onclick="closeModal()">&times;</button>
      </div>
      <form id="modalForm" onsubmit="handleSubmit(event)">
        <div id="formFields"></div>
        <div class="form-actions">
          <button type="button" class="btn btn-secondary" onclick="closeModal()">Cancel</button>
          <button type="submit" class="btn btn-primary">Save</button>
        </div>
      </form>
    </div>
  </div>

  <script>
    const BASE = '';
    let currentTab = 'benchmarks';
    let editingItem = null;

    const TABLES = {
      benchmarks: 'benchmarks',
      programs: 'programs',
      exercises: 'exercises'
    };

    const TAB_NAMES = {
      benchmarks: 'Benchmarks',
      programs: 'Programs',
      exercises: 'Exercises'
    };

    function getToken() {
      return localStorage.getItem('admin_token');
    }

    function saveToken() {
      const token = document.getElementById('tokenInput').value;
      if (token) {
        localStorage.setItem('admin_token', token);
        alert('Token saved!');
        loadData();
      } else {
        alert('Please enter a token');
      }
    }

    function getHeaders() {
      return {
        'Content-Type': 'application/json',
        'Authorization': \`Bearer \${getToken()}\`
      };
    }

    async function apiCall(url, options = {}) {
      try {
        const response = await fetch(url, {
          ...options,
          headers: getHeaders()
        });

        if (!response.ok) {
          throw new Error(\`HTTP error! status: \${response.status}\`);
        }

        return await response.json();
      } catch (error) {
        console.error('API call failed:', error);
        throw error;
      }
    }

    function switchTab(tab) {
      currentTab = tab;
      document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      document.querySelectorAll(\`.tab[onclick="switchTab('\${tab}')"]\`).forEach(t => t.classList.add('active'));
      document.getElementById('currentTabTitle').textContent = TAB_NAMES[tab];
      loadData();
    }

    async function loadData() {
      const token = getToken();
      if (!token) {
        showError('Please enter and save your admin token first');
        return;
      }

      showLoading(true);
      hideError();

      try {
        const result = await apiCall(\`\${BASE}/api/v1/table/\${TABLES[currentTab]}/list\`, {
          method: 'POST',
          body: JSON.stringify({ limit: 200 })
        });

        const data = result.data || [];
        renderTable(data);
      } catch (error) {
        showError(\`Failed to load data: \${error.message}\`);
      } finally {
        showLoading(false);
      }
    }

    function renderTable(data) {
      const container = document.getElementById('tableContainer');

      if (data.length === 0) {
        container.innerHTML = '<div class="empty-state">No items found. Click "Add New" to create one.</div>';
        return;
      }

      const columns = getColumns();
      let html = '<table><thead><tr>';

      columns.forEach(col => {
        html += \`<th>\${col.label}</th>\`;
      });
      html += '<th>Actions</th></tr></thead><tbody>';

      data.forEach(item => {
        html += '<tr>';
        columns.forEach(col => {
          html += \`<td>\{renderColumn(item, col.key)\}</td>\`;
        });

        const status = item.status || 'draft';
        const statusBadge = \`<span class="badge badge-\${status}">\${status}</span>\`;

        html += \`<td class="actions">
          <button class="btn btn-small btn-secondary" onclick="editItem('\${item.id}')">Edit</button>
          <button class="btn btn-small btn-secondary" onclick="toggleStatus('\${item.id}')">Toggle Status</button>
          <button class="btn btn-small btn-danger" onclick="deleteItem('\${item.id}')">Delete</button>
        </td>\`;
        html += '</tr>';
      });

      html += '</tbody></table>';
      container.innerHTML = html;
    }

    function renderColumn(item, key) {
      const value = item[key];
      if (key === 'status') {
        const status = value || 'draft';
        return \`<span class="badge badge-\${status}">\${status}</span>\`;
      }
      if (key === 'bodyweight') {
        return value ? 'Yes' : 'No';
      }
      if (key === 'sortOrder') {
        return value || 0;
      }
      return value || '-';
    }

    function getColumns() {
      const columns = {
        benchmarks: [
          { key: 'name', label: 'Name' },
          { key: 'category', label: 'Category' },
          { key: 'status', label: 'Status' }
        ],
        programs: [
          { key: 'name', label: 'Name' },
          { key: 'category', label: 'Category' },
          { key: 'difficulty', label: 'Difficulty' },
          { key: 'status', label: 'Status' }
        ],
        exercises: [
          { key: 'name', label: 'Name' },
          { key: 'category', label: 'Category' },
          { key: 'bodyweight', label: 'Bodyweight' },
          { key: 'status', label: 'Status' }
        ]
      };
      return columns[currentTab];
    }

    function getFormFields() {
      const fields = {
        benchmarks: [
          { name: 'name', label: 'Name', type: 'text', required: true },
          {
            name: 'category',
            label: 'Category',
            type: 'select',
            options: ['Sundee Fundee', 'Classic WODs', 'Strength', 'Endurance', 'Gymnastics', 'General Fitness'],
            required: true
          },
          { name: 'workoutDescription', label: 'Workout Description', type: 'textarea', required: false },
          {
            name: 'scoringType',
            label: 'Scoring Type',
            type: 'select',
            options: ['time', 'roundsAndReps', 'load', 'reps', 'calories', 'distance'],
            required: false
          },
          { name: 'intensity', label: 'Intensity (1-5)', type: 'number', min: 1, max: 5, required: false },
          { name: 'timeDomain', label: 'Time Domain', type: 'text', required: false },
          { name: 'coachNotes', label: 'Coach Notes', type: 'textarea', required: false },
          { name: 'sortOrder', label: 'Sort Order', type: 'number', required: false }
        ],
        programs: [
          { name: 'name', label: 'Name', type: 'text', required: true },
          { name: 'category', label: 'Category', type: 'text', required: true },
          { name: 'description', label: 'Description', type: 'textarea', required: false },
          { name: 'durationWeeks', label: 'Duration (Weeks)', type: 'number', required: false },
          { name: 'sessionsPerWeek', label: 'Sessions Per Week', type: 'number', required: false },
          {
            name: 'difficulty',
            label: 'Difficulty',
            type: 'select',
            options: ['beginner', 'intermediate', 'advanced'],
            required: false
          },
          { name: 'sortOrder', label: 'Sort Order', type: 'number', required: false }
        ],
        exercises: [
          { name: 'name', label: 'Name', type: 'text', required: true },
          {
            name: 'category',
            label: 'Category',
            type: 'select',
            options: ['Squat', 'Hip Hinge', 'Press', 'Pull', 'Carry', 'Olympic Weightlifting', 'Conditioning'],
            required: true
          },
          { name: 'bodyweight', label: 'Bodyweight', type: 'checkbox', required: false },
          { name: 'sortOrder', label: 'Sort Order', type: 'number', required: false }
        ]
      };
      return fields[currentTab];
    }

    function openModal(item = null) {
      editingItem = item;
      const modal = document.getElementById('modal');
      const title = document.getElementById('modalTitle');
      const fieldsContainer = document.getElementById('formFields');

      title.textContent = item ? 'Edit Item' : 'Add New Item';
      fieldsContainer.innerHTML = renderFormFields(item);
      modal.classList.add('active');
    }

    function closeModal() {
      document.getElementById('modal').classList.remove('active');
      editingItem = null;
    }

    function renderFormFields(item = null) {
      const fields = getFormFields();
      let html = '';

      fields.forEach(field => {
        const value = item ? item[field.name] : '';

        html += '<div class="form-group">';
        html += \`<label for="\${field.name}">\${field.label}\${field.required ? ' *' : ''}</label>\`;

        if (field.type === 'select') {
          html += \`<select id="\${field.name}" name="\${field.name}" \${field.required ? 'required' : ''}>\`;
          html += '<option value="">Select...</option>';
          field.options.forEach(option => {
            const selected = value === option ? 'selected' : '';
            html += \`<option value="\${option}" \${selected}>\${option}</option>\`;
          });
          html += '</select>';
        } else if (field.type === 'textarea') {
          html += \`<textarea id="\${field.name}" name="\${field.name}" \${field.required ? 'required' : ''}>\${value || ''}</textarea>\`;
        } else if (field.type === 'checkbox') {
          const checked = value ? 'checked' : '';
          html += \`<div class="checkbox-group">
            <input type="checkbox" id="\${field.name}" name="\${field.name}" \${checked}>
            <label for="\${field.name}">Yes</label>
          </div>\`;
        } else if (field.type === 'number') {
          const min = field.min ? \`min="\${field.min}"\` : '';
          const max = field.max ? \`max="\${field.max}"\` : '';
          html += \`<input type="number" id="\${field.name}" name="\${field.name}" value="\${value || ''}" \${min} \${max} \${field.required ? 'required' : ''}>\`;
        } else {
          html += \`<input type="\${field.type}" id="\${field.name}" name="\${field.name}" value="\${value || ''}" \${field.required ? 'required' : ''}>\`;
        }

        html += '</div>';
      });

      return html;
    }

    async function handleSubmit(event) {
      event.preventDefault();

      const formData = new FormData(event.target);
      const values = {};

      for (const [key, value] of formData.entries()) {
        if (value === 'on') {
          values[key] = true;
        } else if (value === '') {
          values[key] = null;
        } else if (!isNaN(value)) {
          values[key] = parseFloat(value);
        } else {
          values[key] = value;
        }
      }

      // Handle checkbox unchecked
      const fields = getFormFields();
      fields.forEach(field => {
        if (field.type === 'checkbox' && !values[field.name]) {
          values[field.name] = false;
        }
      });

      try {
        if (editingItem) {
          await updateItem(editingItem.id, values);
        } else {
          await createItem(values);
        }
        closeModal();
        loadData();
      } catch (error) {
        showError(\`Failed to save: \${error.message}\`);
      }
    }

    async function createItem(values) {
      return await apiCall(\`\${BASE}/api/v1/table/\${TABLES[currentTab]}/insert\`, {
        method: 'POST',
        body: JSON.stringify({ values, returning: '*' })
      });
    }

    async function updateItem(id, values) {
      // Build update object with only changed fields
      const updateData = {};
      for (const [key, value] of Object.entries(values)) {
        if (value !== null && value !== undefined && value !== '') {
          updateData[key] = value;
        }
      }

      return await apiCall(\`\${BASE}/api/v1/table/\${TABLES[currentTab]}/edit/\${id}?returning=*\`, {
        method: 'POST',
        body: JSON.stringify(updateData)
      });
    }

    async function editItem(id) {
      try {
        const result = await apiCall(\`\${BASE}/api/v1/table/\${TABLES[currentTab]}/list\`, {
          method: 'POST',
          body: JSON.stringify({ limit: 200 })
        });

        const item = result.data.find(i => i.id === id);
        if (item) {
          openModal(item);
        }
      } catch (error) {
        showError(\`Failed to load item: \${error.message}\`);
      }
    }

    async function toggleStatus(id) {
      try {
        const result = await apiCall(\`\${BASE}/api/v1/table/\${TABLES[currentTab]}/list\`, {
          method: 'POST',
          body: JSON.stringify({ limit: 200 })
        });

        const item = result.data.find(i => i.id === id);
        if (item) {
          const newStatus = item.status === 'published' ? 'draft' : 'published';
          await apiCall(\`\${BASE}/api/v1/table/\${TABLES[currentTab]}/edit/\${id}?returning=*\`, {
            method: 'POST',
            body: JSON.stringify({ status: newStatus })
          });
          loadData();
        }
      } catch (error) {
        showError(\`Failed to toggle status: \${error.message}\`);
      }
    }

    async function deleteItem(id) {
      if (!confirm('Are you sure you want to delete this item?')) {
        return;
      }

      try {
        await apiCall(\`\${BASE}/api/v1/table/\${TABLES[currentTab]}/delete\`, {
          method: 'POST',
          body: JSON.stringify({ where: \`id='\${id}'\` })
        });
        loadData();
      } catch (error) {
        showError(\`Failed to delete: \${error.message}\`);
      }
    }

    function showLoading(show) {
      document.getElementById('loadingContainer').style.display = show ? 'block' : 'none';
      document.getElementById('tableContainer').style.display = show ? 'none' : 'block';
    }

    function showError(message) {
      const container = document.getElementById('errorContainer');
      container.innerHTML = \`<div class="error">\${message}</div>\`;
    }

    function hideError() {
      document.getElementById('errorContainer').innerHTML = '';
    }

    // Initialize
    document.addEventListener('DOMContentLoaded', () => {
      const savedToken = localStorage.getItem('admin_token');
      if (savedToken) {
        document.getElementById('tokenInput').value = savedToken;
        loadData();
      }
    });
  </script>
</body>
</html>`;

export default app
