-- =====================================================
-- AURUM AUTOMATION - SUPABASE DATABASE SETUP
-- =====================================================
-- Copy and paste this entire file into Supabase SQL Editor
-- Run as a single transaction
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- STEP 1: CREATE ENUM TYPES
-- =====================================================

CREATE TYPE contact_status AS ENUM (
  'lead',
  'contacted', 
  'qualified',
  'converted',
  'lost'
);

CREATE TYPE company_status AS ENUM (
  'prospect',
  'active',
  'inactive',
  'churned'
);

CREATE TYPE project_status AS ENUM (
  'scoping',
  'demo',
  'in_progress',
  'live',
  'paused',
  'cancelled'
);

CREATE TYPE invoice_type AS ENUM (
  'setup',
  'monthly',
  'one_time',
  'tool_cost'
);

CREATE TYPE invoice_status AS ENUM (
  'draft',
  'sent',
  'paid',
  'overdue',
  'cancelled'
);

CREATE TYPE meeting_type AS ENUM (
  'discovery',
  'demo',
  'onboarding',
  'support',
  'review'
);

CREATE TYPE meeting_status AS ENUM (
  'scheduled',
  'completed',
  'cancelled',
  'no_show'
);

CREATE TYPE ticket_priority AS ENUM (
  'low',
  'medium',
  'high',
  'critical'
);

CREATE TYPE ticket_status AS ENUM (
  'open',
  'in_progress',
  'waiting',
  'resolved',
  'closed'
);

CREATE TYPE integration_status AS ENUM (
  'active',
  'inactive',
  'testing'
);

CREATE TYPE note_type AS ENUM (
  'contact',
  'company',
  'project',
  'general'
);

CREATE TYPE project_priority AS ENUM (
  'low',
  'medium',
  'high',
  'urgent'
);

-- =====================================================
-- STEP 2: CREATE TABLES
-- =====================================================

-- 1. COMPANIES TABLE
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_name VARCHAR(255) NOT NULL,
  industry VARCHAR(100),
  company_size VARCHAR(50),
  website VARCHAR(255),
  address TEXT,
  city VARCHAR(100),
  country VARCHAR(100) DEFAULT 'Trinidad and Tobago',
  status company_status DEFAULT 'prospect',
  primary_contact_id UUID,
  total_revenue DECIMAL(10,2) DEFAULT 0,
  monthly_recurring DECIMAL(10,2) DEFAULT 0,
  contract_start_date DATE,
  contract_end_date DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. CONTACTS TABLE
CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(50),
  company_name VARCHAR(255),
  company_size VARCHAR(50),
  message TEXT,
  status contact_status DEFAULT 'lead',
  source VARCHAR(100) DEFAULT 'website',
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  assigned_to UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. SERVICES TABLE
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_name VARCHAR(100) NOT NULL,
  service_category VARCHAR(50),
  description TEXT,
  base_setup_fee_min DECIMAL(10,2),
  base_setup_fee_max DECIMAL(10,2),
  base_monthly_fee_min DECIMAL(10,2),
  base_monthly_fee_max DECIMAL(10,2),
  typical_duration_weeks INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. PROJECTS TABLE
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_name VARCHAR(255) NOT NULL,
  project_type VARCHAR(100),
  description TEXT,
  status project_status DEFAULT 'scoping',
  setup_fee DECIMAL(10,2) DEFAULT 0,
  monthly_fee DECIMAL(10,2) DEFAULT 0,
  tool_costs DECIMAL(10,2) DEFAULT 0,
  start_date DATE,
  go_live_date DATE,
  demo_url VARCHAR(255),
  production_url VARCHAR(255),
  assigned_to UUID,
  priority project_priority DEFAULT 'medium',
  estimated_hours INTEGER,
  actual_hours INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. PROJECT_SERVICES TABLE (Many-to-Many)
CREATE TABLE project_services (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(project_id, service_id)
);

-- 6. INVOICES TABLE
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_number VARCHAR(50) UNIQUE NOT NULL,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  invoice_type invoice_type NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  amount_usd DECIMAL(10,2),
  currency VARCHAR(3) DEFAULT 'TTD',
  status invoice_status DEFAULT 'draft',
  issue_date DATE NOT NULL,
  due_date DATE NOT NULL,
  paid_date DATE,
  payment_method VARCHAR(50),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. MEETINGS TABLE
CREATE TABLE meetings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  meeting_type meeting_type NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_minutes INTEGER DEFAULT 30,
  status meeting_status DEFAULT 'scheduled',
  meeting_url VARCHAR(255),
  outcome TEXT,
  attendees TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. SUPPORT_TICKETS TABLE
CREATE TABLE support_tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_number VARCHAR(50) UNIQUE NOT NULL,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
  subject VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  priority ticket_priority DEFAULT 'medium',
  status ticket_status DEFAULT 'open',
  category VARCHAR(50),
  assigned_to UUID,
  resolution TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. INTEGRATIONS TABLE
