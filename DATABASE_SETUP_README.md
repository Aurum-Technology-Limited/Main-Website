# 🗄️ Aurum Automation - Database Setup Guide
**Complete Supabase Implementation for Client Data Management**

---

## 📦 **WHAT'S INCLUDED**

This database implementation provides:

✅ **10 Core Tables** - Complete data model for automation business  
✅ **6 Useful Views** - Pre-built queries for dashboards  
✅ **Auto-Generated Numbers** - Invoice & ticket numbering  
✅ **Indexes & Constraints** - Optimized performance  
✅ **Row Level Security** - Secure data access  
✅ **Sample Data** - Test data to get started  
✅ **Backend Integration** - Ready-to-use API code  

---

## 🚀 **QUICK START (5 MINUTES)**

### Step 1: Create Supabase Project
1. Go to https://supabase.com
2. Click "New Project"
3. Name it: `aurum-automation`
4. Choose region closest to Trinidad (US East recommended)
5. Set a strong database password

### Step 2: Run Setup Script
1. In Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Open `/workspace/supabase_setup.sql`
4. Copy entire contents
5. Paste into SQL Editor
6. Click **RUN** (or press Ctrl+Enter)

✅ You should see: "Success. No rows returned"

### Step 3: Insert Test Data (Optional)
1. Create another new query
2. Open `/workspace/sample_data.sql`
3. Copy entire contents
4. Paste and **RUN**

✅ You should see: Multiple rows inserted

### Step 4: Verify Setup
```sql
-- Run this query to verify:
SELECT 
  table_name, 
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

You should see 10 tables:
- companies
- contacts
- integrations
- invoices
- meetings
- notes
- project_services
- projects
- services
- support_tickets

---

## 📊 **DATABASE STRUCTURE OVERVIEW**

### Core Tables & Their Purpose:

| Table | Purpose | Key Fields |
|-------|---------|------------|
| **contacts** | Website form submissions & leads | email, status, company_size, message |
| **companies** | Client businesses | company_name, status, monthly_recurring, total_revenue |
| **projects** | Automation implementations | project_name, status, setup_fee, monthly_fee |
| **services** | Service catalog | service_name, pricing ranges |
| **project_services** | Links projects ↔ services | Many-to-many relationship |
| **invoices** | Billing & payments | invoice_number, amount, status, due_date |
| **meetings** | Client calls & demos | meeting_type, scheduled_at, outcome |
| **support_tickets** | Client support requests | ticket_number, priority, status |
| **integrations** | Tech tools per project | tool_name (Botpress, HubSpot, etc.) |
| **notes** | General notes on anything | note_text, related_id |

---

## 🔄 **DATA FLOW**

### Contact Form Submission Flow:

```
Website Form
    ↓
n8n Webhook
    ↓
├─→ Supabase (contacts table) ← YOU ARE HERE
└─→ HubSpot CRM
```

### From Lead to Client Journey:

```
1. Contact submits form → contacts table (status: 'lead')
2. You reach out → Update status to 'contacted'
3. Discovery call → meetings table + Update to 'qualified'
4. Create company → companies table
5. Link contact to company → contacts.company_id
6. Create project → projects table
7. Generate invoice → invoices table
8. Project goes live → Update project status to 'live'
9. Monthly billing → Create recurring invoices
10. Support requests → support_tickets table
```

---

## 📈 **PRE-BUILT VIEWS (DASHBOARDS)**

Use these views for instant analytics:

### 1. Active Clients Overview
```sql
SELECT * FROM active_clients_overview;
```
Shows: Company name, # of projects, MRR, total revenue

### 2. Monthly Recurring Revenue
```sql
SELECT * FROM monthly_recurring_revenue;
```
Shows: Total MRR, # of active clients, average project fee

### 3. Pipeline Value
```sql
SELECT * FROM pipeline_value;
```
Shows: Potential revenue from projects in progress

### 4. Overdue Invoices
```sql
SELECT * FROM overdue_invoices;
```
Shows: Unpaid invoices past due date with days overdue

### 5. Project Timeline
```sql
SELECT * FROM project_timeline;
```
Shows: All projects with dates and services

### 6. Support Metrics
```sql
SELECT * FROM support_metrics;
```
Shows: Ticket counts and average resolution time

---

## 🔗 **CONNECTING TO YOUR FORM**

### Option 1: n8n Integration (RECOMMENDED - NO CODING)

**In your n8n workflow:**

1. After webhook trigger, add "Supabase" node
2. Set credentials:
   - Host: `https://your-project.supabase.co`
   - Service Role Key: (from Supabase Settings → API)
