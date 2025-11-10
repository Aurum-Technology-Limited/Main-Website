# 🚀 Quick Reference Guide
**Aurum Automation Database - Copy & Paste Commands**

---

## 📋 **SETUP COMMANDS**

### 1. Create Supabase Project
```
1. Go to https://supabase.com
2. Click "New Project"
3. Name: aurum-automation
4. Region: US East (closest to Trinidad)
5. Set password and save it securely
```

### 2. Get Your Credentials
```
Settings → API

Copy these:
- Project URL: https://xxxxx.supabase.co
- anon public key: eyJhbGc...
- service_role key: eyJhbGc... (KEEP SECRET!)
```

### 3. Run Database Setup
```
1. SQL Editor → New Query
2. Paste contents of: supabase_setup.sql
3. Click RUN
4. Wait ~10 seconds
5. Should see: "Success. No rows returned"
```

### 4. Add Test Data (Optional)
```
1. SQL Editor → New Query
2. Paste contents of: sample_data.sql
3. Click RUN
4. Should see: Multiple inserts successful
```

---

## 🔗 **N8N INTEGRATION (EASIEST)**

### Add Supabase Node to Your Workflow

```yaml
Node Type: Supabase
Position: After webhook trigger, before HubSpot

Credentials:
  Host: https://your-project.supabase.co
  Service Role Key: [paste your service_role key]

Configuration:
  Resource: Row
  Operation: Insert
  Table: contacts
  
Field Mapping:
  first_name: {{ $json.firstName }}
  last_name: {{ $json.lastName }}
  email: {{ $json.email }}
  phone: {{ $json.phone }}
  company_name: {{ $json.company }}
  company_size: {{ $json.companySize }}
  message: {{ $json.message }}
  status: lead
  source: website
```

**Test:**
1. Submit your contact form
2. Check n8n execution log
3. Go to Supabase → Table Editor → contacts
4. Your data should be there! ✅

---

## 📊 **USEFUL QUERIES**

### See All New Leads
```sql
SELECT * FROM contacts 
WHERE status = 'lead' 
ORDER BY created_at DESC 
LIMIT 20;
```

### See Total MRR
```sql
SELECT * FROM monthly_recurring_revenue;
```

### See Active Clients
```sql
SELECT * FROM active_clients_overview;
```

### See Overdue Invoices
```sql
SELECT * FROM overdue_invoices;
```

### Get This Month's Revenue
```sql
SELECT 
  SUM(amount) as total,
  COUNT(*) as invoice_count
FROM invoices
WHERE EXTRACT(MONTH FROM issue_date) = EXTRACT(MONTH FROM CURRENT_DATE)
  AND status = 'paid';
```

### Count Leads by Source
```sql
SELECT 
  source,
  COUNT(*) as count
FROM contacts
GROUP BY source
ORDER BY count DESC;
```

---

## 🛠️ **COMMON OPERATIONS**

### Add a New Contact Manually
```sql
INSERT INTO contacts (
  first_name, last_name, email, phone, 
  company_name, company_size, message, 
  status, source
) VALUES (
  'John', 'Doe', 'john@example.com', '868-555-0123',
  'Example Corp', '11-50', 'Interested in chatbot automation',
  'lead', 'website'
);
```

### Update Contact Status
```sql
UPDATE contacts 
SET status = 'contacted' 
WHERE email = 'john@example.com';
```

### Create a Company
```sql
INSERT INTO companies (
  company_name, industry, company_size, 
  website, city, country, status
) VALUES (
  'ABC Medical Clinic', 'Healthcare', '11-50',
  'https://abcmedical.com', 'Port of Spain', 
  'Trinidad and Tobago', 'prospect'
);
```

### Link Contact to Company
```sql
UPDATE contacts 
SET company_id = (SELECT id FROM companies WHERE company_name = 'ABC Medical Clinic')
WHERE email = 'john@example.com';
```

### Create a Project
```sql
INSERT INTO projects (
  company_id, project_name, project_type, 
  description, status, setup_fee, monthly_fee
) VALUES (
  (SELECT id FROM companies WHERE company_name = 'ABC Medical Clinic'),
  'Medical Clinic AI Chatbot',
  'chatbot',
  '24/7 patient inquiry chatbot with appointment booking',
  'scoping',
  12000.00,
  3000.00
);
```