CREATE TABLE integrations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  tool_name VARCHAR(100) NOT NULL,
  tool_category VARCHAR(50),
  status integration_status DEFAULT 'active',
  api_key_name VARCHAR(100),
  monthly_cost DECIMAL(10,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. NOTES TABLE
CREATE TABLE notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_type note_type NOT NULL,
  related_id UUID NOT NULL,
  note_text TEXT NOT NULL,
  created_by UUID,
  is_private BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 3: CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Contacts indexes
CREATE INDEX idx_contacts_email ON contacts(email);
CREATE INDEX idx_contacts_status ON contacts(status);
CREATE INDEX idx_contacts_company_id ON contacts(company_id);
CREATE INDEX idx_contacts_created_at ON contacts(created_at DESC);

-- Companies indexes
CREATE INDEX idx_companies_name ON companies(company_name);
CREATE INDEX idx_companies_status ON companies(status);
CREATE INDEX idx_companies_country ON companies(country);
CREATE INDEX idx_companies_contract_end ON companies(contract_end_date);

-- Projects indexes
CREATE INDEX idx_projects_company_id ON projects(company_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_assigned_to ON projects(assigned_to);
CREATE INDEX idx_projects_go_live_date ON projects(go_live_date);

-- Invoices indexes
CREATE INDEX idx_invoices_company_id ON invoices(company_id);
CREATE INDEX idx_invoices_invoice_number ON invoices(invoice_number);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);

-- Meetings indexes
CREATE INDEX idx_meetings_contact_id ON meetings(contact_id);
CREATE INDEX idx_meetings_company_id ON meetings(company_id);
CREATE INDEX idx_meetings_scheduled_at ON meetings(scheduled_at);
CREATE INDEX idx_meetings_status ON meetings(status);

-- Support Tickets indexes
CREATE INDEX idx_tickets_ticket_number ON support_tickets(ticket_number);
CREATE INDEX idx_tickets_company_id ON support_tickets(company_id);
CREATE INDEX idx_tickets_status ON support_tickets(status);
CREATE INDEX idx_tickets_priority ON support_tickets(priority);

-- Integrations indexes
CREATE INDEX idx_integrations_project_id ON integrations(project_id);
CREATE INDEX idx_integrations_tool_name ON integrations(tool_name);

-- Notes indexes
CREATE INDEX idx_notes_related_id ON notes(related_id);
CREATE INDEX idx_notes_note_type ON notes(note_type);
CREATE INDEX idx_notes_created_at ON notes(created_at DESC);

-- Project Services composite index
CREATE INDEX idx_project_services_composite ON project_services(project_id, service_id);

-- =====================================================
-- STEP 4: CREATE TRIGGER FUNCTION FOR updated_at
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON contacts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_services_updated_at BEFORE UPDATE ON services
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meetings_updated_at BEFORE UPDATE ON meetings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tickets_updated_at BEFORE UPDATE ON support_tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_integrations_updated_at BEFORE UPDATE ON integrations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notes_updated_at BEFORE UPDATE ON notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- STEP 5: CREATE USEFUL VIEWS
-- =====================================================

-- View: Active clients with project count and revenue
CREATE VIEW active_clients_overview AS
SELECT 
  c.id,
  c.company_name,
  c.industry,
  c.status,
  c.monthly_recurring,
  c.total_revenue,
  COUNT(DISTINCT p.id) as active_projects,
  SUM(p.monthly_fee) as total_monthly_fees,
  c.contract_end_date
FROM companies c
LEFT JOIN projects p ON c.id = p.company_id AND p.status = 'live'
WHERE c.status = 'active'
GROUP BY c.id
ORDER BY c.monthly_recurring DESC;

-- View: Monthly Recurring Revenue (MRR)
CREATE VIEW monthly_recurring_revenue AS
SELECT 
  SUM(monthly_fee) as total_mrr,
  COUNT(DISTINCT company_id) as active_clients,
  AVG(monthly_fee) as avg_project_fee
FROM projects
WHERE status = 'live';

-- View: Pipeline value (potential revenue)
CREATE VIEW pipeline_value AS
SELECT 
  p.status,
  COUNT(*) as project_count,
  SUM(p.setup_fee) as total_setup_fees,
  SUM(p.monthly_fee) as potential_mrr
FROM projects p
WHERE p.status IN ('scoping', 'demo', 'in_progress')
GROUP BY p.status;

-- View: Overdue invoices
CREATE VIEW overdue_invoices AS
SELECT 
  i.id,
  i.invoice_number,
  c.company_name,
  i.amount,
  i.currency,
  i.due_date,
  i.issue_date,
  CURRENT_DATE - i.due_date as days_overdue
FROM invoices i
JOIN companies c ON i.company_id = c.id
WHERE i.status IN ('sent', 'overdue') 
  AND i.due_date < CURRENT_DATE
ORDER BY i.due_date ASC;

-- View: Project timeline (for dashboard)
CREATE VIEW project_timeline AS
SELECT 
  p.id,
  p.project_name,
  c.company_name,
  p.status,
  p.priority,
  p.start_date,
  p.go_live_date,
  p.estimated_hours,
  p.actual_hours,
  ARRAY_AGG(s.service_name) as services
FROM projects p
JOIN companies c ON p.company_id = c.id
LEFT JOIN project_services ps ON p.id = ps.project_id
LEFT JOIN services s ON ps.service_id = s.id
GROUP BY p.id, c.company_name
ORDER BY p.start_date DESC;

-- View: Support ticket metrics
CREATE VIEW support_metrics AS
SELECT 
  status,
  priority,
  COUNT(*) as ticket_count,
  AVG(EXTRACT(EPOCH FROM (COALESCE(resolved_at, NOW()) - created_at))/3600) as avg_resolution_hours
FROM support_tickets
GROUP BY status, priority;

-- =====================================================
-- STEP 6: INSERT DEFAULT SERVICES
-- =====================================================

INSERT INTO services (service_name, service_category, description, base_setup_fee_min, base_setup_fee_max, base_monthly_fee_min, base_monthly_fee_max, typical_duration_weeks) VALUES
('AI Chatbot & Virtual Assistant', 'automation', '24/7 intelligent customer support that handles inquiries, qualifies leads, and provides instant responses.', 5000, 20000, 1500, 5000, 3),
('Lead Generation Automation', 'automation', 'Automated systems to capture, qualify, and nurture leads across all channels.', 8000, 25000, 2000, 6000, 4),
('Email Marketing Automation', 'automation', 'Personalized email campaigns with automated workflows and engagement tracking.', 5000, 15000, 1000, 3000, 2),
('AI Receptionist Automation', 'automation', 'Intelligent call handling, appointment scheduling, and 24/7 phone coverage.', 10000, 30000, 2500, 8000, 4),
('Social Media Automation', 'automation', 'Automated posting, engagement tracking, and social media analytics.', 4000, 12000, 800, 2500, 2),
('Workflow Integration', 'integration', 'Connect and automate workflows between your existing tools and platforms.', 3000, 15000, 500, 2000, 2),
('Custom Automation Consulting', 'consulting', 'Strategy sessions to identify automation opportunities and create implementation roadmap.', 2000, 8000, 0, 0, 1);

-- =====================================================
-- STEP 7: CREATE FUNCTION TO GENERATE INVOICE NUMBERS
-- =====================================================

CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TEXT AS $$
DECLARE
  next_num INTEGER;
  invoice_num TEXT;
BEGIN
  SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM 'INV-\d{4}-(\d+)') AS INTEGER)), 0) + 1
  INTO next_num
  FROM invoices
  WHERE invoice_number LIKE 'INV-' || TO_CHAR(CURRENT_DATE, 'YYYY') || '-%';
  
  invoice_num := 'INV-' || TO_CHAR(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_num::TEXT, 3, '0');
  RETURN invoice_num;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 8: CREATE FUNCTION TO GENERATE TICKET NUMBERS