3. Configure:
   - Operation: **Insert**
   - Table: **contacts**
   - Map fields:
     ```
     first_name → {{ $json.firstName }}
     last_name → {{ $json.lastName }}
     email → {{ $json.email }}
     phone → {{ $json.phone }}
     company_name → {{ $json.company }}
     company_size → {{ $json.companySize }}
     message → {{ $json.message }}
     status → "lead"
     source → "website"
     ```

**That's it!** Your form now saves to Supabase AND HubSpot.

---

### Option 2: Backend API (FOR DEVELOPERS)

If you want more control, see `/workspace/backend_integration_guide.md`

Includes:
- Complete FastAPI backend code
- Supabase client integration
- Duplicate handling
- Error management
- Rate limiting

---

## 🔐 **SECURITY SETUP**

### Important: Row Level Security (RLS)

Your tables have RLS enabled. Current policies:

✅ **Public can INSERT into contacts** (for form submissions)  
✅ **Only authenticated users can READ data**  
❌ **Public cannot read/update/delete**

### To Access Data from Backend:

Use **Service Role Key** (not anon key):

```python
from supabase import create_client

supabase = create_client(
    "https://your-project.supabase.co",
    "your_service_role_key_here"  # From Settings → API
)

# This bypasses RLS for admin operations
contacts = supabase.table("contacts").select("*").execute()
```

### ⚠️ Security Warning:

**NEVER expose Service Role Key in:**
- ❌ Frontend code
- ❌ Git repositories
- ❌ Client-side JavaScript

**ONLY use in:**
- ✅ Backend servers
- ✅ n8n workflows
- ✅ Secure admin tools

---

## 📊 **COMMON QUERIES**

### Get All New Leads (Last 7 Days)
```sql
SELECT 
  first_name, 
  last_name, 
  email, 
  company_name, 
  company_size, 
  created_at
FROM contacts
WHERE status = 'lead'
  AND created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;
```

### Get Active Projects by Client
```sql
SELECT 
  c.company_name,
  p.project_name,
  p.status,
  p.monthly_fee,
  p.go_live_date
FROM projects p
JOIN companies c ON p.company_id = c.id
WHERE c.status = 'active'
ORDER BY c.company_name, p.go_live_date DESC;
```

### Calculate This Month's Revenue
```sql
SELECT 
  SUM(amount) as total_revenue,
  COUNT(*) as invoice_count,
  COUNT(CASE WHEN status = 'paid' THEN 1 END) as paid_count,
  COUNT(CASE WHEN status = 'overdue' THEN 1 END) as overdue_count
FROM invoices
WHERE EXTRACT(MONTH FROM issue_date) = EXTRACT(MONTH FROM CURRENT_DATE)
  AND EXTRACT(YEAR FROM issue_date) = EXTRACT(YEAR FROM CURRENT_DATE);
```

### Get Client Lifetime Value
```sql
SELECT 
  c.company_name,
  c.total_revenue as lifetime_value,
  c.monthly_recurring as current_mrr,
  COUNT(DISTINCT p.id) as total_projects,
  MIN(p.start_date) as first_project_date,
  MAX(p.go_live_date) as latest_go_live
FROM companies c
LEFT JOIN projects p ON c.id = p.company_id
WHERE c.status IN ('active', 'inactive')
GROUP BY c.id
ORDER BY c.total_revenue DESC;
```

---

## 🔄 **SYNCING WITH HUBSPOT**

### Option A: n8n Bi-Directional Sync

**Supabase → HubSpot:**
- Already set up (webhook forwards to HubSpot)

**HubSpot → Supabase:**
1. Create n8n workflow with HubSpot trigger
2. On contact update in HubSpot → Update Supabase
3. Keeps both systems in sync

### Option B: Scheduled Sync

```python
# Python script to sync from HubSpot to Supabase
import os
from supabase import create_client
import hubspot
from hubspot.crm.contacts import SimplePublicObjectInput, ApiException

# Initialize clients
supabase = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))
hs_client = hubspot.Client.create(access_token=os.getenv("HUBSPOT_TOKEN"))

# Fetch contacts from HubSpot
hs_contacts = hs_client.crm.contacts.get_all()

# Update Supabase
for contact in hs_contacts:
    supabase.table("contacts").upsert({
        "email": contact.properties["email"],
        "first_name": contact.properties.get("firstname"),
        "last_name": contact.properties.get("lastname"),
        # ... map other fields
    }, on_conflict="email").execute()
```