### Generate Invoice
```sql
INSERT INTO invoices (
  invoice_number, company_id, project_id,
  invoice_type, amount, currency, status,
  issue_date, due_date
) VALUES (
  generate_invoice_number(), -- Auto-generates: INV-2024-001
  (SELECT id FROM companies WHERE company_name = 'ABC Medical Clinic'),
  (SELECT id FROM projects WHERE project_name = 'Medical Clinic AI Chatbot'),
  'setup',
  12000.00,
  'TTD',
  'sent',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '15 days'
);
```

### Mark Invoice as Paid
```sql
UPDATE invoices 
SET status = 'paid', paid_date = CURRENT_DATE
WHERE invoice_number = 'INV-2024-001';
```

### Create Support Ticket
```sql
INSERT INTO support_tickets (
  ticket_number, company_id, project_id,
  subject, description, priority, status, category
) VALUES (
  generate_ticket_number(), -- Auto-generates: TKT-2024-001
  (SELECT id FROM companies WHERE company_name = 'ABC Medical Clinic'),
  (SELECT id FROM projects WHERE project_name = 'Medical Clinic AI Chatbot'),
  'Chatbot needs update',
  'Client wants to add new FAQ responses',
  'medium',
  'open',
  'feature_request'
);
```

---

## 🔍 **DASHBOARD QUERIES**

### Key Metrics for Homepage
```sql
SELECT 
  (SELECT COUNT(*) FROM contacts WHERE status = 'lead') as new_leads,
  (SELECT COUNT(*) FROM companies WHERE status = 'active') as active_clients,
  (SELECT COALESCE(SUM(monthly_recurring), 0) FROM companies WHERE status = 'active') as total_mrr,
  (SELECT COUNT(*) FROM projects WHERE status IN ('scoping', 'demo', 'in_progress')) as active_projects,
  (SELECT COUNT(*) FROM support_tickets WHERE status = 'open') as open_tickets;
```

### Lead Funnel
```sql
SELECT 
  status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM contacts
GROUP BY status
ORDER BY 
  CASE status
    WHEN 'lead' THEN 1
    WHEN 'contacted' THEN 2
    WHEN 'qualified' THEN 3
    WHEN 'converted' THEN 4
    WHEN 'lost' THEN 5
  END;
```

### Revenue by Month
```sql
SELECT 
  TO_CHAR(issue_date, 'YYYY-MM') as month,
  SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) as revenue,
  COUNT(CASE WHEN status = 'paid' THEN 1 END) as paid_invoices,
  COUNT(CASE WHEN status IN ('sent', 'overdue') THEN 1 END) as pending_invoices
FROM invoices
WHERE issue_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY TO_CHAR(issue_date, 'YYYY-MM')
ORDER BY month DESC;
```

### Top Clients by Revenue
```sql
SELECT 
  company_name,
  total_revenue,
  monthly_recurring,
  (SELECT COUNT(*) FROM projects WHERE company_id = c.id AND status = 'live') as active_projects
FROM companies c
WHERE status = 'active'
ORDER BY total_revenue DESC
LIMIT 10;
```

---

## 🔐 **SECURITY COMMANDS**

### Check RLS Status
```sql
SELECT 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

### View Existing Policies
```sql
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd 
FROM pg_policies
WHERE schemaname = 'public';
```

### Add New RLS Policy
```sql
-- Example: Allow service role to do everything
CREATE POLICY "Service role full access" ON contacts
  FOR ALL 
  USING (auth.jwt()->>'role' = 'service_role')
  WITH CHECK (auth.jwt()->>'role' = 'service_role');
