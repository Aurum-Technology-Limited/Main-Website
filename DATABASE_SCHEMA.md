# Aurum Automation - Database Schema Design
**Platform:** Supabase (PostgreSQL)

---

## 📊 **DATABASE ARCHITECTURE OVERVIEW**

### Core Tables:
1. **contacts** - Lead/contact information from website form
2. **companies** - Client company details
3. **projects** - Automation projects for clients
4. **services** - Available automation services
5. **project_services** - Many-to-many: projects ↔ services
6. **invoices** - Billing and payments
7. **meetings** - Discovery calls, consultations, demos
8. **support_tickets** - Ongoing client support
9. **integrations** - Tech stack tools used per project
10. **notes** - General notes on contacts/companies/projects

---

## 🗂️ **TABLE STRUCTURE**

### 1. CONTACTS (Leads from Website)
**Purpose:** Store all inbound inquiries from contact form

| Field | Type | Description |
|-------|------|-------------|
| id | UUID (PK) | Unique identifier |
| first_name | VARCHAR(100) | First name |
| last_name | VARCHAR(100) | Last name |
| email | VARCHAR(255) | Email address (unique) |
| phone | VARCHAR(50) | Phone number |
| company_name | VARCHAR(255) | Company name |
| company_size | VARCHAR(50) | Employee count range |
| message | TEXT | Inquiry message |
| status | ENUM | lead, contacted, qualified, converted, lost |
| source | VARCHAR(100) | website, referral, linkedin, etc. |
| company_id | UUID (FK) | Link to companies table |
| assigned_to | UUID | Team member assigned |
| created_at | TIMESTAMP | When submitted |
| updated_at | TIMESTAMP | Last modified |

**Indexes:** email, status, company_id, created_at

---

### 2. COMPANIES (Client Businesses)
**Purpose:** Store client company information

| Field | Type | Description |
|-------|------|-------------|
| id | UUID (PK) | Unique identifier |
| company_name | VARCHAR(255) | Legal company name |
| industry | VARCHAR(100) | Healthcare, Legal, Retail, etc. |
| company_size | VARCHAR(50) | 1-10, 11-50, 51-200, etc. |
| website | VARCHAR(255) | Company website |
| address | TEXT | Physical address |
| city | VARCHAR(100) | City |
| country | VARCHAR(100) | Trinidad, Barbados, etc. |
| status | ENUM | prospect, active, inactive, churned |
| primary_contact_id | UUID (FK) | Main contact person |
| total_revenue | DECIMAL(10,2) | Lifetime value |
| monthly_recurring | DECIMAL(10,2) | Current MRR |
| contract_start_date | DATE | When they became client |
| contract_end_date | DATE | Contract expiration |
| notes | TEXT | General notes |
| created_at | TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | Last modified |

**Indexes:** company_name, status, country, contract_end_date

---

### 3. PROJECTS (Automation Implementations)
**Purpose:** Track each automation project/implementation

| Field | Type | Description |
|-------|------|-------------|
| id | UUID (PK) | Unique identifier |
| company_id | UUID (FK) | Client company |
| project_name | VARCHAR(255) | "ABC Clinic Chatbot" |
| project_type | VARCHAR(100) | chatbot, lead_gen, email_automation |
| description | TEXT | Project scope |
| status | ENUM | scoping, demo, in_progress, live, paused, cancelled |
| setup_fee | DECIMAL(10,2) | One-time setup cost (TTD) |
| monthly_fee | DECIMAL(10,2) | Recurring monthly fee (TTD) |
| tool_costs | DECIMAL(10,2) | Platform costs (TTD/month) |
| start_date | DATE | Project kickoff |
| go_live_date | DATE | When launched |
| demo_url | VARCHAR(255) | Link to demo |
| production_url | VARCHAR(255) | Live system URL |
| assigned_to | UUID | Team member |
| priority | VARCHAR(20) | low, medium, high, urgent |
| estimated_hours | INTEGER | Time estimate |
| actual_hours | INTEGER | Time spent |
| created_at | TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | Last modified |

**Indexes:** company_id, status, go_live_date, assigned_to

---

### 4. SERVICES (Automation Services Catalog)
**Purpose:** Define available services

| Field | Type | Description |
|-------|------|-------------|
| id | UUID (PK) | Unique identifier |
| service_name | VARCHAR(100) | AI Chatbot, Lead Generation, etc. |
| service_category | VARCHAR(50) | automation, integration, consulting |
| description | TEXT | Service details |
| base_setup_fee_min | DECIMAL(10,2) | Minimum setup (TTD) |
| base_setup_fee_max | DECIMAL(10,2) | Maximum setup (TTD) |
| base_monthly_fee_min | DECIMAL(10,2) | Minimum monthly (TTD) |
| base_monthly_fee_max | DECIMAL(10,2) | Maximum monthly (TTD) |
| typical_duration_weeks | INTEGER | Implementation time |
| is_active | BOOLEAN | Currently offered |
| created_at | TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | Last modified |

**Indexes:** is_active, service_category

---

### 5. PROJECT_SERVICES (Many-to-Many)
**Purpose:** Link projects to multiple services

| Field | Type | Description |
|-------|------|-------------|
| id | UUID (PK) | Unique identifier |
| project_id | UUID (FK) | References projects |
| service_id | UUID (FK) | References services |
| created_at | TIMESTAMP | Record creation |

**Composite Index:** (project_id, service_id)

---

### 6. INVOICES (Billing & Payments)
**Purpose:** Track all financial transactions