---

## 🛠️ **MAINTENANCE & BACKUPS**

### Automatic Backups
Supabase automatically backs up your database daily.

**To download backup:**
1. Go to Database → Backups
2. Select backup date
3. Download

### Manual Backup
```bash
# Install Supabase CLI
npm install -g supabase

# Backup database
supabase db dump -f backup.sql
```

### Restore from Backup
```bash
psql -h db.your-project.supabase.co -U postgres -f backup.sql
```

---

## 📈 **ANALYTICS & REPORTING**

### Connect to BI Tools:

**Supabase provides direct connections to:**
- Metabase (built-in!)
- Tableau
- Power BI
- Google Data Studio
- Retool

**Connection Details:**
- Host: `db.your-project.supabase.co`
- Port: `5432`
- Database: `postgres`
- User: `postgres`
- Password: (your database password)

---

## 🚨 **TROUBLESHOOTING**

### "Permission Denied" Error
**Cause:** RLS is blocking query  
**Fix:** Use Service Role Key, not anon key

### "Duplicate Key" Error
**Cause:** Email already exists in contacts  
**Fix:** Use `upsert` instead of `insert`:

```sql
INSERT INTO contacts (email, first_name, ...) 
VALUES ('test@example.com', 'Test', ...)
ON CONFLICT (email) 
DO UPDATE SET 
  first_name = EXCLUDED.first_name,
  updated_at = NOW();
```

### "Function generate_invoice_number does not exist"
**Cause:** Setup script didn't run completely  
**Fix:** Re-run `supabase_setup.sql`

### Slow Queries
**Fix:** Check indexes exist:
```sql
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public';
```

---

## 📚 **NEXT STEPS**

### Week 1: Basic Setup
- ✅ Run setup SQL
- ✅ Add sample data
- ✅ Connect n8n to Supabase
- ✅ Test form submission

### Week 2: Integration
- 📧 Set up HubSpot bi-directional sync
- 📊 Create dashboard using views
- 🔔 Set up email notifications for new leads

### Week 3: Automation
- 📅 Auto-create meetings from calendar
- 💰 Auto-generate monthly invoices
- 📊 Weekly revenue reports

### Week 4: Advanced
- 🤖 Build admin panel (Retool/Streamlit)
- 📈 Connect to Power BI/Metabase
- 🔄 Automate client onboarding workflow

---

## 🎯 **KEY BENEFITS**

✅ **Centralized Data** - Single source of truth  
✅ **CRM Independent** - Own your data (not locked into HubSpot)  
✅ **Scalable** - Built on PostgreSQL (enterprise-grade)  
✅ **Real-Time** - Instant updates across all systems  
✅ **Analytics Ready** - Pre-built views for reporting  
✅ **Secure** - Row-level security built-in  
✅ **Free Tier** - Supabase free up to 500MB  

---

## 📞 **SUPPORT RESOURCES**

- **Supabase Docs:** https://supabase.com/docs
- **Supabase Discord:** https://discord.supabase.com
- **SQL Tutorial:** https://www.postgresqltutorial.com
- **n8n Supabase Node:** https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.supabase/

---

## ✅ **SETUP CHECKLIST**

- [ ] Created Supabase project
- [ ] Ran `supabase_setup.sql` successfully
- [ ] Inserted sample data (optional)
- [ ] Verified 10 tables exist
- [ ] Tested sample queries
- [ ] Got Supabase credentials (URL + Service Key)
- [ ] Added Supabase node to n8n workflow
- [ ] Tested form submission → Supabase
- [ ] Verified data appears in contacts table
- [ ] Tested pre-built views
- [ ] Set up RLS policies
- [ ] Documented credentials in secure location

---

## 🎉 **YOU'RE ALL SET!**

Your Supabase database is now the central hub for all Aurum Automation data. 

**What you have:**
- Professional database schema
- Form submissions auto-saved
- Ready for CRM sync
- Dashboard-ready views
- Scalable architecture
- Production-ready security

**What's next:**
Start collecting real client data and build your automation empire! 🚀

---

**Questions?** Review the detailed docs:
- `/workspace/DATABASE_SCHEMA.md` - Full schema documentation
- `/workspace/backend_integration_guide.md` - API implementation
- `/workspace/supabase_setup.sql` - The actual SQL code
- `/workspace/sample_data.sql` - Test data examples