-- =====================================================

CREATE OR REPLACE FUNCTION generate_ticket_number()
RETURNS TEXT AS $$
DECLARE
  next_num INTEGER;
  ticket_num TEXT;
BEGIN
  SELECT COALESCE(MAX(CAST(SUBSTRING(ticket_number FROM 'TKT-\d{4}-(\d+)') AS INTEGER)), 0) + 1
  INTO next_num
  FROM support_tickets
  WHERE ticket_number LIKE 'TKT-' || TO_CHAR(CURRENT_DATE, 'YYYY') || '-%';
  
  ticket_num := 'TKT-' || TO_CHAR(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_num::TEXT, 3, '0');
  RETURN ticket_num;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 9: ADD FOREIGN KEY FOR primary_contact_id
-- =====================================================

-- Add foreign key constraint (deferred because contacts references companies)
ALTER TABLE companies 
ADD CONSTRAINT fk_companies_primary_contact 
FOREIGN KEY (primary_contact_id) 
REFERENCES contacts(id) 
ON DELETE SET NULL;

-- =====================================================
-- STEP 10: CREATE RLS (Row Level Security) POLICIES
-- =====================================================
-- Note: Adjust these based on your authentication setup

-- Enable RLS on all tables
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated users (adjust based on your needs)
-- Example: Allow authenticated users to read all data
CREATE POLICY "Allow authenticated read access" ON contacts
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated read access" ON companies
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated read access" ON projects
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated read access" ON services
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated read access" ON invoices
  FOR SELECT USING (auth.role() = 'authenticated');

-- Public insert for contact form (website submissions)
CREATE POLICY "Allow public insert for contact form" ON contacts
  FOR INSERT WITH CHECK (true);

-- =====================================================
-- SETUP COMPLETE!
-- =====================================================
-- 
-- Next steps:
-- 1. Test the schema by inserting sample data
-- 2. Configure RLS policies based on your auth setup
-- 3. Create API endpoints in your backend
-- 4. Set up HubSpot sync (see HUBSPOT_INTEGRATION.md)
-- 
-- =====================================================