```

---

## 📦 **BACKUP & RESTORE**

### Manual Backup
```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Backup
supabase db dump -f backup_$(date +%Y%m%d).sql
```

### Restore from Backup
```bash
supabase db reset --db-url "postgresql://postgres:[password]@db.your-project.supabase.co:5432/postgres"
psql -h db.your-project.supabase.co -U postgres -f backup.sql
```

---

## 🧪 **TESTING QUERIES**

### Test Data Integrity
```sql
-- Check for contacts without companies
SELECT * FROM contacts 
WHERE company_id IS NOT NULL 
  AND company_id NOT IN (SELECT id FROM companies);

-- Check for orphaned projects
SELECT * FROM projects 
WHERE company_id NOT IN (SELECT id FROM companies);

-- Check for invalid email formats
SELECT * FROM contacts 
WHERE email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$';
```

### Performance Test
```sql
-- Check query execution time
EXPLAIN ANALYZE 
SELECT * FROM contacts WHERE status = 'lead';

-- Check index usage
SELECT 
  schemaname, 
  tablename, 
  indexname, 
  idx_scan 
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

---

## 📱 **MOBILE-FRIENDLY QUERIES**

### Today's Activity
```sql
SELECT 
  'New Leads' as metric, 
  COUNT(*) as count 
FROM contacts 
WHERE created_at::date = CURRENT_DATE
UNION ALL
SELECT 
  'Meetings Today', 
  COUNT(*) 
FROM meetings 
WHERE scheduled_at::date = CURRENT_DATE AND status = 'scheduled'
UNION ALL
SELECT 
  'New Tickets', 
  COUNT(*) 
FROM support_tickets 
WHERE created_at::date = CURRENT_DATE;
```

### This Week Summary
```sql
SELECT 
  COUNT(DISTINCT CASE WHEN c.created_at > CURRENT_DATE - INTERVAL '7 days' THEN c.id END) as new_contacts,
  COUNT(DISTINCT CASE WHEN i.paid_date > CURRENT_DATE - INTERVAL '7 days' THEN i.id END) as payments_received,
  COUNT(DISTINCT CASE WHEN m.scheduled_at > CURRENT_DATE - INTERVAL '7 days' AND m.status = 'completed' THEN m.id END) as meetings_completed
FROM contacts c
CROSS JOIN invoices i
CROSS JOIN meetings m;
```

---

## 🎯 **QUICK TIPS**

### Tip 1: Always Use Transactions for Multiple Related Inserts
```sql
BEGIN;
  INSERT INTO companies (...) VALUES (...) RETURNING id;
  INSERT INTO contacts (...) VALUES (...);
  INSERT INTO projects (...) VALUES (...);
COMMIT;
```

### Tip 2: Use UPSERT for Idempotent Operations
```sql
INSERT INTO contacts (email, first_name, last_name, ...)
VALUES ('john@example.com', 'John', 'Doe', ...)
ON CONFLICT (email) 
DO UPDATE SET 
  first_name = EXCLUDED.first_name,
  updated_at = NOW();
```

### Tip 3: Use Views for Complex Recurring Queries
```sql
CREATE VIEW my_custom_report AS
SELECT ... your complex query ...;

-- Then just:
SELECT * FROM my_custom_report;
```

### Tip 4: Add Indexes for Frequently Filtered Columns
```sql
CREATE INDEX idx_custom ON table_name (column_name);
```

---

## 🚨 **TROUBLESHOOTING**

### Problem: "permission denied for table contacts"
**Solution:** You're using anon key. Switch to service_role key.

### Problem: "duplicate key value violates unique constraint"
**Solution:** Email already exists. Use UPSERT or check first:
```sql
SELECT * FROM contacts WHERE email = 'test@example.com';
```

### Problem: "relation does not exist"
**Solution:** Table not created. Re-run setup script.

### Problem: Slow queries
**Solution:** Check if indexes exist:
```sql
\d+ contacts  -- Shows indexes for contacts table
```

---

## 📞 **NEED HELP?**

- Check `/workspace/DATABASE_SETUP_README.md` for detailed guide
- Check `/workspace/DATABASE_SCHEMA.md` for full schema docs
- Check `/workspace/backend_integration_guide.md` for API setup
- Supabase Docs: https://supabase.com/docs
- SQL Tutorial: https://www.postgresqltutorial.com

---

**Pro Tip:** Bookmark this file in your browser for quick access to common commands!