| Field | Type | Description |
|-------|------|-------------|
| id | UUID (PK) | Unique identifier |
| invoice_number | VARCHAR(50) | INV-2024-001 |
| company_id | UUID (FK) | Client company |
| project_id | UUID (FK) | Related project (optional) |
| invoice_type | ENUM | setup, monthly, one_time, tool_cost |
| amount | DECIMAL(10,2) | Amount in TTD |
| amount_usd | DECIMAL(10,2) | Amount in USD |
| currency | VARCHAR(3) | TTD, USD |
| status | ENUM | draft, sent, paid, overdue, cancelled |
| issue_date | DATE | When created |
| due_date | DATE | Payment deadline |
| paid_date | DATE | When paid |
| payment_method | VARCHAR(50) | bank_transfer, credit_card, etc. |
| notes | TEXT | Additional info |
| created_at | TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | Last modified |

**Indexes:** company_id, invoice_number, status, due_date

---

### 7. MEETINGS (Consultations & Calls)
**Purpose:** Track all client interactions

| Field | Type | Description |
|-------|------|-------------|
| id | UUID (PK) | Unique identifier |
| contact_id | UUID (FK) | Contact person |
| company_id | UUID (FK) | Company (optional) |
| meeting_type | ENUM | discovery, demo, onboarding, support, review |
| title | VARCHAR(255) | Meeting subject |
| description | TEXT | Meeting notes/agenda |
| scheduled_at | TIMESTAMP | Meeting date/time |
| duration_minutes | INTEGER | Meeting length |
| status | ENUM | scheduled, completed, cancelled, no_show |
| meeting_url | VARCHAR(255) | Zoom/Google Meet link |
| outcome | TEXT | Results/next steps |
| attendees | TEXT | Who attended |
| created_at | TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | Last modified |

**Indexes:** contact_id, company_id, scheduled_at, status

---

### 8. SUPPORT_TICKETS (Client Support)
**Purpose:** Track ongoing support requests

| Field | Type | Description |
|-------|------|-------------|
| id | UUID (PK) | Unique identifier |
| ticket_number | VARCHAR(50) | TKT-2024-001 |
| company_id | UUID (FK) | Client company |
| project_id | UUID (FK) | Related project |
| contact_id | UUID (FK) | Who reported |
| subject | VARCHAR(255) | Ticket subject |
| description | TEXT | Issue details |
| priority | ENUM | low, medium, high, critical |
| status | ENUM | open, in_progress, waiting, resolved, closed |
| category | VARCHAR(50) | bug, feature_request, question |
| assigned_to | UUID | Team member |
| resolution | TEXT | How it was solved |
| created_at | TIMESTAMP | When submitted |
| resolved_at | TIMESTAMP | When closed |
| updated_at | TIMESTAMP | Last modified |

**Indexes:** ticket_number, company_id, status, priority

---

### 9. INTEGRATIONS (Tech Stack)
**Purpose:** Track which tools are used in each project

| Field | Type | Description |
|-------|------|-------------|
| id | UUID (PK) | Unique identifier |
| project_id | UUID (FK) | Related project |
| tool_name | VARCHAR(100) | Botpress, HubSpot, Make.com |
| tool_category | VARCHAR(50) | chatbot, crm, automation, ai |
| status | ENUM | active, inactive, testing |
| api_key_name | VARCHAR(100) | Reference (not actual key!) |
| monthly_cost | DECIMAL(10,2) | Tool subscription |
| notes | TEXT | Configuration details |
| created_at | TIMESTAMP | When added |
| updated_at | TIMESTAMP | Last modified |

**Indexes:** project_id, tool_name, status

---

### 10. NOTES (General Notes)
**Purpose:** Add notes to any record

| Field | Type | Description |
|-------|------|-------------|
| id | UUID (PK) | Unique identifier |
| note_type | ENUM | contact, company, project, general |
| related_id | UUID | ID of related record |
| note_text | TEXT | Note content |
| created_by | UUID | Who wrote it |
| is_private | BOOLEAN | Internal only? |
| created_at | TIMESTAMP | When written |
| updated_at | TIMESTAMP | Last modified |

**Indexes:** related_id, note_type, created_at

---

## 🔗 **RELATIONSHIPS**

```
contacts ──→ companies (many-to-one)
companies ──→ projects (one-to-many)
projects ──→ services (many-to-many via project_services)
projects ──→ integrations (one-to-many)
projects ──→ support_tickets (one-to-many)
companies ──→ invoices (one-to-many)
contacts ──→ meetings (one-to-many)
companies ──→ meetings (one-to-many)
```

---

## 📈 **ENUMS (Custom Types)**

- **contact_status:** lead, contacted, qualified, converted, lost
- **company_status:** prospect, active, inactive, churned
- **project_status:** scoping, demo, in_progress, live, paused, cancelled
- **invoice_status:** draft, sent, paid, overdue, cancelled
- **meeting_status:** scheduled, completed, cancelled, no_show
- **ticket_status:** open, in_progress, waiting, resolved, closed
- **priority:** low, medium, high, urgent, critical

---

## 🔐 **SECURITY & ROW LEVEL SECURITY (RLS)**

Supabase recommendation:
- Enable RLS on all tables
- Create policies for authenticated users only
- Separate read/write permissions
- Add audit logging for sensitive changes

---

## 📊 **USEFUL VIEWS TO CREATE**

1. **active_clients_overview** - Companies with active projects
2. **monthly_recurring_revenue** - Sum of all active monthly fees
3. **pipeline_value** - Potential revenue from prospects
4. **overdue_invoices** - Unpaid invoices past due date
5. **project_timeline** - Gantt-style project view

---

This schema is designed to:
✅ Scale with your business
✅ Integrate with HubSpot CRM
✅ Track full customer lifecycle
✅ Support financial reporting
✅ Enable analytics and dashboards
✅ Maintain data integrity
